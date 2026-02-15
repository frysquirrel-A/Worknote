import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';

class SystemMonitorPage extends StatelessWidget {
  const SystemMonitorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final teamProv = context.watch<TeamProvider>();
    final taskProv = context.watch<TaskProvider>();
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("SYSTEM MONITOR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Column( // 모바일 화면을 위해 Column으로 변경
        children: [
          // 상단: 상태 패널
          Expanded(
            flex: 2,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatusCard("Connection", "ONLINE (Drive)", Colors.green),
                const SizedBox(height: 12),
                _buildInfoCard("사용자", "${authProv.currentUser?.name}"),
                _buildInfoCard("팀 ID", teamProv.currentTeamId),
                _buildInfoCard("업무 데이터", "${taskProv.tasks.length}건"),
              ],
            ),
          ),
          
          // 하단: 로그 뷰어
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("LIVE DATA STREAM", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    const Divider(color: Colors.white10),
                    _buildJsonSection("Tasks (Top 3)", taskProv.tasks.take(3).map((e)=>e.toJson()).toList()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi, color: color, size: 20),
          const SizedBox(width: 12),
          // [수정] Expanded로 감싸서 오버플로우 방지
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(width: 8),
          // [수정] Flexible로 감싸서 텍스트가 길어지면 줄바꿈/생략 처리
          Flexible(
            child: Text(value, 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonSection(String filename, dynamic data) {
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    String prettyPrint = encoder.convert(data);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(filename, style: const TextStyle(color: Colors.orangeAccent, fontSize: 11)),
          SelectableText(
            prettyPrint,
            style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 10),
          ),
        ],
      ),
    );
  }
}