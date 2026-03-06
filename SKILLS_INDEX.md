# SKILLS_INDEX.md — WorkNote Skill Catalog

이 파일은 자동 트리거 규칙 파일이 아니라, 사람이 보는 운영용 스킬 카탈로그다.
실제 자동 연결은 `AGENTS.md`의 Skill Routing과 각 `SKILL.md`의 `name` / `description` 조합에 의해 결정된다.

## 현재 사용 가능한 프로젝트 스킬

| 역할명 | 역할 설명 | 언제 쓰는지 | 예시 요청 문장 | 스킬 파일 경로 |
|---|---|---|---|---|
| `worknote-patch-operator` | WorkNote 코드 패치를 안전하게 수행하는 기본 작업 스킬 | 버그 수정, UI 수정, 안정화 패치, 작은 기능 추가, 안전한 코드 변경이 필요할 때 | `이 화면 버그 고쳐줘`, `분석하고 최소 diff로 패치해줘`, `채팅 탭만 수정해줘` | `.agents/skills/worknote-patch-operator/SKILL.md` |
| `ui-review-operator` | 에뮬레이터 탐색, 스크린샷/XML 캡처, HTML 검수 보고서 생성을 담당하는 UI 검수 스킬 | 화면 검수, 스크린샷 세션, 버튼 탐색, HTML 리뷰 보고서, 기능/디자인 정리 요청이 있을 때 | `스크린샷 찍어줘`, `에뮬레이터 버튼 눌러가며 검수해줘`, `HTML 보고서로 정리해줘` | `.agents/skills/ui-review-operator/SKILL.md` |
| `release-audit` | 릴리즈 준비 상태와 배포 블로커를 점검하는 스킬 | TestFlight 준비, release blocker 확인, `flutter analyze 0`, 빌드 가능 상태 점검이 필요할 때 | `배포 전에 뭐가 막히는지 봐줘`, `TestFlight 준비 점검해줘`, `릴리즈 블로커 정리해줘` | `.agents/skills/release-audit/SKILL.md` |
| `skill-maker` | 반복 작업을 새 스킬로 승격시키고 문서 체계를 갱신하는 메타 스킬 | 새 역할을 만들거나, 잘 된 작업을 재사용 가능한 스킬로 남기고 싶을 때 | `이거 스킬로 만들어줘`, `잘 됐으니 이걸 스킬로 만들자`, `새 역할 추가해줘` | `.agents/skills/skill-maker/SKILL.md` |

## 운영 메모
- 새 스킬을 추가할 때는 먼저 기존 역할과 겹치지 않는지 확인한다.
- 새 스킬이 생기면 최소한 다음 3개를 함께 갱신한다:
  - 해당 `.agents/skills/<slug>/SKILL.md`
  - `SKILLS_INDEX.md`
  - 필요 시 `AGENTS.md`의 Skill Routing
- `AGENTS.md`는 짧게 유지하고, 자세한 절차는 각 스킬 문서에 둔다.
