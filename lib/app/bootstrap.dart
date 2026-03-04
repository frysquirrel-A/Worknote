import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:worknote/app/worknote_app.dart';
import 'package:worknote/core/crash/crash_reporter.dart';
import 'package:worknote/core/utils/dev_log.dart';
import 'package:worknote/data/hive/hive_adapters.dart';
import 'package:worknote/data/migrations/hive_migrations.dart';
import 'package:worknote/data/sync/sync_outbox.dart';
import 'package:worknote/domain/models.dart'
    hide
        TaskPriorityAdapter,
        TaskAdapter,
        ProjectAdapter,
        JournalEntryAdapter,
        TeamAdapter,
        AppUserAdapter,
        ChatMessageAdapter;
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/chat/state/chat_provider.dart';
import 'package:worknote/features/journal/state/journal_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';
import 'package:worknote/features/schedule/state/schedule_provider.dart';

void _safeRegisterAdapter<T>(TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }
}

/// ✨ [신규] Hive 박스를 안전하게 오픈하는 함수 (에러 시 자동 복구)
Future<Box<T>> _safeOpenBox<T>(String name) async {
  try {
    return await Hive.openBox<T>(name);
  } catch (e) {
    print('[Debug] Hive Box ($name) 오픈 에러 발생: $e. 복구 시도 중...');
    // 충돌 난 박스 파일을 삭제하고 새로 생성
    await Hive.deleteBoxFromDisk(name);
    return await Hive.openBox<T>(name);
  }
}

Future<void> bootstrap() async {
  print('[Debug] Bootstrap 시작...');

  FlutterError.onError = (FlutterErrorDetails details) {
    DevLog.instance.addLog('Flutter Error: ${details.exception}\n${details.stack}');
    unawaited(CrashReporter.instance.recordFlutterError(details));
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    DevLog.instance.addLog('Platform Error: $error\n$stack');
    unawaited(CrashReporter.instance.record(error, stack, hint: 'PlatformDispatcher'));
    return true;
  };

  runZonedGuarded(() async {
    print('[Debug] Zone 초기화 시작...');
    WidgetsFlutterBinding.ensureInitialized();

    print('[Debug] 날짜 포맷 초기화 중...');
    await initializeDateFormatting('ko_KR', null);

    print('[Debug] Hive 초기화 시작...');
    await Hive.initFlutter();

    print('[Debug] 어댑터 등록 중...');
    _safeRegisterAdapter(TaskPriorityAdapter());
    _safeRegisterAdapter(TaskAdapter());
    _safeRegisterAdapter(ProjectAdapter());
    _safeRegisterAdapter(JournalEntryAdapter());
    _safeRegisterAdapter(TeamAdapter());
    _safeRegisterAdapter(AppUserAdapter());
    _safeRegisterAdapter(ChatMessageAdapter());

    print('[Debug] Hive 박스 오픈 시작 (안전 모드)...');
    // Typed Boxes
    await _safeOpenBox<Task>('tasks');
    await _safeOpenBox<Project>('projects');
    await _safeOpenBox<JournalEntry>('journals');
    await _safeOpenBox<Team>('teams');
    await _safeOpenBox<AppUser>('users');
    await _safeOpenBox<ChatMessage>('messages');

    // Untyped/Meta Boxes
    await _safeOpenBox('settings');
    await _safeOpenBox('chat_threads');
    await _safeOpenBox('task_meta');
    await _safeOpenBox('journal_meta');
    await _safeOpenBox('schedules');

    print('[Debug] 인프라 및 마이그레이션 시작...');
    await CrashReporter.instance.init();
    await SyncOutbox.instance.init();
    
    try {
      await HiveMigrations.run();
    } catch (e) {
      print('[Debug] 마이그레이션 중 오류 (무시하고 진행): $e');
    }

    print('[Debug] runApp 실행 직전...');
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
    print('[Debug] bootstrap 완료 및 앱 실행됨.');
  }, (Object error, StackTrace stack) {
    DevLog.instance.addLog('Guarded Error: $error\n$stack');
    print('[Debug] runZonedGuarded 치명적 에러: $error');
    unawaited(CrashReporter.instance.record(error, stack, hint: 'runZonedGuarded'));
  });
}
