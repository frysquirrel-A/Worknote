import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  runApp(const WorkNoteApp());
}

// --- 1. Data Models ---
enum TaskPriority { high, medium, low, none }
enum AppTone { white, blue, black }
enum DateFilter { all, today, week, twoWeeks }

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
  final DateTime createdAt;
  final DateTime dueDate;
  DateTime? completedAt;
  bool isDone;
  TaskPriority priority;
  List<String> taskNotes;

  Task({
    required this.id,
    required this.title,
    required this.assigneeId,
    required this.assigneeName,
    required this.assigneeEmoji,
    required this.createdAt,
    required this.dueDate,
    this.completedAt,
    this.isDone = false,
    this.priority = TaskPriority.none,
    List<String>? taskNotes,
  }) : taskNotes = taskNotes ?? [];
}

class JournalEntry {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String content;
  final DateTime date;
  final List<String> photos;
  JournalEntry({required this.id, required this.userId, required this.userName, required this.title, required this.content, required this.date, required this.photos});
}

// --- 2. Main App Setup ---
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
  int _selectedIndex = 1; 
  File? _profileImage;
  final List<AppTone> _tabTones = [AppTone.white, AppTone.white, AppTone.white, AppTone.black];

  late List<Task> _tasks;
  late List<JournalEntry> _journals;
  final List<TeamMember> _members = [
    TeamMember(id: 'me', name: '나', emoji: '👩‍💻', role: '현장 총괄'),
    TeamMember(id: 'kim', name: '김반장', emoji: '👨‍💼', role: '설비 팀장'),
    TeamMember(id: 'lee', name: '이대리', emoji: '🧑‍🎨', role: '안전 담당'),
    TeamMember(id: 'park', name: '박기사', emoji: '👷', role: '전기 시공'),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _tasks = [
      Task(id: '1', title: '302호 배관 긴급 누수 점검', assigneeId: 'me', assigneeName: '나', assigneeEmoji: '👩‍💻', createdAt: now.subtract(const Duration(days: 3)), dueDate: now, priority: TaskPriority.high),
      Task(id: '2', title: '안전 교육 일지 작성', assigneeId: 'kim', assigneeName: '김반장', assigneeEmoji: '👨‍💼', createdAt: now.subtract(const Duration(days: 1)), dueDate: now.add(const Duration(days: 2)), priority: TaskPriority.medium),
    ];
    _journals = [];
  }

  void _addTask(Task task) => setState(() => _tasks.add(task));
  void _deleteTask(String id) => setState(() => _tasks.removeWhere((t) => t.id == id));
  void _addJournal(JournalEntry journal) => setState(() => _journals.insert(0, journal));

  @override
  Widget build(BuildContext context) {
    final currentTone = _tabTones[_selectedIndex];
    final isBlack = currentTone == AppTone.black;

    final screens = [
      HomeTab(profileImage: _profileImage, onProfileTap: () async {
        final picker = ImagePicker();
        final file = await picker.pickImage(source: ImageSource.gallery);
        if (file != null) setState(() => _profileImage = File(file.path));
      }, tasks: _tasks, members: _members, tone: _tabTones[0]),
      TeamTaskTab(tasks: _tasks, members: [TeamMember(id: 'all', name: '전체', emoji: '👥', role: ''), ..._members], myProfileImage: _profileImage, onStateChange: () => setState(() {}), onAddTask: _addTask, onDeleteTask: _deleteTask, tone: _tabTones[1]),
      JournalTab(tasks: _tasks, members: _members, onSaveJournal: _addJournal, onCreateTask: _addTask, tone: _tabTones[2]),
      GalleryTab(journals: _journals, members: [TeamMember(id: 'all', name: '전체', emoji: '📂', role: ''), ..._members], myProfileImage: _profileImage, onPhotoCaptured: (path) {
        _addJournal(JournalEntry(id: DateTime.now().toString(), userId: 'me', userName: '나', title: '현장 사진 촬영', content: '카메라로 촬영한 사진입니다.', date: DateTime.now(), photos: [path]));
      }, tone: _tabTones[3]),
    ];

    return Scaffold(
      backgroundColor: _getBgColor(currentTone),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('WorkNote', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: isBlack ? Colors.white : Colors.black87)),
        actions: [
          IconButton(
            icon: Icon(Icons.palette_rounded, color: isBlack ? Colors.blueAccent : const Color(0xFF2563EB)),
            onPressed: () => _showTonePicker(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
          backgroundColor: isBlack ? const Color(0xFF1E293B) : Colors.white,
          indicatorColor: const Color(0xFF2563EB).withOpacity(0.1),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
            NavigationDestination(icon: Icon(Icons.assignment_outlined), label: '팀 업무'),
            NavigationDestination(icon: Icon(Icons.edit_note_rounded), label: '일지'),
            NavigationDestination(icon: Icon(Icons.grid_view_outlined), label: '갤러리'),
          ],
        ),
      ),
    );
  }

  Color _getBgColor(AppTone tone) {
    switch (tone) {
      case AppTone.white: return const Color(0xFFF8FAFC);
      case AppTone.blue: return const Color(0xFFE0F2FE);
      case AppTone.black: return const Color(0xFF0F172A);
    }
  }

  void _showTonePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${['홈', '팀 업무', '일지', '갤러리'][_selectedIndex]} 테마 설정", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _toneOption("White", AppTone.white, Colors.white, Colors.black),
                _toneOption("Blue", AppTone.blue, const Color(0xFF0EA5E9), Colors.white),
                _toneOption("Black", AppTone.black, const Color(0xFF0F172A), Colors.white),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _toneOption(String label, AppTone tone, Color color, Color text) {
    final isSelected = _tabTones[_selectedIndex] == tone;
    return GestureDetector(
      onTap: () { setState(() => _tabTones[_selectedIndex] = tone); Navigator.pop(context); },
      child: Column(
        children: [
          Container(
            width: 70, height: 70, 
            decoration: BoxDecoration(
              color: color, shape: BoxShape.circle, 
              border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade200, width: isSelected ? 4 : 1),
            ),
            child: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// --- Home Tab ---
class HomeTab extends StatelessWidget {
  final File? profileImage;
  final VoidCallback onProfileTap;
  final List<Task> tasks;
  final List<TeamMember> members;
  final AppTone tone;

  const HomeTab({super.key, this.profileImage, required this.onProfileTap, required this.tasks, required this.members, required this.tone});

  @override
  Widget build(BuildContext context) {
    final isDark = tone == AppTone.black;
    final int total = tasks.length;
    final int done = tasks.where((t) => t.isDone).length;
    final double progress = total == 0 ? 0 : done / total;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Icon(Icons.campaign, color: isDark ? Colors.blueAccent : const Color(0xFF2563EB)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("팀 공지사항", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text("오후 3시 B동 안전점검 예정입니다.", style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
              ]))
            ]),
          ),
          const SizedBox(height: 32),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(DateFormat('M월 d일 E요일', 'ko_KR').format(DateTime.now()), style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade600, fontSize: 13)),
              Text("안녕하세요 관리자님! 👷", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
            ]),
            GestureDetector(
              onTap: onProfileTap,
              child: CircleAvatar(radius: 28, backgroundColor: Colors.blue.shade100, backgroundImage: profileImage != null ? FileImage(profileImage!) : null, child: profileImage == null ? const Icon(Icons.person) : null),
            )
          ]),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("업무 달성률", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text("${(progress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2563EB), fontSize: 18))]),
              const SizedBox(height: 16),
              ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, backgroundColor: const Color(0xFF2563EB).withOpacity(0.1), color: const Color(0xFF2563EB), minHeight: 10)),
            ]),
          ),
          const SizedBox(height: 24),
          Row(children: [_card("남은 업무", "${total - done}", const Color(0xFF2563EB), Colors.white), const SizedBox(width: 16), _card("갤러리 사진", "24", isDark ? Colors.white.withOpacity(0.05) : Colors.white, isDark ? Colors.white : Colors.black87)]),
          const SizedBox(height: 40),
          Text("팀원 리스트", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 20),
          SizedBox(height: 120, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: members.length, itemBuilder: (ctx, i) => Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Column(children: [CircleAvatar(radius: 32, backgroundColor: isDark ? Colors.white10 : Colors.white, backgroundImage: (members[i].id == 'me' && profileImage != null) ? FileImage(profileImage!) : null, child: (members[i].id == 'me' && profileImage != null) ? null : Text(members[i].emoji, style: const TextStyle(fontSize: 30))), const SizedBox(height: 10), Text(members[i].name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87))]),
          ))),
        ],
      ),
    );
  }

  Widget _card(String t, String c, Color bg, Color tx) => Expanded(child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(28)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: tx)), const SizedBox(height: 4), Text(t, style: TextStyle(color: tx.withOpacity(0.7), fontSize: 13))])));
}

