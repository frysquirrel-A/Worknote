# AGENTS.md — WorkNote Collaboration Rules

## Project
- WorkNote is a multi-context collaboration app for work, family, couples, clubs, and communities.
- Core modules that must remain intact:
  - Home
  - Tasks
  - Schedule
  - Journal
  - Gallery
  - Messenger
  - Team(Group)
  - Drawer navigation

## Core Rules (PATCH ONLY)
- Do not change folder structure.
- Do not rename files.
- Do not delete existing features.
- Do not roll back existing UI unless explicitly requested.
- Do not refactor Provider architecture.
- Do not rewrite Hive schema or migration unless explicitly instructed.
- Preserve public compatibility:
  - `AuthProvider.currentUser`
  - `AuthProvider.currentProfile`

## Protected Files
- `lib/features/tasks/ui/widgets/task_card.dart`
- `lib/features/tasks/ui/widgets/task_masonry_card.dart`

## Protected-File Override Protocol
- If a request conflicts with a protected-file rule, ask first:
  - `수정 금지 요청이 있어서 진행할 수 없는데, 그래도 수정할까요?`
- Only proceed after explicit user approval.
- Approval is task-scoped. After that task, protection resumes.

## Dangerous Actions
- Do not use destructive recovery such as `Hive.deleteBoxFromDisk(...)` at runtime.
- Do not use whole-box `clear()` for sync or reset flows unless the user explicitly requests destructive behavior.
- Do not guess Firebase, Google sign-in, bundle ID, package ID, or release-signing values.
- During UI inspection or emulator exploration, do not enter external auth, payment, logout, delete, or reset flows unless explicitly requested.

## UI / UX Defaults
- Keep the premium dark direction additive, not as a forced global reskin.
- Prefer `hintText` over `labelText` where safe.
- Use `SnackBar` for recoverable errors.
- Use `CircularProgressIndicator` or skeleton states for loading.

## Build / Test Defaults
- If dependencies changed, run `flutter pub get`.
- Run `flutter analyze` after patching. Errors must be reported immediately.
- If a task touches runtime behavior, run the narrowest relevant test or build check possible.
- If tooling is unavailable, stop and report the blocker instead of claiming success.

## Skill Routing
- Use `worknote-patch-operator` for requests like:
  - `버그 고쳐줘`
  - `이 화면 수정해줘`
  - `패치해줘`
  - `분석하고 코드까지 고쳐줘`
- Use `ui-review-operator` for requests like:
  - `스크린샷 찍어줘`
  - `에뮬레이터 화면 검토해줘`
  - `HTML 보고서로 정리해줘`
  - `화면별 기능과 사용자 컨텍스트 정리해줘`
- Use `release-audit` for requests like:
  - `배포 준비 상태 점검해줘`
  - `TestFlight 전에 뭐가 막히는지 봐줘`
  - `flutter analyze 0 맞춰줘`
  - `릴리즈 블로커 찾아줘`
- Use `skill-maker` for requests like:
  - `이거 스킬로 만들어줘`
  - `이 작업 스킬로 넣어줘`
  - `새로운 역할 추가해줘`
  - `잘 됐으니 이걸 스킬로 만들자`

## Reporting
- Always report:
  - modified files
  - added files
  - analyzer result
  - build/test result if actually run
  - remaining blockers
  - manual human-required steps

## Safety Gate
- If unsure, do not guess.
- Report the risk and ask for a decision.
