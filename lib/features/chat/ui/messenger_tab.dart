import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/core/ui/widgets/empty_state_placeholder.dart';
import 'package:worknote/core/ui/widgets/press_scale.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/chat/state/chat_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';

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
    _chatProvider = context.read<ChatProvider>();

    final teamProv = context.read<TeamProvider>();
    final teamId = teamProv.currentTeamId;
    final teamName = teamProv.currentTeam.name;
    final activeId = _chatProvider.activeThreadId;
    final belongsToTeam =
        activeId == teamId ||
        activeId.startsWith('grp_${teamId}_') ||
        activeId.startsWith('dm_${teamId}_');

    if (_lastTeamId != teamId) {
      _lastTeamId = teamId;
      if (!belongsToTeam) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _chatProvider.setActiveThread(teamId, title: '전체 방 $teamName');
        });
      }
    }

    if (!_started) {
      _started = true;
      _chatProvider.startPolling();
    }
  }

  @override
  void dispose() {
    _chatProvider.stopPolling();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final chatProv = context.watch<ChatProvider>();
    final authProv = context.watch<AuthProvider>();
    final myId = authProv.currentUser?.id ?? 'me';
    final myName = authProv.currentUser?.name ?? '관리자';
    final messages = chatProv.getMessages(chatProv.activeThreadId);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      endDrawer: _buildEndDrawer(context, teamProv, chatProv, myId),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: PressScale(
                    haptic: PressScaleHaptic.selection,
                    onTap: () => _showThreadSelectionSheet(
                      context,
                      teamProv,
                      chatProv,
                      myId,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.forum_rounded,
                            size: 20,
                            color: AppColors.premiumBlue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              chatProv.activeThreadTitle,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: AppColors.darkText,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.darkText.withValues(alpha: 0.68),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(
                      Icons.view_sidebar_outlined,
                      color: AppColors.darkText,
                    ),
                    onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? const EmptyStatePlaceholder(
                    icon: Icons.forum_outlined,
                    title: '아직 대화가 없어요',
                    description: '메시지를 보내 대화를 시작해 보세요.',
                    compact: true,
                    dark: true,
                  )
                : ListView.builder(
                    reverse: true,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    cacheExtent: 320,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return _buildMessageBubble(msg, msg.senderId == myId);
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                bottomInset > 0 ? bottomInset + 8 : 12,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  gradient: AppGradients.messengerPanel,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          hintText: '메시지를 입력하세요.',
                          hintStyle: TextStyle(color: AppColors.darkHint),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _send(chatProv, myId, myName),
                      ),
                    ),
                    const SizedBox(width: 10),
                    PressScale(
                      haptic: PressScaleHaptic.light,
                      onTap: () => _send(chatProv, myId, myName),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: AppColors.premiumBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndDrawer(
    BuildContext context,
    TeamProvider teamProv,
    ChatProvider chatProv,
    String myId,
  ) {
    final userBox = Hive.box<AppUser>('users');
    final groups = chatProv.getGroupThreads(teamProv.currentTeamId);
    final members = teamProv.currentTeam.memberIds
        .where((id) => id != myId)
        .toList();
    return Drawer(
      backgroundColor: AppColors.darkSurface,
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(
              title: Text(
                '채팅 관리',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.darkText,
                ),
              ),
            ),
            const Divider(color: AppColors.darkBorder),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  _drawerSectionTitle('전체 방 (팀 채팅)'),
                  ...teamProv.teams.map(
                    (t) => PressScale(
                      haptic: PressScaleHaptic.selection,
                      onTap: () {
                        chatProv.setActiveThread(t.id, title: '전체 방 ${t.name}');
                        Navigator.pop(context);
                      },
                      child: ListTile(
                        title: Text(
                          t.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Divider(color: AppColors.darkBorder),
                  _drawerSectionTitle('1:1 대화'),
                  ...members.map((uid) {
                    final name = userBox.get(uid)?.name ?? uid;
                    final tid = chatProv.dmThreadId(
                      teamProv.currentTeamId,
                      myId,
                      uid,
                    );
                    return ListTile(
                      title: Text(
                        name,
                        style: const TextStyle(color: AppColors.darkText),
                      ),
                      onTap: () {
                        chatProv.setActiveThread(tid, title: 'DM 방 $name');
                        Navigator.pop(context);
                      },
                      trailing: PressScale(
                        haptic: PressScaleHaptic.medium,
                        onTap: () => _confirmClear(context, chatProv, tid),
                        child: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: AppColors.destructive,
                        ),
                      ),
                    );
                  }),
                  const Divider(color: AppColors.darkBorder),
                  _drawerSectionTitle('그룹 채팅'),
                  ...groups.map(
                    (g) => ListTile(
                      title: Text(
                        (g['title'] ?? '그룹').toString(),
                        style: const TextStyle(color: AppColors.darkText),
                      ),
                      onTap: () {
                        chatProv.setActiveThread(
                          g['id'].toString(),
                          title: '그룹 방 ${(g['title'] ?? '그룹')}',
                        );
                        Navigator.pop(context);
                      },
                      trailing: PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'rename') {
                            _showRenameDialog(
                              context,
                              chatProv,
                              g['id'].toString(),
                              (g['title'] ?? '').toString(),
                            );
                          }
                          if (val == 'delete') {
                            _confirmDeleteGroup(
                              context,
                              chatProv,
                              g['id'].toString(),
                            );
                          }
                        },
                        itemBuilder: (ctx) => const [
                          PopupMenuItem(value: 'rename', child: Text('이름 변경')),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              '방 삭제',
                              style: TextStyle(color: AppColors.destructive),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: const BoxDecoration(
                color: AppColors.darkSurface,
                border: Border(top: BorderSide(color: AppColors.darkBorder)),
              ),
              child: SafeArea(
                top: false,
                child: PressScale(
                  haptic: PressScaleHaptic.medium,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmClear(context, chatProv, chatProv.activeThreadId);
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cleaning_services_outlined,
                        color: Color(0xFFF8D94B),
                      ),
                      SizedBox(width: 10),
                      Text(
                        '현재 대화 내용 지우기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.darkHint,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showThreadSelectionSheet(
    BuildContext context,
    TeamProvider teamProv,
    ChatProvider chatProv,
    String myId,
  ) {
    final userBox = Hive.box<AppUser>('users');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final groups = chatProv.getGroupThreads(teamProv.currentTeamId);
        final members = teamProv.currentTeam.memberIds
            .where((id) => id != myId)
            .toList();
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.62,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (ctx2, scrollCtrl) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(vertical: 18),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.darkHint.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 16, 24, 6),
                    child: Text(
                      '대화 상대 선택',
                      style: TextStyle(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  _drawerSectionTitle('전체 방 (팀 채팅)'),
                  ...teamProv.teams.map(
                    (t) => ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.groups_rounded),
                      ),
                      title: Text(
                        t.name,
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () {
                        chatProv.setActiveThread(t.id, title: '전체 방 ${t.name}');
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  _drawerSectionTitle('1:1 대화'),
                  ...members.map((uid) {
                    final name = userBox.get(uid)?.name ?? uid;
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_rounded),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () {
                        final tid = chatProv.dmThreadId(
                          teamProv.currentTeamId,
                          myId,
                          uid,
                        );
                        chatProv.setActiveThread(tid, title: 'DM 방 $name');
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                  _drawerSectionTitle('그룹 채팅'),
                  ...groups.map(
                    (g) => ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.forum_rounded),
                      ),
                      title: Text(
                        (g['title'] ?? '그룹').toString(),
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () {
                        chatProv.setActiveThread(
                          g['id'].toString(),
                          title: '그룹 방 ${(g['title'] ?? '그룹')}',
                        );
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRenameDialog(
    BuildContext context,
    ChatProvider chatProv,
    String tid,
    String oldTitle,
  ) {
    final ctrl = TextEditingController(text: oldTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          '그룹 이름 변경',
          style: TextStyle(color: AppColors.darkText),
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppColors.darkText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await chatProv.renameGroupThread(tid, ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup(
    BuildContext context,
    ChatProvider chatProv,
    String tid,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          '그룹 방 삭제',
          style: TextStyle(color: AppColors.darkText),
        ),
        content: const Text(
          '그룹 방을 삭제하시겠습니까? 메시지도 함께 삭제됩니다.',
          style: TextStyle(color: AppColors.darkHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await chatProv.deleteGroupThread(tid);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text(
              '삭제',
              style: TextStyle(color: AppColors.destructive),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, ChatProvider chatProv, String tid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          '대화기록 삭제',
          style: TextStyle(color: AppColors.darkText),
        ),
        content: const Text(
          '이 대화방의 모든 메시지를 삭제할까요?',
          style: TextStyle(color: AppColors.darkHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await chatProv.clearThreadMessages(tid);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text(
              '삭제',
              style: TextStyle(color: AppColors.destructive),
            ),
          ),
        ],
      ),
    );
  }

  void _send(ChatProvider chatProv, String myId, String myName) {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    chatProv.sendMessage(chatProv.activeThreadId, text, myId, myName);
    _ctrl.clear();
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                msg.senderName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkHint,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isMe)
                Text(
                  DateFormat('a h:mm', 'ko').format(msg.sentAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.darkHint,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(width: 4),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.premiumBlue : AppColors.darkSurface,
                  border: isMe ? null : Border.all(color: AppColors.darkBorder),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                ),
                child: Text(
                  msg.content,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (!isMe)
                Text(
                  DateFormat('a h:mm', 'ko').format(msg.sentAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.darkHint,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
