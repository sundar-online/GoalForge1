// functions/test/awardXp.test.js
//
// Integration tests for the awardXp HTTPS Callable Function.
//
// Test strategy:
//   - Uses firebase-admin pointed at the Firestore emulator (FIRESTORE_EMULATOR_HOST).
//   - Imports the function handler directly from src/index.js so we can invoke
//     it with a synthetic CallableRequest object — no HTTP layer required.
//   - Each test suite tears down the xp document it touched so tests are isolated.
//
// Error code note:
//   firebase-functions-test v3 wrap() re-throws HttpsError with the raw .code
//   value (e.g. 'unauthenticated', 'invalid-argument') NOT the 'functions/' prefix
//   that the client SDK adds at the wire level. Assertions use raw codes.
//
// Run via:
//   firebase emulators:exec --only firestore --project goalforge-test "npm --prefix functions test"
// or (with emulator already running):
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npm test

"use strict";

const assert = require("assert");

// ── Emulator bootstrap ───────────────────────────────────────────────────────
// Must be set before any firebase-admin import.
const EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";
process.env.FIRESTORE_EMULATOR_HOST = EMULATOR_HOST;
process.env.FIREBASE_AUTH_EMULATOR_HOST =
  process.env.FIREBASE_AUTH_EMULATOR_HOST || "127.0.0.1:9099";

// ── firebase-functions-test in online mode ───────────────────────────────────
const testEnv = require("firebase-functions-test")(
  { projectId: "goalforge-test" },
  // No service-account key path needed — emulator ignores credentials.
);

// ── Import the function AFTER testEnv is initialised ────────────────────────
const { awardXp } = require("../src/index");
const wrapped = testEnv.wrap(awardXp);

// ── Admin Firestore (for setup/teardown) ─────────────────────────────────────
const { getFirestore } = require("firebase-admin/firestore");
const db = getFirestore();

// ── Helpers ──────────────────────────────────────────────────────────────────

/** Delete the xp/profile doc for a uid so each test starts clean. */
async function clearXpDoc(uid) {
  const ref = db.collection("users").doc(uid).collection("xp").doc("profile");
  await ref.delete().catch(() => {}); // ignore if already missing
}

/** Directly read the stored totalXP for a uid. */
async function readTotalXP(uid) {
  const ref = db.collection("users").doc(uid).collection("xp").doc("profile");
  const snap = await ref.get();
  return snap.exists ? snap.data().totalXP : null;
}

/**
 * Build a synthetic CallableRequest for wrap().
 * @param {object} data  - the request payload
 * @param {string|null} authUid - uid for auth context; null = unauthenticated
 */
function makeRequest(data, authUid) {
  return {
    data,
    auth: authUid ? { uid: authUid, token: {} } : null,
    rawRequest: {},
  };
}

// ── Test suite ───────────────────────────────────────────────────────────────

