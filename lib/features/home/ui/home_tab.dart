import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/chat/state/chat_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';

class HomeTab extends StatefulWidget {
  final void Function(String threadId, String? title) onOpenChatThread;
  const HomeTab({super.key, required this.onOpenChatThread});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with AutomaticKeepAliveClientMixin {
  bool _isGroupedView = false; 
  bool _membersSwipe = true;
  bool _projectsSwipe = false;
  bool _tasksSwipe = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); 

    final auth = context.watch<AuthProvider>();
    final teamProv = context.watch<TeamProvider>();
    final taskProv = context.watch<TaskProvider>();

    final me = auth.currentUser;
    final meId = me?.id ?? 'me';
    final meName = me?.name ?? '나';
    final meEmoji = (me?.profileImage != null && me!.profileImage!.isNotEmpty) ? me.profileImage! : '🙂';

    final teamName = teamProv.currentTeam.name;
    final teamInitial = teamName.isNotEmpty ? teamName.characters.first : 'T';

    final usersBox = Hive.box<AppUser>('users');
    final memberIds = teamProv.currentTeam.memberIds;
    final members = memberIds.map((id) => usersBox.get(id) ?? AppUser(id: id, password: '', name: id, profileImage: '👤')).toList(growable: false);
    final teamProjects = taskProv.projects.where((p) => p.teamId == teamProv.currentTeamId).toList();

