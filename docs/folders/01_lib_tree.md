# 01. lib 폴더 트리(요약)

```
lib/
├── app
│   ├── widgets
│   │   └── master_drawer.dart
│   ├── bootstrap.dart
│   ├── main_shell.dart
│   └── worknote_app.dart
├── core
│   ├── theme
│   │   └── app_theme.dart
│   └── ui
│       ├── widgets
│       │   └── date_group_controls.dart
│       └── app_palette.dart
├── data
│   ├── hive
│   │   └── hive_adapters.dart
│   └── services
│       ├── app_reset_service.dart
│       ├── drive_service.dart
│       └── local_db_service.dart
├── domain
│   └── models.dart
├── features
│   ├── auth
│   │   ├── state
│   │   │   └── auth_provider.dart
│   │   └── ui
│   │       └── login_page.dart
│   ├── chat
│   │   ├── state
│   │   │   └── chat_provider.dart
│   │   └── ui
│   │       └── messenger_tab.dart
│   ├── gallery
│   │   └── ui
│   │       └── gallery_tab.dart
│   ├── home
│   │   └── ui
│   │       └── home_tab.dart
│   ├── journal
│   │   ├── state
│   │   │   └── journal_provider.dart
│   │   └── ui
│   │       ├── sheets
│   │       │   ├── journal_detail_sheet.dart
│   │       │   └── journal_write_sheet.dart
│   │       ├── widgets
│   │       │   ├── journal_card.dart
│   │       │   └── journal_view_mode_toggle.dart
│   │       └── journal_tab.dart
│   ├── schedule
│   │   ├── state
│   │   │   └── schedule_provider.dart
│   │   └── ui
│   │       └── schedule_tab.dart
│   ├── system
│   │   └── ui
│   │       ├── admin_dashboard.dart
│   │       └── system_monitor_page.dart
│   ├── tasks
│   │   ├── state
│   │   │   └── task_provider.dart
│   │   └── ui
│   │       ├── sheets
│   │       │   ├── add_task_sheet.dart
│   │       │   ├── task_detail_sheet.dart
│   │       │   └── task_schedule_sheet.dart
│   │       ├── widgets
│   │       │   ├── task_card.dart
│   │       │   ├── task_filter_bar.dart
│   │       │   ├── task_masonry_card.dart
│   │       │   └── task_view_mode_toggle.dart
│   │       ├── task_sort_field.dart
│   │       └── task_tab.dart
│   └── team
│       ├── state
│       │   └── team_provider.dart
│       └── ui
│           └── team_management_page.dart
├── tabs
│   └── task_tab.dart
└── main.dart
```
