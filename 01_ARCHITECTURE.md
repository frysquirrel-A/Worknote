# 01. 아키텍처 개요

## 목표

- **크래시**: 전역 에러 핸들링 + 로컬 크래시 로그 수집으로 재현/분석 가능하게.
- **데이터 오염**: 팀 전환/필터 조건/메타데이터(업무 계획 포함)에서 누락/레거시 키를 방지.
- **성능 저하**: Provider 단에서 캐시/인덱싱, build() 내부에서 연산 최소화.

## 런타임 부트스트랩

진입점은 `lib/main.dart` → `lib/app/bootstrap.dart` 입니다.

부트 순서(요약):

1) `Hive.initFlutter()`
2) Hive Adapter 등록 (`lib/data/hive/hive_adapters.dart`)
3) 필수 Box 오픈 (tasks/projects/journals/teams/users/messages + settings/chat_threads/task_meta/journal_meta/schedules)
4) 인프라 Box 오픈
   - **crash_logs**: `CrashReporter`가 사용
   - **sync_outbox**: `SyncOutbox`가 사용
5) **Hive 스키마 마이그레이션 실행** (`HiveMigrations.run()`)
6) 전역 에러 훅 설치
   - `FlutterError.onError`
   - `PlatformDispatcher.instance.onError`
   - `runZonedGuarded`
7) `MultiProvider`로 Provider 트리 구성 후 `WorkNoteApp` 실행

## 상태 관리

- 기본 패턴: `ChangeNotifier + Provider`
- **금지/주의 포인트**
  - async 이후 `context` 사용 시 `mounted` 체크 누락
  - build() 내부에서 Hive 접근/where/map 반복

## 데이터 접근

- 현재 로컬 1차 저장소: **Hive**
- 메타데이터(업무 계획 포함): `task_meta`, `journal_meta` 등 **untyped box(Map)**
- 향후 원격 동기화 대비:
  - **Outbox 패턴(`SyncOutbox`)**: 로컬 변경 이벤트를 별도 Box에 append

## 운영/장애 대응

- `CrashReporter`가 **치명/비치명 에러를 Hive에 저장**하여 재현이 어려운 크래시를 추적.
- `SystemMonitorPage`에서 운영 지표를 확인할 수 있으며, 필요 시 crash/outbox count를 노출하도록 확장 가능.
