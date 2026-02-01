import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models.dart';
import 'logic/app_controller.dart';
import 'tabs/home_tab.dart';
import 'tabs/task_tab.dart';
import 'tabs/journal_tab.dart';
import 'tabs/gallery_tab.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  
  // 1. 앱의 유일한 전역 컨트롤러 생성
  final appController = AppController();
  
  runApp(WorkNoteApp(controller: appController));
}

class WorkNoteApp extends StatelessWidget {
  final AppController controller;
  const WorkNoteApp({super.key, required this.controller});

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
          titleTextStyle: TextStyle(color: Color(0xFF1E293B), fontSize: 22, fontWeight: FontWeight.w900),
        ),
      ),
      home: MainScreen(controller: controller),
    );
  }
}

class MainScreen extends StatefulWidget {
  final AppController controller;
  const MainScreen({super.key, required this.controller});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  DateTime? _targetGalleryDate;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final screens = [
          HomeTab(
            tasks: widget.controller.tasks, 
            projects: widget.controller.projects, 
            members: widget.controller.members, 
            controller: widget.controller, // 누락된 파라미터 추가
            tone: AppTone.white
          ),
          TeamTaskTab(
            tasks: widget.controller.filteredTasks, 
            projects: widget.controller.projects, 
            members: widget.controller.members, 
            controller: widget.controller,
            tone: AppTone.white
          ),
          JournalTab(
            groupedJournals: widget.controller.groupedJournals, 
            projects: widget.controller.projects, 
            members: widget.controller.members,
            controller: widget.controller,
            onPhotoTap: (d) => setState(() { _targetGalleryDate = d; _selectedIndex = 3; }),
            tone: AppTone.white
          ),
          GalleryTab(
            journals: widget.controller.journals, 
            members: widget.controller.members,
            targetDate: _targetGalleryDate,
            onTargetDateHandled: () => _targetGalleryDate = null,
            tone: AppTone.white
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
    );
  }
}
