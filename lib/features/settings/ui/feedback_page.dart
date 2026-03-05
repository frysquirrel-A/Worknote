import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _feedbackCtrl = TextEditingController();
  bool _isSending = false;
  String _selectedType = '개선';
  bool _isSubmitted = false;

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    final text = _feedbackCtrl.text.trim();
    if (text.length < 5) {
      _showSnack('의견은 5자 이상 입력해 주세요.');
      return;
    }
    if (Firebase.apps.isEmpty) {
      _showSnack('Firebase가 초기화되지 않아 전송할 수 없습니다.');
      return;
    }

    setState(() => _isSending = true);

    final auth = context.read<AuthProvider>();
    final team = context.read<TeamProvider>();
    final payload = <String, dynamic>{
      'type': _selectedType,
      'content': text,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAtClient': DateTime.now().toIso8601String(),
      'userId': auth.currentUser?.id ?? 'unknown',
      'userName': auth.currentUser?.name ?? 'unknown',
      'profileId': auth.currentProfile?.id,
      'teamId': team.currentTeamId,
      'teamName': team.currentTeam.name,
      'platform': _platformLabel(),
      'app': 'worknote',
      'status': 'new',
    };

    try {
      await FirebaseFirestore.instance.collection('feedbacks').add(payload);

      if (!mounted) return;
      setState(() {
        _isSubmitted = true;
      });
      _feedbackCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      _showSnack('전송 실패: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 80, color: Colors.green),
                const SizedBox(height: 24),
                const Text(
                  '접수 완료',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                const Text(
                  '소중한 의견이 성공적으로 접수되었습니다.\n더 나은 서비스로 보답하겠습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.text2, height: 1.5),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '닫기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          '건의하기',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppColors.bg,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '문의 유형',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['버그', '개선', 'UI', '기타'].map((type) {
                return ChoiceChip(
                  label: Text(type),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = type);
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _selectedType == type
                        ? AppColors.primary
                        : AppColors.text,
                    fontWeight: _selectedType == type
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              '내용',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _feedbackCtrl,
              maxLines: 7,
              decoration: InputDecoration(
                hintText: '앱 사용 중 불편한 점이나 개선사항을 편하게 적어주세요.',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        '의견 보내기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