    final today = DateTime.now();
    final todayStr = '${today.year}.${today.month.toString().padLeft(2, '0')}.${today.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('안녕하세요, $meName', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(todayStr, style: const TextStyle(fontSize: 14, color: AppColors.text2)),
                      ],
                    ),
                  ),
                  _ProfileAvatarWithTeamBadge(emoji: meEmoji, teamInitial: teamInitial),
                ],
              ),
              const SizedBox(height: 14),

              _card(context, child: InkWell(borderRadius: BorderRadius.circular(18), onTap: () => _showTeamPicker(context, teamProv), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Text(teamInitial, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('현재 팀', style: TextStyle(fontSize: 12, color: AppColors.text, fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(teamName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)])), const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.text2)])))),
              const SizedBox(height: 10),

              _card(
                context, 
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.dashboard_customize_rounded, size: 18, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text('화면 뷰 설정', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.text)),
                        ],
                      ),
                      Row(
                        children: [
                          _MiniBtn(
                            text: _isGroupedView ? '각각보기' : '묶어보기', 
                            icon: _isGroupedView ? Icons.view_stream_rounded : Icons.view_agenda_rounded, 
                            isActive: _isGroupedView,
                            onTap: () => setState(() => _isGroupedView = !_isGroupedView)
                          ),
                          if (!_isGroupedView) ...[
                            const SizedBox(width: 6),
                            _MiniBtn(
                              text: '슬라이드 뷰', 
                              icon: Icons.swipe_rounded, 
                              isActive: _membersSwipe && _projectsSwipe && _tasksSwipe,
                              onTap: () => setState(() {
                                final newState = !(_membersSwipe && _projectsSwipe && _tasksSwipe);
                                _membersSwipe = newState; _projectsSwipe = newState; _tasksSwipe = newState;
                              })
                            ),
                          ]
                        ],
                      )
                    ],
                  ),
                )
              ),
              const SizedBox(height: 14),
              
              if (_isGroupedView)
                _DashboardPagerCard(
                  members: members, teamProv: teamProv, taskProv: taskProv, meId: meId, teamProjects: teamProjects, onOpenChatThread: widget.onOpenChatThread,
                  membersSwipe: _membersSwipe, projectsSwipe: _projectsSwipe, tasksSwipe: _tasksSwipe,
                  onToggleMembers: () => setState(() => _membersSwipe = !_membersSwipe),
                  onToggleProjects: () => setState(() => _projectsSwipe = !_projectsSwipe),
                  onToggleTasks: () => setState(() => _tasksSwipe = !_tasksSwipe),
                )
              else
                _buildSeparatedCards(members, teamProv, taskProv, meId, teamProjects),

              const SizedBox(height: 14),

              _card(context, child: ListTile(leading: const Icon(Icons.forum_outlined, color: AppColors.primary), title: const Text('팀 대화방 열기', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(teamName, maxLines: 1, overflow: TextOverflow.ellipsis), trailing: const Icon(Icons.chevron_right_rounded), onTap: () { final chatProv = context.read<ChatProvider>(); final threadId = 'grp_${teamProv.currentTeamId}_main'; chatProv.setActiveThread(threadId, title: '$teamName · 대화'); widget.onOpenChatThread(threadId, '$teamName · 대화'); })),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeparatedCards(List<AppUser> members, TeamProvider teamProv, TaskProvider taskProv, String meId, List<Project> teamProjects) {
    return Column(
      children: [
        _SectionCard(
          title: '팀원', icon: Icons.people_alt_rounded, isSwipe: _membersSwipe, onToggleSwipe: () => setState(() => _membersSwipe = !_membersSwipe),
          child: _membersSwipe 
              ? SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: members.map((m) => Padding(padding: const EdgeInsets.only(right: 12), child: _MemberAvatar(user: m, isMe: m.id == meId, role: teamProv.currentTeam.memberRoles[m.id], onTap: () => _showMemberProfileSheet(context, member: m, role: teamProv.currentTeam.memberRoles[m.id], myId: meId)))).toList()))
              : Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Wrap(spacing: 12, runSpacing: 12, children: members.map((m) => _MemberAvatar(user: m, isMe: m.id == meId, role: teamProv.currentTeam.memberRoles[m.id], onTap: () => _showMemberProfileSheet(context, member: m, role: teamProv.currentTeam.memberRoles[m.id], myId: meId))).toList())),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: '프로젝트 현황', icon: Icons.domain_rounded, isSwipe: _projectsSwipe, onToggleSwipe: () => setState(() => _projectsSwipe = !_projectsSwipe),
          child: teamProjects.isEmpty 
              ? const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('프로젝트가 없습니다.', style: TextStyle(color: AppColors.hint))))
              : (_projectsSwipe
                  ? SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: teamProjects.map((p) { 
                      final progress = taskProv.projectProgress(p.id, teamId: teamProv.currentTeamId); 
                      return Container(width: 200, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis), const SizedBox(height: 8), Row(children: [Expanded(child: LinearProgressIndicator(value: progress, backgroundColor: Colors.black12, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary), minHeight: 6, borderRadius: BorderRadius.circular(99))), const SizedBox(width: 8), Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))])])); 
                    }).toList()))
                  : Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: teamProjects.map((p) { final progress = taskProv.projectProgress(p.id, teamId: teamProv.currentTeamId); return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)), const SizedBox(width: 12), SizedBox(width: 100, child: LinearProgressIndicator(value: progress, backgroundColor: Colors.black12, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary), minHeight: 8, borderRadius: BorderRadius.circular(99))), const SizedBox(width: 8), Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))])); }).toList()))),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: '오늘 업무', icon: Icons.checklist_rounded, isSwipe: _tasksSwipe, onToggleSwipe: () => setState(() => _tasksSwipe = !_tasksSwipe),
          child: _buildTasksView(taskProv, teamProv, _tasksSwipe),
        ),
      ],
    );
  }

  Widget _buildTasksView(TaskProvider taskProv, TeamProvider teamProv, bool isSwipe) {
    final today = DateTime.now();
    final tasks = taskProv.tasksForTeam(teamProv.currentTeamId).where((t) => t.dueDate.year == today.year && t.dueDate.month == today.month && t.dueDate.day == today.day).toList();
    if (tasks.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('오늘 마감 업무가 없습니다.', style: TextStyle(color: AppColors.hint))));
    
    if (isSwipe) {
      return SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: tasks.map((t) => Container(width: 220, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t.title, style: const TextStyle(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text('기한: ${t.dueDate.month}/${t.dueDate.day}', style: const TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w800))]))).toList()));
    } else {
      return Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Column(children: tasks.map((t) => ListTile(dense: true, visualDensity: VisualDensity.compact, title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis), subtitle: Text('기한: ${t.dueDate.month}/${t.dueDate.day}', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)))).toList()));
    }
  }

  static Widget _card(BuildContext context, {required Widget child}) { return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))]), child: child); }

  void _showTeamPicker(BuildContext context, TeamProvider teamProv) {
    final teams = teamProv.teams;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) {
      return Container(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(22))), child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(99)))), const SizedBox(height: 12), const Text('팀 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)), const SizedBox(height: 12), if (teams.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('참여 중인 팀이 없습니다.', style: TextStyle(color: AppColors.text2))), if (teams.isNotEmpty) ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.55), child: ListView.separated(shrinkWrap: true, itemBuilder: (_, i) { final t = teams[i];
      final isCurrent = t.id == teamProv.currentTeamId; return ListTile(title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.text)), subtitle: Text('${t.memberIds.length}명', style: const TextStyle(color: AppColors.text2)), trailing: isCurrent ? const Icon(Icons.check_rounded, color: AppColors.primary) : null, onTap: () { teamProv.switchTeam(t.id); Navigator.pop(ctx); });
      }, separatorBuilder: (_, __) => const Divider(height: 1), itemCount: teams.length))])));
    });
  }

  void _showMemberProfileSheet(BuildContext context, {required AppUser member, required String? role, required String myId}) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 24),
            CircleAvatar(radius: 46, backgroundColor: AppColors.primary.withValues(alpha: 0.12), child: Text(member.profileImage ?? '👤', style: const TextStyle(fontSize: 40))),
            const SizedBox(height: 16),
            Text(member.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.text)),
            const SizedBox(height: 4),
            Text(role == null || role.trim().isEmpty ? '팀원' : role, style: const TextStyle(fontSize: 14, color: AppColors.text2, fontWeight: FontWeight.w600)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton.icon(
                onPressed: () { 
                  final teamProv = context.read<TeamProvider>(); final chatProv = context.read<ChatProvider>(); 
                  final dmId = chatProv.dmThreadId(teamProv.currentTeamId, myId, member.id); 
                  chatProv.setActiveThread(dmId, title: 'DM · ${member.name}'); 
                  Navigator.pop(ctx); 
                  widget.onOpenChatThread(dmId, 'DM · ${member.name}'); 
                }, 
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), 
                icon: const Icon(Icons.send_rounded), 
                label: const Text('메시지 보내기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900))
              )
            )
          ]
        )
      );
    });
  }
}

