// GoalForge Cloud Functions
// functions/src/index.js
//
// Security model for awardXp:
//   - Callable function — caller must be authenticated (Firebase Auth JWT required).
//   - uid in the request payload must match the caller's auth uid to prevent
//     cross-user XP grants.
//   - amount is validated: positive integer, max 1000 per call.
//   - Atomic read-modify-write via admin.firestore().runTransaction() — eliminates
//     the race condition present in the previous client-side implementation.

"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();

const MAX_XP_PER_CALL = 1000;
const MAX_TOTAL_XP = 999_999;
const XP_PER_LEVEL_BASE = 100; // simplified; real table lives in the client constants

/**
 * Returns the level for a given totalXP using a simple progression table.
 * Mirrors AppConstants.levelXpMap from the Flutter client.
 *
 * @param {number} totalXP
 * @returns {number} level (1-based)
 */
function calculateLevel(totalXP) {
  // Level thresholds — keep in sync with lib/core/constants/app_constants.dart
  const thresholds = [
    [1, 0],
    [2, 100],
    [3, 250],
    [4, 500],
    [5, 900],
    [6, 1400],
    [7, 2000],
    [8, 2700],
    [9, 3500],
    [10, 4400],
    [11, 5500],
    [12, 6800],
    [13, 8300],
    [14, 10000],
    [15, 12000],
    [16, 14500],
    [17, 17500],
    [18, 21000],
    [19, 25000],
    [20, 30000],
  ];
  let level = 1;
  for (const [lvl, xpRequired] of thresholds) {
    if (totalXP >= xpRequired) level = lvl;
    else break;
  }
  return level;
}

/**
 * awardXp — HTTPS Callable Function
 *
 * Request payload:
 *   { uid: string, amount: number, reason: string }
 *
 * Response:
 *   { totalXP: number, level: number }
 *
 * Errors (HttpsError codes):
 *   unauthenticated — caller has no Firebase Auth token
 *   permission-denied — uid param !== caller's auth uid
 *   invalid-argument — amount is not a positive integer ≤ 1000, or uid is missing
 *   resource-exhausted — totalXP would exceed MAX_TOTAL_XP
 */
exports.awardXp = onCall(async (request) => {
  // ── 1. Auth guard ────────────────────────────────────────────────────────
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const callerUid = request.auth.uid;
  const { uid, amount, reason = "Activity Completed" } = request.data ?? {};

  // ── 2. Cross-user guard ──────────────────────────────────────────────────
  if (!uid || typeof uid !== "string") {
    throw new HttpsError("invalid-argument", "uid must be a non-empty string.");
  }
  if (uid !== callerUid) {
    throw new HttpsError(
      "permission-denied",
      "uid in request must match the authenticated caller's uid."
    );
  }

  // ── 3. Amount validation ─────────────────────────────────────────────────
  if (
    typeof amount !== "number" ||
    !Number.isInteger(amount) ||
    amount <= 0 ||
    amount > MAX_XP_PER_CALL
  ) {
    throw new HttpsError(
      "invalid-argument",
      `amount must be a positive integer no greater than ${MAX_XP_PER_CALL}.`
    );
  }

  // ── 4. Atomic read-modify-write via Firestore transaction ────────────────
  const db = getFirestore();
  const xpRef = db.collection("users").doc(uid).collection("xp").doc("profile");
  const todayStr = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
  const nowIso = new Date().toISOString();

  const { totalXP: newTotalXP, level: newLevel } = await db.runTransaction(
    async (tx) => {
      const snap = await tx.get(xpRef);
      const existing = snap.exists ? snap.data() : {};

      const currentXP = typeof existing.totalXP === "number" ? existing.totalXP : 0;

      // Cap check
      if (currentXP + amount > MAX_TOTAL_XP) {
        throw new HttpsError(
          "resource-exhausted",
          `Awarding ${amount} XP would exceed the maximum total XP cap of ${MAX_TOTAL_XP}.`
        );
      }

      const newTotalXP = currentXP + amount;
      const newLevel = calculateLevel(newTotalXP);

      // Merge xpHistory entry for today
      const xpHistory = typeof existing.xpHistory === "object" && existing.xpHistory !== null
        ? { ...existing.xpHistory }
        : {};
      xpHistory[todayStr] = (xpHistory[todayStr] ?? 0) + amount;

      // Prepend transaction record (keep most recent 50)
      const newTx = {
        id: Date.now().toString(),
        title: reason,
        amount,
        timestamp: nowIso,
        type: "general",
      };
      const transactions = Array.isArray(existing.transactions)
        ? [newTx, ...existing.transactions].slice(0, 50)
        : [newTx];

      const update = {
        totalXP: newTotalXP,
        level: newLevel,
        xpHistory,
        transactions,
        updatedAt: nowIso,
        uid,
      };

      if (snap.exists) {
        tx.update(xpRef, update);
      } else {
        // First-time profile creation — preserve any other fields from the
        // client model with safe defaults.
        tx.set(xpRef, {
          earnedBadges: [],
          unlockedBadgesMap: {},
          storyMoments: [],
          ...update,
        });
      }

      return { totalXP: newTotalXP, level: newLevel };
    }
  );

  return { totalXP: newTotalXP, level: newLevel };
});
