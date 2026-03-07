import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      HapticFeedback.lightImpact();
      await FirebaseFirestore.instance.collection('feedbacks').add(payload);

      if (!mounted) return;
      setState(() => _isSubmitted = true);
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
        backgroundColor: AppColors.darkBg,
        appBar: AppBar(
          backgroundColor: AppColors.darkBg,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: AppColors.darkText),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppGradients.messengerPanel,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.darkBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.24),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 52,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '접수가 완료되었습니다',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '소중한 의견이 정상적으로 접수되었습니다.\n더 나은 WorkNote로 반영하겠습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.darkHint,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.premiumBlue,
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
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text(
          '의견 보내기',
          style: TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: AppColors.darkBg,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.darkText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '서비스 개선 의견',
                    style: TextStyle(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '버그, 개선점, UI 의견을 남겨 주세요. 현재 팀과 프로필 정보가 함께 기록되어 문제 재현과 대응에 도움이 됩니다.',
                    style: TextStyle(
                      color: AppColors.darkHint,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '문의 유형',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['버그', '개선', 'UI', '기타'].map((type) {
                final selected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: selected,
                  onSelected: (value) {
                    if (value) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedType = type);
                    }
                  },
                  backgroundColor: AppColors.darkSurface,
                  selectedColor: AppColors.premiumBlue.withValues(alpha: 0.18),
                  side: BorderSide(
                    color: selected
                        ? AppColors.premiumBlue
                        : AppColors.darkBorder,
                  ),
                  checkmarkColor: AppColors.premiumBlue,
                  labelStyle: TextStyle(
                    color: selected
                        ? AppColors.darkText
                        : AppColors.darkHint,
                    fontWeight: selected
                        ? FontWeight.w900
                        : FontWeight.w700,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              '내용',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _feedbackCtrl,
              maxLines: 8,
              cursorColor: AppColors.premiumBlue,
              style: const TextStyle(color: AppColors.darkText),
              decoration: InputDecoration(
                hintText: '앱 사용 중 불편했던 점이나 개선 아이디어를 편하게 적어 주세요.',
                hintStyle: const TextStyle(color: AppColors.darkHint),
                filled: true,
                fillColor: AppColors.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: AppColors.premiumBlue,
                    width: 1.8,
                  ),
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
                  backgroundColor: AppColors.premiumBlue,
                  disabledBackgroundColor: AppColors.darkSurface2,
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
