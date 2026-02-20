# 03. State(Provider) & Storage(Hive)

## Provider 목록
- `ThemeProvider` (`lib/features/theme/state/theme_provider.dart`)
- `AuthProvider` (`lib/features/auth/state/auth_provider.dart`)
- `TeamProvider` (`lib/features/team/state/team_provider.dart`)
- `TaskProvider` (`lib/features/tasks/state/task_provider.dart`)
- `ChatProvider` (`lib/features/chat/state/chat_provider.dart`)
- `JournalProvider` (`lib/features/journal/state/journal_provider.dart`)
- `ScheduleProvider` (`lib/features/schedule/state/schedule_provider.dart`)

## Hive Box 요약
- `users` : `AppUser`
- `teams` : `Team`
- `tasks` : `Task`
- `projects` : `Project`
- `journal_entries` : `JournalEntry`
- `chat_threads` : `ChatThread`
- `chat_messages` : `ChatMessage`
- `local_settings` : 문자열 key/value
- `task_meta` : taskId → Map (planInclude/scheduleInclude/scheduleStart/scheduleEnd 등)
- `journal_meta` : journalId → Map (북마크, 태그 등)
- `schedules` : `ScheduleEntry`

## Task 메타 키(TaskProvider)
- `planInclude` : bool
- `scheduleInclude` : bool
- `scheduleStart` : ISO8601 string
- `scheduleEnd` : ISO8601 string

