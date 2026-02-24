import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart'; // ✨ Firebase 임포트

import 'package:worknote/app/worknote_app.dart';
import 'package:worknote/core/crash/crash_reporter.dart';
import 'package:worknote/data/hive/hive_adapters.dart';
import 'package:worknote/data/migrations/hive_migrations.dart';
import 'package:worknote/data/sync/sync_outbox.dart';
import 'package:worknote/data/sync/sync_processor.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/chat/state/chat_provider.dart';
import 'package:worknote/features/journal/state/journal_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';
import 'package:worknote/features/schedule/state/schedule_provider.dart';
import 'package:worknote/firebase_options.dart'; // ✨ Firebase 옵션 임포트

void _safeRegisterAdapter<T>(TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }
}

Future<void> bootstrap() async {
  // 1) 글로벌 에러 핸들러 설정 (Zone 밖의 에러 방어)
  FlutterError.onError = (FlutterErrorDetails details) {
    unawaited(CrashReporter.instance.recordFlutterError(details));
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    unawaited(CrashReporter.instance.record(error, stack, hint: 'PlatformDispatcher'));
    return true;
  };

  // 2) ✨ 앱 초기화와 실행을 동일한 Zone 안에서 수행 (Zone Mismatch 해결)
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 🚀 [Firebase 이사] Zone 내부에서 Firebase 초기화 수행
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await initializeDateFormatting('ko_KR', null);
    await Hive.initFlutter();

    // 어댑터 등록
    _safeRegisterAdapter(TaskPriorityAdapter());
    _safeRegisterAdapter(TaskAdapter());
    _safeRegisterAdapter(ProjectAdapter());
    _safeRegisterAdapter(JournalEntryAdapter());
    _safeRegisterAdapter(TeamAdapter());
    _safeRegisterAdapter(AppUserAdapter());
    _safeRegisterAdapter(ChatMessageAdapter());

    // 박스 오픈
    await Hive.openBox<Task>('tasks');
    await Hive.openBox<Project>('projects');
    await Hive.openBox<JournalEntry>('journals');
    await Hive.openBox<Team>('teams');
    await Hive.openBox<AppUser>('users');
    await Hive.openBox<ChatMessage>('messages');

    await Hive.openBox('settings');
    await Hive.openBox('chat_threads');
    await Hive.openBox('task_meta');
    await Hive.openBox('journal_meta');
    await Hive.openBox('schedules');

    // 인프라 초기화
    await CrashReporter.instance.init();
    await SyncOutbox.instance.init();
    await HiveMigrations.run();

    // 동기화 엔진 가동 시작
    SyncProcessor.instance.startBackgroundSync();

    // 앱 실행
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
  }, (Object error, StackTrace stack) {
    unawaited(CrashReporter.instance.record(error, stack, hint: 'runZonedGuarded'));
  });
}
