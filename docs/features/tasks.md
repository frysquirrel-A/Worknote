# Tasks 기능

## 위치
- UI: `lib/features/tasks/ui/`
- State: `lib/features/tasks/state/task_provider.dart`

## 주요 파일
- `ui/task_tab.dart`
  - 업무 탭 메인 화면.
  - 상단 `TaskFilterBar`로 필터(프로젝트/상태/중요도/담당자) + 그룹/정렬/보기(리스트·갤러리) 컨트롤.
  - 카드 레이아웃: `TaskCard`(리스트), `TaskMasonryCard`(갤러리).
- `ui/widgets/task_filter_bar.dart`
  - 필터 UI.
  - 중요도는 `TaskPriority?`(null=전체)로 관리.
  - 정렬 기준은 `TaskSortField`.
- `ui/task_sort_field.dart`
  - UI 정렬 기준 enum.
- `state/task_provider.dart`
  - Hive 박스 로딩, Task/Project CRUD, 메타(계획/달력 포함) 저장.

## 메타 저장 규칙(Hive: `task_meta`)
- key: `taskId`
- value: `Map<String, dynamic>`

사용 key:
- `planInclude` : bool (기본 true)
- `scheduleInclude` : bool (기본 true)
- `scheduleStart` : ISO8601 String? (nullable)
- `scheduleEnd` : ISO8601 String? (nullable)

> `AppResetService`의 샘플 데이터도 동일 키를 사용하도록 맞춰야 합니다.

## 계획(달력) 포함 토글
- 카드의 달력(📅) 아이콘을 누르면 `TaskProvider.setScheduleOptions()`를 호출해서
  `scheduleInclude`와 기간(시작/끝)을 저장합니다.
- 기간이 없으면 `dueDate` 기반으로 fallback 합니다(`effectiveScheduleRange`).
