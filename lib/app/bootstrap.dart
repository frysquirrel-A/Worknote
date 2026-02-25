import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:worknote/app/worknote_app.dart';
import 'package:worknote/core/crash/crash_reporter.dart';
import 'package:worknote/data/hive/hive_adapters.dart';
import 'package:worknote/data/migrations/hive_migrations.dart';
import 'package:worknote/data/sync/sync_outbox.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/chat/state/chat_provider.dart';
import 'package:worknote/features/journal/state/journal_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';
import 'package:worknote/features/schedule/state/schedule_provider.dart';

void _safeRegisterAdapter<T>(TypeAdapter<T> adapter) {
  // Hot restart / test runner 등에서 중복 등록 시 예외가 발생할 수 있어 방어.
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);

  await Hive.initFlutter();

  // 1) Hive Adapters 등록
  _safeRegisterAdapter(TaskPriorityAdapter());
  _safeRegisterAdapter(TaskAdapter());
  _safeRegisterAdapter(ProjectAdapter());
  _safeRegisterAdapter(JournalEntryAdapter());
  _safeRegisterAdapter(TeamAdapter());
  _safeRegisterAdapter(AppUserAdapter());
  _safeRegisterAdapter(ChatMessageAdapter());

  // 2) Typed Boxes 오픈
  await Hive.openBox<Task>('tasks');
  await Hive.openBox<Project>('projects');
  await Hive.openBox<JournalEntry>('journals');
  await Hive.openBox<Team>('teams');
  await Hive.openBox<AppUser>('users');
  await Hive.openBox<ChatMessage>('messages');

  // 3) Untyped/Meta Boxes 오픈 (중요: Provider에서 사용 전 미리 오픈)
  await Hive.openBox('settings');
  await Hive.openBox('chat_threads');
  await Hive.openBox('task_meta');
  await Hive.openBox('journal_meta');
  await Hive.openBox('schedules');

  // 4) Infra boxes (crash logs / sync outbox)
  await CrashReporter.instance.init();
  await SyncOutbox.instance.init();

  // 5) Migrations (schema versioned)
  await HiveMigrations.run();

  // 6) Global error hooks (crash persistence)
  FlutterError.onError = (FlutterErrorDetails details) {
    // Persist first, then forward.
    unawaited(CrashReporter.instance.recordFlutterError(details));
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    unawaited(CrashReporter.instance.record(error, stack, hint: 'PlatformDispatcher'));
    // true = handled (prevents default crash in release)
    return true;
  };

  // 7) Run app in zone to capture async errors.
  runZonedGuarded(
    () {
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TeamProvider()..loadTeams()),
            ChangeNotifierProvider(create: (_) => TaskProvider()..loadData()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => JournalProvider()..loadJournals()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
            ChangeNotifierProvider(create: (_) => ScheduleProvider()),
          ],
          child: const WorkNoteApp(),
        ),
      );
    },
    (Object error, StackTrace stack) {
      unawaited(CrashReporter.instance.record(error, stack, hint: 'runZonedGuarded'));
    },
  );
}
