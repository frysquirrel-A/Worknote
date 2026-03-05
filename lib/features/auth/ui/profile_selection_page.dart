import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:worknote/core/models/work_profile.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/app/widgets/profile_avatar.dart';
import 'package:worknote/features/profile/ui/sheets/profile_focus_sheet.dart';

class ProfileSelectionPage extends StatefulWidget {
  final bool manageMode;

  const ProfileSelectionPage({super.key, this.manageMode = false});

  @override
  State<ProfileSelectionPage> createState() => _ProfileSelectionPageState();
}

class _ProfileSelectionPageState extends State<ProfileSelectionPage> {
  bool _working = false;

  Future<void> _run(Future<AuthFlowResult> Function() task) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final result = await task();
      if (!mounted) return;
      if (result.message != null && result.message!.trim().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!)));
      }
      if (widget.manageMode && result.ok && result.state != AuthFlowState.requiresProfileSelection) {
        Navigator.of(context).maybePop();
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _showRenameDialog(WorkProfile profile) async {
    final ctrl = TextEditingController(text: profile.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('프로필 이름 수정'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '새 프로필 이름'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('저장')),
        ],
      ),
    );
    if (ok != true) return;
    final success = await context.read<AuthProvider>().renameProfile(profile.id, ctrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '프로필 이름이 저장되었습니다.' : '이름 저장에 실패했습니다.')),
    );
  }

  Future<void> _confirmDelete(WorkProfile profile) async {
    final title = profile.isGoogleProfile ? '구글 슬롯 삭제' : '로컬 프로필 삭제';
    final content = profile.isGoogleProfile
        ? '이 슬롯을 삭제하면 현재 연결된 구글 프로필 목록에서 제거됩니다.\n기존 로컬 데이터는 앱 안에 남아 있을 수 있습니다.'
        : '이 로컬 프로필을 삭제합니다.\n현재 프로필이면 다른 프로필로 자동 전환됩니다.';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final success = await context.read<AuthProvider>().deleteProfile(profile.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '프로필이 삭제되었습니다.' : '프로필 삭제에 실패했습니다.')),
    );
    if (widget.manageMode && success) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _confirmUnlink(WorkProfile profile) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('구글 연결 해제'),
        content: Text('${profile.linkedGoogleEmail ?? '구글 계정'} 연결을 해제하고 로컬 프로필로 전환할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('해제')),
        ],
      ),
    );
    if (ok != true) return;

    final success = await context.read<AuthProvider>().unlinkGoogleProfile(profile.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '구글 연결이 해제되었습니다.' : '구글 연결 해제에 실패했습니다.')),
    );
  }

  void _showFocusSheet(WorkProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProfileFocusSheet(
        profileId: profile.id,
        profileName: profile.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final current = auth.currentProfile;
    final bool showPendingSlots = auth.hasPendingGoogleSelection;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(showPendingSlots ? '프로필 슬롯 선택' : '프로필 관리'),
        actions: [
          if (showPendingSlots)
            TextButton(
              onPressed: _working
                  ? null
                  : () {
                      auth.clearPendingGoogleSelection();
                      if (widget.manageMode) Navigator.of(context).maybePop();
                    },
              child: const Text('취소', style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            if (showPendingSlots) ...[
              _PendingGoogleSlotsSection(
                working: _working,
                manageMode: widget.manageMode,
                onSelectProfile: (profile) => _run(() => auth.selectPendingGoogleProfile(profile.id)),
                onCreateSlot: (slotIndex) => _run(() => auth.createPendingGoogleSlot(preferredSlot: slotIndex)),
                onFocusTap: _showFocusSheet,
              ),
              const SizedBox(height: 20),
            ],
            _SectionCard(
              title: '현재 프로필',
              subtitle: current == null
                  ? '선택된 프로필이 없습니다.'
                  : current.isGoogleProfile
                      ? '${current.linkedGoogleEmail} • 슬롯 ${((current.slotIndex ?? 0) + 1)}'
                      : '로컬 전용 프로필',
              child: current == null
                  ? const SizedBox.shrink()
                  : _ProfileTile(
                      profile: current,
                      isCurrent: true,
                      onTap: () {},
                      onFocusTap: () => _showFocusSheet(current),
                      onMenuSelected: (action) {
                        switch (action) {
                          case _ProfileAction.rename:
                            _showRenameDialog(current);
                            break;
                          case _ProfileAction.unlink:
                            _confirmUnlink(current);
                            break;
                          case _ProfileAction.delete:
                            _confirmDelete(current);
                            break;
                        }
                      },
                    ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: '빠른 전환',
              subtitle: '탭을 바꾸지 않고 다른 프로필로 즉시 전환할 수 있습니다.',
              child: Column(
                children: auth.profiles
                    .map(
                      (profile) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProfileTile(
                          profile: profile,
                          isCurrent: current?.id == profile.id,
                          onTap: () async {
                            await auth.switchProfile(profile.id);
                            if (!mounted) return;
                            if (widget.manageMode) Navigator.of(context).maybePop();
                          },
                          onFocusTap: () => _showFocusSheet(profile),
                          onMenuSelected: (action) {
                            switch (action) {
                              case _ProfileAction.rename:
                                _showRenameDialog(profile);
                                break;
                              case _ProfileAction.unlink:
                                _confirmUnlink(profile);
                                break;
                              case _ProfileAction.delete:
                                _confirmDelete(profile);
                                break;
                            }
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: '프로필 추가',
              subtitle: '로컬 프로필을 추가하거나, 다른 구글 계정/슬롯을 연결하세요.',
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _working ? null : () => _run(() => auth.createAdditionalLocalProfile()),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('새 로컬 프로필 만들기'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _working ? null : () => _run(() => auth.loginWithGoogle()),
                      icon: const Icon(Icons.cloud_sync_rounded),
                      label: const Text('구글 계정/슬롯 연결'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingGoogleSlotsSection extends StatelessWidget {
  final bool working;
  final bool manageMode;
  final Future<void> Function(WorkProfile profile) onSelectProfile;
  final Future<void> Function(int slotIndex) onCreateSlot;
  final void Function(WorkProfile profile) onFocusTap;

  const _PendingGoogleSlotsSection({
    required this.working,
    required this.manageMode,
    required this.onSelectProfile,
    required this.onCreateSlot,
    required this.onFocusTap,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.pendingGoogleEmail ?? '';
    final Map<int, WorkProfile> slotMap = {
      for (final p in auth.pendingGoogleProfiles)
        if (p.slotIndex != null) p.slotIndex!: p,
    };

    return _SectionCard(
      title: '구글 5슬롯',
      subtitle: '$email 계정에서 사용할 슬롯을 선택하세요.\n이미 존재하는 슬롯으로 들어가거나, 빈 슬롯에 새 프로필을 만들 수 있습니다.',
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: auth.maxGoogleSlots,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final profile = slotMap[index];
              final occupied = profile != null;

              return InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: working
                    ? null
                    : () async {
                        if (occupied) {
                          await onSelectProfile(profile);
                        } else {
                          await onCreateSlot(index);
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: occupied ? const Color(0xFF2563EB).withValues(alpha: 0.18) : const Color(0xFFE5E7EB)),
                    boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 10))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ProfileAvatar(
                            emoji: occupied
                                ? ((profile.profileImage?.trim().isNotEmpty ?? false) ? profile.profileImage! : (profile.name.trim().isNotEmpty ? profile.name[0] : '🙂'))
                                : '+',
                            userId: profile?.id ?? 'slot_$index',
                            radius: 18,
                            heroPrefix: 'selection',
                          ),
                          const Spacer(),
                          if (occupied)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF2563EB)),
                              onPressed: () => onFocusTap(profile),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        occupied ? (profile.name.trim().isEmpty ? '닉네임 설정 필요' : profile.name) : '빈 슬롯',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        occupied ? '기존 슬롯으로 진입' : '새 프로필 만들기',
                        style: const TextStyle(color: Colors.black54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (working) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 4),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Colors.black54, height: 1.45)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

enum _ProfileAction { rename, unlink, delete }

class _ProfileTile extends StatelessWidget {
  final WorkProfile profile;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onFocusTap;
  final void Function(_ProfileAction action) onMenuSelected;

  const _ProfileTile({
    required this.profile,
    required this.isCurrent,
    required this.onTap,
    required this.onFocusTap,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = profile.isGoogleProfile
        ? '${profile.linkedGoogleEmail} • 슬롯 ${((profile.slotIndex ?? 0) + 1)}'
        : '로컬 전용';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isCurrent ? const Color(0xFF2563EB).withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isCurrent ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              ProfileAvatar(
                emoji: (profile.profileImage?.trim().isNotEmpty ?? false)
                    ? profile.profileImage!
                    : (profile.name.trim().isNotEmpty ? profile.name[0] : '🙂'),
                userId: profile.id,
                radius: 22,
                heroPrefix: 'selection',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.name.trim().isEmpty ? '이름 미설정' : profile.name,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text('현재', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.black54), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: Color(0xFF2563EB)),
                onPressed: onFocusTap,
                tooltip: 'Focus 설정',
              ),
              PopupMenuButton<_ProfileAction>(
                onSelected: onMenuSelected,
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: _ProfileAction.rename, child: Text('이름 수정')),
                  if (profile.isGoogleProfile) const PopupMenuItem(value: _ProfileAction.unlink, child: Text('구글 연결 해제')),
                  const PopupMenuItem(value: _ProfileAction.delete, child: Text('프로필 삭제')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
