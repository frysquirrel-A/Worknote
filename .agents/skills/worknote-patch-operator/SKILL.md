---
name: worknote-patch-operator
description: Safe WorkNote Flutter patch workflow. Use when the user asks to fix bugs, patch UI, adjust flows, stabilize runtime behavior, or implement small features in the real repository while preserving Provider/Hive/Firebase architecture, protecting task card UI files, and validating changes with flutter analyze.
---

# WorkNote Patch Operator

## Purpose
Execute minimal, safe patches in the WorkNote repository without breaking architecture, data safety, or protected UI files.

## Read First
Before editing, read these files if present:
- `AGENTS.md`
- `PROJECT_MAP.md`
- `ARCHITECTURE.md`
- `RELEASE_CHECKLIST.md`
- `PATCHLOG.md`
- `AI_CHECKLIST.md`

## Workflow
1. Inspect the real repository state first. Do not trust placeholder patch text over source code.
2. Limit scope to the user's requested change.
3. Apply the smallest defensible diff.
4. If dependencies changed, run `flutter pub get`.
5. Run `flutter analyze`.
6. Run only the narrowest relevant test/build check for the change.
7. Report blockers immediately if the environment prevents verification.

## Guardrails
- PATCH ONLY.
- No file or folder renames.
- No feature removal.
- No architecture refactors.
- No Hive schema rewrite without explicit migration approval.
- Preserve:
  - `AuthProvider.currentUser`
  - `AuthProvider.currentProfile`

## Protected Files
Do not modify these unless the user explicitly approves it for the current task:
- `lib/features/tasks/ui/widgets/task_card.dart`
- `lib/features/tasks/ui/widgets/task_masonry_card.dart`

If a requested fix requires them, ask exactly:
- `수정 금지 요청이 있어서 진행할 수 없는데, 그래도 수정할까요?`

## Risk Checks
- Do not introduce destructive sync logic.
- Do not guess Firebase or native signing values.
- Do not broaden a local fix into a repo-wide cleanup.
- If a change touches persistence, auth, team switching, or chat scoping, re-check the data safety rules in `AI_CHECKLIST.md`.

## Stop Conditions
Stop and report if:
- protected files would need modification without approval
- analyzer errors would require a broad refactor
- Hive migration is required
- repo content differs materially from planning assumptions
- runtime verification is blocked by missing tooling

## Final Report
Always return:
- Modified files
- Added files
- Key fixes applied
- Analyzer result
- Build/test result (only if actually run)
- Protected files untouched: yes/no
- Manual human-required steps
- Remaining blockers (P0 / P1)
