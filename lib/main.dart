import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);

  // 1. Hive 초기화 (가장 먼저 실행)
  await Hive.initFlutter();
  
  // [중요] deleteFromDisk() 코드는 삭제했습니다. (앱 삭제로 대체함)

  // 2. 어댑터 등록
  Hive.registerAdapter(TaskPriorityAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(ProjectAdapter());
  Hive.registerAdapter(JournalEntryAdapter());
  Hive.registerAdapter(TeamAdapter());
  Hive.registerAdapter(AppUserAdapter());
  Hive.registerAdapter(ChatMessageAdapter());

  // 3. 박스 열기 (데이터베이스 로드)
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
    final authProv = context.watch<AuthProvider>();
    final teamProv = context.watch<TeamProvider>();

    // 테마 설정
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      primaryColor: const Color(0xFF3B82F6),
      cardColor: const Color(0xFF1E293B),
      useMaterial3: true,
      textTheme: GoogleFonts.notoSansKrTextTheme(ThemeData.dark().textTheme),
    );

    final lightTheme = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: const Color(0xFF3B82F6),
      cardColor: Colors.white,
      useMaterial3: true,
      textTheme: GoogleFonts.notoSansKrTextTheme(ThemeData.light().textTheme),
    );

    final blueTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF102A43),
      primaryColor: const Color(0xFF40C4FF),
      cardColor: const Color(0xFF243B53),
      useMaterial3: true,
      textTheme: GoogleFonts.notoSansKrTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: const Color(0xFFD9E2EC),
        displayColor: Colors.white,
      ),
    );

    ThemeData selectedTheme;
    if (teamProv.currentThemeMode == 'light') selectedTheme = lightTheme;
    else if (teamProv.currentThemeMode == 'blue') selectedTheme = blueTheme;
    else selectedTheme = darkTheme;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WorkNote',
      theme: selectedTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
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
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.8)),
              accountName: Row(
                children: [
                  Text("${authProv.currentUser?.name} ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  GestureDetector(
                    onTap: () => _showEditNameDialog(context, authProv),
                    child: const Icon(Icons.edit, size: 16, color: Colors.white70),
                  )
                ],
              ),
              accountEmail: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("팀 직책: ${teamProv.getMyRole(myId)}", style: const TextStyle(color: Colors.white70)),
                  GestureDetector(
                    onTap: () => _showEditRoleDialog(context, teamProv, myId),
                    child: const Text("직책 변경 >", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              currentAccountPicture: CircleAvatar(backgroundColor: Colors.white, child: Text(authProv.currentUser?.name[0] ?? "나", style: TextStyle(fontSize: 24, color: Theme.of(context).primaryColor))),
            ),
            
            ExpansionTile(
              leading: const Icon(Icons.palette),
              title: const Text("앱 테마 설정"),
              children: [
                ListTile(title: const Text("다크 모드 (기본)"), leading: const Icon(Icons.dark_mode), onTap: () => teamProv.changeTheme('dark')),
                ListTile(title: const Text("화이트 모드"), leading: const Icon(Icons.light_mode), onTap: () => teamProv.changeTheme('light')),
                ListTile(title: const Text("블루 모드"), leading: const Icon(Icons.water_drop), onTap: () => teamProv.changeTheme('blue')),
              ],
            ),
            
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  const Padding(padding: EdgeInsets.all(16), child: Text("내 팀 목록", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                  ...teamProv.teams.map((t) => ListTile(
                    leading: Icon(Icons.group_work, color: t.id == teamProv.currentTeamId ? Theme.of(context).primaryColor : Colors.grey),
                    title: Text(t.name),
                    onTap: () {
                      teamProv.switchTeam(t.id);
                      Navigator.pop(context);
                    },
                  )),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text("새 팀 만들기"),
                    onTap: () => _showCreateTeamDialog(context, teamProv, myId),
                  ),
                  ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text("초대 코드로 팀 참여"),
                    onTap: () => _showJoinTeamDialog(context, teamProv),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(icon: Icon(Icons.menu, color: Theme.of(context).textTheme.bodyLarge?.color), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
                  const SizedBox(width: 8),
                  Text(teamProv.currentTeam.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(child: _tabs[_selectedIndex]),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: '홈'),
          NavigationDestination(icon: Icon(Icons.check_circle_outline), label: '업무'),
          NavigationDestination(icon: Icon(Icons.book_outlined), label: '일지'),
          NavigationDestination(icon: Icon(Icons.photo_library_outlined), label: '사진'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: '소통'),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, AuthProvider prov) {
    final ctrl = TextEditingController(text: prov.currentUser?.name);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("이름 변경"),
      content: TextField(controller: ctrl),
      actions: [
        ElevatedButton(onPressed: () { 
          prov.updateName(ctrl.text); 
          if (context.mounted) Navigator.pop(ctx);
        }, child: const Text("저장")),
      ],
    ));
  }

  void _showEditRoleDialog(BuildContext context, TeamProvider prov, String myId) {
    final ctrl = TextEditingController(text: prov.getMyRole(myId));
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("이 팀에서의 직책 변경"),
      content: TextField(controller: ctrl),
      actions: [
        ElevatedButton(onPressed: () { 
          prov.updateMyRole(myId, ctrl.text); 
          if (context.mounted) Navigator.pop(ctx);
        }, child: const Text("저장")),
      ],
    ));
  }

  void _showCreateTeamDialog(BuildContext context, TeamProvider prov, String myId) {
     final ctrl = TextEditingController();
     final roleCtrl = TextEditingController(text: '관리자');
     showDialog(context: context, builder: (ctx) => AlertDialog(
       title: const Text("새 팀 생성"),
       content: Column(
         mainAxisSize: MainAxisSize.min,
         children: [
           TextField(controller: ctrl, decoration: const InputDecoration(labelText: "팀 이름")),
           TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: "내 직책 (예: 팀장)")),
         ],
       ),
       actions: [
         ElevatedButton(onPressed: () {
           if(ctrl.text.isNotEmpty) {
             prov.createTeam(ctrl.text, roleCtrl.text);
           }
           if (context.mounted) Navigator.pop(ctx);
         }, child: const Text("생성")),
       ],
     ));
  }

  void _showJoinTeamDialog(BuildContext context, TeamProvider prov) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("팀 참여하기"),
      content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "초대 코드 입력")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
        ElevatedButton(onPressed: () async {
          if(ctrl.text.isNotEmpty) {
            bool success = await prov.joinTeam(ctrl.text, 'me'); 
             if (context.mounted) Navigator.pop(ctx);
             if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("팀을 찾을 수 없습니다.")));
             }
          }
        }, child: const Text("참여")),
      ],
    ));
  }
}