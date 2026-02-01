import os

# 1. 폴더 구조 생성
os.makedirs('lib/tabs', exist_ok=True)

# 2. 파일별 코드 정의
files = {
    'lib/models.dart': """
import 'package:flutter/material.dart';

enum TaskPriority { high, medium, low, none }
enum AppTone { white, blue, black }
enum DateFilter { all, today, week, twoWeeks }
enum JournalGroupPeriod { day, week, month, quarter, year }

class Project {
  final String id;
  final String name;
  final Color color;
  Project({required this.id, required this.name, required this.color});
}

class TeamMember {
  final String id, name, emoji, role;
  TeamMember({required this.id, required this.name, required this.emoji, required this.role});
}

class Task {
  final String id;
  String title;
  final String assigneeId, assigneeName, assigneeEmoji;
  String projectId;
  final DateTime createdAt, dueDate;
  DateTime updatedAt;
  DateTime? completedAt;
  bool isDone;
  TaskPriority priority;
  List<String> taskNotes;
  String? completionReport;

  Task({
    required this.id, required this.title, required this.assigneeId,
    required this.assigneeName, required this.assigneeEmoji, required this.projectId,
    required this.createdAt, required this.dueDate, DateTime? updatedAt,
    this.completedAt, this.isDone = false, this.priority = TaskPriority.none,
    List<String>? taskNotes, this.completionReport,
  }) : taskNotes = taskNotes ?? [], updatedAt = updatedAt ?? createdAt;
}

class JournalEntry {
  final String id, userId, userName, title, content;
  String? projectId;
  final DateTime date;
  final List<String> photos;
  bool isPrivate;

  JournalEntry({
    required this.id, required this.userId, required this.userName,
    required this.title, required this.content, this.projectId,
    required this.date, required this.photos, this.isPrivate = false,
  });
}
""",
    'lib/tabs/task_tab.dart': """
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';

class TeamTaskTab extends StatefulWidget {
  final List<Task> tasks;
  final List<Project> projects;
  final List<TeamMember> members;
  final Function(Task) onAddTask;
  final Function(Project) onAddProject;
  final VoidCallback onStateChange;
  final AppTone tone;

  const TeamTaskTab({super.key, required this.tasks, required this.projects, required this.members, required this.onAddTask, required this.onAddProject, required this.onStateChange, required this.tone});

  @override
  State<TeamTaskTab> createState() => _TeamTaskTabState();
}

class _TeamTaskTabState extends State<TeamTaskTab> {
  void _showAddTaskDialog() {
    final titleCtrl = TextEditingController();
    Project? selectedProject;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("새 업무 추가"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Autocomplete<Project>(
                displayStringForOption: (p) => "#${p.name}",
                optionsBuilder: (textValue) {
                  if (!textValue.text.contains('#')) return const Iterable<Project>.empty();
                  final search = textValue.text.split('#').last.toLowerCase();
                  return widget.projects.where((p) => p.name.toLowerCase().contains(search));
                },
                onSelected: (p) {
                  final current = titleCtrl.text;
                  final hashIdx = current.lastIndexOf('#');
                  if (hashIdx != -1) titleCtrl.text = current.substring(0, hashIdx).trim();
                  setDialogState(() => selectedProject = p);
                },
                fieldViewBuilder: (ctx, ctrl, focus, onFieldSubmitted) {
                  ctrl.addListener(() { titleCtrl.text = ctrl.text; });
                  return TextField(controller: ctrl, focusNode: focus, decoration: const InputDecoration(labelText: "제목 (#프로젝트)"));
                },
              ),
            ],
          ),
          actions: [
            FilledButton(onPressed: () {
              if (titleCtrl.text.isEmpty) return;
              widget.onAddTask(Task(
                id: DateTime.now().toString(), title: titleCtrl.text,
                assigneeId: 'me', assigneeName: '나', assigneeEmoji: '👩‍💻',
                projectId: selectedProject?.id ?? widget.projects.first.id,
                createdAt: DateTime.now(), dueDate: selectedDate,
              ));
              Navigator.pop(context);
            }, child: const Text("추가"))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: widget.tasks.length,
        itemBuilder: (context, index) => ListTile(title: Text(widget.tasks[index].title)),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddTaskDialog, child: const Icon(Icons.add)),
    );
  }
}
""",
    'lib/main.dart': """
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models.dart';
import 'tabs/task_tab.dart';

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
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
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
  List<Task> _tasks = [];
  List<Project> _projects = [Project(id: 'p1', name: 'A동 신축', color: Colors.blue)];
  List<TeamMember> _members = [TeamMember(id: 'me', name: '나', emoji: '👩‍💻', role: '총괄')];

  @override
  Widget build(BuildContext context) {
    final screens = [
      const Center(child: Text("홈")),
      TeamTaskTab(tasks: _tasks, projects: _projects, members: _members, onAddTask: (t)=>setState(()=>_tasks.add(t)), onAddProject: (p)=>setState(()=>_projects.add(p)), onStateChange: ()=>setState((){}), tone: AppTone.white),
      const Center(child: Text("일지")),
      const Center(child: Text("갤러리")),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: '홈'),
          NavigationDestination(icon: Icon(Icons.assignment), label: '업무'),
          NavigationDestination(icon: Icon(Icons.edit_note), label: '일지'),
          NavigationDestination(icon: Icon(Icons.photo_library), label: '갤러리'),
        ],
      ),
    );
  }
}
"""
}

for path, content in files.items():
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content.strip())
    print(f"✅ 생성 완료: {path}")