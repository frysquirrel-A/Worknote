# Schedule(스케줄) 기능

> **명칭 변경**: 사용자 직관성을 높이기 위해 기존 '계획' 탭에서 **'스케줄'**로 UI 명칭을 통일했습니다.

## 특징 및 연동
- **하단 네비게이션**: 세 번째 탭에 위치하며 '스케줄' 라벨로 표시됨.
- **업무 연동**: 업무(Tasks) 탭의 카드 UI에서 캘린더 아이콘을 활성화한 업무들이 자동으로 리스트 및 달력에 노출됨.
- **데이터 모델**: `ScheduleEntry` 모델을 사용하여 직접 스케줄을 생성하거나, `Task` 메타데이터 기반으로 업무 일정을 표시함.

## 관련 파일
- `lib/features/schedule/ui/schedule_tab.dart`
- `lib/app/main_shell.dart` (탭 이름 정의)
- `lib/features/schedule/state/schedule_provider.dart`
