import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/journal_provider.dart';
import '../providers/team_provider.dart';

class GalleryTab extends StatelessWidget {
  const GalleryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final journalProv = context.watch<JournalProvider>();
    
    // 사진이 있는 일지만 추출하여 평탄화(Flatten)
    final allPhotos = journalProv.journals
      .where((j) => j.teamId == teamProv.currentTeamId && j.photos.isNotEmpty)
      .expand((j) => j.photos)
      .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: allPhotos.isEmpty
          ? const Center(child: Text("사진이 없습니다.", style: TextStyle(color: Colors.grey)))
          : GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, 
                crossAxisSpacing: 2, 
                mainAxisSpacing: 2
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
                          borderRadius: BorderRadius.circular(16),
                          child: path.startsWith('http')
                              ? Image.network(path, fit: BoxFit.contain)
                              : Image.file(File(path), fit: BoxFit.contain),
                        ),
                      )
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: path.startsWith('http')
                        ? Image.network(path, fit: BoxFit.cover)
                        : Image.file(File(path), fit: BoxFit.cover),
                  ),
                );
              },
            ),
    );
  }
}
