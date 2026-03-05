# AGENTS.md — WorkNote Codex Rules

## Golden Rules (PATCH ONLY)
- DO NOT change folder structure
- DO NOT rename files
- DO NOT delete existing features
- DO NOT roll back UI
- DO NOT refactor Provider architecture
- DO NOT rewrite Hive schema/migration unless explicitly instructed
- Maintain public API compatibility:
  - AuthProvider.currentUser
  - AuthProvider.currentProfile

## Protected files (MUST NOT MODIFY)
- lib/features/tasks/ui/widgets/task_card.dart
- lib/features/tasks/ui/widgets/task_masonry_card.dart

## Protected-File Override Protocol
- If a request conflicts with any "MUST NOT MODIFY" or similar no-edit clause, ask first:
  - "수정 금지 요청이 있어서 진행할 수 없는데, 그래도 수정할까요?"
- Only proceed after explicit user approval.
- Approval is task-scoped (only the approved files/scope), then protection resumes.
- Without explicit approval, do not edit protected files.

## Required Modules (MUST stay)
Home / Tasks / Schedule / Journal / Gallery / Messenger / Team(Group) / Drawer navigation

## UI Policy
- Keep premium dark direction (do not re-skin whole app unless requested)
- Prefer hintText over labelText
- Loading: CircularProgressIndicator or skeleton
- Errors: SnackBar

## Workflow
1) Apply patches using minimal diffs
2) Run:
   - flutter pub get
   - flutter analyze (errors must be 0)
3) If analyzer errors occur: stop and report
4) Report output must include:
   - modified files
   - added files
   - analyzer result
   - build result (if run)
   - remaining manual steps

## Safety Gate
If you are unsure about a change, DO NOT change code.
Report the risk and ask for a decision.