// --- Team Task Tab ---
class TeamTaskTab extends StatefulWidget {
  final List<Task> tasks;
  final List<TeamMember> members;
  final File? myProfileImage;
  final VoidCallback onStateChange;
  final Function(Task) onAddTask;
  final Function(String) onDeleteTask;
  final AppTone tone;
  const TeamTaskTab({super.key, required this.tasks, required this.members, this.myProfileImage, required this.onStateChange, required this.onAddTask, required this.onDeleteTask, required this.tone});

  @override
  State<TeamTaskTab> createState() => _TeamTaskTabState();
}

class _TeamTaskTabState extends State<TeamTaskTab> {
  String _statusFilter = '전체';
  String _memberId = 'all';
  DateFilter _dateFilter = DateFilter.all;

  void _showTaskNoteDialog(Task task) {
    final noteController = TextEditingController();
    final isDark = widget.tone == AppTone.black;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(task.isDone ? "완료 리포트" : "진행사항", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(task.title, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (task.taskNotes.isNotEmpty)
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200)),
                    child: ListView.builder(
                      itemCount: task.taskNotes.length,
                      itemBuilder: (c, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.taskNotes[i].split(']')[0] + ']', style: TextStyle(fontSize: 10, color: Colors.blue.shade400, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(task.taskNotes[i].split(']')[1].trim(), style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: TextField(controller: noteController, decoration: const InputDecoration(hintText: "진행사항 입력...", border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))))),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () {
                        if (noteController.text.isEmpty) return;
                        final time = DateFormat('yy.MM.dd HH:mm').format(DateTime.now());
                        setDialogState(() {
                          task.taskNotes.insert(0, "[$time] 나: ${noteController.text}");
                          noteController.clear();
                        });
                        widget.onStateChange();
                      },
                      icon: const Icon(Icons.add),
                    )
                  ],
                ),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("닫기"))],
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    TeamMember selectedMember = widget.members.firstWhere((m) => m.id != 'all');
    DateTime selectedDate = DateTime.now();

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: const Text("새 업무 추가"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleController, decoration: const InputDecoration(labelText: "업무 제목")),
        const SizedBox(height: 16),
        DropdownButtonFormField<TeamMember>(value: selectedMember, items: widget.members.where((m) => m.id != 'all').map((m) => DropdownMenuItem(value: m, child: Text("${m.emoji} ${m.name}"))).toList(), onChanged: (v) => setDialogState(() => selectedMember = v!), decoration: const InputDecoration(labelText: "담당자")),
        const SizedBox(height: 16),
        ListTile(contentPadding: EdgeInsets.zero, title: Text("기한: ${DateFormat('yyyy.MM.dd').format(selectedDate)}"), trailing: const Icon(Icons.calendar_today), onTap: () async {
          final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 365)));
          if (picked != null) setDialogState(() => selectedDate = picked);
        }),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")), FilledButton(onPressed: () { if (titleController.text.isEmpty) return; widget.onAddTask(Task(id: DateTime.now().toString(), title: titleController.text, assigneeId: selectedMember.id, assigneeName: selectedMember.name, assigneeEmoji: selectedMember.emoji, createdAt: DateTime.now(), dueDate: selectedDate)); Navigator.pop(context); }, child: const Text("추가"))],
    )));
  }

  List<Task> get _filtered {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    var list = widget.tasks.where((t) {
      if (_statusFilter == '진행 중') if (t.isDone) return false;
      if (_statusFilter == '완료됨') if (!t.isDone) return false;
      if (_dateFilter == DateFilter.today) {
        final due = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
        return due.isAtSameMomentAs(today);
      }
      if (_dateFilter == DateFilter.week) return t.dueDate.isBefore(today.add(const Duration(days: 7)));
      if (_dateFilter == DateFilter.twoWeeks) return t.dueDate.isBefore(today.add(const Duration(days: 14)));
      return true;
    }).toList();

    if (_memberId != 'all') list = list.where((t) => t.assigneeId == _memberId).toList();
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.tone == AppTone.black;
    final filteredList = _filtered;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [ButtonSegment(value: '전체', label: Text('전체')), ButtonSegment(value: '진행 중', label: Text('진행 중')), ButtonSegment(value: '완료됨', label: Text('완료됨'))],
            selected: {_statusFilter},
            onSelectionChanged: (v) => setState(() => _statusFilter = v.first),
            showSelectedIcon: false,
          ),
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          _dateChip("전체기간", DateFilter.all),
          _dateChip("오늘 할 일", DateFilter.today),
          _dateChip("이번 주", DateFilter.week),
          _dateChip("2WEEKS", DateFilter.twoWeeks),
        ]),
      ),
      SizedBox(
        height: 90,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: widget.members.length,
          itemBuilder: (ctx, i) {
            final m = widget.members[i];
            final isS = _memberId == m.id;
            return GestureDetector(
              onTap: () => setState(() => _memberId = m.id),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(children: [
                  CircleAvatar(radius: 24, backgroundColor: isS ? const Color(0xFF2563EB) : (isDark ? Colors.white10 : Colors.white), backgroundImage: (m.id == 'me' && widget.myProfileImage != null) ? FileImage(widget.myProfileImage!) : null, child: (m.id == 'me' && widget.myProfileImage != null) ? null : Text(m.emoji, style: const TextStyle(fontSize: 22))),
                  const SizedBox(height: 4),
                  Text(m.name, style: TextStyle(fontSize: 11, fontWeight: isS ? FontWeight.bold : FontWeight.normal, color: isS ? const Color(0xFF2563EB) : (isDark ? Colors.white38 : Colors.black54))),
                ]),
              ),
            );
          },
        ),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          itemCount: filteredList.length,
          itemBuilder: (ctx, i) => Dismissible(
            key: Key(filteredList[i].id),
            onDismissed: (dir) => widget.onDeleteTask(filteredList[i].id),
            background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24), color: Colors.red.shade50, child: const Icon(Icons.delete_outline, color: Colors.red)),
            child: GestureDetector(
              onTap: () => _showTaskNoteDialog(filteredList[i]),
              child: _TaskCard(task: filteredList[i], tone: widget.tone, myProfileImage: widget.myProfileImage, onToggle: (v) { setState(() { filteredList[i].isDone = v!; filteredList[i].completedAt = v ? DateTime.now() : null; }); widget.onStateChange(); }, onPriority: () { setState(() { filteredList[i].priority = TaskPriority.values[(filteredList[i].priority.index+1)%4]; }); widget.onStateChange(); }),
            ),
          ),
        ),
      ),
      GestureDetector(
        onTap: _showAddTaskDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle_outline, color: Colors.blue), SizedBox(width: 8), Text("Add Task", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))]),
        ),
      ),
    ]);
  }

  Widget _dateChip(String label, DateFilter filter) {
    final isS = _dateFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _dateFilter = filter),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isS ? Colors.blue.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: isS ? Colors.blue : Colors.grey.shade300)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: isS ? FontWeight.bold : FontWeight.normal, color: isS ? Colors.blue : Colors.grey)),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final AppTone tone;
  final File? myProfileImage;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onPriority;
  const _TaskCard({required this.task, required this.tone, this.myProfileImage, required this.onToggle, required this.onPriority});

  @override
  Widget build(BuildContext context) {
    final isDark = tone == AppTone.black;
    final df = DateFormat('yyyy.MM.dd');
    final dateStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black54);

    return Card(
      elevation: 0, color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade100)), margin: const EdgeInsets.only(bottom: 16),
      child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
        // 왼쪽 영역: 체크박스 + 긴급도 배지 (사이즈 확대 및 정렬)
        SizedBox(width: 48, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Transform.scale(
            scale: 1.2,
            child: Checkbox(value: task.isDone, onChanged: onToggle, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onPriority,
            child: Container(
              width: 32, height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _pColor(task.priority).withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: _pColor(task.priority), width: 1.5)),
              child: Text(_pText(task.priority), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _pColor(task.priority))),
            ),
          ),
        ])),
        const SizedBox(width: 16),
        // 본문 영역
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child: Text(task.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: isDark ? Colors.white : Colors.black87, decoration: task.isDone ? TextDecoration.lineThrough : null))),
            CircleAvatar(radius: 12, backgroundColor: Colors.blue.withOpacity(0.1), backgroundImage: (task.assigneeId == 'me' && myProfileImage != null) ? FileImage(myProfileImage!) : null, child: (task.assigneeId == 'me' && myProfileImage != null) ? null : Text(task.assigneeEmoji, style: const TextStyle(fontSize: 12))),
          ]),
          const SizedBox(height: 4),
          Text(task.isDone ? "📑 완료 리포트" : "📑 진행사항", style: TextStyle(fontSize: 11, color: Colors.blue.shade400, fontWeight: FontWeight.bold)),
          const Divider(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("작성 : ${df.format(task.createdAt)}", style: dateStyle),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text("기한 : ${df.format(task.dueDate)}", style: dateStyle),
              if (task.isDone && task.completedAt != null)
                Text("완료 : ${df.format(task.completedAt!)}", style: dateStyle.copyWith(color: Colors.green, fontSize: 11)),
            ]),
          ])
        ])),
      ])),
    );
  }
  Color _pColor(TaskPriority p) { switch (p) { case TaskPriority.high: return Colors.red; case TaskPriority.medium: return Colors.orange; case TaskPriority.low: return Colors.blue; default: return Colors.grey; } }
  String _pText(TaskPriority p) { switch (p) { case TaskPriority.high: return "상"; case TaskPriority.medium: return "중"; case TaskPriority.low: return "하"; default: return "-"; } }
}