class _MiniBtn extends StatelessWidget {
  final String text; final IconData icon; final bool isActive; final VoidCallback onTap;
  const _MiniBtn({required this.text, required this.icon, required this.isActive, required this.onTap});
  @override Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: isActive ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: isActive ? AppColors.primary : AppColors.border)),
        child: Row(children: [Icon(icon, size: 14, color: isActive ? Colors.white : AppColors.text2), const SizedBox(width: 4), Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isActive ? Colors.white : AppColors.text2))]),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title; final IconData icon; final bool isSwipe; final VoidCallback onToggleSwipe; final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.isSwipe, required this.onToggleSwipe, required this.child});
  @override Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Row(children: [Icon(icon, size: 20, color: AppColors.primary), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)), const Spacer(), IconButton(icon: Icon(isSwipe ? Icons.view_agenda_rounded : Icons.view_carousel_rounded, size: 20, color: AppColors.text2), onPressed: onToggleSwipe, constraints: const BoxConstraints(), padding: EdgeInsets.zero)])),
          Padding(padding: const EdgeInsets.only(bottom: 12), child: child),
        ],
      ),
    );
  }
}

class _DashboardPagerCard extends StatefulWidget {
  final List<AppUser> members; final TeamProvider teamProv; final TaskProvider taskProv; final String meId; final List<Project> teamProjects; final Function(String, String?) onOpenChatThread;
  final bool membersSwipe; final bool projectsSwipe; final bool tasksSwipe;
  final VoidCallback onToggleMembers; final VoidCallback onToggleProjects; final VoidCallback onToggleTasks;

