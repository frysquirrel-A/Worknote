# ARCHITECTURE.md — WorkNote Architecture & Patch Rules

## 1. Product Identity
WorkNote is NOT a construction-only app.
It’s a multi-context collaboration hub: work + family + couples + clubs + communities.
Users separate life contexts into multiple **Groups** and manage them in one app.

## 2. Technical Stack
- Flutter (Dart)
- Provider (state management)
- Hive (local-first persistence)
- Firebase (Core, Crashlytics, Firestore feedback)

Data flow:
UI → Provider → Hive/Firebase

## 3. Non-Negotiable Rules (PATCH ONLY)
Never do:
- Change folder structure
- Rename files
- Delete existing features
- Roll back existing UI
- Replace Provider architecture
- Global refactor across unrelated modules
- Schema-breaking Hive changes without explicit migration plan

Compatibility must remain:
- AuthProvider.currentUser
- AuthProvider.currentProfile

## 4. Module Contracts

### 4.1 Auth / Profiles
- Local-first + Google multi-profile exists.
- Profiles represent user identity; current profile must be switchable.
- Any auth work must not spill into unrelated screens.

### 4.2 Team/Group
- Multi-group structure exists.
- Switching groups is a high-risk operation (state mixing).
- Must ensure safe switch and prevent cross-team data bleed.

### 4.3 Tasks
Task UI is high-risk and must keep its informational density:
- created date
- updated date
- due date
- plan include toggle (calendar icon)
- assignee
- priority
- status (ToDo / InProgress / Done)
- policy: show "계획" in task context (not "일정")

Protected UI files must not be modified:
- task_card.dart
- task_masonry_card.dart

### 4.4 Schedule
- Combines personal schedules and task plans.
- Must not regress on boot load (avoid "empty on restart" bug).
- Visualizes conflicts in future scope, but not required now.

### 4.5 Journal
- Feed-style entries
- Photos + attachment surfaces
- Connect to task/project when applicable
- Defensive lifecycle handling (no disposed controller usage)

### 4.6 Gallery
- Aggregates journal/chat images
- Grid + viewer
- Must handle image load failures gracefully

### 4.7 Messenger
- Core module
- Supports group threads + DM threads
- Must never disappear
- AI conversation feature must not be removed (if present in the codebase)

## 5. Data Safety Rules

### 5.1 Hive safety
- Never delete a Hive box on open failure as "recovery".
- Avoid whole-box `clear()` during sync unless the user explicitly resets.
- Prefer merge-by-id updates (put per id).

### 5.2 Provider lifecycle safety
- Avoid notifyListeners during build.
- Avoid setState after dispose.
- After async work: always check mounted before using context in widgets.

## 6. Release Readiness
- `flutter analyze`: 0 errors required
- Crashlytics receives errors in test builds
- TestFlight build must compile and run
- Manual steps (human required):
  - iOS GoogleService-Info.plist + URL scheme configuration
  - Android release keystore + SHA registration in Firebase console
  - Bundle ID / package ID finalize

## 7. How Codex should work on this repo
- Always read AGENTS.md + PROJECT_MAP.md + RELEASE_CHECKLIST.md + this file first.
- Work in small diffs.
- After each patch:
  - flutter pub get (if dependencies touched)
  - flutter analyze
- Stop immediately if protected files are modified or analyzer errors appear.
