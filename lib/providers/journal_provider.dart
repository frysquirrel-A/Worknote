import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../services/drive_service.dart';

class JournalProvider extends ChangeNotifier {
  final DriveService _driveService = DriveService();
  
  List<JournalEntry> _journals = [];

  // UI Filters
  String searchQuery = '';
  JournalGroupPeriod groupPeriod = JournalGroupPeriod.day;
  String memberFilterId = 'all';

  // --- Getters ---
  List<JournalEntry> get journals => _journals;

  // 팀별, 필터별 그룹화된 일지 가져오기
  Map<String, List<JournalEntry>> getGroupedJournals(String currentTeamId) {
    final filtered = _journals.where((j) {
      if (j.teamId != currentTeamId) return false; // 팀 필터링

      bool canSee = !j.isPrivate || j.userId == 'me';
      bool matchesSearch = j.title.contains(searchQuery) || j.content.contains(searchQuery);
      bool matchesMember = memberFilterId == 'all' || j.userId == memberFilterId;
      return canSee && matchesSearch && matchesMember;
    }).toList();

    final groups = <String, List<JournalEntry>>{};
    for (var j in filtered) {
      String key = _getJournalGroupKey(j.date, groupPeriod);
      groups.putIfAbsent(key, () => []).add(j);
    }
    return groups;
  }

  String _getJournalGroupKey(DateTime d, JournalGroupPeriod p) {
    if (p == JournalGroupPeriod.day) return DateFormat('yyyy-MM-dd').format(d);
    if (p == JournalGroupPeriod.month) return DateFormat('yyyy-MM').format(d);
    return DateFormat('yyyy년').format(d);
  }

  // --- Actions ---

  Future<void> loadJournals() async {
    final data = await _driveService.syncJsonData(
      _journals.map((e) => e.toJson()).toList(), 
      'worknote_journals.json'
    );
    if (data != null) {
      _journals = data.map((e) => JournalEntry.fromJson(e)).toList();
    }
    notifyListeners();
  }

  // [중요] 사진 추가 (업로드 포함)
  Future<String?> uploadPhoto(String filePath, bool isWifiOnly) async {
    return await _driveService.uploadPhoto(filePath, isWifiOnly);
  }

  Future<void> addJournal(JournalEntry e) async {
    _journals.insert(0, e);
    notifyListeners();
    await _sync();
  }

  Future<void> updateJournal(JournalEntry updatedEntry) async {
    final index = _journals.indexWhere((j) => j.id == updatedEntry.id);
    if (index != -1) {
      _journals[index] = updatedEntry;
      notifyListeners();
      await _sync();
    }
  }

  Future<void> _sync() async {
    await _driveService.syncJsonData(
      _journals.map((e) => e.toJson()).toList(), 
      'worknote_journals.json'
    );
  }

  void setFilters({String? search, JournalGroupPeriod? period, String? memberId}) {
    if (search != null) searchQuery = search;
    if (period != null) groupPeriod = period;
    if (memberId != null) memberFilterId = memberId;
    notifyListeners();
  }
}
