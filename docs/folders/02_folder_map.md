# 02. 폴더별 역할

## `lib/app/`
앱 시작/쉘(탭)/전역 위젯.

- `bootstrap.dart`
  - Hive 초기화, Adapter 등록, Box 오픈.
  - `runApp()` 전에 1회 실행.
- `worknote_app.dart`
  - MaterialApp 설정(테마, 폰트 등).
- `main_shell.dart`
  - 하단 탭 UI, 탭 간 이동, 특정 탭(메신저)으로 점프하는 헬퍼.
- `widgets/master_drawer.dart`
  - 디버그/운영 도구 메뉴(리셋, 샘플 데이터, ...).

## `lib/core/`
앱 전반에서 공통으로 쓰는 UI/테마/유틸.

- `theme/app_theme.dart`
  - ThemeData 생성 및 스타일 상수.
- `ui/app_palette.dart`
  - 컬러 팔레트(텍스트/보더/...)
- `ui/widgets/`
  - 범용 위젯 모음(현재는 확장 여지).
- `crash/`
  - 전역 에러 수집/저장(CrashReporter).

## `lib/domain/`
데이터 모델(순수 타입).

- `models.dart`
  - `AppUser`, `Team`, `Project`, `Task`, `ChatThread`, `ChatMessage`, `JournalEntry`, `ScheduleEntry` 등.
  - Hive 저장을 위한 `HiveType/HiveField` 메타를 포함.

## `lib/data/`
로컬 저장/외부 API(예: Drive) 등 **인프라 계층**.

- `services/local_db_service.dart`
  - `local_settings` Box를 통한 key-value 설정 저장.
- `services/app_reset_service.dart`
  - 박스 초기화 / 샘플 데이터 시드.
- `services/drive_service.dart`
  - Drive 연동 관련(현재는 뼈대/확장용).
- `hive/hive_adapters.dart`
  - Hive 어댑터 등록(도메인 타입 매핑).
- `migrations/hive_migrations.dart`
  - Hive 스키마 버전/마이그레이션.
- `sync/sync_outbox.dart`
  - Outbox 패턴(로컬 변경 이벤트 큐).

## `lib/features/`
기능 단위 모듈. 각 feature는 대략
- `state/` : ChangeNotifier Provider
- `ui/` : 화면/위젯

주요 feature:
- `home/` : 홈 탭(팀 선택, 팀원, 프로젝트 현황, 오늘의 업무)
- `tasks/` : 업무 탭(필터, 정렬, 카드/갤러리 뷰, 상세/추가 바텀시트)
- `schedule/` : 계획 탭(개인 계획 항목 관리)
- `journal/` : 기록 탭
- `chat/` : 메신저 탭
- `team/` : 팀 데이터 관리

## `lib/tabs/`
과거 구조 호환용(legacy).

- `task_tab.dart`
  - 예전 import 경로(`lib/tabs/task_tab.dart`)가 남아있어도 빌드가 깨지지 않도록,
    새 `features/tasks/ui/task_tab.dart`로 forwarding하는 래퍼.
