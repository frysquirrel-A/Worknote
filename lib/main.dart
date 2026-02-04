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
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()), 
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
      home: authProv.currentUser == null 
          ? const LoginPage() 
          : const MainScreen(),
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

  final List<Widget> _tabs = [
    const HomeTab(),
    const TeamTaskTab(),
    const JournalTab(), 
    const GalleryTab(), 
    const MessengerTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)], 
          ),
        ),
        child: SafeArea(child: _tabs[_selectedIndex]),
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
}