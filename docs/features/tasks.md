# Tasks 기능

## 위치
- UI: `lib/features/tasks/ui/`
- State: `lib/features/tasks/state/task_provider.dart`

## 주요 카드 UI (Hybrid 개편)
- **TaskCard (리스트형)**
  - **구획 분리**: 좌측(체크 버튼 및 중요도), 중앙(프로젝트명, 제목, 상세 날짜), 우측(작성자 및 담당자)으로 구획을 명확히 나누고 수직 구분선 추가.
  - **날짜 정보 (2줄 밀집)**: 
    - 1줄: 작성일, 기한(빨간색 강조)
    - 2줄: 수정일, 일정(계획) 또는 완료일 표시.
  - **인적 정보**: 작성자와 담당자를 수직으로 나란히 배치하여 시인성 강화.
  - **캘린더 토글**: 중앙 우측에 독립된 버튼으로 배치하여 직관적인 일정 연동 지원.

- **TaskMasonryCard (갤러리형)**
  - 리스트형과 동일한 정보 위계 유지.
  - 프로젝트 태그, 중요도, 상태 배지, 기한, 캘린더 아이콘, 담당자 에모지를 갤러리 카드 레이아웃에 맞춰 조밀하게 배치.

## 주요 컨트롤 및 로직
- **일정 연동**: 카드 내 캘린더 아이콘 터치 시 `TaskProvider.setScheduleOptions()`를 호출하여 `includeInSchedule` 및 기간 저장.
- **데이터 격리 (Isolation)**: 팀 전환 시 해당 팀에 소속된 프로젝트와 업무 데이터만 완벽하게 필터링되도록 보장.
- **프로젝트 정보**: `# 프로젝트명` 태그를 상단에 노출하여 업무의 소속을 즉시 파악 가능.

## 관련 파일
- `lib/features/tasks/ui/widgets/task_card.dart`
- `lib/features/tasks/ui/widgets/task_masonry_card.dart`
