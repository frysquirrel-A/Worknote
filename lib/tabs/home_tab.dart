import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import '../logic/app_controller.dart';

class HomeTab extends StatelessWidget {
  final List<Task> tasks;
  final List<Project> projects;
  final List<TeamMember> members;
  final AppController controller;
  final AppTone tone;

  const HomeTab({super.key, required this.tasks, required this.projects, required this.members, required this.controller, required this.tone});

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("프로필 이미지 설정", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("사진을 가져올 방법을 선택하세요."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, ImageSource.camera), child: const Text("카메라")),
          TextButton(onPressed: () => Navigator.pop(ctx, ImageSource.gallery), child: const Text("갤러리")),
        ],
      ),
    );

    if (source != null) {
      final file = await picker.pickImage(source: source);
      if (file != null) {
        controller.updateProfileImage(File(file.path));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = tone == AppTone.black;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('M월 d일 E요일', 'ko_KR').format(DateTime.now()), style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text("안녕하세요 관리자님! 👷", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                ],
              ),
              GestureDetector(
                onTap: () => _pickImage(context),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFE0E7FF),
                  backgroundImage: controller.profileImage != null ? FileImage(controller.profileImage!) : null,
                  child: controller.profileImage == null ? const Icon(Icons.person, color: Color(0xFF2563EB)) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text("프로젝트 현황", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          if (projects.isEmpty)
            const Center(child: Text("등록된 프로젝트가 없습니다."))
          else
            ...projects.map((p) {
              final pTasks = tasks.where((t) => t.projectId == p.id).toList();
              final done = pTasks.where((t) => t.isDone).length;
              final total = pTasks.length;
              final progress = total == 0 ? 0.0 : done / total;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))],
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: p.color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
                          ],
                        ),
                        Text("${(progress * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.w900, color: p.color)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(value: progress, minHeight: 8, color: p.color, backgroundColor: p.color.withValues(alpha: 0.1)),
                    ),
                    const SizedBox(height: 8),
                    Text("진행 $done / 전체 $total", style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),
          Text("팀원 리스트", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: members.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  children: [
                    CircleAvatar(radius: 32, backgroundColor: const Color(0xFFE0E7FF), child: Text(members[i].emoji, style: const TextStyle(fontSize: 28))),
                    const SizedBox(height: 8),
                    Text(members[i].name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
