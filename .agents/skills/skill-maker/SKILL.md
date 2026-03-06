---
name: skill-maker
description: Create or update reusable repo-specific skills when the user says things like '이거 스킬로 만들어줘', '이 작업 스킬로 넣어줘', '새로운 역할 추가해줘', or '잘 됐으니 이걸 스킬로 만들자'. Use when a repeated workflow should become a documented role under .agents/skills with SKILLS_INDEX.md and, if needed, minimal AGENTS.md routing updates.
---

# Skill Maker

## 역할 목적
반복 가치가 있는 작업을 새 역할 스킬로 정리하고, 그 역할이 실제로 다시 호출될 수 있도록 문서 체계를 함께 갱신한다.

## 언제 사용하는지
- 사용자가 특정 작업을 표준화하고 싶을 때
- 사용자가 새 역할이나 운영자를 추가하고 싶을 때
- 이미 잘 작동한 워크플로를 다음부터는 짧은 말로 재사용하고 싶을 때
- 기존 스킬의 이름, 설명, 트리거 문구, 절차를 손보고 싶을 때

## 새 스킬 생성 절차
1. 현재 문서 상태를 읽는다:
   - `AGENTS.md`
   - `SKILLS_INDEX.md`
   - 기존 `.agents/skills/*/SKILL.md`
2. 새 역할이 진짜로 분리 가치가 있는지 판단한다.
   - 기존 스킬을 확장하면 충분한지 먼저 검토한다.
3. 역할명을 기억하기 쉬운 slug로 정한다.
   - 소문자, 숫자, 하이픈만 사용한다.
   - 역할 중심 이름으로 짓는다.
4. `SKILL.md`를 만든다.
   - YAML front matter에는 `name`, `description`만 둔다.
   - `description`에는 언제 이 스킬을 써야 하는지 트리거 문구를 구체적으로 적는다.
   - 본문에는 실행 절차, 금지 행동, 중단 조건, 최종 보고 형식을 넣는다.
5. `SKILLS_INDEX.md`를 갱신한다.
   - 역할명
   - 역할 설명
   - 언제 쓰는지
   - 예시 요청 문장
   - 실제 파일 경로
6. `AGENTS.md`의 Skill Routing을 검토한다.
   - 자주 쓰일 역할만 최소 반영한다.
   - 라우팅이 과도하게 늘어나지 않게 유지한다.
7. 충돌 여부를 다시 확인한다.
   - 기존 역할과 설명이 겹치지 않는지 확인한다.
   - 관련 없는 기존 내용은 유지한다.

## 금지 행동
- 같은 역할을 이름만 바꿔 중복 생성하지 않는다.
- `AGENTS.md`를 장문 절차 문서로 만들지 않는다.
- `SKILLS_INDEX.md`를 자동 트리거 규칙 파일처럼 취급하지 않는다.
- 실제 프로젝트와 무관한 범용 역할을 과도하게 추가하지 않는다.
- 기존 스킬을 설명 없이 덮어쓰지 않는다.

## 중단 조건
- 새 역할과 기존 역할의 경계가 불명확할 때
- 사용자가 원하는 반복 작업이 아직 충분히 검증되지 않았을 때
- AGENTS 라우팅을 늘리면 오히려 혼란이 커질 때
- 기존 문서와 충돌하지만 어느 쪽이 최신인지 판단할 근거가 없을 때

## 최종 보고 형식
- 왜 새 스킬이 필요한지
- 생성/수정한 스킬 slug
- 생성/수정한 파일 목록
- `AGENTS.md` 라우팅 변경 여부
- `SKILLS_INDEX.md` 반영 내용
- 앞으로 이 스킬을 어떻게 호출하면 되는지
