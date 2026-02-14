import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import '../models.dart';
import '../providers/journal_provider.dart';
import '../providers/team_provider.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';

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
    
    // [7 수리] 하드코딩 제거 및 필터링
    final allJournals = journalProv.journals.where((j) {
      bool matchesTeam = j.teamId == teamProv.currentTeamId;
      bool matchesSearch = j.title.contains(_searchQuery) || j.content.contains(_searchQuery);
      return matchesTeam && matchesSearch;
    }).toList();

    // [4-4 수리] 일별/전체 리스트 렌더링 로직 분리
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Column(
        children: [
          _buildSearchHeader(),
          _buildViewModeSegment(),
          Expanded(
            child: allJournals.isEmpty
                ? const Center(child: Text("일지가 없습니다.", style: TextStyle(color: Colors.grey)))
                : _viewMode == "일별" 
                    ? _buildGroupedTimeline(allJournals)
                    : _buildFlatList(allJournals),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
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
    );
  }

  Widget _buildViewModeSegment() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _segmentButton("일별", _viewMode == "일별"),
          _segmentButton("전체 리스트", _viewMode == "전체 리스트"),
        ],
      ),
    );
  }

  Widget _segmentButton(String label, bool isSelected) {
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

  // [4-4 수리] 일별 그룹화 타임라인 뷰
  Widget _buildGroupedTimeline(List<JournalEntry> journals) {
    final grouped = groupBy(journals, (JournalEntry j) => DateFormat('yyyy-MM-dd').format(j.date));
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final date = sortedKeys[index];
        final items = grouped[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  Text(date, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ),
            ),
            ...items.map((j) => _buildJournalCard(j)),
          ],
        );
      },
    );
  }

  Widget _buildFlatList(List<JournalEntry> journals) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: journals.length,
      itemBuilder: (context, index) => _buildJournalCard(journals[index]),
    );
  }

  Widget _buildJournalCard(JournalEntry journal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(DateFormat('HH:mm').format(journal.date), style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
              const Spacer(),
              if (journal.userName.isNotEmpty)
                Text(journal.userName, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(journal.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(journal.content, style: const TextStyle(color: Color(0xFF64748B), height: 1.5, fontSize: 14)),
        ],
      ),
    );
  }
}
