import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  runApp(const WorkNoteApp());
}

// =============================================================================
// [COMMON] Data Models & Enums
// =============================================================================
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
  final String id;
  final String name;
  final String emoji;
  final String role;
  TeamMember({required this.id, required this.name, required this.emoji, required this.role});
}

class Task {
  final String id;
  String title;
  final String assigneeId;
  final String assigneeName;
  final String assigneeEmoji;
  String projectId;
  final DateTime createdAt;
  DateTime updatedAt;
  final DateTime dueDate;
  DateTime? completedAt;
  bool isDone;
  TaskPriority priority;
  List<String> taskNotes; 
  String? completionReport;

  Task({
    required this.id,
    required this.title,
    required this.assigneeId,
    required this.assigneeName,
    required this.assigneeEmoji,
    required this.projectId,
    required this.createdAt,
    DateTime? updatedAt,
    required this.dueDate,
    this.completedAt,
    this.isDone = false,
    this.priority = TaskPriority.none,
    List<String>? taskNotes,
    this.completionReport,
  }) : taskNotes = taskNotes ?? [], updatedAt = updatedAt ?? createdAt;
}

class JournalEntry {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String content;
  String? projectId;
  final DateTime date;
  final List<String> photos;
  bool isPrivate;

  JournalEntry({
    required this.id, 
    required this.userId, 
    required this.userName, 
    required this.title, 
    required this.content, 
    this.projectId,
    required this.date, 
    required this.photos,
    this.isPrivate = false,
  });
}

// =============================================================================
// [MAIN] App Bootstrap & Global State
// =============================================================================
class WorkNoteApp extends StatelessWidget {
  const WorkNoteApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WorkNote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        textTheme: GoogleFonts.notoSansKrTextTheme(),
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
  File? _profileImage;
  final List<AppTone> _tabTones = [AppTone.white, AppTone.blue, AppTone.white, AppTone.black];

  late List<Task> _tasks;
  late List<JournalEntry> _journals;
  final List<Project> _projects = [
    Project(id: 'p1', name: 'A동 아파트 신축', color: Colors.blue),
    Project(id: 'p2', name: 'B동 설비 보수', color: Colors.orange),
    Project(id: 'p3', name: 'C동 전기 증설', color: Colors.green),
  ];
  final List<TeamMember> _members = [
    TeamMember(id: 'me', name: '나', emoji: '👩‍💻', role: '현장 총괄'),
    TeamMember(id: 'kim', name: '김반장', emoji: '👨‍💼', role: '설비 팀장'),
    TeamMember(id: 'lee', name: '이대리', emoji: '🧑‍🎨', role: '안전 담당'),
    TeamMember(id: 'park', name: '박기사', emoji: '👷', role: '전기 시공'),
  ];

