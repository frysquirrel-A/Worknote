# Home 기능

## 목적
- 팀의 현재 상태를 한 화면에서 요약(팀 선택/팀원/프로젝트/오늘 할 일)
- 팀원 프로필 팝업에서 DM(메신저)로 바로 이동

## 주요 UI 요소
- 팀 선택 박스
  - Home 상단 인사 영역 아래.
  - 탭하면 BottomSheet에서 팀 목록 선택.
  - 선택 시 `TeamProvider.switchTeam()` 호출.
- 팀원 리스트
  - Home 구성 순서: 인사 → 팀 선택 → **팀원 리스트** → 프로젝트 현황 → 오늘 할 일.
  - 팀원 아바타 탭 → BottomSheet 프로필 팝업(이름/역할/메시지 보내기).
  - 메시지 보내기 → `ChatProvider.dmThreadId(teamId, myId, memberId)`로 threadId 생성 후
    `MainShell`의 콜백(`onOpenChatThread`)으로 메신저 탭으로 이동.
- 내 프로필 배지
  - 우측 상단 내 아바타에 현재 팀 이름 첫 글자 배지.

## 관련 파일
- `lib/features/home/ui/home_tab.dart`
  - 위 요구사항 구현.
