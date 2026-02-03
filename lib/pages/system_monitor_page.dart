import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../providers/team_provider.dart';
import '../providers/task_provider.dart';

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
        title: const Text("SYSTEM ARCHITECTURE HUB", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // [왼쪽] 구조 다이어그램 & 상태 패널
          Expanded(
            flex: 2,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildStatusCard("Connection Status", "ONLINE (Google Drive)", Colors.green),
                const SizedBox(height: 16),
                _buildStructureDiagram(),
                const SizedBox(height: 16),
                _buildInfoCard("현재 사용자", "${authProv.currentUser?.name} (${authProv.currentUser?.role})"),
                _buildInfoCard("현재 팀 ID", teamProv.currentTeamId),
                _buildInfoCard("총 업무 데이터", "${taskProv.tasks.length}건 동기화됨"),
              ],
            ),
          ),
          
          // [오른쪽] 실제 JSON 데이터 뷰어 (Raw Data)
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("LIVE DATA STREAM (JSON)", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  const Divider(color: Colors.white10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildJsonSection("Users (worknote_users.json)", authProv.currentUser?.toJson() ?? {}),
                          _buildJsonSection("Teams (worknote_teams.json)", teamProv.teams.map((e)=>e.toJson()).toList()),
                          _buildJsonSection("Tasks (worknote_tasks.json)", taskProv.tasks.take(5).map((e)=>e.toJson()).toList()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildJsonSection(String filename, dynamic data) {
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    String prettyPrint = encoder.convert(data);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("📄 $filename", style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SelectableText(
            prettyPrint,
            style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildStructureDiagram() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Icon(Icons.cloud_circle, size: 40, color: Colors.blue),
          const Text("Google Drive (Server)", style: TextStyle(color: Colors.blue, fontSize: 10)),
          Container(height: 20, width: 2, color: Colors.grey),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
            child: const Text("DriveService (API)", style: TextStyle(color: Colors.white, fontSize: 10)),
          ),
          Container(height: 20, width: 2, color: Colors.grey),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(Icons.phone_iphone, color: Colors.white),
              Icon(Icons.laptop_mac, color: Colors.white),
            ],
          ),
          const Text("Clients (App)", style: TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}
