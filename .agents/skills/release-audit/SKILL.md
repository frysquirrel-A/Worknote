---
name: release-audit
description: WorkNote release readiness and blocker audit. Use when the user asks about TestFlight readiness, release blockers, flutter analyze 0, build verification, native config gaps, manual launch requirements, or wants a focused release check without broad product refactoring.
---

# Release Audit

## Purpose
Audit WorkNote for release readiness with emphasis on build health, analyzer status, native configuration gaps, and manual human-required steps.

## Read First
Read these files before auditing:
- `AGENTS.md`
- `PROJECT_MAP.md`
- `ARCHITECTURE.md`
- `RELEASE_CHECKLIST.md`
- `AI_CHECKLIST.md`

## Workflow
1. Inspect the current repository and native config.
2. Run the minimum relevant checks:
   - `flutter pub get` if needed
   - `flutter analyze`
   - targeted build checks if tooling is available
3. Separate findings into:
   - code blockers
   - configuration blockers
   - manual human-required release steps
4. Report only what is verified from the real repo or actual command output.

## Focus Areas
- analyzer errors and high-risk warnings
- Android manifest and build config gaps
- iOS plist and sign-in scheme gaps
- release signing/manual config blockers
- Crashlytics/Firebase setup blockers
- data corruption or destructive recovery risks

## 금지 행동
- Do not invent missing Firebase values.
- Do not guess final application IDs, bundle IDs, or signing identities.
- Do not silently “fix” release settings by using debug settings as if they were production-ready.
- Do not broaden a release audit into unrelated UI refactoring.

## 중단 조건
Stop and report if:
- Flutter tooling is unavailable
- native build tooling is unavailable
- fixes would require broad architecture refactors
- release blockers depend on secrets or files not present in the repo

## 최종 보고 형식
- checks actually run
- analyzer result
- build result
- confirmed release blockers
- manual human-required steps
- recommended next release actions
