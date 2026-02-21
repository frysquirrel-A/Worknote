import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:worknote/data/sync/sync_outbox.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/data/services/drive_service.dart';
import 'package:collection/collection.dart';

class JournalProvider extends ChangeNotifier {
  final DriveService _driveService = DriveService();

  /// Meta storage for journals (untyped Hive box).
  /// Schema (value: Map):
  /// - kind: String ('note'|'progress'|'completionReport')
  /// - relatedTaskId: String? (optional)
  /// - progressUpdates: List<Map>  (each: {id,text,at,userId,userName})
  Box get _metaBox => Hive.box('journal_meta');
  
  List<JournalEntry> _journals = [];
  bool _isLoading = false;

  List<JournalEntry> get journals => _journals;
  bool get isLoading => _isLoading;

  // --- Meta helpers ---
  JournalKind getKind(String journalId) {
    final raw = _metaBox.get(journalId);
    if (raw is Map) {
      final k = raw['kind']?.toString();
      return JournalKind.values.firstWhere(
        (e) => e.name == k,
        orElse: () => JournalKind.note,
      );
    }
    return JournalKind.note;
  }

  String? getRelatedTaskId(String journalId) {
    final raw = _metaBox.get(journalId);
    if (raw is Map) return raw['relatedTaskId']?.toString();
    return null;
  }

  List<Map<String, dynamic>> getProgressUpdates(String journalId) {
    final raw = _metaBox.get(journalId);
    if (raw is Map) {
      final list = raw['progressUpdates'];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m.cast()))
            .toList();
      }
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> setMeta(
    String journalId, {
    required JournalKind kind,
    String? relatedTaskId,
  }) async {
    final current = _metaBox.get(journalId);
    final Map<String, dynamic> next = (current is Map)
        ? Map<String, dynamic>.from(current.cast())
        : <String, dynamic>{};

    next['kind'] = kind.name;
    next['relatedTaskId'] = relatedTaskId;
    next.putIfAbsent('progressUpdates', () => <Map<String, dynamic>>[]);

    await _metaBox.put(journalId, next);
    notifyListeners();
  }

  Future<void> addProgressUpdate({
    required String journalId,
    required String text,
    required String userId,
    required String userName,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final current = _metaBox.get(journalId);
    final Map<String, dynamic> next = (current is Map)
        ? Map<String, dynamic>.from(current.cast())
        : <String, dynamic>{};

    final List<Map<String, dynamic>> updates = (next['progressUpdates'] is List)
        ? (next['progressUpdates'] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m.cast()))
            .toList()
        : <Map<String, dynamic>>[];

    updates.add({
      'id': '${DateTime.now().microsecondsSinceEpoch}',
      'text': trimmed,
      'at': DateTime.now().toIso8601String(),
      'userId': userId,
      'userName': userName,
    });

    next['progressUpdates'] = updates;
    await _metaBox.put(journalId, next);

    // Also bump updatedAt for the journal entry itself
    final idx = _journals.indexWhere((j) => j.id == journalId);
    if (idx >= 0) {
      final j = _journals[idx];
      j.updatedAt = DateTime.now();
      await Hive.box<JournalEntry>('journals').put(j.id, j);
    }

    notifyListeners();
  }

  Map<String, List<JournalEntry>> getGroupedJournals(String teamId) {
    final filtered = _journals.where((j) => j.teamId == teamId).toList();
    return groupBy(filtered, (JournalEntry j) => j.date.toIso8601String().substring(0, 10));
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  // 1. 데이터 로드
  Future<void> loadJournals() async {
    _setLoading(true);
    var box = Hive.box<JournalEntry>('journals');
    _journals = box.values.toList();
    _journals.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    _setLoading(false);
  }

  Future<void> updateJournal(JournalEntry entry) async {
    final box = Hive.box<JournalEntry>('journals');
    entry.updatedAt = DateTime.now();
    await box.put(entry.id, entry);

    // Outbox: journal upsert
    unawaited(
      SyncOutbox.instance.enqueue(
        teamId: entry.teamId,
        entity: 'journal',
        action: 'put',
        entityId: entry.id,
        payload: {
          'title': entry.title,
          'date': entry.date.toIso8601String(),
        },
      ),
    );

    final idx = _journals.indexWhere((j) => j.id == entry.id);
    if (idx >= 0) _journals[idx] = entry;
    _journals.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> deleteJournal(String journalId) async {
    final box = Hive.box<JournalEntry>('journals');
    final before = box.get(journalId);

    await box.delete(journalId);
    await _metaBox.delete(journalId);

    // Outbox: journal delete
    unawaited(
      SyncOutbox.instance.enqueue(
        teamId: before?.teamId ?? 'unknown',
        entity: 'journal',
        action: 'delete',
        entityId: journalId,
        payload: {
          'title': before?.title ?? '',
        },
      ),
    );

    _journals.removeWhere((j) => j.id == journalId);
    notifyListeners();
  }

  // [핵심] 사진 더미 데이터를 포함한 시스템 초기화
  Future<void> resetSystem(String currentTeamId) async {
    var box = Hive.box<JournalEntry>('journals');

    // 1. 싹 비우기
    await box.clear();
    _journals.clear();
    notifyListeners();

    // 2. 현재 팀 ID에 맞춘 샘플 생성 (사진 URL 포함)
    final now = DateTime.now();
    final dummyJournals = [
      JournalEntry(
        id: 'j1', teamId: currentTeamId, userId: 'me', userName: '나',
        title: '현장 점검 완료 (샘플)',
        content: 'A동 302호 배관 점검 결과 이상 없습니다. 추가 자재 발주 예정입니다.',
        date: now, 
        // [수정] 갤러리 확인을 위한 고화질 현장 사진 샘플 추가
        photos: [
          'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?q=80&w=500',
          'https://images.unsplash.com/photo-1504307651254-35680f356dfd?q=80&w=500',
        ],
      ),
      JournalEntry(
        id: 'j2', teamId: currentTeamId, userId: 'm1', userName: '김반장',
        title: '오전 안전 교육 (샘플)',
        content: '추락 방지 및 보호구 착용 철저 교육 실시함. 팀원 전원 참석.',
        date: now.subtract(const Duration(days: 1)), 
        // [수정] 어제 날짜 사진 샘플 추가
        photos: [
          'https://images.unsplash.com/photo-1581094794329-c8112a89af12?q=80&w=500',
        ],
      ),
    ];

    // 3. 로컬 DB 저장
    for (var j in dummyJournals) {
      await box.put(j.id, j);
    }

    // 4. 메모리 적재 및 UI 갱신
    _journals = dummyJournals;
    _journals.sort((a, b) => b.date.compareTo(a.date));
    
    notifyListeners();
  }

  Future<String?> uploadPhoto(String localPath) async {
    final fileName = 'journal_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await _driveService.uploadPhoto(localPath, fileName);
  }

  Future<void> addJournal(JournalEntry entry) async {
    var box = Hive.box<JournalEntry>('journals');
    await box.put(entry.id, entry);

    // Outbox: journal create
    unawaited(
      SyncOutbox.instance.enqueue(
        teamId: entry.teamId,
        entity: 'journal',
        action: 'put',
        entityId: entry.id,
        payload: {
          'title': entry.title,
          'date': entry.date.toIso8601String(),
        },
      ),
    );

    _journals.insert(0, entry);
    notifyListeners();
  }
}