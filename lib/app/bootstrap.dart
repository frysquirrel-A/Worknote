import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:worknote/app/worknote_app.dart';
import 'package:worknote/data/hive/hive_adapters.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/chat/state/chat_provider.dart';
import 'package:worknote/features/journal/state/journal_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';
import 'package:worknote/features/schedule/state/schedule_provider.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);

  await Hive.initFlutter();

  // Hive Adapters
  Hive.registerAdapter(TaskPriorityAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(ProjectAdapter());
  Hive.registerAdapter(JournalEntryAdapter());
  Hive.registerAdapter(TeamAdapter());
  Hive.registerAdapter(AppUserAdapter());
  Hive.registerAdapter(ChatMessageAdapter());

  // Boxes
  await Hive.openBox('settings');
  await Hive.openBox<Task>('tasks');
  await Hive.openBox<Project>('projects');
  await Hive.openBox<JournalEntry>('journals');
  await Hive.openBox<Team>('teams');
  await Hive.openBox<AppUser>('users');
  await Hive.openBox<ChatMessage>('messages');

  // Meta boxes (untyped/dynamic)
  // - task_meta: schedule inclusion, schedule date, completion report timestamps, etc.
  // - journal_meta: journal kind (note/progress/report), relatedTaskId, progress updates, etc.
  await Hive.openBox('task_meta');
  await Hive.openBox('journal_meta');

  // Personal schedules (untyped)
  await Hive.openBox('schedules');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TeamProvider()..loadTeams()),
        ChangeNotifierProvider(create: (_) => TaskProvider()..loadData()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()..loadJournals()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()..load()),
      ],
      child: const WorkNoteApp(),
    ),
  );
}
