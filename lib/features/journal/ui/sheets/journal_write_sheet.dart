import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/journal/state/journal_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';

Future<void> showJournalWriteSheet({
  required BuildContext context,
  required String myId,
  required String myName,
  JournalKind? prefillKind,
  String? prefillRelatedTaskId,
  String? prefillTitle,
  String? prefillContent,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _JournalWriteSheet(
      myId: myId,
      myName: myName,
      prefillKind: prefillKind,
      prefillRelatedTaskId: prefillRelatedTaskId,
      prefillTitle: prefillTitle,
      prefillContent: prefillContent,
    ),
  );
}

class _JournalWriteSheet extends StatefulWidget {
  final String myId, myName;
  final JournalKind? prefillKind;
  final String? prefillRelatedTaskId, prefillTitle, prefillContent;

  const _JournalWriteSheet({
    required this.myId,
    required this.myName,
    this.prefillKind,
    this.prefillRelatedTaskId,
    this.prefillTitle,
    this.prefillContent,
  });

  @override
  State<_JournalWriteSheet> createState() => _JournalWriteSheetState();
}

class _JournalWriteSheetState extends State<_JournalWriteSheet> {
  late final TextEditingController titleCtrl;
  late final TextEditingController contentCtrl;
  late JournalKind kind;
  late String? relatedTaskId;
  String? selectedProjectId;
  bool isPrivate = false;
  final List<String> photos = [];

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.prefillTitle ?? '');
    contentCtrl = TextEditingController(text: widget.prefillContent ?? '');
    kind = widget.prefillKind ?? JournalKind.note;
    relatedTaskId = widget.prefillRelatedTaskId;
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<JournalProvider>();
    final teamProv = context.read<TeamProvider>();
    final taskProv = context.read<TaskProvider>();
    final teamId = teamProv.currentTeamId;
    final tasksForTeam = taskProv.tasks.where((t) => t.teamId == teamId).toList();
    final projectsForTeam = taskProv.projects.where((p) => p.teamId == teamId).toList();

    final safeRelatedTaskId = tasksForTeam.any((t) => t.id == relatedTaskId) ? relatedTaskId : null;
    final safeProjectId = projectsForTeam.any((p) => p.id == selectedProjectId) ? selectedProjectId : null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24), // 상단 패딩 축소
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text('일지 작성', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.text))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: _kindColor(kind).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: Text(_kindLabel(kind), style: TextStyle(color: _kindColor(kind), fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12), // 여백 축소
              Container(
                padding: const EdgeInsets.all(8), // 패딩 축소
                decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                child: Row(
                  children: [
                    _kindChip(label: '일반', selected: kind == JournalKind.note, onTap: () => setState(() => kind = JournalKind.note)),
                    const SizedBox(width: 6),
                    _kindChip(label: '진행', selected: kind == JournalKind.progress, onTap: () => setState(() => kind = JournalKind.progress)),
                    const SizedBox(width: 6),
                    _kindChip(label: '보고서', selected: kind == JournalKind.completionReport, onTap: () => setState(() => kind = JournalKind.completionReport)),
                  ],
                ),
              ),
              const SizedBox(height: 16), // 제목 필드를 더 위로 올림
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 16),
                decoration: InputDecoration(labelText: '제목', labelStyle: const TextStyle(color: AppColors.text2), filled: true, fillColor: AppColors.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: safeRelatedTaskId,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
                decoration: InputDecoration(labelText: '관련 업무(선택)', labelStyle: const TextStyle(color: AppColors.text2), filled: true, fillColor: AppColors.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                items: [const DropdownMenuItem(value: null, child: Text('선택 안함')), ...tasksForTeam.map((t) => DropdownMenuItem(value: t.id, child: Text(t.title, overflow: TextOverflow.ellipsis)))],
                onChanged: (v) => setState(() => relatedTaskId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: safeProjectId,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
                decoration: InputDecoration(labelText: '프로젝트(선택)', labelStyle: const TextStyle(color: AppColors.text2), filled: true, fillColor: AppColors.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                items: [const DropdownMenuItem(value: null, child: Text('선택 안함')), ...projectsForTeam.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))],
                onChanged: (v) => setState(() => selectedProjectId = v),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.25),
                contentPadding: EdgeInsets.zero,
                value: isPrivate,
                onChanged: (v) => setState(() => isPrivate = v),
                title: const Text(
                  '비공개 일지',
                  style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text, fontSize: 14),
                ),
                subtitle: const Text('팀원에게 보이지 않음', style: TextStyle(color: AppColors.hint, fontSize: 12)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await ImagePicker().pickMultiImage();
                        if (!mounted) return;
                        if (picked.isEmpty) return;
                        setState(() => photos.addAll(picked.map((x) => x.path)));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.bg, foregroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                      icon: const Icon(Icons.photo_library_rounded, size: 20),
                      label: const Text('사진 추가', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${photos.length}장', style: const TextStyle(color: AppColors.hint, fontWeight: FontWeight.w800)),
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
                        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.image_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            SizedBox(width: 120, child: Text(p.split('/').last, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.text2))),
                            const SizedBox(width: 6),
                            GestureDetector(onTap: () => setState(() => photos.removeAt(idx)), child: const Icon(Icons.close_rounded, size: 16, color: AppColors.danger)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                minLines: 6,
                maxLines: 10,
                style: const TextStyle(color: AppColors.text, fontSize: 14),
                decoration: InputDecoration(hintText: _hintByKind(kind), hintStyle: const TextStyle(color: AppColors.hint), filled: true, fillColor: AppColors.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(14)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    try {
                      final entryId = const Uuid().v4();
                      await prov.addJournal(JournalEntry(
                        id: entryId, teamId: teamProv.currentTeamId, userId: widget.myId, userName: widget.myName,
                        title: titleCtrl.text.trim(), content: contentCtrl.text.trim(), date: DateTime.now(), updatedAt: DateTime.now(),
                        photos: photos, projectId: selectedProjectId, isPrivate: isPrivate,
                      ));
                      await prov.setMeta(entryId, kind: kind, relatedTaskId: relatedTaskId);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('일지 저장 실패: $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('저장하기', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kindChip({required String label, required bool selected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: selected ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppColors.primary : AppColors.border)),
          child: Center(child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.text2, fontWeight: FontWeight.w900, fontSize: 12))),
        ),
      ),
    );
  }
}

String _kindLabel(JournalKind kind) {
  return switch (kind) { JournalKind.note => '일반 일지', JournalKind.progress => '진행사항', JournalKind.completionReport => '완료 보고서' };
}

Color _kindColor(JournalKind kind) {
  return switch (kind) { JournalKind.note => AppColors.primary, JournalKind.progress => AppColors.warning, JournalKind.completionReport => AppColors.success };
}

String _hintByKind(JournalKind kind) {
  return switch (kind) { JournalKind.note => '오늘의 작업/특이사항 기록...', JournalKind.progress => '현재 상태, 다음 액션 기록...', JournalKind.completionReport => '작업 결과, 검수 내용 기록...' };
}
