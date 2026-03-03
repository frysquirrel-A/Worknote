import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:worknote/firebase_options.dart';

import 'package:worknote/app/worknote_app.dart';
import 'package:worknote/core/crash/crash_reporter.dart';
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
  // 에러 훅 설정
  FlutterError.onError = (FlutterErrorDetails details) {
    unawaited(CrashReporter.instance.recordFlutterError(details));
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    unawaited(CrashReporter.instance.record(error, stack, hint: 'PlatformDispatcher'));
    return true;
  };

  runZonedGuarded(
    () async {
      // ✨ [구역 대통합 수술] 동일한 Zone 내에서 엔진 및 DB 초기화 실행
      WidgetsFlutterBinding.ensureInitialized();

      // ✨ [클라우드 점화] 롤백으로 사라졌던 Firebase 엔진 스위치 복구
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await initializeDateFormatting('ko_KR', null);

      await Hive.initFlutter();

      // 1) Hive Adapters 등록
      _safeRegisterAdapter(TaskStatusAdapter());
      _safeRegisterAdapter(TaskPriorityAdapter());
      _safeRegisterAdapter(DateFilterAdapter());
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

      // 3) Untyped/Meta Boxes 오픈
      await Hive.openBox('settings');
      await Hive.openBox('chat_threads');
      await Hive.openBox('task_meta');
      await Hive.openBox('journal_meta');
      await Hive.openBox('schedules');

      // 4) Infra boxes (crash logs / sync outbox)
      await CrashReporter.instance.init();
      await SyncOutbox.instance.init();

      // 5) Migrations
      await HiveMigrations.run();

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
      debugPrint('Zone Error: $error');
    },
  );
}
