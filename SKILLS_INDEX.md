# SKILLS_INDEX.md — WorkNote Skill Catalog

This file is a human/operator catalog. It is not the automatic routing source of truth.
Automatic routing is decided by `AGENTS.md` plus each `SKILL.md` file's `name` and `description`.

## Available Project Skills

| Role | Description | When to Use | Example Request | Skill File |
|---|---|---|---|---|
| `worknote-patch-operator` | Safe patch workflow for real repository changes. | Use for bug fixes, UI polish, stability patches, and small feature work that must preserve Provider/Hive/Firebase architecture. | `이 화면 버그 고쳐줘`, `분석하고 최소 diff로 패치해줘`, `실제 코드 수정해줘` | `.agents/skills/worknote-patch-operator/SKILL.md` |
| `ui-review-operator` | Safe UI exploration, screenshot capture, and HTML review reporting. | Use for emulator walkthroughs, screenshot sessions, runtime UI verification, and HTML review packages for humans or other AIs. | `스크린샷 찍어줘`, `HTML 리뷰 보고서 만들어줘`, `에뮬레이터 화면 검수해줘` | `.agents/skills/ui-review-operator/SKILL.md` |
| `release-audit` | Release-readiness audit for build blockers and manual gaps. | Use before TestFlight or release work to separate code-safe fixes from manual human-required steps. | `릴리즈 블로커 찾아줘`, `TestFlight 전에 뭐가 막히는지 점검해줘`, `배포 준비 상태 audit 해줘` | `.agents/skills/release-audit/SKILL.md` |
| `skill-maker` | Meta skill for turning a successful repeated workflow into a reusable project skill. | Use when a task pattern has stabilized and should be turned into a new reusable role plus documentation updates. | `이 작업 스킬로 만들어줘`, `잘 됐으니 이걸 스킬로 만들자`, `새 역할 추가해줘` | `.agents/skills/skill-maker/SKILL.md` |

## Operating Notes
- Before adding a new skill, confirm it does not overlap too heavily with an existing one.
- When a new skill is created, update these three places together:
  - the new `.agents/skills/<slug>/SKILL.md`
  - `SKILLS_INDEX.md`
  - `AGENTS.md` skill routing only if the new routing is actually needed
- Keep `AGENTS.md` short and policy-oriented. Put detailed workflows inside each skill file.
