import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/journal/state/journal_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';

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
    final authProv = context.watch<AuthProvider>();
    final myId = authProv.currentUser?.id ?? 'me';
    final myName = authProv.currentUser?.name ?? '관리자';
    
    final allJournals = journalProv.journals.where((j) {
      bool matchesTeam = j.teamId == teamProv.currentTeamId;
      final q = _searchQuery.trim().toLowerCase();
      bool matchesSearch = q.isEmpty || j.title.toLowerCase().contains(q) || j.content.toLowerCase().contains(q);
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
          Expanded(child: _buildJournalList(allJournals)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.edit_document, color: Colors.white),
        onPressed: () => _showWriteModal(context, journalProv, teamProv, myId, myName),
      ),
    );
  }

  Widget _buildJournalList(List<JournalEntry> journals) {
    if (_viewMode == "전체 리스트") {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: journals.length,
        itemBuilder: (context, index) {
          final journal = journals[index];
          return _buildJournalCard(context, journal);
        },
      );
    }

    // 일별 그룹
    final Map<String, List<JournalEntry>> grouped = {};
    for (final j in journals) {
      final k = DateFormat('yyyy-MM-dd').format(j.date);
      grouped.putIfAbsent(k, () => []).add(j);
    }
    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        for (final k in keys) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 6),
            child: Row(
              children: [
                Container(width: 4, height: 14, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text(k, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              ],
            ),
          ),
          ...grouped[k]!.map((j) => _buildJournalCard(context, j)),
          const SizedBox(height: 6),
        ]
      ],
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

  void _showWriteModal(BuildContext context, JournalProvider prov, TeamProvider teamProv, String myId, String myName) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final taskProv = context.read<TaskProvider>();
    String? selectedProjectId;
    bool isPrivate = false;
    final List<String> photos = [];

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
              const Text("일지 작성", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: "제목",
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: selectedProjectId,
                decoration: InputDecoration(
                  labelText: "관련 프로젝트(선택)",
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text("선택 안함")),
                  ...taskProv.projects.where((p) => p.teamId == teamProv.currentTeamId).map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                ],
                onChanged: (v) => setModalState(() => selectedProjectId = v),
              ),
              const SizedBox(height: 10),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: isPrivate,
                onChanged: (v) => setModalState(() => isPrivate = v),
                title: const Text("비공개 일지", style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text("팀원에게 보이지 않도록 저장"),
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await ImagePicker().pickMultiImage();
                        if (picked.isEmpty) return;
                        setModalState(() => photos.addAll(picked.map((x) => x.path)));},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text("사진 추가", style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text("${photos.length}장", style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800)),
                ],
              ),

              if (photos.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 46,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final p = photos[idx];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.image_rounded, size: 16, color: Color(0xFF2563EB)),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 120,
                              child: Text(
                                p.split('/').last,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setModalState(() => photos.removeAt(idx)),
                              child: const Icon(Icons.close_rounded, size: 16),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: contentCtrl,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    hintText: "오늘의 작업/특이사항/사진 설명 등을 기록하세요",
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    prov.addJournal(JournalEntry(
                      id: const Uuid().v4(), teamId: teamProv.currentTeamId,
                      userId: myId,
                      userName: myName,
                      title: titleCtrl.text.trim(),
                      content: contentCtrl.text.trim(),
                      date: DateTime.now(),
                      updatedAt: DateTime.now(),
                      photos: photos,
                      projectId: selectedProjectId,
                      isPrivate: isPrivate,
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
