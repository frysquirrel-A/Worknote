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
    final teamProv = context.watch<TeamProvider>();
    final authProv = context.watch<AuthProvider>();

    final pixelDarkTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0E1A), 
      primaryColor: const Color(0xFF4D88FF), 
      cardColor: const Color(0xFF161C2C), 
      useMaterial3: true,
      textTheme: GoogleFonts.notoSansKrTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: Colors.white.withValues(alpha: 0.9),
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0A0E1A).withValues(alpha: 0.95),
        indicatorColor: const Color(0xFF4D88FF).withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WorkNote',
      theme: pixelDarkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      locale: const Locale('ko', 'KR'),
      home: authProv.currentUser == null ? const LoginPage() : const MainScreen(),
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

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildPixelDrawer(context, teamProv, authProv),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.8),
            radius: 1.5,
            colors: [Color(0xFF1A2235), Color(0xFF0A0E1A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.sort_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(teamProv.currentTeam.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                    const Spacer(),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(authProv.currentUser?.name[0] ?? "U", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Expanded(child: _tabs[_selectedIndex]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: '홈'),
          NavigationDestination(icon: Icon(Icons.assignment_rounded), label: '업무'),
          NavigationDestination(icon: Icon(Icons.calendar_today_rounded), label: '스케줄'),
          NavigationDestination(icon: Icon(Icons.auto_stories_rounded), label: '일지'),
          NavigationDestination(icon: Icon(Icons.photo_library_rounded), label: '사진'),
          NavigationDestination(icon: Icon(Icons.forum_rounded), label: '소통'),
        ],
      ),
    );
  }

  Widget _buildPixelDrawer(BuildContext context, TeamProvider teamProv, AuthProvider authProv) {
    final myId = authProv.currentUser?.id ?? 'me';
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: const Color(0xFF0A0E1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(32), bottomRight: Radius.circular(32))),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                CircleAvatar(radius: 35, backgroundColor: Theme.of(context).primaryColor, child: Text(authProv.currentUser?.name[0] ?? "U", style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold))),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(authProv.currentUser?.name ?? "사용자", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text("직책: ${teamProv.getMyRole(myId)}", style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _drawerItem(Icons.add_to_drive_rounded, "구글 드라이브 연동", () {}),
          _drawerItem(Icons.group_add_rounded, "초대 코드로 팀 참여", () {}),
          _drawerItem(Icons.add_business_rounded, "새 팀 만들기", () {}),
          
          _drawerItem(Icons.refresh_rounded, "시스템 초기화 (Reset)", () => _showResetDialog(context, teamProv.currentTeamId), color: Colors.orangeAccent),

          const Divider(color: Colors.white10, height: 40, indent: 24, endIndent: 24),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: teamProv.teams.map((t) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 32),
                leading: Icon(Icons.hub_rounded, color: t.id == teamProv.currentTeamId ? Theme.of(context).primaryColor : Colors.white24, size: 20),
                title: Text(t.name, style: TextStyle(color: t.id == teamProv.currentTeamId ? Colors.white : Colors.white.withValues(alpha: 0.5), fontWeight: t.id == teamProv.currentTeamId ? FontWeight.bold : FontWeight.normal)),
                onTap: () {
                  teamProv.switchTeam(t.id);
                  Navigator.pop(context);
                },
              )).toList(),
            ),
          ),
          _drawerItem(Icons.logout_rounded, "로그아웃", () => authProv.logout(), color: Colors.redAccent),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, String currentTeamId) {
    bool includeSample = true; // [복구] 상태 변수

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF161C2C),
          title: const Text("시스템 초기화", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("모든 로컬 데이터를 삭제하시겠습니까?", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              CheckboxListTile(
                title: const Text("샘플 데이터 포함", style: TextStyle(color: Colors.white)),
                value: includeSample,
                onChanged: (v) => setState(() => includeSample = v!),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.blueAccent,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (includeSample) {
                  // [복구] 태스크와 일지 모두 샘플 주입 초기화 실행
                  await context.read<TaskProvider>().resetSystem(currentTeamId);
                  await context.read<JournalProvider>().resetSystem(currentTeamId);
                } else {
                  // 순수 비우기
                  await Hive.box<Task>('tasks').clear();
                  await Hive.box<Project>('projects').clear();
                  await Hive.box<JournalEntry>('journals').clear();
                  await context.read<TaskProvider>().loadData();
                  await context.read<JournalProvider>().loadJournals();
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("시스템이 초기화되었습니다.")));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text("초기화 실행"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      leading: Icon(icon, color: color ?? Colors.white.withValues(alpha: 0.7), size: 22),
      title: Text(title, style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
      onTap: onTap,
    );
  }

  void _showEditNameDialog(BuildContext context, AuthProvider prov) {}
  void _showCreateTeamDialog(BuildContext context, TeamProvider prov, String myId) {}
  void _showJoinTeamDialog(BuildContext context, TeamProvider prov) {}
}