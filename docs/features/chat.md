# Chat(메신저) 기능

## 핵심 아이디어
- 팀 단위로 메시지를 분리하고, DM은 두 사용자 ID를 정렬하여 **항상 같은 threadId**가 나오도록 구성합니다.

## DM Thread ID 규칙
- 구현: `ChatProvider.dmThreadId(teamId, userA, userB)`
- 규칙:
  - `a`와 `b`를 문자열 정렬 후 `dm_<teamId>_<a>_<b>` 형식
  - 같은 두 사용자 조합이면 어떤 순서로 호출해도 동일한 ID

## 탭 이동
- `MainShell._openChatThread(threadId, title)`
  - `ChatProvider.setActiveThread(...)`
  - 탭 인덱스를 메신저 탭으로 변경

## 관련 파일
- `lib/features/chat/state/chat_provider.dart`
- `lib/features/chat/ui/messenger_tab.dart`
- `lib/app/main_shell.dart`