  DateTime? _targetGalleryDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _tasks = [
      Task(id: '1', title: '302호 배관 긴급 누수 점검', assigneeId: 'me', assigneeName: '나', assigneeEmoji: '👩‍💻', projectId: 'p1', createdAt: now.subtract(const Duration(days: 3)), dueDate: now, priority: TaskPriority.high),
      Task(id: '2', title: '안전 교육 일지 작성', assigneeId: 'kim', assigneeName: '김반장', assigneeEmoji: '👨‍💼', projectId: 'p2', createdAt: now.subtract(const Duration(days: 1)), dueDate: now.add(const Duration(days: 1)), priority: TaskPriority.medium),
    ];
    _journals = [
      JournalEntry(id: 'j1', userId: 'me', userName: '나', title: '오전 현장 점검', content: '전체적으로 공정이 원활하게 진행되고 있음.', projectId: 'p1', date: now.subtract(const Duration(hours: 5)), photos: []),
    ];
  }

  void _addTask(Task task) => setState(() => _tasks.add(task));
  void _addProject(Project p) => setState(() => _projects.add(p));
  void _deleteTask(String id) => setState(() => _tasks.removeWhere((t) => t.id == id));
  void _addJournal(JournalEntry journal) => setState(() => _journals.insert(0, journal));

  Color _getBgColor(AppTone tone) {
    switch (tone) {
      case AppTone.white: return const Color(0xFFF8FAFC);
      case AppTone.blue: return const Color(0xFFE0F2FE);
      case AppTone.black: return const Color(0xFF0F172A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTone = _tabTones[_selectedIndex];
    final isBlack = currentTone == AppTone.black;

    final screens = [
      HomeTab(profileImage: _profileImage, onProfileTap: () async {
        final picker = ImagePicker();
        final file = await picker.pickImage(source: ImageSource.gallery);
        if (file != null) setState(() => _profileImage = File(file.path));
      }, tasks: _tasks, projects: _projects, members: _members, tone: _tabTones[0]),
      TeamTaskTab(tasks: _tasks, projects: _projects, members: [TeamMember(id: 'all', name: '전체', emoji: '👥', role: ''), ..._members], myProfileImage: _profileImage, onStateChange: () => setState(() {}), onAddTask: _addTask, onAddProject: _addProject, onDeleteTask: _deleteTask, tone: _tabTones[1]),
      JournalTab(journals: _journals, tasks: _tasks, projects: _projects, members: [TeamMember(id: 'all', name: '전체', emoji: '👥', role: ''), ..._members], onSaveJournal: _addJournal, onCreateTask: _addTask, onAddProject: _addProject, tone: _tabTones[2], onPhotoTap: (d) => setState(() { _targetGalleryDate = d; _selectedIndex = 3; })),
      GalleryTab(journals: _journals, members: [TeamMember(id: 'all', name: '전체', emoji: '📂', role: ''), ..._members], myProfileImage: _profileImage, onPhotoCaptured: (path) {
        _addJournal(JournalEntry(id: DateTime.now().toString(), userId: 'me', userName: '나', title: '현장 사진 촬영', content: '카메라 촬영분', date: DateTime.now(), photos: [path]));
      }, tone: _tabTones[3], targetDate: _targetGalleryDate, onTargetDateHandled: () => _targetGalleryDate = null),
    ];

    return Scaffold(
      backgroundColor: _getBgColor(currentTone),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('WorkNote', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: isBlack ? Colors.white : Colors.black87)),
        actions: [
          IconButton(icon: Icon(Icons.palette_rounded, color: isBlack ? const Color(0xFF448AFF) : const Color(0xFF2563EB)), onPressed: () => _showTonePicker()),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
          backgroundColor: isBlack ? const Color(0xFF1E293B) : Colors.white,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
            NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: '팀 업무'),
            NavigationDestination(icon: Icon(Icons.edit_note_rounded), selectedIcon: Icon(Icons.edit_note_rounded), label: '일지'),
            NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: '갤러리'),
          ],
        ),
      ),
    );
  }

  void _showTonePicker() {
    showModalBottomSheet(context: context, builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _toneTile("White", AppTone.white), _toneTile("Blue", AppTone.blue), _toneTile("Black", AppTone.black),
      ]),
    ));
  }
  Widget _toneTile(String l, AppTone t) => ListTile(title: Text(l), onTap: () { setState(() => _tabTones[_selectedIndex] = t); Navigator.pop(context); });
}

// =============================================================================
// [PART 1] HOME TAB
// =============================================================================
class HomeTab extends StatelessWidget {
  final File? profileImage;
  final VoidCallback onProfileTap;
  final List<Task> tasks;
  final List<Project> projects;
  final List<TeamMember> members;
  final AppTone tone;
  const HomeTab({super.key, this.profileImage, required this.onProfileTap, required this.tasks, required this.projects, required this.members, required this.tone});

