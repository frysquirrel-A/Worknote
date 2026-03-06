import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:worknote/firebase_options.dart';

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
import 'package:worknote/features/profile/state/focus_provider.dart';
import 'package:worknote/features/profile/models/profile_focus_prefs.dart';

void _safeRegisterAdapter<T>(TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }
}

/// Hive 諛뺤뒪瑜??덉쟾?섍쾶 ?ㅽ뵂?섎뒗 ?⑥닔 (?먮윭 ??rethrow)
Future<Box<T>> _safeOpenBox<T>(String name) async {
  try {
    return await Hive.openBox<T>(name);
  } catch (e) {
    DevLog.instance.addLog('Hive open failed: $name / $e');
    rethrow;
  }
}

Future<void> bootstrap() async {
  print('[Debug] Bootstrap ?쒖옉...');

  runZonedGuarded(
    () async {
      bool firebaseReady = false;
      print('[Debug] Zone 珥덇린???쒖옉...');
      final binding = WidgetsFlutterBinding.ensureInitialized();
      final isTestBinding = binding.runtimeType.toString().toLowerCase().contains(
        'test',
      );

      // Firebase 諛?Crashlytics 珥덇린??
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        firebaseReady = true;
      } catch (e, st) {
        DevLog.instance.addLog('Firebase init failed: $e\n$st');
        debugPrint(
          '[Debug] Firebase init failed, continue without Firebase services: $e',
        );
      }

      // ?뚮윭???꾨젅?꾩썙???먮윭瑜?Crashlytics 諛?DevLog濡??꾩넚
      if (!isTestBinding) {
        FlutterError.onError = (FlutterErrorDetails details) {
          DevLog.instance.addLog(
            'Flutter Error: ${details.exception}\n${details.stack}',
          );
          if (firebaseReady) {
            FirebaseCrashlytics.instance.recordFlutterFatalError(details);
          }
          FlutterError.presentError(details);
        };

        // 鍮꾨룞湲??먮윭源뚯? 紐⑤몢 ?ъ갑
        PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
          DevLog.instance.addLog('Platform Error: $error\n$stack');
          if (firebaseReady) {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          }
          return true;
        };
      } else {
        debugPrint('[Debug] Test binding detected, keep default error handlers.');
      }

      print('[Debug] ?좎쭨 ?щ㎎ 珥덇린??以?..');
      await initializeDateFormatting('ko_KR', null);

      print('[Debug] Hive 珥덇린???쒖옉...');
      await Hive.initFlutter();

      print('[Debug] ?대뙌???깅줉 以?..');
      _safeRegisterAdapter(TaskPriorityAdapter());
      _safeRegisterAdapter(TaskAdapter());
      _safeRegisterAdapter(ProjectAdapter());
      _safeRegisterAdapter(JournalEntryAdapter());
      _safeRegisterAdapter(TeamAdapter());
      _safeRegisterAdapter(AppUserAdapter());
      _safeRegisterAdapter(ChatMessageAdapter());
      _safeRegisterAdapter(
        ProfileFocusPrefsAdapter(),
      ); // ??[異붽?] Focus ?ㅼ젙 ?대뙌???깅줉

      print('[Debug] Hive 諛뺤뒪 ?ㅽ뵂 ?쒖옉 (?덉쟾 紐⑤뱶)...');
      await _safeOpenBox<Task>('tasks');
      await _safeOpenBox<Project>('projects');
      await _safeOpenBox<JournalEntry>('journals');
      await _safeOpenBox<Team>('teams');
      await _safeOpenBox<AppUser>('users');
      await _safeOpenBox<ChatMessage>('messages');

      await _safeOpenBox('settings');
      await _safeOpenBox('chat_threads');
      await _safeOpenBox('task_meta');
      await _safeOpenBox('journal_meta');
      await _safeOpenBox('schedules');
      await _safeOpenBox<ProfileFocusPrefs>(
        'focus_prefs',
      ); // ??[異붽?] Focus ?ㅼ젙 諛뺤뒪 ?ㅽ뵂

      print('[Debug] ?명봽??諛?留덉씠洹몃젅?댁뀡 ?쒖옉...');
      await CrashReporter.instance.init();
      await SyncOutbox.instance.init();

      try {
        await HiveMigrations.run();
      } catch (e) {
        print('[Debug] 留덉씠洹몃젅?댁뀡 以??ㅻ쪟 (臾댁떆?섍퀬 吏꾪뻾): $e');
      }

      print('[Debug] runApp ?ㅽ뻾 吏곸쟾...');
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TeamProvider()..loadTeams()),
            ChangeNotifierProvider(create: (_) => TaskProvider()..loadData()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(
              create: (_) => JournalProvider()..loadJournals(),
            ),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
            ChangeNotifierProvider(create: (_) => ScheduleProvider()..load()),
            ChangeNotifierProvider(
              create: (_) => FocusProvider()..init(),
            ), // ??[異붽?] FocusProvider ?깅줉
          ],
          child: const WorkNoteApp(),
        ),
      );
      print('[Debug] bootstrap ?꾨즺 諛????ㅽ뻾??');
    },
    (Object error, StackTrace stack) {
      DevLog.instance.addLog('Guarded Error: $error\n$stack');
      if (Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
      print('[Debug] runZonedGuarded 移섎챸???먮윭: $error');
      unawaited(
        CrashReporter.instance.record(error, stack, hint: 'runZonedGuarded'),
      );
    },
  );
}