describe("awardXp Cloud Function", function () {
  // Give tests enough time for emulator round-trips and the concurrency test.
  this.timeout(25_000);

  // ── 1. Happy path — valid call, new profile ────────────────────────────────
  describe("1. Happy path — fresh profile", () => {
    const UID = "test-user-happy";

    before(async () => clearXpDoc(UID));
    after(async () => clearXpDoc(UID));

    it("returns { totalXP, level } and persists totalXP in Firestore", async () => {
      const result = await wrapped(makeRequest({ uid: UID, amount: 50, reason: "Task done" }, UID));

      assert.strictEqual(typeof result.totalXP, "number", "totalXP should be a number");
      assert.strictEqual(typeof result.level, "number", "level should be a number");
      assert.strictEqual(result.totalXP, 50, "totalXP should be 50");
      assert.strictEqual(result.level, 1, "50 XP is still level 1 (threshold: 100)");

      const stored = await readTotalXP(UID);
      assert.strictEqual(stored, 50, "Firestore doc should reflect totalXP = 50");
    });
  });

  // ── 2. Happy path — existing profile accumulates correctly ─────────────────
  describe("2. Happy path — existing profile", () => {
    const UID = "test-user-accumulate";

    before(async () => {
      await clearXpDoc(UID);
      // Seed with 80 XP so next award crosses the level-2 threshold (100 XP).
      await db.collection("users").doc(UID).collection("xp").doc("profile").set({
        totalXP: 80,
        level: 1,
        xpHistory: {},
        transactions: [],
        earnedBadges: [],
        unlockedBadgesMap: {},
        storyMoments: [],
        updatedAt: new Date().toISOString(),
        uid: UID,
      });
    });
    after(async () => clearXpDoc(UID));

    it("accumulates on existing XP and upgrades level correctly", async () => {
      const result = await wrapped(makeRequest({ uid: UID, amount: 30, reason: "Level up" }, UID));

      assert.strictEqual(result.totalXP, 110, "80 + 30 = 110");
      assert.strictEqual(result.level, 2, "110 XP should be level 2 (threshold: 100)");

      const stored = await readTotalXP(UID);
      assert.strictEqual(stored, 110, "Firestore should store 110");
    });
  });

  // ── 3. Unauthenticated call ────────────────────────────────────────────────
  describe("3. Unauthenticated call", () => {
    it("throws 'unauthenticated' when no auth context", async () => {
      let threw = false;
      try {
        await wrapped(makeRequest({ uid: "any-uid", amount: 10 }, null));
      } catch (err) {
        threw = true;
        // wrap() preserves the raw HttpsError.code without the 'functions/' prefix.
        const code = err.code.replace(/^functions\//, "");
        assert.strictEqual(code, "unauthenticated",
          `Expected 'unauthenticated', got '${err.code}'`);
      }
      assert.ok(threw, "Should have thrown");
    });
  });

  // ── 4. Cross-user call ─────────────────────────────────────────────────────
  describe("4. Cross-user call", () => {
    it("throws 'permission-denied' when uid !== auth.uid", async () => {
      let threw = false;
      try {
        await wrapped(makeRequest({ uid: "victim-uid", amount: 100 }, "attacker-uid"));
      } catch (err) {
        threw = true;
        const code = err.code.replace(/^functions\//, "");
        assert.strictEqual(code, "permission-denied",
          `Expected 'permission-denied', got '${err.code}'`);
      }
      assert.ok(threw, "Should have thrown");
    });
  });

  // ── 5. Invalid amount variants ─────────────────────────────────────────────
  describe("5. Amount validation", () => {
    const UID = "test-user-validation";
    const cases = [
      { label: "amount = 0", data: { uid: UID, amount: 0 } },
      { label: "amount = -1", data: { uid: UID, amount: -1 } },
      { label: "amount = 1001 (> MAX)", data: { uid: UID, amount: 1001 } },
      { label: "amount = 0.5 (non-integer)", data: { uid: UID, amount: 0.5 } },
      { label: "amount = 'ten' (string)", data: { uid: UID, amount: "ten" } },
      { label: "amount missing (undefined)", data: { uid: UID } },
    ];

    for (const { label, data } of cases) {
      it(`throws 'invalid-argument' for ${label}`, async () => {
        let threw = false;
        try {
          await wrapped(makeRequest(data, UID));
        } catch (err) {
          threw = true;
          const code = err.code.replace(/^functions\//, "");
          assert.strictEqual(code, "invalid-argument",
            `[${label}] Expected 'invalid-argument', got '${err.code}'`);
        }
        assert.ok(threw, `[${label}] Should have thrown`);
      });
    }
  });

  // ── 6. XP cap enforcement ──────────────────────────────────────────────────
  describe("6. XP cap enforcement", () => {
    const UID = "test-user-cap";

    before(async () => {
      await clearXpDoc(UID);
      // Seed 1 XP below the cap so a 2-XP award would exceed it.
      await db.collection("users").doc(UID).collection("xp").doc("profile").set({
        totalXP: 999_998,
        level: 20,
        xpHistory: {},
        transactions: [],
        earnedBadges: [],
        unlockedBadgesMap: {},
        storyMoments: [],
        updatedAt: new Date().toISOString(),
        uid: UID,
      });
    });
    after(async () => clearXpDoc(UID));

    it("throws 'resource-exhausted' when totalXP would exceed 999999", async () => {
      let threw = false;
      try {
        // 999_998 + 2 = 1_000_000 > 999_999
        await wrapped(makeRequest({ uid: UID, amount: 2 }, UID));
      } catch (err) {
        threw = true;
        const code = err.code.replace(/^functions\//, "");
        assert.strictEqual(code, "resource-exhausted",
          `Expected 'resource-exhausted', got '${err.code}'`);
      }
      assert.ok(threw, "Should have thrown on cap breach");
    });

    it("succeeds when totalXP lands exactly on the cap (999998 + 1 = 999999)", async () => {
      // Reset to 999_998 (the cap test above left the doc untouched — tx threw)
      await db.collection("users").doc(UID).collection("xp").doc("profile")
        .update({ totalXP: 999_998 });

      const result = await wrapped(makeRequest({ uid: UID, amount: 1 }, UID));
      assert.strictEqual(result.totalXP, 999_999, "Exact cap should succeed");
    });
  });

  // ── 7. Concurrency / race-condition regression ─────────────────────────────
  describe("7. Concurrent calls — race-condition regression", () => {
    const UID = "test-user-concurrent";

    before(async () => clearXpDoc(UID));
    after(async () => clearXpDoc(UID));

    it("two concurrent 100-XP awards produce exactly 200 XP with no lost update", async () => {
      const [r1, r2] = await Promise.all([
        wrapped(makeRequest({ uid: UID, amount: 100, reason: "Call 1" }, UID)),
        wrapped(makeRequest({ uid: UID, amount: 100, reason: "Call 2" }, UID)),
      ]);

      assert.ok(r1.totalXP > 0, `Call 1 returned totalXP=${r1.totalXP}, expected > 0`);
      assert.ok(r2.totalXP > 0, `Call 2 returned totalXP=${r2.totalXP}, expected > 0`);

      // Ground truth is Firestore — must be exactly 200.
      const stored = await readTotalXP(UID);
      assert.strictEqual(stored, 200,
        `Expected 200 XP after two concurrent 100-XP awards, got ${stored}. ` +
        `A value of 100 would indicate a lost update (race condition).`
      );
    });

    it("ten concurrent 10-XP awards produce exactly 100 XP", async () => {
      await clearXpDoc(UID); // fresh slate

      const calls = Array.from({ length: 10 }, (_, i) =>
        wrapped(makeRequest({ uid: UID, amount: 10, reason: `Batch call ${i + 1}` }, UID))
      );
      await Promise.all(calls);

      const stored = await readTotalXP(UID);
      assert.strictEqual(stored, 100,
        `Expected 100 XP from 10×10-XP concurrent awards, got ${stored}.`
      );
    });
  });
});
