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
  Future<void> processOutbox() async {
    if (_isSyncing) return;

    // 1. 버튼을 누르면 무조건 스피너부터 돌기 시작합니다!
    _isSyncing = true;
    notifyListeners();

    // UX 개선: 사용자가 눌렀다는 걸 인지할 수 있도록 최소 0.5초간 스피너 유지
    await Future.delayed(const Duration(milliseconds: 500));

    // 준비 안됨 or 큐가 비어있음 or 드라이브 오프라인이면 종료
    if (!SyncOutbox.instance.isReady) {
      _isSyncing = false;
      notifyListeners();
      return;
    }

    final box = Hive.box<Map>(SyncOutbox.boxName);
    if (box.isEmpty) {
      _isSyncing = false;
      notifyListeners();
      return;
    }

    if (!_driveService.isReady) {
      _isSyncing = false;
      notifyListeners();
      return;
    }

    try {
      // 2. 아웃박스에서 변경이 발생한 엔티티(종류) 추출
      final entitiesToSync = <String>{};
      for (final raw in box.values) {
        final entity = raw['entity'] as String?;
        if (entity != null) entitiesToSync.add(entity);
      }

      // 3. Drive JSON 파일 특성상, 변경이 있는 엔티티의 전체 최신 상태를 덮어쓰기(Full Sync)
      for (final entity in entitiesToSync) {
        await _syncEntityToDrive(entity);
      }

      // 4. 모든 동기화가 성공하면 아웃박스 큐 비우기
      await SyncOutbox.instance.clear();
      
    } catch (e, stack) {
      // 동기화 중 에러가 나면 큐를 비우지 않고 크래시 리포트에 기록 (재시도 보장)
      unawaited(CrashReporter.instance.record(e, stack, hint: 'SyncProcessor.processOutbox'));
    } finally {
      // 5. 작업이 성공하든 실패하든 마지막에 스피너를 멈춤
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
