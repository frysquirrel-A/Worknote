import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';
import 'package:worknote/app/widgets/master_drawer.dart';

import 'package:worknote/features/home/ui/home_tab.dart';
import 'package:worknote/features/tasks/ui/task_tab.dart';
import 'package:worknote/features/schedule/ui/schedule_tab.dart';
import 'package:worknote/features/journal/ui/journal_tab.dart';
import 'package:worknote/features/gallery/ui/gallery_tab.dart';
import 'package:worknote/features/chat/ui/messenger_tab.dart';
import 'package:worknote/core/ui/app_palette.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _didMigrateLegacy = false;

  final List<Widget> _tabs = const [
    HomeTab(),
    TeamTaskTab(),
    ScheduleTab(),
    JournalTab(),
    GalleryTab(),
    MessengerTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final authProv = context.watch<AuthProvider>();
    final myId = authProv.currentUser?.id ?? 'me';

    if (!_didMigrateLegacy && authProv.currentUser != null) {
      _didMigrateLegacy = true;
      Future.microtask(() => teamProv.migrateLegacyMeToUser(myId));
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppPalette.shellBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_open_rounded, size: 30),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text("WORKNOTE Master"),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_active_outlined), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const MasterDrawer(),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(top: 6, bottom: bottomInset > 0 ? bottomInset : 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
          indicatorColor: AppPalette.primary.withValues(alpha: 0.12),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: '홈'),
            NavigationDestination(icon: Icon(Icons.check_circle_outline_rounded), selectedIcon: Icon(Icons.check_circle_rounded), label: '업무'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: '일정'),
            NavigationDestination(icon: Icon(Icons.edit_note_rounded), selectedIcon: Icon(Icons.edit_note_rounded), label: '일지'),
            NavigationDestination(icon: Icon(Icons.photo_library_outlined), selectedIcon: Icon(Icons.photo_library_rounded), label: '사진'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded), label: '소통'),
          ],
        ),
      ),
    );
  }
}
