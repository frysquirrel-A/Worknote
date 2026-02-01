import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';

class GalleryTab extends StatefulWidget {
  final List<JournalEntry> journals;
  final List<TeamMember> members;
  final DateTime? targetDate;
  final VoidCallback onTargetDateHandled;
  final AppTone tone;

  const GalleryTab({super.key, required this.journals, required this.members, this.targetDate, required this.onTargetDateHandled, required this.tone});

  @override
  State<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<GalleryTab> {
  final Map<String, GlobalKey> _dateKeys = {};

  @override
  void didUpdateWidget(GalleryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetDate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final dateStr = DateFormat('yyyy-MM-dd').format(widget.targetDate!);
        if (_dateKeys.containsKey(dateStr)) {
          final context = _dateKeys[dateStr]!.currentContext;
          if (context != null) {
            Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 600));
          }
          widget.onTargetDateHandled();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<String>>{};
    for (var j in widget.journals) {
      if (j.photos.isNotEmpty) {
        String d = DateFormat('yyyy-MM-dd').format(j.date);
        grouped.putIfAbsent(d, () => []).addAll(j.photos);
      }
    }
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) {
      return const Center(child: Text("저장된 사진이 없습니다."));
    }

    return ListView.builder(
      itemCount: dates.length,
      itemBuilder: (c, i) {
        final d = dates[i];
        _dateKeys[d] = GlobalKey();
        return Column(key: _dateKeys[d], crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: grouped[d]!.length,
            itemBuilder: (cc, pIdx) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(grouped[d]![pIdx]), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 24),
        ]);
      },
    );
  }
}
