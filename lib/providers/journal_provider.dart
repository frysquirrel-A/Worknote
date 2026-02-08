import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; 
import '../models.dart';
import '../services/drive_service.dart';
import '../services/local_db_service.dart'; 
import 'package:collection/collection.dart';

class JournalProvider extends ChangeNotifier {
  final DriveService _driveService = DriveService();
  final LocalDatabaseService _localDb = LocalDatabaseService(); 
  
  List<JournalEntry> _journals = [];
  bool _isLoading = false;

  List<JournalEntry> get journals => _journals;
  bool get isLoading => _isLoading;

  Map<String, List<JournalEntry>> getGroupedJournals(String teamId) {
    final filtered = _journals.where((j) => j.teamId == teamId).toList();
    return groupBy(filtered, (JournalEntry j) => j.date.toIso8601String().substring(0, 10));
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  Future<void> loadJournals() async {
    _setLoading(true);
    
    // 1. [Offline First] 로컬 로드
    _journals = _localDb.getAll<JournalEntry>('journals');
    if (_journals.isNotEmpty) {
      _setLoading(false);
    }

    // 2. [Background] 드라이브 동기화
    try {
      final data = await _driveService.syncJsonData(
        _journals.map((e) => e.toJson()).toList(), 
        'worknote_journals.json'
      );

      if (data != null && data.isNotEmpty) {
        _journals = data.map((e) => JournalEntry.fromJson(e)).toList();
        await _localDb.syncAll<JournalEntry>('journals', _journals, (j) => j.id);
      } 
      
      if (_journals.isEmpty) {
        _journals = [
          JournalEntry(
            id: const Uuid().v4(), teamId: 'default',
            userId: 'me', userName: '김반장',
            title: '오늘의 현장 점검',
            content: '첫 일지를 작성해보세요!',
            date: DateTime.now(),
            photos: [],
          )
        ];
      }
    } catch (e) {
      print("⚠️ 오프라인 모드: 일지 동기화 실패 ($e)");
    }
    
    _setLoading(false);
  }

  Future<String?> uploadPhoto(String localPath) async {
    final fileName = 'journal_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await _driveService.uploadPhoto(localPath, fileName);
  }

  Future<void> addJournal(JournalEntry entry) async {
    _journals.insert(0, entry);
    notifyListeners();

    await _localDb.put<JournalEntry>('journals', entry.id, entry);

    await _driveService.syncJsonData(
      _journals.map((e) => e.toJson()).toList(), 
      'worknote_journals.json'
    );
  }
}