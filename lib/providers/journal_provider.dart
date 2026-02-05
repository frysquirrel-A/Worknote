import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; 
import '../models.dart';
import '../services/drive_service.dart';
import 'package:collection/collection.dart';

class JournalProvider extends ChangeNotifier {
  final DriveService _driveService = DriveService();
  
  List<JournalEntry> _journals = [];
  bool _isLoading = false;

  List<JournalEntry> get journals => _journals;
  bool get isLoading => _isLoading;

  Map<String, List<JournalEntry>> getGroupedJournals(String teamId) {
    final filtered = _journals.where((j) => j.teamId == teamId).toList();
    return groupBy(filtered, (JournalEntry j) => j.date.toIso8601String().substring(0, 10));
  }

  Future<void> loadJournals() async {
    _setLoading(true);
    final data = await _driveService.syncJsonData(
      _journals.map((e) => e.toJson()).toList(), 
      'worknote_journals.json'
    );

    if (data != null && data.isNotEmpty) {
      _journals = data.map((e) => JournalEntry.fromJson(e)).toList();
    } else {
      _journals = [
        JournalEntry(
          id: const Uuid().v4(), teamId: 'default',
          userId: 'me', userName: '김반장',
          title: '오늘의 현장 점검',
          content: '302동 타설 작업 완료했습니다. 특이사항 없습니다.',
          date: DateTime.now(),
          photos: [],
        )
      ];
    }
    _setLoading(false);
  }

  Future<String?> uploadPhoto(String localPath) async {
    final fileName = 'journal_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await _driveService.uploadPhoto(localPath, fileName);
  }

  Future<void> addJournal(JournalEntry journal) async {
    _setLoading(true);
    _journals.insert(0, journal);
    
    await _driveService.syncJsonData(
      _journals.map((e) => e.toJson()).toList(), 
      'worknote_journals.json'
    );

    notifyListeners();
    _setLoading(false);
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
