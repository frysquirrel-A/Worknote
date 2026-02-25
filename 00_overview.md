# 00. 전체 개요

## 아키텍처 한 줄 요약
- **UI(Flutter Widget)** ↔ **State(ChangeNotifier Provider)** ↔ **Local Storage(Hive Box)** 로 동작하는 **오프라인 중심(offline-first)** 구조.
- `lib/features/*` 단위로 화면/상태를 묶고, 공통 타입은 `lib/domain/models.dart`에 둡니다.

## 런타임 흐름
1. `main.dart` → `bootstrap()`
2. `bootstrap()`에서 Hive 초기화/Adapter 등록/Box 오픈
3. `WorkNoteApp`(MaterialApp) 시작
4. `MainShell`이 하단 탭(홈/업무/계획/기록/시스템/메신저)을 구성
5. 각 탭은 `Provider`를 통해 상태를 읽고(Watch) 업데이트(Notify)합니다.

## 상태 관리(Provider)
- Provider는 `ChangeNotifier` 기반입니다.
- UI는 `context.watch<T>()`로 상태를 구독하고, `context.read<T>()`로 액션을 호출합니다.

주요 Provider:
- `ThemeProvider`: 앱 테마/색상
- `AuthProvider`: 로그인 상태/현재 유저
- `TeamProvider`: 팀 목록, 현재 팀, 팀 전환
- `TaskProvider`: 업무(Task)/프로젝트(Project) 데이터 및 필터/정렬에 필요한 헬퍼
- `ChatProvider`: 스레드(채팅방) + 메시지
- `JournalProvider`: 기록(일지)
- `ScheduleProvider`: 계획(일정) 엔트리

## 영속화(Hive)
- 데이터는 Hive Box에 저장됩니다. 대표 Box:
  - `users` : AppUser
  - `teams` : Team
  - `tasks` : Task
  - `projects` : Project
  - `task_meta` : Task 메타(계획 포함여부, 계획 시작/종료 등)
  - `chat_threads`, `chat_messages`
  - `journal_entries`, `journal_meta`
  - `schedules`
  - `local_settings` : 마지막 팀, 로그인 유저 등 간단한 설정

> Task의 "계획(기존 일정) 반영"은 `task_meta` 박스의 키(`planInclude`, `scheduleInclude`, `scheduleStart`, `scheduleEnd`)로 관리합니다.

## 데모 데이터
- `AppResetService.resetAll(seedSampleData: true)`는 샘플 데이터를 생성합니다.
- 개발/테스트에서 필터/스크롤/레이아웃 검증을 빠르게 하기 위해 사용합니다.
