# WorkNote 코드 구조(기준: 과거 코드 스냅샷)

이 문서는 **lib/** 기준 구조를 빠르게 이해하기 위한 “AI 협업용 설계도”입니다.

## 큰 그림(초등학생 버전)
- **화면(UI)**: `lib/tabs/` (홈/업무/스케줄/일지/사진/소통)
- **두뇌(상태/로직)**: `lib/providers/` (Task/Team/Chat/Journal/Auth 등)
- **창고(저장/동기화)**: `lib/services/` (Hive 로컬 DB, Drive 동기화 등)

> 규칙: UI는 Provider를 호출하고, Provider는 Service/Hive를 호출합니다.

## “기능이 사라진 것처럼 보이는” 대표 원인
- UI 파일만 바꾸고, 연결되는 Provider/Service를 같이 바꾸지 않음
- 서로 다른 구조(`tabs/providers` vs `features/...`)가 섞여 들어옴

## 작업 원칙(요청 반영)
- 폴더/파일 구조는 유지(큰 리팩토링 금지)
- 1회 작업 = 1개 체크리스트 항목 완료