  const _DashboardPagerCard({required this.members, required this.teamProv, required this.taskProv, required this.meId, required this.teamProjects, required this.onOpenChatThread, required this.membersSwipe, required this.projectsSwipe, required this.tasksSwipe, required this.onToggleMembers, required this.onToggleProjects, required this.onToggleTasks});
  @override State<_DashboardPagerCard> createState() => _DashboardPagerCardState();
}
class _DashboardPagerCardState extends State<_DashboardPagerCard> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  
  @override Widget build(BuildContext context) {
    bool currentSwipe = _currentIndex == 0 ? widget.membersSwipe : (_currentIndex == 1 ? widget.projectsSwipe : widget.tasksSwipe);
    VoidCallback currentToggle = _currentIndex == 0 ? widget.onToggleMembers : (_currentIndex == 1 ? widget.onToggleProjects : widget.onToggleTasks);

    return Container(
      height: 310, 
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))]), 
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), 
          child: Row(children: [
            Text(['팀원', '프로젝트', '오늘 업무'][_currentIndex], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)), 
            const Spacer(), 
            IconButton(icon: Icon(currentSwipe ? Icons.view_agenda_rounded : Icons.view_carousel_rounded, size: 20, color: AppColors.text2), onPressed: currentToggle, constraints: const BoxConstraints(), padding: EdgeInsets.zero),
            const SizedBox(width: 12),
            _buildTabButton(0, Icons.people_alt_rounded), const SizedBox(width: 8), 
            _buildTabButton(1, Icons.domain_rounded), const SizedBox(width: 8), 
            _buildTabButton(2, Icons.checklist_rounded)
          ])
        ), 
        const Divider(height: 1, color: AppColors.border), 
        Expanded(
          child: PageView(
            controller: _pageController, 
            physics: currentSwipe ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
            onPageChanged: (idx) => setState(() => _currentIndex = idx), 
            children: [_buildMembersView(), _buildProjectsView(), _buildTodayTasksView()]
          )
        )
      ])
    );
  }
  
  Widget _buildTabButton(int index, IconData icon) { final isActive = _currentIndex == index; return GestureDetector(onTap: () { _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); }, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: isActive ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: isActive ? AppColors.primary : AppColors.border)), child: Icon(icon, size: 16, color: isActive ? Colors.white : AppColors.text2))); }
  
  Widget _buildMembersView() => widget.membersSwipe 
      ? SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(16), child: Row(children: widget.members.map((m) => Padding(padding: const EdgeInsets.only(right: 12), child: _MemberAvatar(user: m, isMe: m.id == widget.meId, role: widget.teamProv.currentTeam.memberRoles[m.id], onTap: () => context.findAncestorStateOfType<_HomeTabState>()?._showMemberProfileSheet(context, member: m, role: widget.teamProv.currentTeam.memberRoles[m.id], myId: widget.meId)))).toList()))
      : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Wrap(spacing: 12, runSpacing: 12, children: [for (final m in widget.members) _MemberAvatar(user: m, isMe: m.id == widget.meId, role: widget.teamProv.currentTeam.memberRoles[m.id], onTap: () => context.findAncestorStateOfType<_HomeTabState>()?._showMemberProfileSheet(context, member: m, role: widget.teamProv.currentTeam.memberRoles[m.id], myId: widget.meId))]));
  
  Widget _buildProjectsView() => widget.projectsSwipe
      ? SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(16), child: Row(children: widget.teamProjects.map((p) { final progress = widget.taskProv.projectProgress(p.id, teamId: widget.teamProv.currentTeamId); return Container(width: 200, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis), const SizedBox(height: 8), Row(children: [Expanded(child: LinearProgressIndicator(value: progress, backgroundColor: Colors.black12, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary), minHeight: 6, borderRadius: BorderRadius.circular(99))), const SizedBox(width: 8), Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))])])); }).toList()))
      : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [...widget.teamProjects.map((p) { final progress = widget.taskProv.projectProgress(p.id, teamId: widget.teamProv.currentTeamId); return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)), const SizedBox(width: 12), SizedBox(width: 100, child: LinearProgressIndicator(value: progress, backgroundColor: Colors.black12, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary), minHeight: 8, borderRadius: BorderRadius.circular(99))), const SizedBox(width: 8), Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))])); }), if (widget.teamProjects.isEmpty) const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text('프로젝트가 없습니다.', style: TextStyle(color: AppColors.hint))))]));
  
  Widget _buildTodayTasksView() { 
    final today = DateTime.now(); final tasks = widget.taskProv.tasksForTeam(widget.teamProv.currentTeamId).where((t) => t.dueDate.year == today.year && t.dueDate.month == today.month && t.dueDate.day == today.day).toList(); if (tasks.isEmpty) return const Center(child: Text('오늘 마감 업무가 없습니다.', style: TextStyle(color: AppColors.hint))); 
    return widget.tasksSwipe
        ? SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(16), child: Row(children: tasks.map((t) => Container(width: 220, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t.title, style: const TextStyle(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text('기한: ${t.dueDate.month}/${t.dueDate.day}', style: const TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w800))]))).toList()))
        : ListView.builder(padding: const EdgeInsets.all(8), itemCount: tasks.length > 5 ? 5 : tasks.length, itemBuilder: (ctx, i) => ListTile(dense: true, title: Text(tasks[i].title, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis), subtitle: Text('기한: ${tasks[i].dueDate.month}/${tasks[i].dueDate.day}', style: const TextStyle(color: AppColors.danger)))); 
  }
}

class _ProfileAvatarWithTeamBadge extends StatelessWidget { final String emoji; final String teamInitial; const _ProfileAvatarWithTeamBadge({required this.emoji, required this.teamInitial}); @override Widget build(BuildContext context) { return Stack(clipBehavior: Clip.none, children: [CircleAvatar(radius: 22, backgroundColor: AppColors.primary.withValues(alpha: 0.12), child: Text(emoji, style: const TextStyle(fontSize: 20))), Positioned(right: -2, bottom: -2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white, width: 2)), child: Text(teamInitial, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900))))]); } }
class _MemberAvatar extends StatelessWidget { final AppUser user; final bool isMe; final String? role; final VoidCallback onTap; const _MemberAvatar({required this.user, required this.isMe, required this.role, required this.onTap}); @override Widget build(BuildContext context) { return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Column(mainAxisSize: MainAxisSize.min, children: [Stack(clipBehavior: Clip.none, children: [CircleAvatar(radius: 26, backgroundColor: AppColors.primary.withValues(alpha: 0.12), child: Text(user.profileImage ?? '👤', style: const TextStyle(fontSize: 24))), if (isMe) Positioned(right: -2, top: -2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white, width: 2)), child: const Text('나', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))))]), const SizedBox(height: 8), SizedBox(width: 66, child: Text(user.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.text), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)), if (role != null && role!.trim().isNotEmpty) SizedBox(width: 66, child: Text(role!, style: const TextStyle(fontSize: 10, color: AppColors.text2, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center))])); } }
