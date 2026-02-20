# Journal 기능 설계 (features/journal)

이 문서는 **일지(Journal)** 탭의 UI/상태관리/저장 구조를 빠르게 이해하기 위한 가이드입니다.

## 목표

- 팀별로 일지를 작성/조회/수정/삭제한다.
- 일지는 날짜 기반으로 보기(일별) 또는 전체 리스트 보기(전체)로 탐색한다.
- **비공개 일지**를 지원하여 팀원에게 노출되지 않게 저장한다.
- 관련 업무(Task) / 프로젝트(Project) 연결을 지원한다.

## 핵심 파일

- `lib/features/journal/ui/journal_tab.dart`
  - 일지 탭 메인 UI
  - 날짜별 섹션/전체 리스트 토글, 작성 버튼(바텀시트 호출)

- `lib/features/journal/ui/sheets/journal_write_sheet.dart`
  - 일지 작성/수정 바텀시트
  - TextEditingController 생명주기 관리(닫힐 때 disposed 이슈 방지)

- `lib/features/journal/state/journal_provider.dart`
  - Provider 상태 관리
  - Hive 박스 I/O(저장/조회/필터)

## 데이터 구조

- 모델: `lib/domain/models.dart`의 `JournalEntry`
  - `teamId`, `authorId`, `authorName`, `date`, `content`
  - `isPrivate`(비공개), `relatedTaskId`, `projectId` 등 확장 필드

- 저장소(Hive)
  - `journals` 박스: `JournalEntry` 리스트/맵 저장
  - `journal_meta` 박스: 탭 설정/필터 상태 저장(필요 시)

## 화면 동작 흐름

1. `JournalTab` 진입 → `JournalProvider`가 현재 팀(`TeamProvider.currentTeamId`) 기준으로 데이터 제공
2. 상단 토글(일별/전체)
   - 일별: 날짜별로 그룹핑 + 해당 날짜 섹션만 보기
   - 전체: 최신순 리스트
3. `+` 또는 “작성” 버튼 → `JournalWriteSheet` 바텀시트 열림
4. 저장 시
   - Provider에 `addOrUpdateJournalEntry()` 호출
   - Hive 박스에 영속화
   - UI 자동 갱신(Provider notify)

## UI 가이드

- 텍스트 대비(가독성) 최우선: 본문/제목은 **블랙 톤**, 보조 정보는 `AppColors.text2`
- 바텀시트는 `isScrollControlled: true` + 내부 `SingleChildScrollView`로 오버플로우 방지
- 컨트롤(드롭다운/스위치)은 한 화면에서 조작 가능하도록 섹션 간 여백은 과도하지 않게 유지

## 디버그/테스트 팁

- 샘플 데이터는 `AppResetService`에서 생성할 수 있음
- 팀 전환 시 일지가 정상적으로 필터링되는지 확인(팀별 데이터 분리)