// --- Journal Tab ---
class JournalTab extends StatefulWidget {
  final List<Task> tasks;
  final List<TeamMember> members;
  final Function(JournalEntry) onSaveJournal;
  final Function(Task) onCreateTask;
  final AppTone tone;
  const JournalTab({super.key, required this.tasks, required this.members, required this.onSaveJournal, required this.onCreateTask, required this.tone});

  @override
  State<JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<JournalTab> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final isDark = widget.tone == AppTone.black;
    return Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      TextField(controller: _title, decoration: InputDecoration(hintText: "일지 제목", hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey), border: InputBorder.none), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
      const Divider(height: 32),
      Expanded(child: TextField(controller: _content, maxLines: null, decoration: InputDecoration(hintText: "기록하세요...", border: InputBorder.none, hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey)), style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black87))),
      SizedBox(width: double.infinity, height: 56, child: FilledButton(onPressed: () { if (_title.text.isNotEmpty) widget.onSaveJournal(JournalEntry(id: DateTime.now().toString(), userId: 'me', userName: '나', title: _title.text, content: _content.text, date: DateTime.now(), photos: [])); }, child: const Text("저장")))
    ]));
  }
}

// --- Gallery Tab ---
class GalleryTab extends StatefulWidget {
  final List<JournalEntry> journals;
  final List<TeamMember> members;
  final File? myProfileImage;
  final Function(String) onPhotoCaptured;
  final AppTone tone;
  const GalleryTab({super.key, required this.journals, required this.members, this.myProfileImage, required this.onPhotoCaptured, required this.tone});