  @override
  Widget build(BuildContext context) {
    final isDark = tone == AppTone.black;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(DateFormat('M월 d일 E요일', 'ko_KR').format(DateTime.now()), style: const TextStyle(fontSize: 13, color: Colors.grey)),
            Text("안녕하세요 관리자님! 👷", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
          ]),
          GestureDetector(onTap: onProfileTap, child: CircleAvatar(radius: 28, backgroundColor: Colors.blue.shade100, backgroundImage: profileImage != null ? FileImage(profileImage!) : null, child: profileImage == null ? const Icon(Icons.person) : null))
        ]),
        const SizedBox(height: 32),
        Text("프로젝트별 달성률", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 16),
        ...projects.map((p) {
          final pTasks = tasks.where((t) => t.projectId == p.id).toList();
          final total = pTasks.length;
          final done = pTasks.where((t) => t.isDone).length;
          final progress = total == 0 ? 0.0 : done / total;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: p.color, shape: BoxShape.circle)), const SizedBox(width: 8), Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold))]),
                Text("${(progress * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.w900, color: p.color)),
              ]),
              const SizedBox(height: 12),
              ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 8, color: p.color, backgroundColor: p.color.withValues(alpha: 0.1))),
              const SizedBox(height: 8),
              Text("진행 $done / 전체 $total", style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          );
        }),
        const SizedBox(height: 40),
        Text("팀원 리스트", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 20),
        SizedBox(height: 120, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: members.length, itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.only(right: 24),
          child: Column(children: [CircleAvatar(radius: 32, backgroundColor: isDark ? Colors.white10 : Colors.white, child: Text(members[i].emoji, style: const TextStyle(fontSize: 30))), const SizedBox(height: 10), Text(members[i].name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87))]),
        ))),
      ]),
    );
  }
}

// =============================================================================
// [PART 2] TEAM TASK TAB
// =============================================================================
class TeamTaskTab extends StatefulWidget {
  final List<Task> tasks;
  final List<Project> projects;
  final List<TeamMember> members;
  final File? myProfileImage;
  final VoidCallback onStateChange;
  final Function(Task) onAddTask;
  final Function(Project) onAddProject;
  final Function(String) onDeleteTask;
  final AppTone tone;
  const TeamTaskTab({super.key, required this.tasks, required this.projects, required this.members, this.myProfileImage, required this.onStateChange, required this.onAddTask, required this.onAddProject, required this.onDeleteTask, required this.tone});

  @override
  State<TeamTaskTab> createState() => _TeamTaskTabState();
}

class _TeamTaskTabState extends State<TeamTaskTab> {
  String _projectId = 'all';
  String _statusFilter = '전체';
  TaskPriority? _priorityFilter; 
  DateFilter _dateFilter = DateFilter.all;
  String _memberId = 'all';

  void _showTaskNoteDialog(Task task) {
    final noteCtrl = TextEditingController();
    final reportCtrl = TextEditingController(text: task.completionReport);
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: Text(task.isDone ? "완료 보고서" : "진행사항 기록", style: const TextStyle(fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ...task.taskNotes.map((n) => ListTile(title: Text(n, style: const TextStyle(fontSize: 13)))),
        const SizedBox(height: 16),
        if (!task.isDone) ...[
          TextField(controller: noteCtrl, decoration: InputDecoration(hintText: "진행사항 입력...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 8),
          FilledButton(onPressed: () {
            if (noteCtrl.text.isEmpty) return;
            setState(() { task.taskNotes.insert(0, "[${DateFormat('MM.dd HH:mm').format(DateTime.now())}] ${noteCtrl.text}"); task.updatedAt = DateTime.now(); });
            noteCtrl.clear(); setDialogState(() {}); widget.onStateChange();
          }, child: const Text("기록 추가"))
        ] else ...[
          const Text("완료된 업무의 최종 성과를 기록하세요.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(controller: reportCtrl, maxLines: 3, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 8),
          FilledButton(onPressed: () {
            setState(() { task.completionReport = reportCtrl.text; task.updatedAt = DateTime.now(); });
            Navigator.pop(ctx); widget.onStateChange();
          }, child: const Text("보고서 업데이트"))
        ]
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("닫기"))],
    )));
  }

