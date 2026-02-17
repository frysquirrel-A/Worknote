import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
    _journals.insert(0, entry);
    notifyListeners();
  }
}