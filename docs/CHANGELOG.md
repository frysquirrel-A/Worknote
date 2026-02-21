# 변경 내역 (핵심)

이 문서는 배포/패치 ZIP을 적용할 때 “무엇이 바뀌었는지” 빠르게 확인하기 위한 요약입니다.

## 이번 번들에서 반영된 내용

- **운영 안정성(크래시 수집) 추가**
  - `CrashReporter` 도입: `crash_logs` Hive box에 전역 에러 저장
  - `bootstrap.dart`에서 `FlutterError.onError` / `PlatformDispatcher.instance.onError` / `runZonedGuarded`로 수집

- **데이터 무결성(마이그레이션) 추가**
  - `HiveMigrations` 도입: `app_meta.schema_version` 기반
  - v1→v2: `task_meta.scheduleDate` → `scheduleStart/scheduleEnd` 정규화 + `scheduleInclude` 기본값 보장

- **향후 동기화 기반(Outbox) 추가**
  - `SyncOutbox` 도입: 로컬 변경 이벤트를 `sync_outbox`에 append
  - Task/Journal/Chat Provider에 실제 enqueue 적용


- **빌드 안정화**
  - `HomeTab`에서 존재하지 않는 경로(`core/theme/app_colors.dart`) 참조 제거 → `core/ui/app_palette.dart`로 통일

- **Flutter 최신 경고 대응**
  - `withOpacity()` 사용 코드들을 `withValues(alpha: …)`로 일괄 교체
  - `Switch.activeColor` → `activeThumbColor`(+ `activeTrackColor` 보강)
  - `DropdownButtonFormField.value` → `initialValue`

- **문서 보강**
  - `docs/AI_CHECKLIST.md` 추가(작업 진행/남은 작업 트래킹)
  - 기능 문서 추가: `docs/features/journal.md`, `docs/features/gallery.md`, `docs/features/system_admin.md`

## 적용 방법

1. 기존 프로젝트에서 `lib/` 백업
2. 이 ZIP의 `lib/`, `docs/`를 **동일 경로로 덮어쓰기**
3. 실행

```bash
flutter clean
flutter pub get
flutter run
```
