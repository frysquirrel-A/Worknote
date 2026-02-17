import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
import '../providers/journal_provider.dart';
import '../providers/team_provider.dart';
import '../providers/task_provider.dart';

class JournalTab extends StatefulWidget {
  const JournalTab({super.key});

  @override
  State<JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<JournalTab> {
  String _searchQuery = "";
  String _viewMode = "일별";

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final journalProv = context.watch<JournalProvider>();
    
    final allJournals = journalProv.journals.where((j) {
      bool matchesTeam = j.teamId == teamProv.currentTeamId;
      bool matchesSearch = j.title.contains(_searchQuery) || j.content.contains(_searchQuery);
      return matchesTeam && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 검색창
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: "일지 내용을 검색하세요...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // 뷰 모드 세그먼트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildSegment("일별", _viewMode == "일별"),
                _buildSegment("전체 리스트", _viewMode == "전체 리스트"),
              ],
            ),
          ),

          // 일지 리스트
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: allJournals.length,
              itemBuilder: (context, index) {
                final journal = allJournals[index];
                return _buildJournalCard(context, journal);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.edit_document, color: Colors.white),
        onPressed: () => _showWriteModal(context, journalProv, teamProv),
      ),
    );
  }

  Widget _buildSegment(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewMode = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isSelected ? const Color(0xFF2563EB) : Colors.transparent, width: 2)),
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: isSelected ? const Color(0xFF2563EB) : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ),
        ),
      ),
    );
  }

  Widget _buildJournalCard(BuildContext context, JournalEntry journal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(DateFormat('yyyy-MM-dd').format(journal.date), style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              if (journal.projectId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text("관련 프로젝트", style: TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(journal.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text(journal.content, style: const TextStyle(color: Color(0xFF64748B), height: 1.5)),
        ],
      ),
    );
  }

  void _showWriteModal(BuildContext context, JournalProvider prov, TeamProvider teamProv) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final taskProv = context.read<TaskProvider>();
    String? selectedProjectId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("일지 작성", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "제목")),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: selectedProjectId,
                items: [
                  const DropdownMenuItem(value: null, child: Text("선택 안함")),
                  ...taskProv.projects.where((p) => p.teamId == teamProv.currentTeamId).map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                ],
                onChanged: (v) => setModalState(() => selectedProjectId = v),
              ),
              const SizedBox(height: 16),
              Expanded(child: TextField(controller: contentCtrl, maxLines: 10, decoration: const InputDecoration(hintText: "내용을 입력하세요"))),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.isEmpty) return;
                    prov.addJournal(JournalEntry(
                      id: const Uuid().v4(), teamId: teamProv.currentTeamId,
                      userId: 'me', userName: '관리자', title: titleCtrl.text, content: contentCtrl.text,
                      date: DateTime.now(), photos: [], projectId: selectedProjectId,
                    ));
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                  child: const Text("저장하기"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
