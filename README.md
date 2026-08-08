# GoalForge

A Flutter productivity app built on Firebase Auth + Firestore with Flutter BLoC state management.

## Getting Started

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## Firebase Setup

`lib/firebase_options.dart` and `android/app/google-services.json` are listed in
`.gitignore` and **must never be committed**.  Real credentials are generated locally
by the FlutterFire CLI and injected in CI via GitHub Actions secrets.

### Local development

1. Copy the template file:
   ```bash
   cp lib/firebase_options.dart.example lib/firebase_options.dart
   ```
2. Run the FlutterFire CLI to replace all placeholder values with real credentials:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This regenerates `lib/firebase_options.dart` **and** `android/app/google-services.json`
   automatically from your Firebase project.

### CI / GitHub Actions

The workflows in `.github/workflows/` reference two repository secrets:

| Secret name           | Description                                      |
|-----------------------|--------------------------------------------------|
| `FIREBASE_API_KEY`    | Web API key from the Firebase console            |
| `FIREBASE_PROJECT_ID` | Firebase project ID (e.g. `goalforge-fcae0`)    |

Add these in **Settings → Secrets and variables → Actions** on GitHub before running
any security workflow.

### Cloud Functions

XP awarding is handled server-side by the `awardXp` Cloud Function under `functions/`.
Deploy with:
```bash
cd functions && npm install
firebase deploy --only functions
```
