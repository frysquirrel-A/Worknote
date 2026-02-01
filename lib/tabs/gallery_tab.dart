import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
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

  // 이미지 경로 타입(URL/File)에 따른 렌더링 엔진
  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  Future<void> _openCamera() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    // 참고: image_picker를 통한 카메라 실행은 촬영 후 자동으로 앱으로 돌아옵니다.
    if (image != null) {
      // 촬영한 사진에 대한 처리가 필요하다면 여기에 추가 (예: 일지 쓰기로 연결 등)
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

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F9),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // 상단 타이틀 영역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                const Text("전체 갤러리", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                const Spacer(),
                IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: Colors.black)),
              ],
            ),
          ),
          
          Expanded(
            child: dates.isEmpty
                ? _buildEmptyView()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: dates.length,
                    itemBuilder: (c, i) {
                      final d = dates[i];
                      final key = _dateKeys.putIfAbsent(d, () => GlobalKey());
                      return Column(
                        key: key,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                            child: Row(
                              children: [
                                Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(2))),
                                const SizedBox(width: 12),
                                Text(d, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
                              ],
                            ),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: grouped[d]!.length,
                            itemBuilder: (cc, pIdx) => ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _buildImage(grouped[d]![pIdx]),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: FloatingActionButton(
          onPressed: _openCamera,
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.camera_alt_rounded, size: 28),
        ),
      ),
    );
  }

  // 이미지와 동일한 "사진이 없습니다" 뷰
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(color: Color(0xFFE2E5EE), shape: BoxShape.circle),
            child: const Icon(Icons.image_outlined, size: 40, color: Color(0xFF7C82A1)),
          ),
          const SizedBox(height: 24),
          const Text("사진이 없습니다", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          const Text("우측 하단 카메라 버튼을 눌러\n사진 캡처를 시작하세요", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Color(0xFF7C82A1), fontWeight: FontWeight.w500)),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
