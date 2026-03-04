import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/journal/state/journal_provider.dart';

/// 일지 상세 바텀시트 호출 함수
Future<void> showJournalDetailSheet({
  required BuildContext context,
  required JournalEntry entry,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _JournalDetailSheetContent(entry: entry),
  );
}

/// [리팩토링] 메인 콘텐츠 위젯: 수정 사항 반영을 위해 StatefulWidget으로 구성
class _JournalDetailSheetContent extends StatefulWidget {
  final JournalEntry entry;
  const _JournalDetailSheetContent({required this.entry});

  @override
  State<_JournalDetailSheetContent> createState() => _JournalDetailSheetContentState();
}

class _JournalDetailSheetContentState extends State<_JournalDetailSheetContent> {
  late JournalEntry current;

  @override
  void initState() {
    super.initState();
    current = widget.entry;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<JournalProvider>();
    final auth = context.read<AuthProvider>();
    final myId = auth.currentUser?.id ?? 'me';
    final myName = auth.currentUser?.name ?? '관리자';

    final kind = prov.getKind(current.id);
    final relatedTaskId = prov.getRelatedTaskId(current.id);
    final updates = prov.getProgressUpdates(current.id);

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(current.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                ),
                IconButton(
                  onPressed: () async {
                    // [작업 지시 2, 3] _EditEntrySheet 호출
                    final updated = await showModalBottomSheet<JournalEntry>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (eCtx) => _EditEntrySheet(entry: current),
                    );
                    if (updated != null) {
                      setState(() => current = updated);
                    }
                  },
                  icon: const Icon(Icons.edit_rounded),
                ),
                IconButton(
                  onPressed: () async {
                    await prov.deleteJournal(current.id);
                    if (mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),

            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill(DateFormat('yyyy.MM.dd').format(current.date), AppPalette.primary),
                _pill('작성자: ${current.userName}', Colors.black54),
                _kindPill(kind),
                if (current.isPrivate) _pill('비공개', Colors.grey),
                if (relatedTaskId != null) _pill('업무 연결됨', const Color(0xFFF59E0B)),
              ],
            ),

            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                children: [
                  Text(current.content, style: const TextStyle(color: AppPalette.textDark, height: 1.5)),
                  const SizedBox(height: 16),

                  if (current.photos.isNotEmpty) ...[
                    const Text('사진', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: current.photos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (c, i) {
                          final p = current.photos[i];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: 160,
                              child: _buildImage(p),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  Row(
                    children: [
                      const Expanded(
                        child: Text('진행사항 타임라인', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          // [작업 지시 1, 3] _AddProgressDialog 호출
                          await showDialog(
                            context: context,
                            builder: (dctx) => _AddProgressDialog(
                              journalId: current.id,
                              userId: myId,
                              userName: myName,
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('추가'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (updates.isEmpty)
                    const Text('아직 진행사항이 없습니다.', style: TextStyle(color: Colors.grey))
                  else
                    ...updates
                        .sortedBy((m) => m['at']?.toString() ?? '')
                        .map((m) => _progressCard(m)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🚨 [작업 지시 1] 진행사항 추가 다이얼로그 분리
class _AddProgressDialog extends StatefulWidget {
  final String journalId;
  final String userId;
  final String userName;
  const _AddProgressDialog({required this.journalId, required this.userId, required this.userName});

  @override
  State<_AddProgressDialog> createState() => _AddProgressDialogState();
}

class _AddProgressDialogState extends State<_AddProgressDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('진행사항 추가'),
      content: TextField(
        controller: _ctrl,
        maxLines: 4,
        decoration: const InputDecoration(hintText: '진행 상황/이슈/다음 액션을 간단히 기록'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        ElevatedButton(
          onPressed: () async {
            final text = _ctrl.text.trim();
            if (text.isEmpty) return;
            await context.read<JournalProvider>().addProgressUpdate(
              journalId: widget.journalId,
              text: text,
              userId: widget.userId,
              userName: widget.userName,
            );
            if (mounted) Navigator.pop(context);
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}

// 🚨 [작업 지시 2] 일지 수정 시트 분리
class _EditEntrySheet extends StatefulWidget {
  final JournalEntry entry;
  const _EditEntrySheet({required this.entry});

  @override
  State<_EditEntrySheet> createState() => _EditEntrySheetState();
}

class _EditEntrySheetState extends State<_EditEntrySheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late bool _isPrivate;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.entry.title);
    _contentCtrl = TextEditingController(text: widget.entry.content);
    _isPrivate = widget.entry.isPrivate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('일지 수정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: '제목',
              filled: true,
              fillColor: AppPalette.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isPrivate,
            onChanged: (v) => setState(() => _isPrivate = v),
            title: const Text('비공개', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contentCtrl,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: '내용',
              filled: true,
              fillColor: AppPalette.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final t = _titleCtrl.text.trim();
                if (t.isEmpty) return;
                final updated = JournalEntry(
                  id: widget.entry.id,
                  teamId: widget.entry.teamId,
                  userId: widget.entry.userId,
                  userName: widget.entry.userName,
                  title: t,
                  content: _contentCtrl.text.trim(),
                  projectId: widget.entry.projectId,
                  date: widget.entry.date,
                  updatedAt: DateTime.now(),
                  photos: widget.entry.photos,
                  isPrivate: _isPrivate,
                );
                await context.read<JournalProvider>().updateJournal(updated);
                if (mounted) Navigator.pop(context, updated);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppPalette.primary, foregroundColor: Colors.white),
              child: const Text('저장', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 공통 UI 헬퍼 및 유틸리티 (로직 보존) ---

Widget _buildImage(String path) {
  if (path.startsWith('http')) {
    return Image.network(path, fit: BoxFit.cover);
  }
  return Image.file(File(path), fit: BoxFit.cover);
}

Widget _pill(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
  );
}

Widget _kindPill(JournalKind kind) {
  final Color c = switch (kind) {
    JournalKind.note => AppPalette.primary,
    JournalKind.progress => const Color(0xFFF59E0B),
    JournalKind.completionReport => const Color(0xFF10B981),
  };
  final String label = switch (kind) {
    JournalKind.note => '일반',
    JournalKind.progress => '진행사항',
    JournalKind.completionReport => '완료보고서',
  };
  return _pill(label, c);
}

Widget _progressCard(Map<String, dynamic> m) {
  final at = DateTime.tryParse((m['at'] ?? '').toString());
  final time = at == null ? '' : DateFormat('MM.dd HH:mm').format(at);
  final user = (m['userName'] ?? '').toString();
  final text = (m['text'] ?? '').toString();

  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppPalette.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timeline_rounded, size: 16, color: AppPalette.primary),
            const SizedBox(width: 6),
            Text(time, style: const TextStyle(fontWeight: FontWeight.w900, color: AppPalette.textDark)),
            const Spacer(),
            Text(user, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Text(text, style: const TextStyle(color: AppPalette.textDark, height: 1.4)),
      ],
    ),
  );
}

extension _MapSortExt on List<Map<String, dynamic>> {
  List<Map<String, dynamic>> sortedBy(String Function(Map<String, dynamic>) key) {
    final copy = [...this];
    copy.sort((a, b) => key(a).compareTo(key(b)));
    return copy;
  }
}
