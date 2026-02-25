# 03. Gemini 핸드오프 프롬프트

아래 프롬프트를 그대로 Gemini(또는 다른 LLM)에게 전달하면, 이번 작업의 변경점/의도를 빠르게 이해하고 후속 작업을 이어갈 수 있습니다.

---

## ✅ Gemini용 프롬프트

너는 Flutter/Dart 시니어 아키텍트이자 코드 리뷰어다.

내가 제공하는 프로젝트는 WORKNOTE(업무/일지/계획/채팅) 앱이며, 최근 안정화 패치가 적용되었다.

### 현재 코드베이스에서 이미 적용된 작업(반드시 인지)

1) **전역 크래시 수집(CrashReporter) 추가**
   - 파일: `lib/core/crash/crash_reporter.dart`
   - Hive box `crash_logs`에 Map 형태로 에러/스택/시간을 저장
   - `bootstrap.dart`에서 `FlutterError.onError`, `PlatformDispatcher.instance.onError`, `runZonedGuarded`를 통해 수집

2) **Hive 스키마 마이그레이션 시스템 추가**
   - 파일: `lib/data/migrations/hive_migrations.dart`
   - Hive box `app_meta`의 `schema_version`으로 버전 관리
   - v1→v2 마이그레이션: `task_meta.scheduleDate` → `scheduleStart/scheduleEnd` + `scheduleInclude` 기본값 보장

3) **Outbox 패턴(SyncOutbox) 추가 + 실제 Provider에 적용**
   - 파일: `lib/data/sync/sync_outbox.dart`
   - Hive box `sync_outbox`에 로컬 변경 이벤트를 append
   - 적용된 곳:
     - `TaskProvider`: add/status/meta/delete에 enqueue
     - `JournalProvider`: add/update/delete에 enqueue
     - `ChatProvider`: 스레드 생성/이름변경/삭제/메시지 전송/대화 삭제에 enqueue

4) **부트스트랩 강화**
   - 파일: `lib/app/bootstrap.dart`
   - Hive 박스들을 Provider 사용 전에 선오픈
   - CrashReporter/SyncOutbox init, 마이그레이션 실행 추가

### 너( Gemini )가 이어서 할 수 있는 후속 고도화 과제(우선순위)

- Outbox를 실제 Google Drive(또는 서버) 동기화로 연결하는 설계(Outbox 소비/재시도/충돌 해결)
- ChatMessage/Thread 데이터 모델 정합성(팀/스레드 식별자 분리, 장기 호환 가능한 Hive Adapter 포맷)
- SystemMonitorPage에 crash/outbox 상태 노출 + 내보내기(export) 기능

### 요구 사항

- 디자인 취향 개선, 단순 리팩토링 제안 금지
- 크래시/데이터 무결성/성능 관점에서만 수정 제안 및 코드 패치 제공
- 수정 시 **전체 파일 코드**로 출력

프로젝트 폴더 구조와 변경 파일을 우선 스캔한 뒤, 크래시/데이터 오염 가능성이 큰 지점부터 우선적으로 개선안을 제시해라.