  @override
  State<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<GalleryTab> {
  String _selectedId = 'all';
  @override
  Widget build(BuildContext context) {
    final isDark = widget.tone == AppTone.black;
    final grouped = <String, List<String>>{};
    for (var j in widget.journals) {
      if ((_selectedId == 'all' || j.userId == _selectedId) && j.photos.isNotEmpty) {
        String d = DateFormat('yyyy-MM-dd').format(j.date);
        grouped.putIfAbsent(d, () => []).addAll(j.photos);
      }
    }
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(children: [
      SizedBox(height: 110, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: widget.members.length, itemBuilder: (ctx, i) => GestureDetector(onTap: () => setState(() => _selectedId = widget.members[i].id), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Column(children: [CircleAvatar(radius: 26, backgroundColor: _selectedId == widget.members[i].id ? Colors.blue : (isDark ? Colors.white10 : Colors.white), backgroundImage: (widget.members[i].id == 'me' && widget.myProfileImage != null) ? FileImage(widget.myProfileImage!) : null, child: (widget.members[i].id == 'me' && widget.myProfileImage != null) ? null : Text(widget.members[i].emoji, style: const TextStyle(fontSize: 24))), const SizedBox(height: 8), Text(widget.members[i].name, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black54))]))))),
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(20), itemCount: dates.length, itemBuilder: (ctx, i) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(dates[i], style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontWeight: FontWeight.w900, fontSize: 18))),
        GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16), itemCount: grouped[dates[i]]!.length, itemBuilder: (ctx, pIdx) => Stack(fit: StackFit.expand, children: [ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(File(grouped[dates[i]]![pIdx]), fit: BoxFit.cover)), Positioned(right: 12, bottom: 12, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle), child: const Icon(Icons.lock_rounded, color: Colors.white, size: 16)))]))
      ])))
    ]);
  }
}
