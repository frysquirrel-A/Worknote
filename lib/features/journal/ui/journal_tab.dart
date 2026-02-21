import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/journal/state/journal_provider.dart';
import 'package:worknote/features/journal/ui/sheets/journal_write_sheet.dart';
import 'package:worknote/features/journal/ui/widgets/journal_card.dart';
import 'package:worknote/features/team/state/team_provider.dart';
import 'package:worknote/features/journal/ui/widgets/journal_view_mode_toggle.dart';

class JournalTab extends StatefulWidget {
  const JournalTab({super.key});

  @override
  State<JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<JournalTab> {
  String _searchQuery = '';
  JournalKind? _kindFilter;

  String _viewMode = '일별'; // 세그먼트 컨트롤용 뷰 모드 ('일별' 또는 '전체 리스트')
  bool _newestFirst = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final journalProv = context.watch<JournalProvider>();
    final authProv = context.watch<AuthProvider>();
    final myId = authProv.currentUser?.id ?? 'me';
    final myName = authProv.currentUser?.name ?? '관리자';

    final allJournals = journalProv.journals.where((j) {
      final matchesTeam = j.teamId == teamProv.currentTeamId;
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty || j.title.toLowerCase().contains(q) || j.content.toLowerCase().contains(q);
      if (!matchesTeam || !matchesSearch) return false;
      if (_kindFilter != null && journalProv.getKind(j.id) != _kindFilter) return false;
      return true;
    }).toList();

    // 일별 그룹핑 로직
    final Map<String, List<JournalEntry>> grouped = {};
    for (final j in allJournals) {
      final k = DateFormat('yyyy-MM-dd').format(DateTime(j.date.year, j.date.month, j.date.day));
      grouped.putIfAbsent(k, () => []).add(j);
    }

    final displayKeys = grouped.keys.toList()..sort((a, b) => _newestFirst ? b.compareTo(a) : a.compareTo(b));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '일지 내용을 검색하세요...',
                hintStyle: const TextStyle(color: AppColors.hint),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _JournalKindFilterRow(current: _kindFilter, onChanged: (k) => setState(() => _kindFilter = k)),
          ),
          
          // 새로 추가된 세그먼트 컨트롤 + 정렬 버튼 라인
          if (allJournals.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: JournalViewModeToggle(
                      viewMode: _viewMode,
                      onChanged: (mode) => setState(() => _viewMode = mode),
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () => setState(() => _newestFirst = !_newestFirst),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border)
                      ),
                      child: Icon(
                        _newestFirst ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  )
                ],
              ),
            ),
            
          const SizedBox(height: 8),
          Expanded(
            child: allJournals.isEmpty
                ? const Center(child: Text('조건에 맞는 일지가 없습니다.', style: TextStyle(color: AppColors.hint, fontWeight: FontWeight.bold)))
                : _viewMode == '일별'
                    ? _DateGroupedJournalView(dateKeys: displayKeys, grouped: grouped, scrollController: _scrollController)
                    : _FlatJournalView(items: allJournals, scrollController: _scrollController, newestFirst: _newestFirst),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _JournalWriteButton(onPressed: () => showJournalWriteSheet(context: context, myId: myId, myName: myName)),
    );
  }
}

class _JournalWriteButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _JournalWriteButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20), width: double.infinity, height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 10),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text('일지작성', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
      ),
    );
  }
}

// 뷰 모드 1: 일별 보기 (그룹핑)
class _DateGroupedJournalView extends StatelessWidget {
  final List<String> dateKeys;
  final Map<String, List<JournalEntry>> grouped;
  final ScrollController scrollController;
  const _DateGroupedJournalView({required this.dateKeys, required this.grouped, required this.scrollController});
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController, padding: const EdgeInsets.fromLTRB(20, 8, 20, 100), itemCount: dateKeys.length,
      itemBuilder: (context, index) {
        final key = dateKeys[index];
        final items = (grouped[key] ?? [])..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(bottom: 10, top: 6), child: Row(children: [Container(width: 4, height: 14, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 8), Text(key, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.text)), const Spacer(), Text('${items.length}건', style: const TextStyle(color: AppColors.hint, fontWeight: FontWeight.w800, fontSize: 12))])),
          ...items.map((j) => Padding(padding: const EdgeInsets.only(bottom: 8), child: JournalCard(entry: j))),
          const SizedBox(height: 6),
        ]);
      },
    );
  }
}

// 뷰 모드 2: 전체 리스트 보기 (플랫)
class _FlatJournalView extends StatelessWidget {
  final List<JournalEntry> items;
  final ScrollController scrollController;
  final bool newestFirst;
  const _FlatJournalView({required this.items, required this.scrollController, required this.newestFirst});
  
  @override
  Widget build(BuildContext context) {
    final sortedItems = [...items]..sort((a, b) => newestFirst ? b.updatedAt.compareTo(a.updatedAt) : a.updatedAt.compareTo(b.updatedAt));
    
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: sortedItems.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: JournalCard(entry: sortedItems[index]),
        );
      },
    );
  }
}

class _JournalKindFilterRow extends StatelessWidget {
  final JournalKind? current;
  final ValueChanged<JournalKind?> onChanged;
  const _JournalKindFilterRow({required this.current, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
      _chip(label: '전체', selected: current == null, onTap: () => onChanged(null)),
      const SizedBox(width: 8),
      _chip(label: '일반', selected: current == JournalKind.note, onTap: () => onChanged(JournalKind.note)),
      const SizedBox(width: 8),
      _chip(label: '진행', selected: current == JournalKind.progress, onTap: () => onChanged(JournalKind.progress), color: AppColors.warning),
      const SizedBox(width: 8),
      _chip(label: '보고서', selected: current == JournalKind.completionReport, onTap: () => onChanged(JournalKind.completionReport), color: AppColors.success),
    ]));
  }
  Widget _chip({required String label, required bool selected, required VoidCallback onTap, Color color = AppColors.primary}) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: selected ? color : AppColors.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: selected ? color : AppColors.border)), child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.text, fontWeight: FontWeight.w900, fontSize: 12))));
  }
}
