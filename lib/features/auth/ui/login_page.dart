import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/auth/ui/profile_selection_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(Icons.architecture_rounded, size: 72, color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'WORKNOTE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '현장의 모든 기록, 팀과 함께 공유하세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 36),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                        ),
                        child: Column(
                          children: [
                            _buildLargeButton(
                              context,
                              label: '가입 없이 바로 사용하기 (개인용)',
                              icon: Icons.person_pin_circle_rounded,
                              color: Colors.blueAccent,
                              onTap: authProv.isLoading ? null : () => _showNicknameDialog(context, authProv),
                            ),
                            const SizedBox(height: 16),
                            _buildLargeButton(
                              context,
                              label: '구글 계정으로 시작하기',
                              icon: Icons.cloud_sync_rounded,
                              color: Colors.white.withValues(alpha: 0.06),
                              textColor: Colors.white,
                              isOutlined: true,
                              onTap: authProv.isLoading
                                  ? null
                                  : () async {
                                      final result = await authProv.loginWithGoogle();
                                      if (!context.mounted) return;
                                      if (result.state == AuthFlowState.failed || result.state == AuthFlowState.cancelled) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(result.message ?? '구글 로그인에 실패했습니다.')),
                                        );
                                      }
                                    },
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              '로컬 프로필은 나중에 구글 계정과 연결할 수 있고,\n구글 로그인 시 하나의 계정에서 최대 5개의 독립 프로필을 사용할 수 있어요.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.45),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (authProv.isLoading)
              const Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(minHeight: 3, color: Colors.blueAccent),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    Color textColor = Colors.white,
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22, color: isOutlined ? Colors.blueAccent : Colors.white),
        label: Text(
          label,
          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : color,
          foregroundColor: textColor,
          elevation: isOutlined ? 0 : 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: isOutlined ? const BorderSide(color: Colors.white24) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  void _showNicknameDialog(BuildContext context, AuthProvider authProv) {
    final TextEditingController nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('프로필 시작', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이름을 지금 정해도 되고,\n바로 시작한 뒤 프로필 설정 화면에서 정해도 됩니다.',
              style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '예: 홍길동 소장',
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
            child: const Text('취소', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await authProv.loginAsLocal();
            },
            child: const Text('나중에 설정', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await authProv.loginAsLocal(nameCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('시작하기', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
