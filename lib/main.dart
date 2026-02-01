import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models.dart';
import 'tabs/home_tab.dart';
import 'tabs/task_tab.dart';
import 'tabs/journal_tab.dart';
import 'tabs/gallery_tab.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  runApp(const WorkNoteApp());
}

class WorkNoteApp extends StatelessWidget {
  const WorkNoteApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WorkNote Master',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2563EB),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF1E293B), 
            fontSize: 22, 
            fontWeight: FontWeight.w900, 
            fontStyle: FontStyle.italic
          ),
        ),
      ),
      home: const MainScreen(),
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
  final List<Task> _tasks = [];
  final List<JournalEntry> _journals = [];
  final List<Project> _projects = [];
  final List<TeamMember> _members = [
    TeamMember(id: 'me', name: '나', emoji: '👷', role: '현장 총괄'),
    TeamMember(id: 'kim', name: '김반장', emoji: '👨‍🔧', role: '설비 팀장'),
  ];
  DateTime? _targetGalleryDate;

  @override
  void initState() {
    super.initState();
    _projects.addAll([
      Project(id: 'p1', name: 'A동 아파트 신축', color: Colors.blue),
      Project(id: 'p2', name: 'B동 설비 보수', color: Colors.orange),
    ]);
    _tasks.add(Task(
      id: 't1', title: '배관 누수 긴급 점검', assigneeId: 'me', assigneeName: '나',
      assigneeEmoji: '👷', projectId: 'p1', createdAt: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 1)), priority: TaskPriority.high,
    ));
  }

  void _onStateChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeTab(tasks: _tasks, projects: _projects, members: _members, tone: AppTone.white),
      TeamTaskTab(
        tasks: _tasks, projects: _projects, members: _members,
        onAddTask: (t) => setState(() => _tasks.add(t)),
        onAddProject: (p) => setState(() => _projects.add(p)),
        onStateChange: _onStateChange,
        tone: AppTone.white,
      ),
      JournalTab(
        journals: _journals, projects: _projects, members: _members,
        onSaveJournal: (j) => setState(() => _journals.insert(0, j)),
        onPhotoTap: (d) => setState(() { _targetGalleryDate = d; _selectedIndex = 3; }),
        tone: AppTone.white,
      ),
      GalleryTab(
        journals: _journals, members: _members, targetDate: _targetGalleryDate,
        onTargetDateHandled: () => _targetGalleryDate = null,
        tone: AppTone.white,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('WORKNOTE Master'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: '업무'),
          NavigationDestination(icon: Icon(Icons.edit_note_outlined), selectedIcon: Icon(Icons.edit_note), label: '일지'),
          NavigationDestination(icon: Icon(Icons.photo_library_outlined), selectedIcon: Icon(Icons.photo_library), label: '갤러리'),
        ],
      ),
    );
  }
}
