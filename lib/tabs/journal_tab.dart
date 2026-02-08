import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../providers/journal_provider.dart';
import '../providers/team_provider.dart';

class JournalTab extends StatelessWidget {
  const JournalTab({super.key});

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final journalProv = context.watch<JournalProvider>();

    final groupedJournals = journalProv.getGroupedJournals(teamProv.currentTeamId);
    final sortedDates = groupedJournals.keys.toList()..sort((a, b) => b.compareTo(a));

    // [수정 포인트] 테마 감지 방식 변경
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.edit, color: Colors.white),
        onPressed: () => _showAddJournalDialog(context, journalProv, teamProv),
      ),
      body: sortedDates.isEmpty
          ? Center(child: Text("작성된 일지가 없습니다.", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final dateKey = sortedDates[index];
                final journals = groupedJournals[dateKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateHeader(dateKey, isDark),
                    ...journals.map((j) => _buildJournalCard(context, j, isDark)),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildDateHeader(String dateStr, bool isDark) {
    DateTime date = DateTime.parse(dateStr);
    String formatted = DateFormat('M월 d일 EEEE', 'ko_KR').format(date);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(formatted, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
    );
  }

  Widget _buildJournalCard(BuildContext context, JournalEntry journal, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey[300],
                child: Text(journal.userName.isNotEmpty ? journal.userName[0] : "?", style: const TextStyle(fontSize: 10, color: Colors.black)),
              ),
              const SizedBox(width: 8),
              Text(journal.userName, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(DateFormat('a h:mm', 'ko_KR').format(journal.updatedAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(journal.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Text(journal.content, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
          if (journal.photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: journal.photos.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 80,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.black12),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(journal.photos[index], fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image)),
                  );
                },
              ),
            )
          ]
        ],
      ),
    );
  }

  void _showAddJournalDialog(BuildContext context, JournalProvider prov, TeamProvider teamProv) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("새 일지 작성"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "제목")),
          TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: "내용"), maxLines: 3),
        ],
      ),
      actions: [
        ElevatedButton(onPressed: () {
          Navigator.pop(ctx);
        }, child: const Text("작성")),
      ],
    ));
  }
}
