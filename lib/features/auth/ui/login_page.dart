import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // 깊은 밤의 현장 네이비
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // 🏗️ 상단 타이틀 구역
              const Icon(Icons.architecture_rounded, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 24),
              const Text(
                "WORKNOTE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "현장의 모든 기록, 팀과 함께 공유하세요",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const Spacer(),

              // 🚀 하단 버튼 구역
              Column(
                children: [
                  // 버튼 1: 로컬 모드
                  _buildLargeButton(
                    context,
                    label: "가입 없이 바로 사용하기 (개인용)",
                    icon: Icons.person_pin_circle_rounded,
                    color: Colors.blueAccent,
                    onTap: () => _showNicknameDialog(context, authProv),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 버튼 2: 구글 모드
                  _buildLargeButton(
                    context,
                    label: "구글 계정으로 시작하기",
                    icon: Icons.g_mobiledata_rounded,
                    color: Colors.white.withValues(alpha: 0.1),
                    textColor: Colors.white,
                    isOutlined: true,
                    onTap: () async {
                      await authProv.loginWithGoogle();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 공통 대형 버튼 빌더
  Widget _buildLargeButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Color textColor = Colors.white,
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 24, color: isOutlined ? Colors.blueAccent : Colors.white),
        label: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : color,
          foregroundColor: textColor,
          elevation: isOutlined ? 0 : 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isOutlined ? const BorderSide(color: Colors.white24) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  // 💬 닉네임 입력 다이얼로그
  void _showNicknameDialog(BuildContext context, AuthProvider authProv) {
    final TextEditingController nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "닉네임 설정",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "앱에서 사용할 이름을 입력해주세요.\n가입 없이 즉시 시작됩니다.",
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              autofocus: true, // ✨ [수정] autoFocus -> autofocus
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "예: 홍길동 소장",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blueAccent),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("취소", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                await authProv.loginAsLocal(name);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("시작하기", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
