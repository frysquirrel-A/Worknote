# AI_CHECKLIST.md — WorkNote Safe Patch Checklist for Codex

## Purpose
This file is a safety checklist for AI agents working on the WorkNote Flutter repository.

Use this before and after every patch.

The priority is:
1. Do not break existing features
2. Do not corrupt data
3. Do not regress UI
4. Do not refactor architecture unless explicitly requested

## 1. PATCH ONLY RULE
Before modifying anything, confirm:
- Am I applying a minimal diff?
- Am I preserving file names and folder structure?
- Am I keeping existing functionality?
- Am I avoiding broad refactors?

If the answer is "no" to any of these, stop and report.

## 2. PROTECTED FILES
These files are protected and must not be modified unless the user explicitly approves:
- `lib/features/tasks/ui/widgets/task_card.dart`
- `lib/features/tasks/ui/widgets/task_masonry_card.dart`

If a requested fix seems to require editing these files:
- stop
- explain why
- ask for explicit approval

## 3. ARCHITECTURE GUARDRAILS
Do not change these unless explicitly asked:
- Provider-based state architecture
- Hive persistence model
- Firebase integration structure
- Main tab structure
- Drawer-based major navigation
- AuthProvider public compatibility:
  - `currentUser`
  - `currentProfile`

Do not replace Provider with another state management solution.
Do not move features between layers.

## 4. HIVE / LOCAL DATA SAFETY
Before touching persistence code, check:
- Am I deleting a box or clearing all records?
- Am I changing a key name?
- Am I changing object meaning without migration?
- Am I introducing destructive sync?

Forbidden patterns unless explicitly approved:
- `Hive.deleteBoxFromDisk(...)` as runtime recovery
- whole-box `clear()` during sync
- schema-breaking model changes without migration
- cross-profile or cross-team data writes

Preferred patterns:
- merge-by-id
- per-record put/delete
- preserve auth/profile identity data
- report manual migration needs instead of guessing

## 5. PROVIDER LIFECYCLE SAFETY
When editing widget/provider interaction, always check:
- no `notifyListeners()` during build
- no `setState()` after dispose
- after async gaps, check `mounted` before using context
- do not introduce circular provider updates
- do not reset tab/provider state unexpectedly on navigation

If adding async UI code, prefer:

```dart
if (!mounted) return;
```

Apply that guard before:
- Navigator calls
- SnackBar
- dialogs
- bottom sheets
- `context.read/watch` dependent actions

## 6. UI REGRESSION SAFETY
Before changing UI, check:
- Am I preserving the existing screen structure?
- Am I changing a visual style only, not behavior?
- Am I touching a screen outside the requested scope?
- Am I removing any visible information from cards/forms?

Never remove core information from task cards, including:
- created date
- updated date
- due date
- plan/calendar toggle
- assignee
- priority
- status

Use:
- `SnackBar` for recoverable error
- `hintText` preferred over `labelText`
- premium dark direction if styling is being updated

Do not introduce a brand-new design system if only polish is requested.

## 7. MESSENGER SAFETY
Messenger is a core module.

Do not:
- remove messenger tab
- break DM thread behavior
- break group thread behavior
- remove AI conversation hooks if present
- rewrite message model without migration plan

If working on messenger:
- preserve existing thread IDs
- preserve empty-message guard
- avoid destructive full-box sync
- keep keyboard dismissal and input behavior intact

## 8. RELEASE SAFETY
Before changing native config, check:

Android:
- INTERNET permission present
- do not guess final applicationId
- do not silently keep debug signing as a production solution
- report SHA/manual Firebase setup clearly

iOS:
- do not invent real `REVERSED_CLIENT_ID` values
- if `GoogleService-Info.plist` is missing, report as manual blocker
- add only permissions actually needed by features

If native config cannot be fully completed from repo context:
- patch only what is safe
- report remaining human-required steps

## 9. DEPENDENCY SAFETY
Before removing any package from `pubspec.yaml`:
- search the whole repository first
- confirm it is unused in actual source
- confirm it is not needed by generated/native/build files
- if uncertain, report only and do not remove

Never remove dependencies just because they looked unused in an incomplete snapshot.

## 10. PLACEHOLDER / INCOMPLETE FILE SAFETY
If a file appears to be:
- placeholder content
- truncated
- binary/unreadable
- clearly different from planning docs

Then:
- inspect the real repository version first
- do not assume old snapshot content is still current
- apply only minimal changes after inspection
- if uncertain, report and stop

## 11. RESPONSIVE UI SAFETY
When adjusting layout:

Prefer:
- `SafeArea`
- `Expanded` / `Flexible`
- spacing cleanup
- `MediaQuery` only when needed

Avoid:
- hardcoded fixed widths/heights unless already strongly intentional
- rewriting entire layouts
- replacing working layouts just for aesthetics

Always check likely overflow zones:
- app bars
- drawer headers
- chips
- bottom sheets
- composer/input rows
- long title rows

## 12. INTERACTION SAFETY
When adding haptics / animation:

Allowed:
- `HapticFeedback.lightImpact()` on important CTAs
- `HapticFeedback.selectionClick()` on tab/chip switches
- tiny press-scale interactions

Avoid:
- animation spam
- global behavior rewrites
- changing every button at once
- introducing inconsistent duplicate interaction systems

Prefer reusing existing shared interaction widgets.

## 13. COMMAND SAFETY
Recommended workflow:
- inspect relevant files
- apply a small patch
- run `flutter analyze`
- if safe, continue
- report modified files and manual steps

If environment allows, optional:
- `flutter build apk --debug`
- `flutter build ios --no-codesign`

Do not claim build success without actually running the build.

## 14. STOP CONDITIONS
Stop immediately and report if any of these occur:
- protected files would need modification
- Hive migration is required
- Provider architecture would need redesign
- analyzer errors appear and need broad refactor
- real repository differs significantly from planning assumptions
- requested change would delete or disable a feature

## 15. FINAL REPORT FORMAT
Every task should end with:
- Modified files
- Added files
- Analyzer result
- Build result (only if actually run)
- Protected files untouched: yes/no
- Manual human-required steps
- Remaining blockers (P0 / P1)

## 16. WORKNOTE-SPECIFIC REMINDERS
This app is not work-only.
It supports:
- work
- family
- couples
- clubs
- communities

Therefore:
- avoid construction-only wording
- avoid work-only assumptions
- keep language broad and inclusive across contexts

Preferred vocabulary:
- `plan / 계획` in task context

Keep Home / Tasks / Schedule / Journal / Gallery / Messenger all intact.

## 17. IF UNSURE
If unsure:
- do not invent
- do not refactor
- do not "clean up" broadly
- report uncertainty clearly
