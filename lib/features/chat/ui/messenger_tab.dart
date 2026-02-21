import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/chat/state/chat_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';

class MessengerTab extends StatefulWidget {
  const MessengerTab({super.key});
  @override
  State<MessengerTab> createState() => _MessengerTabState();
}

class _MessengerTabState extends State<MessengerTab> {
  final TextEditingController _ctrl = TextEditingController();
  late ChatProvider _chatProvider;
  bool _started = false;
  String? _lastTeamId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);

        // 팀 전환 시, 이전 팀의 threadId가 남아 메시지가 섞여 보이는 데이터 오염을 방지.
    final teamProv = Provider.of<TeamProvider>(context, listen: false);
    final teamId = teamProv.currentTeamId;
    final teamName = teamProv.currentTeam.name;

    final activeId = _chatProvider.activeThreadId;
    final belongsToTeam = activeId == teamId ||
        activeId.startsWith('grp_${teamId}_') ||
        activeId.startsWith('dm_${teamId}_');

    if (_lastTeamId != teamId) {
      _lastTeamId = teamId;
      if (!belongsToTeam) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _chatProvider.setActiveThread(teamId, title: '단체 · $teamName');
        });
      }
    }


    if (!_started) {
      _started = true;
      _chatProvider.startPolling();
    }
  }

  @override
  void dispose() { _chatProvider.stopPolling(); _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final chatProv = context.watch<ChatProvider>();
    final authProv = context.watch<AuthProvider>();
    final myId = authProv.currentUser?.id ?? 'me';
    final myName = authProv.currentUser?.name ?? '관리자';
    final messages = chatProv.getMessages(chatProv.activeThreadId);

    return Scaffold(
      backgroundColor: AppColors.bg,
      endDrawer: _buildEndDrawer(context, teamProv, chatProv, myId),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: Row(children: [
          Expanded(child: GestureDetector(onTap: () => _showThreadSelectionSheet(context, teamProv, chatProv, myId), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]), child: Row(children: [const Icon(Icons.forum_rounded, size: 20, color: AppColors.primary), const SizedBox(width: 12), Expanded(child: Text(chatProv.activeThreadTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.text), overflow: TextOverflow.ellipsis)), const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.hint)])))),
          const SizedBox(width: 8),
          Builder(builder: (ctx) => IconButton(icon: const Icon(Icons.view_sidebar_outlined, color: AppColors.text2), onPressed: () => Scaffold.of(ctx).openEndDrawer())),
        ])),
        Expanded(
        child: messages.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.chat_bubble_outline_rounded, size: 44, color: AppColors.hint),
                      SizedBox(height: 12),
                      Text('아직 메시지가 없습니다.', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.text)),
                      SizedBox(height: 6),
                      Text('하단 입력창에 메시지를 보내거나, 상단에서 대화 대상을 선택해 보세요.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.hint, height: 1.4)),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                reverse: true,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                itemCount: messages.length,
                itemBuilder: (context, index) => _buildMessageBubble(messages[index], messages[index].senderId == myId),
              ),
      ),
        Container(padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), decoration: BoxDecoration(color: AppColors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))]), child: Row(children: [
          Expanded(child: TextField(controller: _ctrl, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.text), decoration: InputDecoration(hintText: "메시지를 입력하세요...", hintStyle: const TextStyle(color: AppColors.hint), filled: true, fillColor: AppColors.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)))),
          const SizedBox(width: 12),
          GestureDetector(onTap: () { if (_ctrl.text.trim().isEmpty) return; chatProv.sendMessage(chatProv.activeThreadId, _ctrl.text, myId, myName); _ctrl.clear(); }, child: Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Icon(Icons.send_rounded, color: Colors.white, size: 24))),
        ])),
      ]),
    );
  }

  Widget _buildEndDrawer(BuildContext context, TeamProvider teamProv, ChatProvider chatProv, String myId) {
    final userBox = Hive.box<AppUser>('users');
    final groups = chatProv.getGroupThreads(teamProv.currentTeamId);
    return Drawer(backgroundColor: AppColors.surface, child: SafeArea(child: Column(children: [
      const ListTile(title: Text('채팅 관리', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.text))),
      const Divider(color: AppColors.border),
      Expanded(child: ListView(children: [
        _drawerSectionTitle('단체 (팀 채널)'),
        ...teamProv.teams.map((t) => ListTile(title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)), onTap: () { chatProv.setActiveThread(t.id, title: "단체 · ${t.name}"); Navigator.pop(context); })),
        const Divider(color: AppColors.border),
        _drawerSectionTitle('1:1 대화'),
        ...teamProv.currentTeam.memberIds.where((id) => id != myId).map((uid) { final name = userBox.get(uid)?.name ?? uid; final tid = chatProv.dmThreadId(teamProv.currentTeamId, myId, uid); return ListTile(title: Text(name, style: const TextStyle(color: AppColors.text)), onTap: () { chatProv.setActiveThread(tid, title: "DM · $name"); Navigator.pop(context); }, trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger), onPressed: () => _confirmClear(context, chatProv, tid))); }),
        const Divider(color: AppColors.border),
        _drawerSectionTitle('그룹 채팅'),
        ...groups.map((g) => ListTile(title: Text(g['title'] ?? '그룹', style: const TextStyle(color: AppColors.text)), onTap: () { chatProv.setActiveThread(g['id'], title: "그룹 · ${g['title']}"); Navigator.pop(context); }, trailing: PopupMenuButton<String>(onSelected: (val) { if (val == 'rename') _showRenameDialog(context, chatProv, g['id'], g['title']); if (val == 'delete') _confirmDeleteGroup(context, chatProv, g['id']); }, itemBuilder: (ctx) => [const PopupMenuItem(value: 'rename', child: Text('이름 변경')), const PopupMenuItem(value: 'delete', child: Text('방 삭제', style: TextStyle(color: AppColors.danger)))]))),
      ])),
      const Divider(color: AppColors.border),
      ListTile(leading: const Icon(Icons.cleaning_services_outlined, color: AppColors.warning), title: const Text('현재 대화 내용 지우기', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)), onTap: () { Navigator.pop(context); _confirmClear(context, chatProv, chatProv.activeThreadId); }),
    ])));
  }

  Widget _drawerSectionTitle(String title) => Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text(title, style: const TextStyle(fontSize: 12, color: AppColors.hint, fontWeight: FontWeight.bold)));

  void _showThreadSelectionSheet(BuildContext context, TeamProvider teamProv, ChatProvider chatProv, String myId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
      final groups = chatProv.getGroupThreads(teamProv.currentTeamId);
      final members = teamProv.currentTeam.memberIds.where((id) => id != myId).toList();
      final userBox = Hive.box<AppUser>('users');
      return SingleChildScrollView(padding: const EdgeInsets.symmetric(vertical: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text("대화 대상 선택", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.text))),
        const SizedBox(height: 16),
        _drawerSectionTitle("단체 (팀 채널)"),
        ...teamProv.teams.map((t) => ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 24), leading: const CircleAvatar(child: Icon(Icons.groups_rounded)), title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)), onTap: () { chatProv.setActiveThread(t.id, title: "단체 · ${t.name}"); Navigator.pop(ctx); })),
        _drawerSectionTitle("1:1 대화"),
        ...members.map((uid) { final name = userBox.get(uid)?.name ?? uid; return ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 24), leading: const CircleAvatar(child: Icon(Icons.person_rounded)), title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)), onTap: () { final tid = chatProv.dmThreadId(teamProv.currentTeamId, myId, uid); chatProv.setActiveThread(tid, title: "DM · $name"); Navigator.pop(ctx); }); }),
        _drawerSectionTitle("그룹 채팅"),
        ...groups.map((g) => ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 24), leading: const CircleAvatar(child: Icon(Icons.forum_rounded)), title: Text(g['title'] ?? '그룹대화', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)), onTap: () { chatProv.setActiveThread(g['id'], title: "그룹 · ${g['title']}"); Navigator.pop(ctx); })),
        ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 24), leading: const CircleAvatar(backgroundColor: AppColors.bg, child: Icon(Icons.add_rounded, color: AppColors.primary)), title: const Text("새 그룹 만들기", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)), onTap: () { Navigator.pop(ctx); _showCreateGroupDialog(context, teamProv, chatProv, myId); }),
      ]));
    });
  }

  void _showCreateGroupDialog(BuildContext context, TeamProvider teamProv, ChatProvider chatProv, String myId) {
    final titleCtrl = TextEditingController(); final selectedIds = <String>{}; final userBox = Hive.box<AppUser>('users'); final members = teamProv.currentTeam.memberIds.where((id) => id != myId).toList();
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), backgroundColor: AppColors.surface, title: const Text("새 그룹 만들기", style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text)), content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: titleCtrl, style: const TextStyle(color: AppColors.text), decoration: const InputDecoration(hintText: "그룹방 이름", hintStyle: TextStyle(color: AppColors.hint))), const SizedBox(height: 16), const Text("멤버 선택", style: TextStyle(fontSize: 12, color: AppColors.hint, fontWeight: FontWeight.bold)), Flexible(child: ListView(shrinkWrap: true, children: members.map((uid) => CheckboxListTile(title: Text(userBox.get(uid)?.name ?? uid, style: const TextStyle(color: AppColors.text)), value: selectedIds.contains(uid), onChanged: (v) => setModalState(() => v == true ? selectedIds.add(uid) : selectedIds.remove(uid)))).toList()))])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")), ElevatedButton(onPressed: () async { if (titleCtrl.text.trim().isEmpty || selectedIds.isEmpty) return; final tid = await chatProv.createGroupThread(teamId: teamProv.currentTeamId, title: titleCtrl.text, memberIds: [myId, ...selectedIds]); chatProv.setActiveThread(tid, title: "그룹 · ${titleCtrl.text}"); if (ctx.mounted) Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text("생성", style: TextStyle(color: Colors.white)))])));
  }

  void _showRenameDialog(BuildContext context, ChatProvider chatProv, String tid, String oldTitle) {
    final ctrl = TextEditingController(text: oldTitle);
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: AppColors.surface, title: const Text('그룹 이름 변경', style: TextStyle(color: AppColors.text)), content: TextField(controller: ctrl, style: const TextStyle(color: AppColors.text)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')), TextButton(onPressed: () async { await chatProv.renameGroupThread(tid, ctrl.text.trim()); if (ctx.mounted) Navigator.pop(ctx); }, child: const Text('변경'))]));
  }

  void _confirmDeleteGroup(BuildContext context, ChatProvider chatProv, String tid) {
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: AppColors.surface, title: const Text('그룹 삭제', style: TextStyle(color: AppColors.text)), content: const Text('그룹방을 삭제하시겠습니까? 메시지도 함께 삭제됩니다.', style: TextStyle(color: AppColors.text2)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')), TextButton(onPressed: () async { await chatProv.deleteGroupThread(tid); if (ctx.mounted) Navigator.pop(ctx); }, child: const Text('삭제', style: TextStyle(color: AppColors.danger)))]));
  }

  void _confirmClear(BuildContext context, ChatProvider chatProv, String tid) {
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: AppColors.surface, title: const Text('대화 기록 삭제', style: TextStyle(color: AppColors.text)), content: const Text('이 대화방의 모든 메시지를 삭제할까요?', style: TextStyle(color: AppColors.text2)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')), TextButton(onPressed: () async { await chatProv.clearThreadMessages(tid); if (ctx.mounted) Navigator.pop(ctx); }, child: const Text('삭제', style: TextStyle(color: AppColors.danger)))]));
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
      if (!isMe) Padding(padding: const EdgeInsets.only(left: 4, bottom: 4), child: Text(msg.senderName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.text2))),
      Row(mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (isMe) Text(DateFormat('a h:mm', 'ko').format(msg.sentAt), style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        Container(constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), decoration: BoxDecoration(color: isMe ? AppColors.primary : AppColors.surface, border: isMe ? null : Border.all(color: AppColors.border), borderRadius: BorderRadius.only(topLeft: const Radius.circular(20), topRight: const Radius.circular(20), bottomLeft: Radius.circular(isMe ? 20 : 4), bottomRight: Radius.circular(isMe ? 4 : 20))), child: Text(msg.content, style: TextStyle(color: isMe ? Colors.white : AppColors.text, fontWeight: FontWeight.w700, fontSize: 15, height: 1.4))),
        const SizedBox(width: 4),
        if (!isMe) Text(DateFormat('a h:mm', 'ko').format(msg.sentAt), style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.bold)),
      ]),
    ]));
  }
}
