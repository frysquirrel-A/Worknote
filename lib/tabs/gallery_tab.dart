import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers/journal_provider.dart';
import '../providers/team_provider.dart';

class GalleryTab extends StatelessWidget {
  const GalleryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final journalProv = context.watch<JournalProvider>();
    
    final allPhotos = journalProv.journals
      .where((j) => j.teamId == teamProv.currentTeamId && j.photos.isNotEmpty)
      .expand((j) => j.photos)
      .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: allPhotos.isEmpty
          ? const Center(child: Text("사진이 없습니다.", style: TextStyle(color: Colors.white30)))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, 
                crossAxisSpacing: 12, 
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: allPhotos.length,
              itemBuilder: (context, index) {
                final path = allPhotos[index];
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context, 
                      builder: (c) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: File(path).existsSync()
                              ? Image.file(File(path), fit: BoxFit.contain)
                              : const Icon(Icons.broken_image, color: Colors.white, size: 100),
                        ),
                      )
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: File(path).existsSync()
                          ? Image.file(File(path), fit: BoxFit.cover)
                          : const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
