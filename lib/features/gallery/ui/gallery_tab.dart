import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:worknote/core/ui/widgets/empty_state_placeholder.dart';
import 'package:worknote/features/journal/state/journal_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';

class GalleryTab extends StatelessWidget {
  const GalleryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final journalProv = context.watch<JournalProvider>();

    final groupedPhotos = <String, List<String>>{};
    final teamJournals = journalProv.journals
        .where((j) => j.teamId == teamProv.currentTeamId)
        .toList();

    for (final journal in teamJournals) {
      if (journal.photos.isEmpty) continue;
      final dateKey = DateFormat('yyyy-MM-dd').format(journal.date);
      groupedPhotos
          .putIfAbsent(dateKey, () => <String>[])
          .addAll(journal.photos);
    }

    final sortedKeys = groupedPhotos.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          '전체 갤러리',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: sortedKeys.isEmpty
          ? const EmptyStatePlaceholder(
              icon: Icons.photo_library_outlined,
              title: '아직 업로드된 사진이 없어요',
              description: '업무 또는 일지에 사진을 추가하면 여기에 표시됩니다.',
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final dateKey = sortedKeys[index];
                final photos = groupedPhotos[dateKey]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateKey,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    MasonryGridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: photos.length,
                      itemBuilder: (context, i) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _buildImage(photos[i]),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        onPressed: () {},
        child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.grey),
          );
        },
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
        );
      },
    );
  }
}
