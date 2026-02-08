import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart'; 
import '../models.dart';
import '../providers/journal_provider.dart';
import '../providers/team_provider.dart';
import '../providers/auth_provider.dart'; 

class GalleryTab extends StatelessWidget {
  const GalleryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final journalProv = context.watch<JournalProvider>();
    final authProv = context.watch<AuthProvider>(); 

    final Map<String, List<String>> groupedPhotos = {};
    
    final teamJournals = journalProv.journals.where((j) => j.teamId == teamProv.currentTeamId).toList();
    
    for (var j in teamJournals) {
      if (j.photos.isNotEmpty) {
        String dateKey = DateFormat('yyyy-MM-dd').format(j.date);
        if (!groupedPhotos.containsKey(dateKey)) {
          groupedPhotos[dateKey] = [];
        }
        groupedPhotos[dateKey]!.addAll(j.photos);
      }
    }

    final sortedKeys = groupedPhotos.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: sortedKeys.isEmpty
          ? _buildEmptyView()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final dateKey = sortedKeys[index];
                final photos = groupedPhotos[dateKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        children: [
                          Container(width: 4, height: 18, decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 12),
                          Text(
                            _formatDate(dateKey),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text("${photos.length}장", style: const TextStyle(fontSize: 11, color: Colors.white70)),
                          ),
                        ],
                      ),
                    ),
                    
                    MasonryGridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: photos.length,
                      itemBuilder: (context, photoIndex) {
                        return GestureDetector(
                          onTap: () => _openImageViewer(context, photos[photoIndex]),
                          child: Hero(
                            tag: photos[photoIndex],
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildImage(photos[photoIndex]),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
      
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        elevation: 10,
        child: const Icon(Icons.camera_alt, color: Colors.white),
        onPressed: () async {
          final picker = ImagePicker();
          final xFile = await picker.pickImage(source: ImageSource.camera);
          
          if (xFile != null) {
            if(!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("사진을 클라우드에 저장 중입니다...")));

            await journalProv.uploadPhoto(xFile.path);

            final newEntry = JournalEntry(
              id: const Uuid().v4(),
              teamId: teamProv.currentTeamId,
              userId: authProv.currentUser?.id ?? 'unknown',
              userName: authProv.currentUser?.name ?? '익명', 
              title: "현장 사진", 
              content: "",    
              date: DateTime.now(),
              photos: [xFile.path], 
              isPrivate: false,
            );

            await journalProv.addJournal(newEntry);

            if(!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("갤러리에 사진이 추가되었습니다!")));
          }
        },
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      if(date.year == now.year && date.month == now.month && date.day == now.day) {
        return "오늘 (Today)";
      }
      return DateFormat('M월 d일 E요일', 'ko_KR').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white24)));
    } else {
      return Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white24)));
    }
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 60, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text("아직 등록된 사진이 없습니다.", style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("카메라 버튼을 눌러 현장 사진을\n바로 찍어보세요.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12)),
        ],
      ),
    );
  }

  void _openImageViewer(BuildContext context, String path) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Close",
      barrierColor: Colors.black.withValues(alpha: 0.95),
      pageBuilder: (ctx, _, __) {
        return Stack(
          children: [
            Center(
              child: Hero(
                tag: path,
                child: InteractiveViewer(
                  child: path.startsWith('http') ? Image.network(path) : Image.file(File(path)),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            )
          ],
        );
      },
    );
  }
}