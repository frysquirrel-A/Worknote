import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';

class TeamManagementPage extends StatefulWidget {
  const TeamManagementPage({super.key});

  @override
  State<TeamManagementPage> createState() => _TeamManagementPageState();
}

class _TeamManagementPageState extends State<TeamManagementPage> {
  final _createNameCtrl = TextEditingController();
  final _createRoleCtrl = TextEditingController(text: '관리자');
  final _joinCodeCtrl = TextEditingController();

  @override
  void dispose() {
    _createNameCtrl.dispose();
    _createRoleCtrl.dispose();
    _joinCodeCtrl.dispose();
    super.dispose();
  }

  Future<bool> _ensureCloudReady(AuthProvider authProv) async {
    if (authProv.isDriveConnected) return true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('구글 연동 필요'),
        content: Text(
          authProv.currentUser?.isLocal == true
              ? '현재는 로컬 프로필입니다.\n팀 초대/Drive 동기화 기능을 쓰려면 구글 계정을 연결해야 합니다.'
              : '구글 Drive 연결을 다시 활성화해야 팀 초대 코드를 조회할 수 있습니다.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('연결하기')),
        ],
      ),
    );

    if (ok != true) return false;
    final result = await authProv.connectGoogleDrive(bridgeCurrentLocal: true);
    if (!mounted) return false;
    if (result.message != null && result.message!.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!)));
    }
    return result.ok;
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final teamProv = context.watch<TeamProvider>();
    final myId = authProv.currentUser?.id ?? 'me';
    final myName = authProv.currentUser?.name ?? '관리자';

    final team = teamProv.currentTeam;

    return Scaffold(
      appBar: AppBar(title: const Text('팀 관리')),
      backgroundColor: const Color(0xFFF8FAFC),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle('현재 팀'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.hub_rounded, color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(team.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                    Text(
                      '내 역할: ${teamProv.getMyRole(myId)}',
                      style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.key_rounded, size: 18, color: Color(0xFF2563EB)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                team.inviteCode,
                                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: '복사',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: team.inviteCode));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('초대 코드 복사 완료')));
                      },
                      icon: const Icon(Icons.copy_all_rounded),
                    ),
                    IconButton(
                      tooltip: '재생성',
                      onPressed: () async {
                        final ready = await _ensureCloudReady(authProv);
                        if (!ready) return;
                        await teamProv.regenerateInviteCode(team.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('초대 코드가 재생성되었습니다.')));
                      },
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('팀원: ${team.memberIds.length}명', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle('새 팀 만들기'),
          const SizedBox(height: 10),
          _card(
            child: Column(
              children: [
                TextField(controller: _createNameCtrl, decoration: _inputDecoration('팀 이름')),
                const SizedBox(height: 10),
                TextField(controller: _createRoleCtrl, decoration: _inputDecoration('내 역할(예: 관리자/팀원)')),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final name = _createNameCtrl.text.trim();
                      if (name.isEmpty) return;
                      final role = _createRoleCtrl.text.trim().isEmpty ? '관리자' : _createRoleCtrl.text.trim();
                      await teamProv.createTeam(name, myId: myId, myRole: role);
                      if (!context.mounted) return;
                      _createNameCtrl.clear();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('팀 "$name" 생성 완료')));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('팀 생성', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle('초대 코드로 팀 참여'),
          const SizedBox(height: 10),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _joinCodeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDecoration('초대 코드 (예: ABCD1234)'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final code = _joinCodeCtrl.text.trim().toUpperCase();
                      if (code.isEmpty) return;
                      final ready = await _ensureCloudReady(authProv);
                      if (!ready) return;
                      final ok = await teamProv.joinTeam(code, myId, myRole: '팀원');
                      if (!context.mounted) return;
                      if (ok) {
                        _joinCodeCtrl.clear();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('팀 참여 완료')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('팀을 찾지 못했습니다. (Drive 연동 여부/코드를 확인하세요)')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
                    ),
                    icon: const Icon(Icons.group_add_rounded),
                    label: const Text('팀 참여', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  authProv.isDriveConnected
                      ? '현재 Drive 연결이 활성화되어 있습니다. 같은 구글 드라이브 데이터 범위에서 초대 코드를 조회합니다.'
                      : 'TIP: 팀 참여는 Drive 연결이 필요합니다. 로컬 프로필도 구글 계정과 연결하면 바로 사용할 수 있어요.',
                  style: TextStyle(color: Colors.grey[600], height: 1.35, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle('내 팀 목록'),
          const SizedBox(height: 10),
          _card(
            child: Column(
              children: teamProv.teams.map((t) {
                final selected = t.id == teamProv.currentTeamId;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, color: selected ? const Color(0xFF2563EB) : Colors.grey),
                  title: Text(t.name, style: TextStyle(fontWeight: selected ? FontWeight.w900 : FontWeight.w700)),
                  subtitle: Text('코드: ${t.inviteCode} • 팀원 ${t.memberIds.length}명'),
                  onTap: () {
                    teamProv.switchTeam(t.id);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('팀 전환: ${t.name}')));
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle('내 정보'),
          const SizedBox(height: 10),
          _card(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
                child: Text(authProv.currentUser?.profileImage ?? (myName.isNotEmpty ? myName[0] : 'U')),
              ),
              title: Text(myName, style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(
                authProv.isGoogleLinked
                    ? 'ID: $myId • Google: ${authProv.currentUser?.linkedGoogleEmail ?? ''}'
                    : 'ID: $myId • 로컬 프로필',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)));
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