  void _showAddTaskDialog() {
    final titleCtrl = TextEditingController();
    Project? selectedProject;
    DateTime selectedDate = DateTime.now();
    String currentPrefix = "";

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: const Text("새 업무 추가", style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Autocomplete<String>(
          optionsBuilder: (textValue) {
            if (!textValue.text.contains('#')) { currentPrefix = textValue.text; return const Iterable<String>.empty(); }
            final parts = textValue.text.split('#');
            currentPrefix = parts[0];
            final search = parts.last;
            final matching = widget.projects.where((p) => p.name.contains(search)).map((p) => "#${p.name}").toList();
            if (search.isNotEmpty) matching.add("신규 생성: #$search");
            return matching;
          },
          onSelected: (val) {
            if (val.startsWith("신규 생성: ")) {
              final newP = Project(id: DateTime.now().toString(), name: val.split('#').last, color: Colors.blue);
              widget.onAddProject(newP); selectedProject = newP;
            } else {
              selectedProject = widget.projects.firstWhere((p) => p.name == val.substring(1));
            }
            WidgetsBinding.instance.addPostFrameCallback((_) { titleCtrl.text = currentPrefix.trim(); setDialogState(() {}); });
          },
          fieldViewBuilder: (ctx, ctrl, focus, onFieldSubmitted) {
            ctrl.addListener(() { titleCtrl.text = ctrl.text; });
            return TextField(controller: ctrl, focusNode: focus, decoration: const InputDecoration(labelText: "제목 (#프로젝트)"));
          },
        ),
        DropdownButton<Project>(
          isExpanded: true, value: selectedProject ?? widget.projects.first,
          items: widget.projects.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
          onChanged: (v) => setDialogState(() => selectedProject = v),
        ),
        SizedBox(height: 100, child: CupertinoDatePicker(mode: CupertinoDatePickerMode.date, initialDateTime: selectedDate, onDateTimeChanged: (v) => selectedDate = v)),
      ]),
      actions: [FilledButton(onPressed: () {
        widget.onAddTask(Task(id: DateTime.now().toString(), title: titleCtrl.text, assigneeId: 'me', assigneeName: '나', assigneeEmoji: '👩‍💻', projectId: selectedProject?.id ?? widget.projects.first.id, createdAt: DateTime.now(), dueDate: selectedDate));
        Navigator.pop(context);
      }, child: const Text("추가"))],
    )));
  }

  List<Task> get _filtered {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return widget.tasks.where((t) {
      if (_projectId != 'all' && t.projectId != _projectId) return false;
      if (_statusFilter == '진행 중' && t.isDone) return false;
      if (_statusFilter == '완료됨' && !t.isDone) return false;
      if (_priorityFilter != null && t.priority != _priorityFilter) return false;
      if (_dateFilter == DateFilter.today && !DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day).isAtSameMomentAs(today)) return false;
      if (_dateFilter == DateFilter.week && t.dueDate.isAfter(today.add(const Duration(days: 7)))) return false;
      if (_dateFilter == DateFilter.twoWeeks && t.dueDate.isAfter(today.add(const Duration(days: 14)))) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.tone == AppTone.black;
    final list = _filtered;
    return Column(children: [
      Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: IntrinsicHeight(child: Row(children: [
          _filterCellWithMenu("프로젝트", _projectId == 'all' ? "전체" : widget.projects.firstWhere((p) => p.id == _projectId).name, 
            ['전체', ...widget.projects.map((p)=>p.name)], (v)=>setState(()=>_projectId = v == '전체' ? 'all' : widget.projects.firstWhere((p)=>p.name==v).id)),
          _filterDivider(),
          _filterCellWithMenu("진행현황", _statusFilter, ['전체','진행 중','완료됨'], (v)=>setState(()=>_statusFilter=v)),
          _filterDivider(),
          _filterCellWithMenu("중요도", _priorityFilter == null ? "전체" : _pText(_priorityFilter!), ['전체','상','중','하'], (v)=>setState(()=>_priorityFilter = v=='전체'?null:(v=='상'?TaskPriority.high:(v=='중'?TaskPriority.medium:TaskPriority.low)))),
          _filterDivider(),
          _filterCellWithMenu("기한", _dFilterText(_dateFilter), ['전체','오늘','이번 주','2주'], (v)=>setState(()=>_dateFilter = v=='전체'?DateFilter.all:(v=='오늘'?DateFilter.today:(v=='이번 주'?DateFilter.week:DateFilter.twoWeeks)))),
        ])),
      ),
      Expanded(child: ListView.builder(itemCount: list.length, itemBuilder: (ctx, i) => GestureDetector(onTap: () => _showTaskNoteDialog(list[i]), child: _TaskCard(task: list[i], projects: widget.projects, tone: widget.tone, onToggle: (v) { setState(() { list[i].isDone = v!; list[i].completedAt = v ? DateTime.now() : null; list[i].updatedAt = DateTime.now(); }); widget.onStateChange(); }, onPriority: () { setState(() { list[i].priority = TaskPriority.values[(list[i].priority.index+1)%4]; list[i].updatedAt = DateTime.now(); }); widget.onStateChange(); })))),
      Padding(padding: const EdgeInsets.only(bottom: 16), child: FloatingActionButton.extended(onPressed: _showAddTaskDialog, label: const Text("업무 추가"), icon: const Icon(Icons.add))),
    ]);
  }

  Widget _filterCellWithMenu(String t, String v, List<String> options, Function(String) onPick) {
    return Expanded(child: PopupMenuButton<String>(
      onSelected: onPick,
      itemBuilder: (ctx) => options.map((o) => PopupMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13)))).toList(),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Column(children: [Text(t, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w900)), Text(v, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis)])),
    ));
  }
  Widget _filterDivider() => VerticalDivider(width: 1, indent: 15, endIndent: 15, color: Colors.grey.shade200);
  String _pText(TaskPriority p) { switch(p) { case TaskPriority.high: return "상"; case TaskPriority.medium: return "중"; case TaskPriority.low: return "하"; default: return "없음"; } }
  String _dFilterText(DateFilter f) { switch(f) { case DateFilter.today: return "오늘"; case DateFilter.week: return "이번 주"; case DateFilter.twoWeeks: return "2주"; default: return "전체"; } }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final List<Project> projects;
  final AppTone tone;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onPriority;
  const _TaskCard({required this.task, required this.projects, required this.onToggle, required this.onPriority, required this.tone});

  @override
  Widget build(BuildContext context) {
    final isDark = tone == AppTone.black;
    final p = projects.firstWhere((p) => p.id == task.projectId, orElse: () => Project(id: 'err', name: '알수없음', color: Colors.grey));
    final df = DateFormat('yy.MM.dd');
    final labelStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      child: Padding(padding: const EdgeInsets.all(20), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 48, child: Column(children: [
          Checkbox(value: task.isDone, onChanged: onToggle),
          const SizedBox(height: 12),
          GestureDetector(onTap: onPriority, child: Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: _pColor(task.priority).withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: _pColor(task.priority), width: 2)), child: Text(_pText(task.priority), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _pColor(task.priority))))),
        ])),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.name, style: TextStyle(fontSize: 10, color: p.color, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(task.title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, decoration: task.isDone ? TextDecoration.lineThrough : null, color: isDark ? Colors.white : Colors.black87)),
          const Divider(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("작성:${df.format(task.createdAt)}", style: labelStyle), Text("기한:${df.format(task.dueDate)}", style: labelStyle)]),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("수정:${df.format(task.updatedAt)}", style: labelStyle.copyWith(color: Colors.blue)),
            if (task.isDone && task.completedAt != null) Text("완료:${df.format(task.completedAt!)}", style: labelStyle.copyWith(color: Colors.green)),
          ]),
        ])),
      ])),
    );
  }
  Color _pColor(TaskPriority p) { switch (p) { case TaskPriority.high: return Colors.red; case TaskPriority.medium: return Colors.orange; case TaskPriority.low: return Colors.blue; default: return Colors.grey; } }
  String _pText(TaskPriority p) { switch (p) { case TaskPriority.high: return "상"; case TaskPriority.medium: return "중"; case TaskPriority.low: return "하"; default: return "-"; } }
}

