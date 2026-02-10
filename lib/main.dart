import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:hive_flutter/hive_flutter.dart';

import 'models.dart'; 
import 'data/hive_adapters.dart'; 

import 'providers/team_provider.dart';
import 'providers/task_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/journal_provider.dart'; 
import 'providers/chat_provider.dart';    
import 'pages/login_page.dart';
import 'tabs/home_tab.dart';
import 'tabs/task_tab.dart'; 
import 'tabs/messenger_tab.dart';
import 'tabs/journal_tab.dart'; 
import 'tabs/gallery_tab.dart'; 
import 'tabs/schedule_tab.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);

  await Hive.initFlutter();
  
  Hive.registerAdapter(TaskPriorityAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(ProjectAdapter());
  Hive.registerAdapter(JournalEntryAdapter());
  Hive.registerAdapter(TeamAdapter());
  Hive.registerAdapter(AppUserAdapter());
  Hive.registerAdapter(ChatMessageAdapter());

  await Hive.openBox('settings');
  await Hive.openBox<Task>('tasks');
  await Hive.openBox<Project>('projects');
  await Hive.openBox<JournalEntry>('journals');
  await Hive.openBox<Team>('teams');
  await Hive.openBox<AppUser>('users');
  await Hive.openBox<ChatMessage>('messages');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TeamProvider()..loadTeams()),
        ChangeNotifierProvider(create: (_) => TaskProvider()..loadData()),
        ChangeNotifierProvider(create: (_) => AuthProvider()), 
        ChangeNotifierProvider(create: (_) => JournalProvider()..loadJournals()), 
        ChangeNotifierProvider(create: (_) => ChatProvider()),    
      ],
      child: const WorkNoteApp(),
    ),
  );
}

class WorkNoteApp extends StatelessWidget {
  const WorkNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2월 2일 마스터피스 폰트 테마
    final masterpieceTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC), 
      primaryColor: const Color(0xFF2563EB), 
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.notoSansKrTextTheme().copyWith(
        displayLarge: const TextStyle(fontWeight: FontWeight.w900),
        titleLarge: const TextStyle(fontWeight: FontWeight.w900),
        bodyLarge: const TextStyle(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleTextStyle: TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        iconTheme: IconThemeData(color: Colors.black87),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WorkNote Master',
      theme: masterpieceTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      locale: const Locale('ko', 'KR'),
      home: context.watch<AuthProvider>().currentUser == null ? const LoginPage() : const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // [복구] 모든 탭 완벽 구성
  final List<Widget> _tabs = [
    const HomeTab(),
    const TeamTaskTab(),
    const ScheduleTab(), 
    const JournalTab(), 
    const GalleryTab(), 
    const MessengerTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final authProv = context.watch<AuthProvider>();
    final myId = authProv.currentUser?.id ?? 'me';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
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
      // [복구] 사이드바 (Drawer)
      drawer: _buildMasterDrawer(context, teamProv, authProv),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 25, offset: const Offset(0, -5))],
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
          indicatorColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF2563EB)), label: '홈'),
            NavigationDestination(icon: Icon(Icons.check_circle_outline_rounded), selectedIcon: Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB)), label: '업무'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB)), label: '스케줄'),
            NavigationDestination(icon: Icon(Icons.edit_note_rounded), selectedIcon: Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB)), label: '일지'),
            NavigationDestination(icon: Icon(Icons.photo_library_outlined), selectedIcon: Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB)), label: '사진'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded, color: Color(0xFF2563EB)), label: '소통'),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterDrawer(BuildContext context, TeamProvider teamProv, AuthProvider authProv) {
    final myId = authProv.currentUser?.id ?? 'me';
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(32), bottomRight: Radius.circular(32))),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
            currentAccountPicture: GestureDetector(
              onTap: () => _showAvatarPicker(context, authProv),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF2563EB),
                child: Text(authProv.currentUser?.name[0] ?? "나", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ),
            accountName: Row(
              children: [
                Text(authProv.currentUser?.name ?? "사용자", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showEditNameDialog(context, authProv),
                  child: const Icon(Icons.edit_rounded, size: 16, color: Colors.blueAccent),
                ),
              ],
            ),
            accountEmail: Text("직책: ${teamProv.getMyRole(myId)}", style: const TextStyle(color: Colors.grey)),
          ),
          _drawerItem(Icons.cloud_sync_rounded, "구글 드라이브 연동", () async {
            if (!authProv.isGoogleLinked) {
              final success = await authProv.connectGoogleDrive();
              if (success && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("연동 성공!")));
            }
          }, color: authProv.isGoogleLinked ? Colors.green : null),
          _drawerItem(Icons.palette_outlined, "테마 설정", () => _showThemeDialog(context, teamProv)),
          const Divider(indent: 20, endIndent: 20),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(padding: EdgeInsets.fromLTRB(24, 16, 24, 8), child: Text("내 팀 목록", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),
                ...teamProv.teams.map((t) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(Icons.hub_rounded, color: t.id == teamProv.currentTeamId ? const Color(0xFF2563EB) : Colors.grey, size: 20),
                  title: Text(t.name, style: TextStyle(fontWeight: t.id == teamProv.currentTeamId ? FontWeight.bold : FontWeight.normal)),
                  onTap: () {
                    teamProv.switchTeam(t.id);
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
          ),
          _drawerItem(Icons.logout_rounded, "로그아웃", () => authProv.logout(), color: Colors.redAccent),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: color ?? Colors.black54),
      title: Text(title, style: TextStyle(color: color ?? Colors.black87, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  void _showEditNameDialog(BuildContext context, AuthProvider prov) {
    final ctrl = TextEditingController(text: prov.currentUser?.name);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("이름 변경"),
      content: TextField(controller: ctrl),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
        ElevatedButton(onPressed: () { prov.updateName(ctrl.text); Navigator.pop(ctx); }, child: const Text("저장")),
      ],
    ));
  }

  void _showAvatarPicker(BuildContext context, AuthProvider authProv) {
    final avatars = ["👷", "👨‍🔧", "👩‍🔬", "👨‍💻", "👩‍💼", "🦸"];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("캐릭터 선택", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 20, crossAxisSpacing: 20),
              itemCount: avatars.length,
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                },
                child: CircleAvatar(radius: 40, backgroundColor: const Color(0xFFF1F5F9), child: Text(avatars[i], style: const TextStyle(fontSize: 32))),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, TeamProvider prov) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("테마 선택"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: const Text("다크 모드"), onTap: () { prov.changeTheme('dark'); Navigator.pop(ctx); }),
          ListTile(title: const Text("화이트 모드"), onTap: () { prov.changeTheme('light'); Navigator.pop(ctx); }),
          ListTile(title: const Text("블루 모드"), onTap: () { prov.changeTheme('blue'); Navigator.pop(ctx); }),
        ],
      ),
    ));
  }
}
