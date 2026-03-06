# PROJECT_MAP.md — WorkNote Project Map (Codex)

## Purpose
This file is a fast navigation map for Codex.
WorkNote is a multi-context collaboration app (work + family + couples + clubs + communities).
The app organizes life contexts into multiple Groups and provides unified management:
Tasks / Schedule / Journal / Gallery / Messenger.

## Golden Rule
PATCH ONLY. No architecture refactors. No file/folder renames. No feature removal.

## App Shell & Navigation
- **lib/app/main_shell.dart**
  - Bottom navigation tabs:
    - Home
    - Tasks
    - Schedule
    - Journal
    - Gallery
    - Messenger
  - Must preserve the existing tab structure.
  - Preferred: use IndexedStack to preserve tab state (no state reset on tab switch).

- **Drawer**
  - Entry point to profile switching / team switching / settings / reset tools.
  - Must not break existing routes and drawer flows.

## Providers (Do not re-architect)
- **AuthProvider**
  - Compatibility MUST be preserved:
    - `currentUser`
    - `currentProfile`
  - Local-first + Google multi-profile concept exists.
  - Any auth work must not refactor unrelated screens.

- **TeamProvider**
  - Handles team/group switching.
  - High risk: state mixing when team changes.
  - Must ensure membership and safe switching without data corruption.

- **TaskProvider**
  - Task lifecycle + metadata.
  - High risk: Task UI regression (must preserve card fields & plan toggle).
  - Terms policy: prefer "계획(Plan)" over "일정" on task card context.

- **ScheduleProvider**
  - Personal schedules + task plan aggregation.
  - Risk: missing boot load leading to empty schedules.

- **ChatProvider**
  - Threads (group + DM) + message list.
  - Risk: thread scoping / message scoping.
  - Messenger is core module and must never be removed.

## Data Stores
### Hive (Local-first)
Main boxes (names may exist in bootstrap/setup):
- settings
- tasks + task_meta
- projects
- journals + journal_meta
- teams
- users
- messages (chat)
- crash_logs / dev_logs (if present)

High-risk patterns:
- Any auto-recovery that deletes boxes on open failure (data loss risk).
- Whole-box `clear()` during sync without merge-by-id (data loss risk).

### Firebase
Enabled:
- Firebase Core
- Crashlytics
- Firestore (feedback write path)

Not in scope unless explicitly requested:
- Storage
- FCM

## Modules (Must keep)
- Home: summary + quick entry
- Tasks: creation, assignee, due, priority, status, plan toggle
- Schedule: calendar + personal schedules + task plans
- Journal: feed + write sheet + photos + connect to tasks/projects
- Gallery: image grid + viewer (team scoped)
- Messenger: group chat + DM + media (and AI conversation must not disappear)

## Protected Files (MUST NOT MODIFY)
- lib/features/tasks/ui/widgets/task_card.dart
- lib/features/tasks/ui/widgets/task_masonry_card.dart

## UX Policy
- Errors: SnackBar
- Loading: CircularProgressIndicator or premium skeleton
- Input fields: prefer hintText over labelText
- Theme direction: premium dark tokens may be added additively; do not force global theme rewrite unless asked.

## Release Goal
TestFlight-ready build:
- Crash 0
- Data corruption 0
- Feature loss 0
- UI regression 0