// =============================================================================
// [PART 3] JOURNAL TAB
// =============================================================================
class JournalTab extends StatefulWidget {
  final List<JournalEntry> journals;
  final List<Task> tasks;
  final List<Project> projects;
  final List<TeamMember> members;
  final Function(JournalEntry) onSaveJournal;
  final Function(Task) onCreateTask;
  final Function(Project) onAddProject;
  final AppTone tone;
  final Function(DateTime) onPhotoTap;
  const JournalTab({super.key, required this.journals, required this.tasks, required this.projects, required this.members, required this.onSaveJournal, required this.onCreateTask, required this.onAddProject, required this.tone, required this.onPhotoTap});
  @override State<JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<JournalTab> {
  String _searchQuery = '';
  JournalGroupPeriod _groupPeriod = JournalGroupPeriod.day;
  String _memberFilterId = 'all';

  void _showWriteJournalDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    Project? selectedProject;
    bool isPrivate = false;
    List<String> selectedPhotos = [];

    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))), builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("일지 작성", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "제목", border: OutlineInputBorder())),
        const SizedBox(height: 16),
        DropdownButtonFormField<Project>(isExpanded: true, value: selectedProject, items: widget.projects.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(), onChanged: (v) => setDialogState(() => selectedProject = v), decoration: const InputDecoration(labelText: "프로젝트")),
        const SizedBox(height: 16),
        TextField(controller: contentCtrl, maxLines: 5, decoration: const InputDecoration(labelText: "내용", border: OutlineInputBorder())),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("비공개 설정"), Switch(value: isPrivate, onChanged: (v) => setDialogState(() => isPrivate = v))]),
        Row(children: [IconButton.filledTonal(onPressed: () async {
          final picker = ImagePicker();
          final images = await picker.pickMultiImage();
          if (images.isNotEmpty) setDialogState(() => selectedPhotos.addAll(images.map((e) => e.path)));
        }, icon: const Icon(Icons.add_a_photo)), Expanded(child: SizedBox(height: 60, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: selectedPhotos.length, itemBuilder: (c, i) => Image.file(File(selectedPhotos[i])))))]),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 56, child: FilledButton(onPressed: () {
          widget.onSaveJournal(JournalEntry(id: DateTime.now().toString(), userId: 'me', userName: '나', title: titleCtrl.text, content: contentCtrl.text, projectId: selectedProject?.id, date: DateTime.now(), photos: selectedPhotos, isPrivate: isPrivate));
          Navigator.pop(context);
        }, child: const Text("저장하기"))),
        const SizedBox(height: 32),
      ]),
    )));
  }

  String _getGroupKey(DateTime date, JournalGroupPeriod period) {
    switch (period) {
      case JournalGroupPeriod.day: return DateFormat('yyyy-MM-dd').format(date);
      case JournalGroupPeriod.week: return "${DateFormat('yyyy-MM').format(date)} ${((date.day-1)/7).floor()+1}주차";
      case JournalGroupPeriod.month: return DateFormat('yyyy-MM').format(date);
      case JournalGroupPeriod.quarter: return "${date.year}년 ${((date.month-1)/3).floor()+1}분기";
      case JournalGroupPeriod.year: return "${date.year}년";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.tone == AppTone.black;
    final filtered = widget.journals.where((j) {
      bool canSee = !j.isPrivate || j.userId == 'me';
      bool matchesSearch = j.title.contains(_searchQuery) || j.content.contains(_searchQuery);
      bool matchesMember = _memberFilterId == 'all' || j.userId == _memberFilterId;
      return canSee && matchesSearch && matchesMember;
    }).toList();
    final groups = <String, List<JournalEntry>>{};
    for (var j in filtered) {
      String key = _getGroupKey(j.date, _groupPeriod);
      groups.putIfAbsent(key, () => []).add(j);
    }
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(preferredSize: const Size.fromHeight(180), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.all(16), child: TextField(onChanged: (v) => setState(() => _searchQuery = v), decoration: InputDecoration(hintText: "일지 검색...", prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(32))))),
        SizedBox(height: 60, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: widget.members.length, itemBuilder: (c, i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: ActionChip(label: Text(widget.members[i].name), onPressed: () => setState(() => _memberFilterId = widget.members[i].id))))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          const Text("그룹 기준: ", style: TextStyle(fontSize: 12, color: Colors.grey)),
          DropdownButton<JournalGroupPeriod>(value: _groupPeriod, items: const [
            DropdownMenuItem(value: JournalGroupPeriod.day, child: Text("일")),
            DropdownMenuItem(value: JournalGroupPeriod.week, child: Text("주")),
            DropdownMenuItem(value: JournalGroupPeriod.month, child: Text("월")),
            DropdownMenuItem(value: JournalGroupPeriod.quarter, child: Text("분기")),
            DropdownMenuItem(value: JournalGroupPeriod.year, child: Text("년")),
          ], onChanged: (v) => setState(() => _groupPeriod = v!)),
        ])),
      ])),
      body: ListView.builder(itemCount: keys.length, itemBuilder: (c, i) {
        final group = groups[keys[i]]!;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.all(16), child: Text(keys[i], style: const TextStyle(fontWeight: FontWeight.w900))),
          ...group.map((j) => ListTile(title: Text(j.title), subtitle: Text(j.content, maxLines: 1, overflow: TextOverflow.ellipsis), onTap: () => _showDetail(j))),
        ]);
      }),
      floatingActionButton: FloatingActionButton(onPressed: _showWriteJournalDialog, child: const Icon(Icons.edit)),
    );
  }

  void _showDetail(JournalEntry j) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(j.title), content: Text(j.content), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("닫기"))]));
  }
}

