import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
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
    final isDark = teamProv.isDarkMode;
    
    final grouped = journalProv.getGroupedJournals(teamProv.currentTeamId);
    final keys = grouped.keys.toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orangeAccent,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text("일지 쓰기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showWriteModal(context, journalProv, teamProv),
      ),
      body: keys.isEmpty 
        ? Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_note, size: 60, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text("작성된 일지가 없습니다.", style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
            ],
          ))
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final dateKey = keys[index];
              final entries = grouped[dateKey]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.orangeAccent),
                        const SizedBox(width: 8),
                        Text(dateKey, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                      ],
                    ),
                  ),
                  ...entries.map((j) => Container(
                    margin: const EdgeInsets.only(bottom: 20, left: 4),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(j.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                            Text(j.userName, style: const TextStyle(fontSize: 12, color: Colors.blueAccent)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(j.content, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), height: 1.5)),
                        if (j.photos.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: j.photos.length,
                              itemBuilder: (c, i) => Container(
                                width: 100, margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  image: DecorationImage(
                                    image: FileImage(File(j.photos[i])),
                                    fit: BoxFit.cover
                                  ),
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
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("작업 일지 작성", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 24),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "제목",
                  labelStyle: const TextStyle(color: Colors.blueAccent),
                  filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentCtrl,
                maxLines: 6,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "상세 내용",
                  labelStyle: const TextStyle(color: Colors.blueAccent),
                  filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent.withValues(alpha: 0.1), foregroundColor: Colors.blueAccent),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("사진 첨부"),
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
                ],
              ),
              if (tempPhotos.isNotEmpty) 
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    height: 80, 
                    child: ListView(
                      scrollDirection: Axis.horizontal, 
                      children: tempPhotos.map((p) => Container(
                        width: 80, margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: FileImage(File(p)), fit: BoxFit.cover)),
                      )).toList()
                    )
                  ),
                ),
              const Spacer(),
              SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () {
                  if(titleCtrl.text.isEmpty) return;
                  prov.addJournal(JournalEntry(
                    id: const Uuid().v4(), teamId: teamProv.currentTeamId,
                    userId: 'me', userName: '김반장', title: titleCtrl.text, content: contentCtrl.text,
                    date: DateTime.now(), photos: tempPhotos,
                  ));
                  Navigator.pop(context);
                },
                child: const Text("일지 등록", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
              ))
            ],
          ),
        ),
      ),
    );
  }
}
