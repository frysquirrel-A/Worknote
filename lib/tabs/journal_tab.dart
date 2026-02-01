import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';

class JournalTab extends StatefulWidget {
  final List<JournalEntry> journals;
  final List<Project> projects;
  final List<TeamMember> members;
  final Function(JournalEntry) onSaveJournal;
  final Function(DateTime) onPhotoTap;
  final AppTone tone;

  const JournalTab({super.key, required this.journals, required this.projects, required this.members, required this.onSaveJournal, required this.onPhotoTap, required this.tone});

  @override
  State<JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<JournalTab> {
  String _searchQuery = '';
  JournalGroupPeriod _groupPeriod = JournalGroupPeriod.day;
  String _memberFilterId = 'all';

  void _showWriteJournalDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    Project? selectedProject;
    bool isPrivate = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("일지 작성", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "제목", border: OutlineInputBorder())),
              const SizedBox(height: 16),
              DropdownButtonFormField<Project>(
                value: selectedProject,
                items: widget.projects.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                onChanged: (v) => setModalState(() => selectedProject = v),
                decoration: const InputDecoration(labelText: "관련 프로젝트", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(controller: contentCtrl, maxLines: 5, decoration: const InputDecoration(labelText: "내용", border: OutlineInputBorder())),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("비공개 설정", style: TextStyle(fontWeight: FontWeight.bold)),
                  Switch(value: isPrivate, activeColor: const Color(0xFF2563EB), onChanged: (v) => setModalState(() => isPrivate = v)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    if (titleCtrl.text.isEmpty) return;
                    widget.onSaveJournal(JournalEntry(
                      id: DateTime.now().toString(),
                      userId: 'me',
                      userName: '나',
                      title: titleCtrl.text,
                      content: contentCtrl.text,
                      projectId: selectedProject?.id,
                      date: DateTime.now(),
                      photos: [],
                      isPrivate: isPrivate,
                    ));
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text("저장하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _getGroupKey(DateTime d, JournalGroupPeriod p) {
    if (p == JournalGroupPeriod.day) return DateFormat('yyyy-MM-dd').format(d);
    if (p == JournalGroupPeriod.month) return DateFormat('yyyy-MM').format(d);
    return DateFormat('yyyy년').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.journals.where((j) {
      bool canSee = !j.isPrivate || j.userId == 'me';
      bool matchesSearch = j.title.contains(_searchQuery) || j.content.contains(_searchQuery);
      bool matchesMember = _memberFilterId == 'all' || j.userId == _memberFilterId;
      return canSee && matchesSearch && matchesMember;
    }).toList();

    final groups = <String, List<JournalEntry>>{};
    for (var j in filtered) {
      String key = _getGroupKey(j.date, _groupPeriod);
      groups.putIfAbsent(key, () => []).add(j);
    }
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: "일지 내용을 검색하세요...",
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(40), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(40), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
          ),
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _filterCell("그룹 주기", _periodText(_groupPeriod), 
                    ["일별", "월별", "분기별"], (v) {
                      setState(() {
                        if (v == "일별") _groupPeriod = JournalGroupPeriod.day;
                        else if (v == "월별") _groupPeriod = JournalGroupPeriod.month;
                        else _groupPeriod = JournalGroupPeriod.quarter;
                      });
                    }, color: const Color(0xFF2563EB)),
                  const VerticalDivider(width: 1, indent: 12, endIndent: 12, color: Color(0xFFF1F5F9)),
                  _filterCell("담당 팀원", _memberFilterId == 'all' ? "전체 리스트" : widget.members.firstWhere((m) => m.id == _memberFilterId).name, 
                    ["전체 리스트", ...widget.members.map((m) => m.name)], (v) {
                      setState(() {
                        if (v == "전체 리스트") _memberFilterId = 'all';
                        else _memberFilterId = widget.members.firstWhere((m) => m.name == v).id;
                      });
                    }),
                ],
              ),
            ),
          ),

          Expanded(
            child: keys.isEmpty
                ? const Center(child: Text("기록된 일지가 없습니다.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: keys.length,
                    itemBuilder: (ctx, i) {
                      final key = keys[i];
                      final items = groups[key]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: Row(
                              children: [
                                Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(2))),
                                const SizedBox(width: 8),
                                Text(key, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
                              ],
                            ),
                          ),
                          ...items.map((j) {
                            final member = widget.members.firstWhere((m) => m.id == j.userId, orElse: () => TeamMember(id: '?', name: '알 수 없음', emoji: '👤', role: ''));
                            final project = j.projectId != null 
                                ? widget.projects.firstWhere((p) => p.id == j.projectId, orElse: () => Project(id: '?', name: '?', color: Colors.grey))
                                : null;

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32), side: const BorderSide(color: Color(0xFFF1F5F9))),
                              color: Colors.white,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(j.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B)))),
                                    Row(
                                      children: [
                                        if (j.isPrivate) Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.lock, size: 14, color: Color(0xFFF59E0B))),
                                        // 프로젝트 배지
                                        if (project != null)
                                          Container(
                                            margin: const EdgeInsets.only(right: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: project.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: project.color.withValues(alpha: 0.2))),
                                            child: Text("#${project.name}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: project.color)),
                                          ),
                                        // 작성자 표시
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                                          child: Text("${member.emoji} ${member.name}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(j.content, style: const TextStyle(color: Color(0xFF64748B), height: 1.5, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                                ),
                                onTap: () => widget.onPhotoTap(j.date),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showWriteJournalDialog,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit),
        label: const Text("일지 쓰기", style: TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _filterCell(String label, String value, List<String> options, Function(String) onPick, {Color? color}) {
    return Expanded(
      child: PopupMenuButton<String>(
        onSelected: onPick,
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        itemBuilder: (ctx) => options.map((o) => PopupMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))).toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color ?? const Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  String _periodText(JournalGroupPeriod p) {
    if (p == JournalGroupPeriod.day) return "일별";
    if (p == JournalGroupPeriod.month) return "월별";
    return "분기별";
  }
}
