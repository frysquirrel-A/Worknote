import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/journal/state/journal_provider.dart';
import 'package:worknote/features/journal/ui/sheets/journal_detail_sheet.dart';

class JournalCard extends StatelessWidget {
  final JournalEntry entry;

  const JournalCard({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<JournalProvider>();
    final kind = prov.getKind(entry.id);
    final updates = prov.getProgressUpdates(entry.id);
    final hasPhotos = entry.photos.isNotEmpty;

    return GestureDetector(
      onTap: () => showJournalDetailSheet(context: context, entry: entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppPalette.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  DateFormat('yyyy-MM-dd').format(entry.date),
                  style: const TextStyle(color: AppPalette.primary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                _kindBadge(kind),
                if (hasPhotos) ...[
                  const SizedBox(width: 6),
                  _smallStat(Icons.photo_rounded, '${entry.photos.length}'),
                ],
                if (updates.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _smallStat(Icons.timeline_rounded, '${updates.length}'),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              entry.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppPalette.textDark),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              entry.content,
              style: const TextStyle(color: AppPalette.textMuted, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.black45),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.userName,
                    style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w800, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (entry.isPrivate) ...[
                  const Icon(Icons.lock_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  const Text('비공개', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w800, fontSize: 12)),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _kindBadge(JournalKind kind) {
  final Color c = switch (kind) {
    JournalKind.note => AppPalette.primary,
    JournalKind.progress => const Color(0xFFF59E0B),
    JournalKind.completionReport => const Color(0xFF10B981),
  };
  final String label = switch (kind) {
    JournalKind.note => '일반',
    JournalKind.progress => '진행',
    JournalKind.completionReport => '보고서',
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: c.withValues(alpha: 0.25)),
    ),
    child: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 11)),
  );
}

Widget _smallStat(IconData icon, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppPalette.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.black54),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w900, fontSize: 11)),
      ],
    ),
  );
}
