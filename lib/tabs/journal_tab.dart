import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import '../logic/app_controller.dart';

class JournalTab extends StatelessWidget {
  final Map<String, List<JournalEntry>> groupedJournals;
  final List<Project> projects;
  final List<TeamMember> members;
  final AppController controller;
  final Function(DateTime) onPhotoTap;
  final AppTone tone;

  const JournalTab({
    super.key, 
    required this.groupedJournals, 
    required this.projects, 
    required this.members, 
    required this.controller, 
    required this.onPhotoTap, 
    required this.tone
  });

  void _showJournalDetail(BuildContext context, JournalEntry journal) {
    final member = members.firstWhere((m) => m.id == journal.userId, orElse: () => TeamMember(id: '?', name: '알 수 없음', emoji: '👤', role: ''));
    final project = journal.projectId != null 
        ? projects.firstWhere((p) => p.id == journal.projectId, orElse: () => Project(id: '?', name: '?', color: Colors.grey))
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (project != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: project.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text("#${project.name}", style: TextStyle(color: project.color, fontWeight: FontWeight.w900, fontSize: 13)),
                        ),
                      const SizedBox(height: 8),
                      Text("${member.emoji} ${member.name} 작성", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("작성: ${DateFormat('yy.MM.dd HH:mm').format(journal.date)}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
                      Text("수정: ${DateFormat('yy.MM.dd HH:mm').format(journal.updatedAt)}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(journal.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              const Divider(height: 48),
              Text(journal.content, style: const TextStyle(fontSize: 16, height: 1.8, color: Color(0xFF334155))),
              const SizedBox(height: 32),
              if (journal.photos.isNotEmpty) ...[
                const Text("첨부 사진", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: journal.photos.length,
                    itemBuilder: (c, i) => GestureDetector(
                      onTap: () => _showPhotoPreview(context, journal.photos[i], journal.date),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(image: _getImageProvider(journal.photos[i]), fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showWriteJournalDialog(context, existingEntry: journal);
                  },
                  icon: const Icon(Icons.edit_note),
                  label: const Text("일지 수정하기", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhotoPreview(BuildContext context, String path, DateTime date) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.9),
      pageBuilder: (ctx, anim1, anim2) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Center(child: InteractiveViewer(child: Image(image: _getImageProvider(path), fit: BoxFit.contain))),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      style: IconButton.styleFrom(backgroundColor: Colors.white24),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                        onPhotoTap(date);
                      },
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: const Text("갤러리에서 보기", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(backgroundColor: Colors.blue.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http')) return NetworkImage(path);
    return FileImage(File(path));
  }

  void _showWriteJournalDialog(BuildContext context, {JournalEntry? existingEntry}) {
    final titleCtrl = TextEditingController(text: existingEntry?.title);
    final contentCtrl = TextEditingController(text: existingEntry?.content);
    Project? selectedProject = existingEntry?.projectId != null 
        ? projects.firstWhere((p) => p.id == existingEntry!.projectId) : null;
    bool isPrivate = existingEntry?.isPrivate ?? false;
    List<String> photos = existingEntry != null ? List.from(existingEntry.photos) : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => StatefulBuilder(
        builder: (stfCtx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existingEntry == null ? "일지 작성" : "일지 수정", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "제목", border: OutlineInputBorder())),
              const SizedBox(height: 16),
              DropdownButtonFormField<Project>(
                initialValue: selectedProject,
                items: projects.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                onChanged: (v) => setModalState(() => selectedProject = v),
                decoration: const InputDecoration(labelText: "관련 프로젝트", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(controller: contentCtrl, maxLines: 5, decoration: const InputDecoration(labelText: "내용", border: OutlineInputBorder())),
              const SizedBox(height: 16),
              const Text("사진 첨부", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  // 카메라 직접 촬영 아이콘
                  InkWell(
                    onTap: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.camera);
                      if (image != null) setModalState(() => photos.insert(0, image.path));
                    },
                    child: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
                      child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 갤러리 앨범 연동 리스트
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length + 1, // +1은 앨범 추가 버튼 대용
                        itemBuilder: (c, i) {
                          if (i == photos.length) {
                            return InkWell(
                              onTap: () async {
                                final picker = ImagePicker();
                                final image = await picker.pickImage(source: ImageSource.gallery);
                                if (image != null) setModalState(() => photos.insert(0, image.path));
                              },
                              child: Container(
                                width: 60, height: 60,
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.photo_library_rounded, color: Colors.grey),
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image(image: _getImageProvider(photos[i]), width: 60, height: 60, fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("비공개 설정", style: TextStyle(fontWeight: FontWeight.bold)),
                  Switch(
                    value: isPrivate, 
                    activeThumbColor: const Color(0xFF2563EB), 
                    onChanged: (v) => setModalState(() => isPrivate = v)
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: FilledButton(
                    onPressed: () {
                      if (titleCtrl.text.isEmpty) return;
                      if (existingEntry == null) {
                        controller.addJournal(JournalEntry(
                          id: DateTime.now().toString(), userId: 'me', userName: '나',
                          title: titleCtrl.text, content: contentCtrl.text,
                          projectId: selectedProject?.id, date: DateTime.now(),
                          photos: photos, isPrivate: isPrivate,
                        ));
                      } else {
                        controller.updateJournal(existingEntry.id, titleCtrl.text, contentCtrl.text, selectedProject?.id, isPrivate, photos);
                      }
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(existingEntry == null ? "저장하기" : "수정 완료", style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = groupedJournals.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (v) {
                controller.journalSearchQuery = v;
                controller.refresh();
              },
              decoration: InputDecoration(
                hintText: "일지 내용을 검색하세요...",
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
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _filterCell("그룹 주기", _periodText(controller.journalGroupPeriod), 
                    ["일별", "월별", "분기별"], (v) {
                      if (v == "일별") controller.journalGroupPeriod = JournalGroupPeriod.day;
                      else if (v == "월별") controller.journalGroupPeriod = JournalGroupPeriod.month;
                      else controller.journalGroupPeriod = JournalGroupPeriod.quarter;
                      controller.refresh();
                    }, color: const Color(0xFF2563EB)),
                  const VerticalDivider(width: 1, indent: 12, endIndent: 12, color: Color(0xFFF1F5F9)),
                  _filterCell("담당 팀원", controller.journalMemberFilterId == 'all' ? "전체 리스트" : members.firstWhere((m) => m.id == controller.journalMemberFilterId).name, 
                    ["전체 리스트", ...members.map((m) => m.name)], (v) {
                      if (v == "전체 리스트") controller.journalMemberFilterId = 'all';
                      else controller.journalMemberFilterId = members.firstWhere((m) => m.name == v).id;
                      controller.refresh();
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
                      final items = groupedJournals[key]!;
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
                            final member = members.firstWhere((m) => m.id == j.userId, orElse: () => TeamMember(id: '?', name: '알 수 없음', emoji: '👤', role: ''));
                            final project = j.projectId != null 
                                ? projects.firstWhere((p) => p.id == j.projectId, orElse: () => Project(id: '?', name: '?', color: Colors.grey))
                                : null;
                            return GestureDetector(
                              onTap: () => _showJournalDetail(context, j),
                              child: Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFF1F5F9))),
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(child: Text(j.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B)))),
                                          if (project != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(color: project.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: project.color.withValues(alpha: 0.2))),
                                              child: Text("#${project.name}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: project.color)),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(j.content, style: const TextStyle(color: Color(0xFF64748B), height: 1.5, fontWeight: FontWeight.w500), maxLines: 3, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (j.isPrivate) const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.lock, size: 14, color: Color(0xFFF59E0B))),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                                            child: Text("${member.emoji} ${member.name}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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
        onPressed: () => _showWriteJournalDialog(context),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
          ],
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
