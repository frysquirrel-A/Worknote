# WorkNote

WorkNote is a multi-context collaboration app for work, family, couples, clubs, and communities.
Users organize each life context as a separate group while managing tasks, schedules, journals, gallery items, and messenger threads inside one app.

## Core Modules
- Home
- Tasks
- Schedule
- Journal
- Gallery
- Messenger
- Team / Group management
- Drawer-based profile and settings flows

## Tech Stack
- Flutter / Dart
- Provider
- Hive (local-first persistence)
- Firebase Core / Crashlytics / Firestore

## Current Product Direction
- Local-first multi-profile auth flow
- Optional Google linking on top of local profiles
- Premium dark tokens added additively, not as a forced global reskin
- Release target: TestFlight-ready build with zero analyzer errors

## Important Architecture Rule
UI → Provider → Hive / Firebase

Do not refactor this architecture unless explicitly requested.

## Protected UI Files
These task card files are protected and must not be modified without explicit approval:
- `lib/features/tasks/ui/widgets/task_card.dart`
- `lib/features/tasks/ui/widgets/task_masonry_card.dart`

## Basic Workflow
1. Apply minimal diffs
2. Run `flutter analyze`
3. Run the narrowest relevant verification for the change
4. Report remaining manual release steps separately
