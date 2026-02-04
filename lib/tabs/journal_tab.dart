import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
import '../providers/journal_provider.dart';
import '../providers/team_provider.dart';

class JournalTab extends StatelessWidget {
  const JournalTab({super.key});

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final journalProv = context.watch<JournalProvider>();
    final isDark = teamProv.isDarkMode;
    
    final grouped = journalProv.getGroupedJournals(teamProv.currentTeamId);
    final keys = grouped.keys.toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text("일지 쓰기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showWriteModal(context, journalProv, teamProv),
      ),
      body: keys.isEmpty 
        ? Center(child: Text("작성된 일지가 없습니다.", style: TextStyle(color: Colors.grey[400])))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final dateKey = keys[index];
              final entries = grouped[dateKey]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(dateKey, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue[300])),
                  ),
                  ...entries.map((j) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(j.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                        const SizedBox(height: 8),
                        Text(j.content, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                        if (j.photos.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: j.photos.length,
                              itemBuilder: (c, i) => Container(
                                width: 80, margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey,
                                  image: DecorationImage(image: FileImage(File(j.photos[i])),
                                  fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          )
                        ]
                      ],
                    ),
                  ))
                ],
              );
            },
          ),
    );
  }

  void _showWriteModal(BuildContext context, JournalProvider prov, TeamProvider teamProv) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    List<String> tempPhotos = [];

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: teamProv.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("일지 작성", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 16),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "제목")),
              const SizedBox(height: 12),
              TextField(controller: contentCtrl, maxLines: 5, decoration: const InputDecoration(labelText: "내용")),
              const SizedBox(height: 16),
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.blue),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final xFile = await picker.pickImage(source: ImageSource.camera);
                    if (xFile != null) {
                      final uploadedId = await prov.uploadPhoto(xFile.path);
                      if (uploadedId != null) {
                        setState(() => tempPhotos.add(xFile.path));
                      }
                    }
                  },
                ),
                const Text("사진 추가"),
              ]),
              if (tempPhotos.isNotEmpty) SizedBox(height: 60, child: ListView(scrollDirection: Axis.horizontal, children: tempPhotos.map((p)=>Padding(padding:const EdgeInsets.all(4), child: Image.file(File(p)))).toList())),
              const Spacer(),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
                onPressed: () {
                  prov.addJournal(JournalEntry(
                    id: const Uuid().v4(), teamId: teamProv.currentTeamId,
                    userId: 'me', userName: '나', title: titleCtrl.text, content: contentCtrl.text,
                    date: DateTime.now(), photos: tempPhotos,
                  ));
                  Navigator.pop(context);
                },
                child: const Text("저장하기"),
              ))
            ],
          ),
        ),
      ),
    );
  }
}