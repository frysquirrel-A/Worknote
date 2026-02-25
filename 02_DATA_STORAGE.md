# 02. 데이터 저장소(Hive) & 마이그레이션

## Hive Boxes

### Typed Boxes

- `tasks` : `Task`
- `projects` : `Project`
- `journals` : `JournalEntry`
- `teams` : `Team`
- `users` : `AppUser`
- `messages` : `ChatMessage`

### Untyped / Meta Boxes

- `settings` : 앱 설정 / 사용자 설정
- `chat_threads` : 채팅방(스레드) 메타
- `task_meta` : 업무별 메타 (계획 포함, 중요도/완료보고 시간 등)
- `journal_meta` : 일지별 메타 (진행/보고서 등)
- `schedules` : 계획 탭 데이터(별도 엔티티)

### Infra Boxes

- `crash_logs` : 전역 에러 로그 (CrashReporter)
- `sync_outbox` : 변경 이벤트 큐 (SyncOutbox)
- `app_meta` : 스키마 버전 등 앱 메타

## 스키마 버전 관리

- 구현 위치: `lib/data/migrations/hive_migrations.dart`
- 키: `app_meta['schema_version']`
- `latestSchemaVersion`를 증가시키면 신규 마이그레이션을 추가할 수 있음.

## 현재 적용된 마이그레이션

### v1 → v2

- `task_meta`에 저장되던 레거시 키 `scheduleDate`를
  - `scheduleStart` / `scheduleEnd`로 승격
  - `scheduleInclude` 기본값 보장

## 주의사항 (매우 중요)

- Hive TypeAdapter를 **순차 read/write만으로 구현**하면(필드 카운트/필드 번호 없이) 장기 호환성이 떨어짐.
- 신규 모델 필드를 추가할 때는
  1) 기존 데이터 읽기 호환성
  2) 마이그레이션
  3) 원격 동기화 포맷

을 반드시 함께 설계해야 함.
