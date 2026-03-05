import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:worknote/app/widgets/master_drawer.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/auth/ui/profile_selection_page.dart';
import 'package:worknote/features/chat/state/chat_provider.dart';
import 'package:worknote/features/chat/ui/messenger_tab.dart';
import 'package:worknote/features/gallery/ui/gallery_tab.dart';
import 'package:worknote/features/home/ui/home_tab.dart';
import 'package:worknote/features/journal/ui/journal_tab.dart';
import 'package:worknote/features/schedule/ui/schedule_tab.dart';
import 'package:worknote/features/tasks/ui/task_tab.dart';
import 'package:worknote/features/team/state/team_provider.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AuthProvider? _authProv;
  TeamProvider? _teamProv;
  String? _lastSyncedUserId;
  late final List<Widget> _tabs;

  void _openChatThread(String threadId, String? title) {
    context.read<ChatProvider>().setActiveThread(
      threadId,
      title: title ?? 'Chat',
    );
    setState(() => _selectedIndex = 5);
  }

  @override
  void initState() {
    super.initState();
    _tabs = [
      HomeTab(onOpenChatThread: _openChatThread),
      const TeamTaskTab(),
      const ScheduleTab(),
      const JournalTab(),
      const GalleryTab(),
      const MessengerTab(),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _teamProv ??= context.read<TeamProvider>();

    final auth = context.read<AuthProvider>();
    if (_authProv != auth) {
      _authProv?.removeListener(_syncForActiveUser);
      _authProv = auth;
      _authProv?.addListener(_syncForActiveUser);
    }

    _syncForActiveUser();
  }

  void _syncForActiveUser() {
    final user = _authProv?.currentUser;
    final myId = user?.id;
    if (myId == null || myId == _lastSyncedUserId) return;

    _lastSyncedUserId = myId;
    Future.microtask(() async {
      await _teamProv?.migrateLegacyMeToUser(myId);
      await _teamProv?.ensureCurrentUserMembership(myId, defaultRole: 'admin');
    });
  }

  @override
  void dispose() {
    _authProv?.removeListener(_syncForActiveUser);
    super.dispose();
  }

  void _openProfileManager() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: const ProfileSelectionPage(manageMode: true),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentName = context.select<AuthProvider, String>(
      (p) => p.currentUser?.name ?? 'WORKNOTE Master',
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.menu_open_rounded,
            size: 28,
            color: Colors.black87,
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WORKNOTE Master',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            Text(
              currentName,
              style: const TextStyle(
                color: Colors.black45,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Switch profile',
            icon: const Icon(
              Icons.switch_account_rounded,
              color: Colors.black87,
            ),
            onPressed: _openProfileManager,
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.black87,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const MasterDrawer(),
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  );
                }
                return const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(color: Color(0xFF2563EB));
                }
                return const IconThemeData(color: Colors.black87);
              }),
            ),
            child: NavigationBar(
              height: 60,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) {
                if (_selectedIndex == idx) return;
                HapticFeedback.selectionClick();
                setState(() => _selectedIndex = idx);
              },
              indicatorColor: const Color(0xFF2563EB).withValues(alpha: 0.08),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined, size: 22),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.check_circle_outline_rounded, size: 22),
                  label: 'Tasks',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined, size: 22),
                  label: 'Schedule',
                ),
                NavigationDestination(
                  icon: Icon(Icons.edit_note_rounded, size: 22),
                  label: 'Journal',
                ),
                NavigationDestination(
                  icon: Icon(Icons.photo_library_outlined, size: 22),
                  label: 'Gallery',
                ),
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline_rounded, size: 22),
                  label: 'Chat',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
