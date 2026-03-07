import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/core/ui/widgets/empty_state_placeholder.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/journal/state/journal_provider.dart';
import 'package:worknote/features/journal/ui/sheets/journal_write_sheet.dart';
import 'package:worknote/features/team/state/team_provider.dart';

class GalleryTab extends StatelessWidget {
  const GalleryTab({super.key});

  void _openJournalPhotoFlow(BuildContext context) {
    final authProv = context.read<AuthProvider>();
    showJournalWriteSheet(
      context: context,
      myId: authProv.currentUser?.id ?? 'me',
      myName: authProv.currentUser?.name ?? '사용자',
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final journalProv = context.watch<JournalProvider>();
    final authProv = context.watch<AuthProvider>();

    final groupedPhotos = <String, List<String>>{};
    final teamJournals = journalProv.journals
        .where((j) => j.teamId == teamProv.currentTeamId)
        .toList();

    for (final journal in teamJournals) {
      if (journal.photos.isEmpty) continue;
      final dateKey = DateFormat('yyyy-MM-dd').format(journal.date);
      groupedPhotos.putIfAbsent(dateKey, () => <String>[]).addAll(journal.photos);
    }

    final sortedKeys = groupedPhotos.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        foregroundColor: AppColors.darkText,
        title: const Text(
          '팀 갤러리',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.darkText,
          ),
        ),
        backgroundColor: AppColors.darkBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '일지 작성',
            icon: const Icon(Icons.edit_note_rounded, color: AppColors.darkText),
            onPressed: () => _openJournalPhotoFlow(context),
          ),
        ],
      ),
      body: sortedKeys.isEmpty
          ? EmptyStatePlaceholder(
              icon: Icons.photo_library_outlined,
              title: '아직 업로드된 사진이 없어요',
              description: '업무 또는 일지에 사진을 추가하면 여기에 표시됩니다.',
              ctaLabel: '+ 사진 남기기',
              onTap: () => _openJournalPhotoFlow(context),
              dark: true,
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
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
                              color: AppColors.premiumBlue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateKey,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkText,
                            ),
                          ),
                          const Spacer(),
                          if (index == 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.darkSurface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppColors.darkBorder),
                              ),
                              child: Text(
                                '${photos.length}장',
                                style: const TextStyle(
                                  color: AppColors.darkHint,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
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
                            color: AppColors.darkSurface,
                            border: Border.all(color: AppColors.darkBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
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
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.premiumBlue,
        tooltip: '사진이 포함된 일지 작성',
        onPressed: () => showJournalWriteSheet(
          context: context,
          myId: authProv.currentUser?.id ?? 'me',
          myName: authProv.currentUser?.name ?? '사용자',
        ),
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
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.premiumBlue,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.darkHint,
            ),
          );
        },
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.darkHint,
          ),
        );
      },
    );
  }
}
