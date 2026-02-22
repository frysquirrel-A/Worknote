import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:worknote/data/sync/sync_outbox.dart';
import 'package:worknote/data/services/drive_service.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/core/crash/crash_reporter.dart';

class SyncProcessor extends ChangeNotifier {
  static final SyncProcessor instance = SyncProcessor._();
  SyncProcessor._();

  final DriveService _driveService = DriveService();
  bool _isSyncing = false;
  Timer? _timer;

  bool get isSyncing => _isSyncing;

  /// 앱 구동 시 호출하여 1분 주기로 백그라운드 동기화 큐를 검사합니다.
  void startBackgroundSync() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => processOutbox());
  }

  /// 아웃박스를 소비하여 실제 서버(구글 드라이브)와 동기화를 수행합니다.
  Future<String> processOutbox() async {
    if (_isSyncing) return '이미 동기화가 진행 중입니다.';

    _isSyncing = true;
    notifyListeners();

    // UX: 스피너가 도는 것을 확실히 보여주기 위한 최소 대기 시간
    await Future.delayed(const Duration(milliseconds: 600));

    if (!SyncOutbox.instance.isReady) {
      _isSyncing = false;
      notifyListeners();
      return '로컬 저장소가 준비되지 않았습니다.';
    }

    final box = Hive.box<Map>(SyncOutbox.boxName);
    if (box.isEmpty) {
      _isSyncing = false;
      notifyListeners();
      return '동기화할 데이터가 없습니다.';
    }

    // 🚨 여기서 로그인이 안 되어 있으면 큐를 비우지 않고 바로 종료됩니다!
    if (!_driveService.isReady) {
      _isSyncing = false;
      notifyListeners();
      return '구글 드라이브 연동(로그인)이 필요합니다.';
    }

    try {
      final entitiesToSync = <String>{};
      for (final raw in box.values) {
        final entity = raw['entity'] as String?;
        if (entity != null) entitiesToSync.add(entity);
      }

      for (final entity in entitiesToSync) {
        await _syncEntityToDrive(entity);
      }

      // ✨ 드라이브 업로드까지 완벽하게 성공했을 때만 큐를 비웁니다!
      await SyncOutbox.instance.clear();
      return '구글 드라이브 동기화가 완료되었습니다! ✨';
      
    } catch (e, stack) {
      unawaited(CrashReporter.instance.record(e, stack, hint: 'SyncProcessor.processOutbox'));
      return '동기화 중 오류가 발생했습니다. (네트워크 확인)';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _syncEntityToDrive(String entity) async {
    switch (entity) {
      case 'task':
      case 'task_meta':
        final tasks = Hive.box<Task>('tasks').values.map((e) => e.toJson()).toList();
        await _driveService.syncJsonData(tasks, 'worknote_tasks.json');
        break;
      case 'project':
        final projects = Hive.box<Project>('projects').values.map((e) => e.toJson()).toList();
        await _driveService.syncJsonData(projects, 'worknote_projects.json');
        break;
      case 'journal':
        final journals = Hive.box<JournalEntry>('journals').values.map((e) => e.toJson()).toList();
        await _driveService.syncJsonData(journals, 'worknote_journals.json');
        break;
      case 'chat_message':
      case 'chat_thread':
        final chats = Hive.box<ChatMessage>('messages').values.map((e) => e.toJson()).toList();
        await _driveService.syncJsonData(chats, 'worknote_chats.json');
        break;
    }
  }
}
