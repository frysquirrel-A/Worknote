# WorkNote UI Static Catalog

Generated: 2026-03-07
Mode: execution-free UI catalog
Basis: source code + project docs only

## 1. Environment Summary

- `flutter`, `dart`, and `adb` are not directly available in the current shell PATH.
- This report does not run the app, capture screenshots, or dump UI XML.
- This is a static catalog of the current UI structure inferred from source files.

## 2. Reference Docs

- `AGENTS.md`
- `PROJECT_MAP.md`
- `ARCHITECTURE.md`
- `PATCHLOG.md`
- `AI_CHECKLIST.md`
- `RELEASE_CHECKLIST.md`

## 3. Critical Findings Before Any Redesign

### 3.1 Encoding damage is already present

Mojibake / broken strings are visible in multiple files, including:

- `AGENTS.md`
- `ios/Runner/Info.plist`
- `lib/app/main_shell.dart`
- `lib/app/widgets/master_drawer.dart`
- `lib/features/tasks/ui/task_tab.dart`
- `lib/features/tasks/ui/widgets/task_filter_bar.dart`
- `lib/features/tasks/ui/sheets/add_task_sheet.dart`
- `lib/features/journal/ui/sheets/journal_write_sheet.dart`
- `lib/features/gallery/ui/gallery_tab.dart`
- `lib/features/chat/ui/messenger_tab.dart`

This should be treated as a P0 quality issue before large UI cleanup.

### 3.2 Global visual split

From `lib/core/ui/app_palette.dart`:

- Light base shell: `bg`, `surface`, `border`
- Main accent: `primary = #2563EB`
- Dedicated dark messenger tokens:
  - `darkBg = #061121`
  - `darkSurface = #0D1A32`
  - `darkSurface2 = #122347`
  - `premiumBlue = #5B8CFF`
  - `AppGradients.messengerPanel`

Interpretation:

- Most tabs still read as light dashboard/productivity surfaces.
- Messenger is the clearest premium-dark destination.
- The app is not yet a fully unified design system.

## 4. Static UI Catalog

## Home / Drawer

Source files:

- `lib/app/main_shell.dart`
- `lib/app/widgets/master_drawer.dart`
- `lib/features/home/ui/home_tab.dart`

Likely visible capabilities:

- current user / profile header
- current team or group context
- project progress summary
- today task summary
- member and chat entry points
- drawer access to management/settings/integration flows

Document links:

- `PROJECT_MAP.md - Modules > Home`
- `ARCHITECTURE.md - 1. Product Identity`
- `ARCHITECTURE.md - 4.2 Team/Group`

Static concerns:

- drawer contains risky entries close to normal settings flows
- top-right profile / notification actions exist but need runtime verification
- some labels are already encoding-damaged

## Tasks

Source files:

- `lib/features/tasks/ui/task_tab.dart`
- `lib/features/tasks/ui/widgets/task_filter_bar.dart`
- `lib/features/tasks/ui/sheets/add_task_sheet.dart`
- `lib/features/tasks/ui/widgets/task_card.dart`
- `lib/features/tasks/ui/widgets/task_masonry_card.dart`

Likely visible capabilities:

- project/category/period filtering
- sort direction toggle
- list/grid switching
- grouped task lists
- add-task bottom sheet
- assignee/project/due/priority/plan fields

Document links:

- `PROJECT_MAP.md - Providers > TaskProvider`
- `PROJECT_MAP.md - Modules > Tasks`
- `ARCHITECTURE.md - 4.3 Tasks`

Static concerns:

- top control bar is dense and likely easy to mis-tap
- forms still use `labelText` patterns in places
- protected task cards are rich but text quality is currently degraded by encoding damage

## Schedule

Source file:

- `lib/features/schedule/ui/schedule_tab.dart`

Likely visible capabilities:

- monthly calendar
- previous/next month navigation
- today jump
- search
- card/list mode toggle
- all-team schedule aggregation
- add plan / personal schedule CTA

Document links:

- `PROJECT_MAP.md - Providers > ScheduleProvider`
- `PROJECT_MAP.md - Modules > Schedule`
- `ARCHITECTURE.md - 4.4 Schedule`

Static concerns:

- crash/debug button is still present in the app bar
- strings are damaged in multiple UI labels
- runtime hitbox and navigation behavior still need later execution-based review

## Journal

Source files:

- `lib/features/journal/ui/journal_tab.dart`
- `lib/features/journal/ui/sheets/journal_write_sheet.dart`

Likely visible capabilities:

- journal feed/list
- status/type filtering
- write CTA
- related task/project linking
- privacy toggle
- photo attachment
- body composer

Document links:

- `PROJECT_MAP.md - Modules > Journal`
- `ARCHITECTURE.md - 4.5 Journal`

Static concerns:

- write sheet is feature-rich but visually and cognitively dense
- forms still lean on labels and damaged strings
- image picker path exists and will need safe runtime review later

## Gallery

Source file:

- `lib/features/gallery/ui/gallery_tab.dart`

Likely visible capabilities:

- date-grouped image sections
- masonry grid
- local/network image rendering
- loading/error builders
- add/camera floating action button

Document links:

- `PROJECT_MAP.md - Modules > Gallery`
- `ARCHITECTURE.md - 4.6 Gallery`

Static concerns:

- floating action button currently has an empty handler
- this is effectively a dead button
- labels and empty state text are damaged by encoding issues

## Messenger

Source file:

- `lib/features/chat/ui/messenger_tab.dart`

Likely visible capabilities:

- thread selector
- group / DM split
- message list
- composer input
- send CTA
- end drawer / management area
- empty state support

Document links:

- `PROJECT_MAP.md - Providers > ChatProvider`
- `PROJECT_MAP.md - Modules > Messenger`
- `ARCHITECTURE.md - 4.7 Messenger`
- `PATCHLOG.md - v2 Patch Package`

Static concerns:

- visually the strongest and most coherent premium-dark area
- style gap versus the rest of the app is still large
- some text is also encoding-damaged here

## 5. Priority Suggestions

P0:

- repair encoding damage across docs and user-facing UI strings
- remove or gate the schedule crash/debug action
- replace the dead gallery FAB with a safe action or proper implementation

P1:

- simplify or rebalance the Tasks top control strip
- reorganize Home drawer risk actions
- reduce form density in Journal and Task creation flows

P2:

- define whether premium dark remains messenger-only or becomes a broader shell language

## 6. Limits of This Report

This mode does not verify:

- actual tap behavior
- animation or transition quality
- overflow / keyboard / scroll issues
- data-driven empty vs populated states
- external auth branches

Use this document as a source-based UI map, not as runtime proof.
