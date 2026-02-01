import 'dart:math';
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
  String _projectId = 'all';
  String _statusFilter = '전체';
  TaskPriority? _priorityFilter;
  DateFilter _dateFilter = DateFilter.all;
  String _memberId = 'all';

  Color _getRandomColor() {
    final colors = [
      Colors.blue, Colors.red, Colors.orange, Colors.green, 
      Colors.purple, Colors.teal, Colors.indigo, Colors.pink
    ];
    return colors[Random().nextInt(colors.length)];
  }

  void _showTaskDetailDialog(Task task) {
    final noteCtrl = TextEditingController();
    final reportCtrl = TextEditingController(text: task.completionReport);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(task.isDone ? "완료 보고서" : "진행사항 기록", style: const TextStyle(fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (task.taskNotes.isNotEmpty) ...[
                  const Align(alignment: Alignment.centerLeft, child: Text("기록된 히스토리", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8),
                  ...task.taskNotes.map((n) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Text(n, style: const TextStyle(fontSize: 13)),
                    ),
                  )),
                  const Divider(height: 32),
                ],
                if (!task.isDone) ...[
                  TextField(
                    controller: noteCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: "현재 진행 상황을 입력하세요...", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (noteCtrl.text.isEmpty) return;
                        setState(() {
                          final nowStr = DateFormat('MM.dd HH:mm').format(DateTime.now());
                          task.taskNotes.insert(0, "[$nowStr] ${noteCtrl.text}");
                          task.updatedAt = DateTime.now();
                        });
                        noteCtrl.clear();
                        setDialogState(() {});
                        widget.onStateChange();
                      },
                      child: const Text("기록 추가"),
                    ),
                  ),
                ] else ...[
                  const Text("최종 성과 및 업무 마감 내용을 기록하세요.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reportCtrl,
                    maxLines: 5,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          task.completionReport = reportCtrl.text;
                          task.updatedAt = DateTime.now();
                        });
                        Navigator.pop(ctx);
                        widget.onStateChange();
                      },
                      child: const Text("보고서 저장"),
                    ),
                  ),
                ]
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("닫기"))],
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    final titleCtrl = TextEditingController();
    Project? selectedProject;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("새 업무 추가", style: TextStyle(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Autocomplete<String>(
                optionsBuilder: (textValue) {
                  if (!textValue.text.contains('#')) return const Iterable<String>.empty();
                  final search = textValue.text.split('#').last.toLowerCase();
                  return widget.projects
                      .where((p) => p.name.toLowerCase().contains(search))
                      .map((p) => "#${p.name}");
                },
                onSelected: (val) {
                  final name = val.substring(1);
                  selectedProject = widget.projects.firstWhere((p) => p.name == name);
                  final current = titleCtrl.text;
                  final hashIdx = current.lastIndexOf('#');
                  if (hashIdx != -1) titleCtrl.text = current.substring(0, hashIdx).trim();
                  setDialogState(() {});
                },
                fieldViewBuilder: (ctx, ctrl, focus, onFieldSubmitted) {
                  if (ctrl.text.isEmpty && titleCtrl.text.isNotEmpty) ctrl.text = titleCtrl.text;
                  ctrl.addListener(() => titleCtrl.text = ctrl.text);
                  return TextField(controller: ctrl, focusNode: focus, decoration: const InputDecoration(labelText: "제목 (#프로젝트)", hintText: "업무 제목 입력..."));
                },
              ),
              const SizedBox(height: 16),
              if (selectedProject != null)
                Row(
                  children: [
                    const Text("프로젝트: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Chip(label: Text(selectedProject!.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)), backgroundColor: selectedProject!.color),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.isEmpty) return;
                
                if (selectedProject == null && titleCtrl.text.contains('#')) {
                  final parts = titleCtrl.text.split('#');
                  final newName = parts.last.trim();
                  if (newName.isNotEmpty) {
                    selectedProject = Project(id: DateTime.now().toString(), name: newName, color: _getRandomColor());
                    widget.onAddProject(selectedProject!);
                  }
                }

                widget.onAddTask(Task(
                  id: DateTime.now().toString(),
                  title: titleCtrl.text.split('#').first.trim(),
                  assigneeId: 'me',
                  assigneeName: '나',
                  assigneeEmoji: '👩‍💻',
                  projectId: selectedProject?.id ?? widget.projects.first.id,
                  createdAt: DateTime.now(),
                  dueDate: DateTime.now().add(const Duration(days: 1)),
                ));
                Navigator.pop(context);
              },
              child: const Text("추가", style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  List<Task> get _filteredTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return widget.tasks.where((t) {
      if (_projectId != 'all' && t.projectId != _projectId) return false;
      if (_statusFilter == '진행 중' && t.isDone) return false;
      if (_statusFilter == '완료됨' && !t.isDone) return false;
      if (_priorityFilter != null && t.priority != _priorityFilter) return false;
      if (_memberId != 'all' && t.assigneeId != _memberId) return false;
      
      final taskDate = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      if (_dateFilter == DateFilter.today && !taskDate.isAtSameMomentAs(today)) return false;
      if (_dateFilter == DateFilter.week && t.dueDate.isAfter(today.add(const Duration(days: 7)))) return false;
      if (_dateFilter == DateFilter.twoWeeks && t.dueDate.isAfter(today.add(const Duration(days: 14)))) return false;
      if (_dateFilter == DateFilter.oneMonth && t.dueDate.isAfter(today.add(const Duration(days: 30)))) return false; // 1달 필터 로직 추가
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredTasks;
    final df = DateFormat('yy.MM.dd');

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                _filterCell("프로젝트", _projectId == 'all' ? "전체" : widget.projects.firstWhere((p) => p.id == _projectId).name, 
                  ['전체', ...widget.projects.map((p) => p.name)], (v) => setState(() => _projectId = v == '전체' ? 'all' : widget.projects.firstWhere((p) => p.name == v).id), color: const Color(0xFF2563EB)),
                _vDivider(),
                _filterCell("상태", _statusFilter, ['전체', '진행 중', '완료됨'], (v) => setState(() => _statusFilter = v), 
                  color: _statusFilter == '진행 중' ? Colors.orange : (_statusFilter == '완료됨' ? Colors.green : null)),
                _vDivider(),
                _filterCell("중요도", _priorityFilter == null ? "전체" : _pText(_priorityFilter!), ['전체', '상', '중', '하', '없음'], 
                  (v) => setState(() => _priorityFilter = v == '전체' ? null : _parsePriority(v)), 
                  color: _priorityFilter != null ? _pColor(_priorityFilter!) : null),
                _vDivider(),
                _filterCell("기한", _dFilterText(_dateFilter), ['전체', '오늘', '이번 주', '2주', '1달'], (v) {
                  setState(() {
                    if (v == '전체') _dateFilter = DateFilter.all;
                    else if (v == '오늘') _dateFilter = DateFilter.today;
                    else if (v == '이번 주') _dateFilter = DateFilter.week;
                    else if (v == '2주') _dateFilter = DateFilter.twoWeeks;
                    else if (v == '1달') _dateFilter = DateFilter.oneMonth; // 1달 옵션 매핑
                  });
                }),
              ],
            ),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text("필터에 맞는 업무가 없습니다.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final task = list[i];
                    final project = widget.projects.firstWhere((p) => p.id == task.projectId, orElse: () => Project(id: '?', name: '알 수 없음', color: Colors.grey));
                    const labelStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B));

                    return GestureDetector(
                      onTap: () => _showTaskDetailDialog(task),
                      child: Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFF1F5F9))),
                        color: task.isDone ? const Color(0xFFF8FAFC) : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 48,
                                child: Column(
                                  children: [
                                    Checkbox(
                                      value: task.isDone,
                                      activeColor: const Color(0xFF2563EB),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      onChanged: (val) {
                                        setState(() {
                                          task.isDone = val!;
                                          task.completedAt = val ? DateTime.now() : null;
                                          task.updatedAt = DateTime.now();
                                        });
                                        widget.onStateChange();
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          task.priority = TaskPriority.values[(task.priority.index + 1) % 4];
                                          task.updatedAt = DateTime.now();
                                        });
                                        widget.onStateChange();
                                      },
                                      child: Container(
                                        width: 36, height: 36,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _pColor(task.priority).withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: _pColor(task.priority), width: 2),
                                        ),
                                        child: Text(_pText(task.priority), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _pColor(task.priority))),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(project.name, style: TextStyle(fontSize: 10, color: project.color, fontWeight: FontWeight.w900)),
                                        Text(task.assigneeEmoji, style: const TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(task.title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, decoration: task.isDone ? TextDecoration.lineThrough : null, color: task.isDone ? Colors.grey : const Color(0xFF1E293B))),
                                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("작성: ${df.format(task.createdAt)}", style: labelStyle),
                                        Text("기한: ${df.format(task.dueDate)}", style: labelStyle),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("수정: ${df.format(task.updatedAt)}", style: labelStyle.copyWith(color: const Color(0xFF2563EB))),
                                        if (task.isDone && task.completedAt != null) 
                                          Text("완료: ${df.format(task.completedAt!)}", style: labelStyle.copyWith(color: const Color(0xFF10B981))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _showAddTaskDialog,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.3),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 20),
                  SizedBox(width: 8),
                  Text("ADD TASK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterCell(String label, String value, List<String> options, Function(String) onPick, {Color? color}) {
    return Expanded(
      child: PopupMenuButton<String>(
        onSelected: onPick,
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        itemBuilder: (ctx) => options.map((o) => PopupMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)))).toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color ?? const Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vDivider() => const VerticalDivider(width: 1, indent: 15, endIndent: 15, color: Color(0xFFF1F5F9));
  
  String _pText(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return "상";
      case TaskPriority.medium: return "중";
      case TaskPriority.low: return "하";
      case TaskPriority.none: return "-";
    }
  }

  Color _pColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return const Color(0xFFEF4444);
      case TaskPriority.medium: return const Color(0xFFF59E0B);
      case TaskPriority.low: return const Color(0xFF3B82F6);
      case TaskPriority.none: return const Color(0xFF94A3B8);
    }
  }

  TaskPriority _parsePriority(String v) {
    if (v == "상") return TaskPriority.high;
    if (v == "중") return TaskPriority.medium;
    if (v == "하") return TaskPriority.low;
    return TaskPriority.none;
  }

  String _dFilterText(DateFilter f) {
    switch (f) {
      case DateFilter.today: return "오늘";
      case DateFilter.week: return "이번 주";
      case DateFilter.twoWeeks: return "2주";
      case DateFilter.oneMonth: return "1달";
      case DateFilter.all: return "전체";
    }
  }
}