// =============================================================================
// [PART 4] GALLERY TAB
// =============================================================================
class GalleryTab extends StatefulWidget {
  final List<JournalEntry> journals;
  final List<TeamMember> members;
  final File? myProfileImage;
  final Function(String) onPhotoCaptured;
  final AppTone tone;
  final DateTime? targetDate;
  final VoidCallback onTargetDateHandled;
  const GalleryTab({super.key, required this.journals, required this.members, this.myProfileImage, required this.onPhotoCaptured, required this.tone, this.targetDate, required this.onTargetDateHandled});
  @override State<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<GalleryTab> {
  final Map<String, GlobalKey> _dateKeys = {};
  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<String>>{};
    for (var j in widget.journals) {
      if (j.photos.isNotEmpty) {
        String d = DateFormat('yyyy-MM-dd').format(j.date);
        grouped.putIfAbsent(d, () => []).addAll(j.photos);
      }
    }
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return ListView.builder(itemCount: dates.length, itemBuilder: (c, i) {
      final d = dates[i];
      _dateKeys.putIfAbsent(d, () => GlobalKey());
      return Column(key: _dateKeys[d], children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold))),
        GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3), itemCount: grouped[d]!.length, itemBuilder: (cc, pIdx) => Image.file(File(grouped[d]![pIdx]), fit: BoxFit.cover)),
      ]);
    });
  }
}
