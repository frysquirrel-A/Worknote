import 'package:flutter/material.dart';
import '../models.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  final List<Project> projects = [
    Project(id: 'p1', name: 'A동 아파트 신축', color: Colors.blue),
    Project(id: 'p2', name: 'B동 설비 보수', color: Colors.orange),
    Project(id: 'p3', name: 'C동 전기 증설', color: Colors.green),
  ];

  final List<TeamMember> members = [
    TeamMember(id: 'me', name: '나', emoji: '👩‍💻', role: '현장 총괄'),
    TeamMember(id: 'kim', name: '김반장', emoji: '👨‍💼', role: '설비 팀장'),
    TeamMember(id: 'lee', name: '이대리', emoji: '🧑‍🎨', role: '안전 담당'),
  ];

  final List<Task> tasks = [];
  final List<JournalEntry> journals = [];

  void initSamples() {
    if (tasks.isEmpty) {
      tasks.add(Task(
        id: '1', title: '302호 배관 긴급 누수 점검', assigneeId: 'me', assigneeName: '나',
        assigneeEmoji: '👩‍💻', projectId: 'p1', createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 1)), priority: TaskPriority.high,
      ));
    }
    
    // 갤러리용 샘플 데이터 10개 추가
    if (journals.isEmpty) {
      final now = DateTime.now();
      for (int i = 1; i <= 10; i++) {
        journals.add(JournalEntry(
          id: 'sample_$i', 
          userId: i % 2 == 0 ? 'me' : 'kim', 
          userName: i % 2 == 0 ? '나' : '김반장',
          title: '샘플 현장 사진 $i', 
          content: '자동 생성된 샘플 데이터입니다.', 
          projectId: 'p1',
          date: now.subtract(Duration(days: i ~/ 3)), 
          photos: ['https://picsum.photos/seed/$i/400/400'], // 온라인 더미 이미지
        ));
      }
    }
  }
}
