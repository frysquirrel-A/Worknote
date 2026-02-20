import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';
import 'package:worknote/features/chat/state/chat_provider.dart';
import 'package:worknote/app/widgets/master_drawer.dart';

import 'package:worknote/features/home/ui/home_tab.dart';
import 'package:worknote/features/tasks/ui/task_tab.dart';
import 'package:worknote/features/schedule/ui/schedule_tab.dart';
import 'package:worknote/features/journal/ui/journal_tab.dart';
import 'package:worknote/features/gallery/ui/gallery_tab.dart';
import 'package:worknote/features/chat/ui/messenger_tab.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _didMigrateLegacy = false;

  void _openChatThread(String threadId, String? title) {
    context.read<ChatProvider>().setActiveThread(threadId, title: title ?? '채팅');
    setState(() => _selectedIndex = 5);
  }

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final authProv = context.watch<AuthProvider>();
    final myId = authProv.currentUser?.id ?? 'me';

    if (!_didMigrateLegacy && authProv.currentUser != null) {
      _didMigrateLegacy = true;
      Future.microtask(() => teamProv.migrateLegacyMeToUser(myId));
    }

    final List<Widget> tabs = [
      HomeTab(onOpenChatThread: _openChatThread),
      const TeamTaskTab(),
      const ScheduleTab(),
      const JournalTab(),
      const GalleryTab(),
      const MessengerTab(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_open_rounded, size: 28, color: Colors.black87),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          "WORKNOTE Master",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const MasterDrawer(),
      body: tabs[_selectedIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              // [요구사항 1, 2] 비활성 탭 색상 진하게 변경 및 활성 탭 유지
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12);
                }
                return const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 12);
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
              onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
              indicatorColor: const Color(0xFF2563EB).withValues(alpha: 0.08),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined, size: 22), label: '홈'),
                NavigationDestination(icon: Icon(Icons.check_circle_outline_rounded, size: 22), label: '업무'),
                NavigationDestination(icon: Icon(Icons.calendar_month_outlined, size: 22), label: '계획'),
                NavigationDestination(icon: Icon(Icons.edit_note_rounded, size: 22), label: '일지'),
                NavigationDestination(icon: Icon(Icons.photo_library_outlined, size: 22), label: '사진'),
                NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded, size: 22), label: '소통'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
