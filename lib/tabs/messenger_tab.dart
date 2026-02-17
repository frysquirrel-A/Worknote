import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/team_provider.dart';

class MessengerTab extends StatefulWidget {
  const MessengerTab({super.key});

  @override
  State<MessengerTab> createState() => _MessengerTabState();
}

class _MessengerTabState extends State<MessengerTab> {
  final TextEditingController _ctrl = TextEditingController();
  late ChatProvider _chatProv;
  String? _lastTeamId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ChatProvider>().startPolling());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // dispose 시 안전하게 참조하기 위해 ChatProvider를 로컬에 보관
    _chatProv = context.read<ChatProvider>();
    final teamProv = context.read<TeamProvider>();
    final teamId = teamProv.currentTeamId;

    // 팀이 바뀌었을 때만 활성 스레드 동기화 수행
    if (_lastTeamId != teamId) {
      _lastTeamId = teamId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _chatProv.ensureActiveForTeam(team: teamProv.currentTeam);
      });
    }
  }

  @override
  void dispose() {
    // context 대신 캐싱된 _chatProv 사용 (deactivated ancestor 에러 방지)
    _chatProv.stopPolling();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final teamProv = context.watch<TeamProvider>();
    final chatProv = context.watch<ChatProvider>();

    final myId = authProv.currentUser?.id ?? 'me';
    final myName = authProv.currentUser?.name ?? '관리자';

    final team = teamProv.currentTeam;

    final threadId = chatProv.activeThreadId.isEmpty ? team.id : chatProv.activeThreadId;
    final threadTitle = chatProv.activeThreadTitle.isEmpty ? '단체 · ${team.name}' : chatProv.activeThreadTitle;

    final messages = chatProv.getMessages(threadId);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      endDrawer: _ChatManageDrawer(
        myId: myId,
        team: team,
        teamProv: teamProv,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // top bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openThreadPicker(context, myId: myId, myName: myName),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.forum_outlined, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                threadTitle,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.expand_more_rounded),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Builder(
                    builder: (ctx) => IconButton(
                      tooltip: '채팅 관리',
                      onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                      icon: const Icon(Icons.view_sidebar_outlined),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.senderId == myId;
                  return _buildMessageBubble(msg, isMe);
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        hintText: '메시지 입력...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () async {
                      final text = _ctrl.text.trim();
                      if (text.isEmpty) return;
                      _ctrl.clear();
                      await chatProv.sendMessage(threadId, text, myId, myName);
                    },
                    icon: const Icon(Icons.send_rounded),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isMe ? null : Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.senderName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isMe ? Colors.white70 : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.content,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isMe ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openThreadPicker(BuildContext context, {required String myId, required String myName}) async {
    final teamProv = context.read<TeamProvider>();
    final chatProv = context.read<ChatProvider>();
    final team = teamProv.currentTeam;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final members = team.memberIds;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: 8),
              const ListTile(
                title: Text('대화 선택', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.groups_rounded),
                title: Text('단체 · ${team.name}'),
                onTap: () {
                  chatProv.setActiveThread(threadId: team.id, title: '단체 · ${team.name}');
                  Navigator.pop(ctx);
                },
              ),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Text('DM', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              ...members.where((id) => id != myId).map((id) {
                final title = 'DM · $id';
                return ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(title),
                  onTap: () {
                    final tid = chatProv.dmThreadId(team.id, myId, id);
                    chatProv.setActiveThread(threadId: tid, title: title);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Text('그룹', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline_rounded),
                title: const Text('그룹 만들기'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _createGroupDialog(context, teamId: team.id, myId: myId);
                },
              ),
              ...chatProv.threadsForTeam(team.id).where((t) => t.type == 'group').map((t) {
                return ListTile(
                  leading: const Icon(Icons.forum_outlined),
                  title: Text('그룹 · ${t.title}'),
                  subtitle: Text('${t.memberIds.length}명', style: const TextStyle(fontSize: 12)),
                  onTap: () {
                    chatProv.setActiveThread(threadId: t.id, title: '그룹 · ${t.title}');
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createGroupDialog(BuildContext context, {required String teamId, required String myId}) async {
    final chatProv = context.read<ChatProvider>();
    final teamProv = context.read<TeamProvider>();
    final team = teamProv.currentTeam;

    final titleCtrl = TextEditingController();
    final selected = <String>{myId};

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('그룹 채팅 만들기'),
          content: StatefulBuilder(
            builder: (ctx2, setState2) {
              return SizedBox(
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(hintText: '그룹 이름'),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: team.memberIds.map((id) {
                          final checked = selected.contains(id);
                          return CheckboxListTile(
                            value: checked,
                            title: Text(id == myId ? '나' : id),
                            onChanged: (v) {
                              setState2(() {
                                if (v == true) {
                                  selected.add(id);
                                } else {
                                  if (id != myId) selected.remove(id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('생성'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final title = titleCtrl.text.trim().isEmpty ? '새 그룹' : titleCtrl.text.trim();
      final tid = await chatProv.createGroupThread(teamId: teamId, title: title, memberIds: selected.toList());
      chatProv.setActiveThread(threadId: tid, title: '그룹 · $title');
    }
    titleCtrl.dispose();
  }
}

class _ChatManageDrawer extends StatelessWidget {
  final String myId;
  final Team team;
  final TeamProvider teamProv;

  const _ChatManageDrawer({required this.myId, required this.team, required this.teamProv});

  @override
  Widget build(BuildContext context) {
    final chatProv = context.watch<ChatProvider>();
    final threads = chatProv.threadsForTeam(team.id).where((t) => t.type == 'group').toList();

    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const ListTile(
              title: Text('채팅 관리', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.groups_rounded),
              title: Text('단체 · ${team.name}'),
              onTap: () {
                chatProv.setActiveThread(threadId: team.id, title: '단체 · ${team.name}');
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: const Text('현재 대화 내용 지우기'),
              onTap: () async {
                await chatProv.clearThreadMessages(chatProv.activeThreadId.isEmpty ? team.id : chatProv.activeThreadId);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text('그룹 대화', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            ...threads.map((t) => ListTile(
                  leading: const Icon(Icons.forum_outlined),
                  title: Text(t.title),
                  subtitle: Text('${t.memberIds.length}명'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await chatProv.deleteGroupThread(t.id);
                      Navigator.pop(context);
                    },
                  ),
                  onTap: () {
                    chatProv.setActiveThread(threadId: t.id, title: '그룹 · ${t.title}');
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}
