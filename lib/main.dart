import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart'; 
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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WorkNote',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF3B82F6),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansKrTextTheme(ThemeData.dark().textTheme),
      ),
      home: authProv.currentUser == null ? const LoginPage() : const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
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

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1E1B4B)),
              accountName: Text(teamProv.currentTeam.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: Text("초대코드: ${teamProv.currentTeam.inviteCode}", style: const TextStyle(color: Colors.blueAccent)),
              currentAccountPicture: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.hub, color: Colors.white, size: 40)),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Padding(padding: EdgeInsets.all(16), child: Text("내 팀 목록", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                  ...teamProv.teams.map((t) => ListTile(
                    leading: Icon(Icons.group_work, color: t.id == teamProv.currentTeamId ? Colors.blue : Colors.grey),
                    title: Text(t.name),
                    onTap: () {
                      teamProv.switchTeam(t.id);
                      Navigator.pop(context);
                    },
                  )),
                  ListTile(
                    leading: const Icon(Icons.add, color: Colors.blue),
                    title: const Text("새 팀 만들기", style: TextStyle(color: Colors.blue)),
                    onTap: () => _showCreateTeamDialog(context, teamProv),
                  ),
                  const Divider(color: Colors.white10),
                  const Padding(padding: EdgeInsets.all(16), child: Text("팀원 목록", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                  ...teamProv.currentTeam.memberIds.map((m) => ListTile(
                    leading: const CircleAvatar(radius: 12, child: Text("👤", style: TextStyle(fontSize: 12))),
                    title: Text(m, style: const TextStyle(fontSize: 14)),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)], 
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    const SizedBox(width: 8),
                    Text(teamProv.currentTeam.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              Expanded(child: _tabs[_selectedIndex]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.9), 
          border: const Border(top: BorderSide(color: Colors.white10)),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
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
      ),
    );
  }

  void _showCreateTeamDialog(BuildContext context, TeamProvider prov) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text("새 팀 생성"),
      content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "팀 이름을 입력하세요")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
        ElevatedButton(onPressed: () {
          if(ctrl.text.isNotEmpty) prov.createTeam(ctrl.text);
          Navigator.pop(ctx);
        }, child: const Text("생성")),
      ],
    ));
  }
}
