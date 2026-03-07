import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

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
import 'package:worknote/features/profile/models/profile_focus_prefs.dart';
import 'package:worknote/features/profile/state/focus_provider.dart';
import 'package:worknote/features/schedule/state/schedule_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';

void _logDebug(String message) {
  if (kDebugMode) {
    debugPrint('[bootstrap] $message');
  }
}

void _safeRegisterAdapter<T>(TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }
}

Future<Box<T>> _safeOpenBox<T>(String name) async {
  try {
    return await Hive.openBox<T>(name);
  } catch (error, stackTrace) {
    DevLog.instance.addLog('Hive open failed: $name / $error\n$stackTrace');
    rethrow;
  }
}

Future<void> bootstrap() async {
  _logDebug('start');

  runZonedGuarded(
    () async {
      var firebaseReady = false;
      final binding = WidgetsFlutterBinding.ensureInitialized();
      final isTestBinding = binding.runtimeType.toString().toLowerCase().contains(
        'test',
      );

      _logDebug('initialize Firebase');
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        firebaseReady = true;
      } catch (error, stackTrace) {
        DevLog.instance.addLog('Firebase init failed: $error\n$stackTrace');
        _logDebug('Firebase unavailable, continue without it: $error');
      }

      if (!isTestBinding) {
        FlutterError.onError = (details) {
          DevLog.instance.addLog(
            'Flutter Error: ${details.exception}\n${details.stack}',
          );
          if (firebaseReady) {
            FirebaseCrashlytics.instance.recordFlutterFatalError(details);
          }
          FlutterError.presentError(details);
        };

        PlatformDispatcher.instance.onError = (error, stackTrace) {
          DevLog.instance.addLog('Platform Error: $error\n$stackTrace');
          if (firebaseReady) {
            FirebaseCrashlytics.instance.recordError(
              error,
              stackTrace,
              fatal: true,
            );
          }
          return true;
        };
      } else {
        _logDebug('test binding detected, keep default error handlers');
      }

      _logDebug('initialize locale formatting');
      await initializeDateFormatting('ko_KR', null);

      _logDebug('initialize Hive');
      await Hive.initFlutter();

      _logDebug('register Hive adapters');
      _safeRegisterAdapter(TaskPriorityAdapter());
      _safeRegisterAdapter(TaskAdapter());
      _safeRegisterAdapter(ProjectAdapter());
      _safeRegisterAdapter(JournalEntryAdapter());
      _safeRegisterAdapter(TeamAdapter());
      _safeRegisterAdapter(AppUserAdapter());
      _safeRegisterAdapter(ChatMessageAdapter());
      _safeRegisterAdapter(ProfileFocusPrefsAdapter());

      _logDebug('open Hive boxes');
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
      await _safeOpenBox<ProfileFocusPrefs>('focus_prefs');

      _logDebug('initialize crash reporter and sync outbox');
      await CrashReporter.instance.init();
      await SyncOutbox.instance.init();

      try {
        await HiveMigrations.run();
      } catch (error, stackTrace) {
        DevLog.instance.addLog('Hive migration warning: $error\n$stackTrace');
        _logDebug('Hive migration warning ignored: $error');
      }

      _logDebug('run app');
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
            ChangeNotifierProvider(create: (_) => FocusProvider()..init()),
          ],
          child: const WorkNoteApp(),
        ),
      );
    },
    (error, stackTrace) {
      DevLog.instance.addLog('Guarded Error: $error\n$stackTrace');
      if (Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: true,
        );
      }
      _logDebug('runZonedGuarded caught: $error');
      unawaited(
        CrashReporter.instance.record(
          error,
          stackTrace,
          hint: 'runZonedGuarded',
        ),
      );
    },
  );
}
