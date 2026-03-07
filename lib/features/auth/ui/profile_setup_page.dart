import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:worknote/features/auth/state/auth_provider.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key, this.heroTag});

  final String? heroTag;

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  static const List<String> _avatars = <String>[
    '🙂',
    '😎',
    '🧠',
    '🌿',
    '🚀',
    '📝',
  ];

  late final TextEditingController _nameCtrl;
  String? _selectedAvatar;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl = TextEditingController(text: auth.currentProfile?.name ?? '');
    _selectedAvatar = auth.currentProfile?.profileImage;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해 주세요')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final okName = await auth.updateName(name);
      final okAvatar = await auth.updateProfileImage(_selectedAvatar);
      if (!mounted) return;
      if (!okName || !okAvatar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필 저장에 실패했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.currentProfile;
    final heroTag = widget.heroTag ?? 'profile_avatar_${profile?.id ?? 'new'}';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '프로필 설정',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        auth.isGoogleLinked
                            ? '${auth.currentProfile?.linkedGoogleEmail ?? '구글 계정'}으로 사용할 이름을 정해 주세요.'
                            : '가입 없이 시작한 로컬 프로필입니다.\n앱 안에서 사용할 이름을 정해 주세요.',
                        style: const TextStyle(
                          color: Colors.black54,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Hero(
                          tag: heroTag,
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.12),
                            child: Text(
                              (_selectedAvatar?.trim().isNotEmpty ?? false)
                                  ? _selectedAvatar!
                                  : ((_nameCtrl.text.trim().isNotEmpty)
                                        ? _nameCtrl.text.trim()[0]
                                        : 'W'),
                              style: const TextStyle(fontSize: 34),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _avatars
                            .map(
                              (emoji) => InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () => setState(() => _selectedAvatar = emoji),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _selectedAvatar == emoji
                                        ? const Color(
                                            0xFF2563EB,
                                          ).withValues(alpha: 0.12)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: _selectedAvatar == emoji
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameCtrl,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: '닉네임을 입력해 주세요',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                auth.isGoogleLinked
                                    ? '이 이름은 현재 프로필에만 적용됩니다. 같은 구글 계정에서도 프로필별로 다른 이름을 사용할 수 있어요.'
                                    : '로컬 프로필은 원할 때 구글 계정과 연결해 클라우드 기능을 사용할 수 있어요.',
                                style: const TextStyle(
                                  color: Color(0xFF334155),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('저장하기'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
