# Schedule(계획) 기능

> 코드상 폴더/클래스명은 `schedule`이지만, **UI 표기(라벨)는 '계획'**으로 통일했습니다.

## 관련 파일
- `lib/features/schedule/ui/schedule_tab.dart`
- `lib/features/schedule/state/schedule_provider.dart`

## 데이터 모델
- `ScheduleEntry` (in `domain/models.dart`)
  - `id`, `title`, `startAt`, `endAt`, `colorValue` 등

## 저장소(Hive)
- `schedules` box

