import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'tabs/home_tab.dart';
import 'tabs/task_tab.dart'; 
import 'tabs/journal_tab.dart'; 
import 'tabs/gallery_tab.dart';
import 'tabs/messenger_tab.dart';

// Providers
import 'providers/team_provider.dart';
import 'providers/task_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/auth_provider.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadUsers()),
        ChangeNotifierProvider(create: (_) => TeamProvider()..loadTeams()),
        ChangeNotifierProvider(create: (_) => TaskProvider()..loadData()),
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
    final isDark = context.watch<TeamProvider>().isDarkMode;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WorkNote Master',
      theme: ThemeData(
        useMaterial3: true,
        brightness: isDark ? Brightness.dark : Brightness.light,
        colorSchemeSeed: const Color(0xFF2563EB),
        scaffoldBackgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
        appBarTheme: AppBarTheme(
          backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.w900),
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        ),
      ),
      home: authProv.isLoggedIn ? const MainScreen() : const LoginPage(),
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

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final isDark = teamProv.isDarkMode;

    final screens = [
      const HomeTab(),
      const TeamTaskTab(),
      const MessengerTab(),
      const JournalTab(), 
      const GalleryTab(), 
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('WORKNOTE', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(teamProv.currentTeam.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF2563EB)),
              accountName: const Text("관리자", style: TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text("팀 코드: ${teamProv.currentTeam.inviteCode}"),
              currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Text("👷", style: TextStyle(fontSize: 30))),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Padding(padding: EdgeInsets.all(16), child: Text("내 팀 목록", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                  ...teamProv.teams.map((t) => ListTile(
                    leading: Icon(Icons.group_work, color: t.id == teamProv.currentTeamId ? Colors.blue : Colors.grey),
                    title: Text(t.name, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                    trailing: t.id == teamProv.currentTeamId ? const Icon(Icons.check, color: Colors.blue) : null,
                    onTap: () {
                      teamProv.switchTeam(t.id);
                      Navigator.pop(context);
                    },
                  )),
                  ListTile(
                    leading: const Icon(Icons.add, color: Colors.blue),
                    title: const Text("새 팀 만들기", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    onTap: () {
                       showDialog(context: context, builder: (ctx) => AlertDialog(
                         title: const Text("새 팀 생성"),
                         content: TextField(onSubmitted: (v) {
                           if (v.trim().isNotEmpty) {
                             teamProv.createTeam(v.trim());
                           }
                           Navigator.pop(ctx);
                           Navigator.pop(context);
                         }),
                       ));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), label: '업무'),
          NavigationDestination(icon: Icon(Icons.forum_outlined), label: '메신저'),
          NavigationDestination(icon: Icon(Icons.edit_note_outlined), label: '일지'),
          NavigationDestination(icon: Icon(Icons.photo_library_outlined), label: '갤러리'),
        ],
      ),
    );
  }
}
