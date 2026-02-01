import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../logic/app_controller.dart';

class TeamTaskTab extends StatelessWidget {
  final List<Task> tasks; 
  final List<Project> projects;
  final List<TeamMember> members;
  final AppController controller;
  final AppTone tone;

  const TeamTaskTab({
    super.key, 
    required this.tasks, 
    required this.projects, 
    required this.members, 
    required this.controller, 
    required this.tone
  });

  void _showTaskDetailDialog(BuildContext context, Task task) {
    final noteCtrl = TextEditingController();
    final reportCtrl = TextEditingController(text: task.completionReport);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text(task.isDone ? "완료 보고서" : "업무 진행 기록", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(task.title, style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
              const Divider(height: 48),
              if (task.taskNotes.isNotEmpty) ...[
                const Text("진행 히스토리", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 16),
                ...task.taskNotes.map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.1))),
                    child: Text(n, style: const TextStyle(fontSize: 14, height: 1.5)),
                  ),
                )),
                const SizedBox(height: 24),
              ],
              if (!task.isDone) ...[
                TextField(
                  controller: noteCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: "오늘의 진행 상황을 상세히 기록하세요...", border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)))),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      if (noteCtrl.text.isEmpty) return;
                      final nowStr = DateFormat('MM.dd HH:mm').format(DateTime.now());
                      task.taskNotes.insert(0, "[$nowStr] ${noteCtrl.text}");
                      task.updatedAt = DateTime.now();
                      controller.refresh();
                      noteCtrl.clear();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("진행사항 저장", style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ] else ...[
                const Text("최종 마감 성과", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 16),
                TextField(
                  controller: reportCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)))),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      task.completionReport = reportCtrl.text;
                      task.updatedAt = DateTime.now();
                      controller.refresh();
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("보고서 최종 저장", style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    Project? selectedProject;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => StatefulBuilder(
        builder: (stfCtx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("새 업무 추가", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              Autocomplete<String>(
                optionsBuilder: (textValue) {
                  if (!textValue.text.contains('#')) return const Iterable<String>.empty();
                  final parts = textValue.text.split('#');
                  final search = parts.last.toLowerCase();
                  return projects.where((p) => p.name.toLowerCase().contains(search)).map((p) => "#${p.name}");
                },
                onSelected: (val) {
                  final name = val.substring(1);
                  selectedProject = projects.firstWhere((p) => p.name == name);
                  final current = titleCtrl.text;
                  final hashIdx = current.lastIndexOf('#');
                  if (hashIdx != -1) titleCtrl.text = current.substring(0, hashIdx).trim();
                  setModalState(() {});
                },
                fieldViewBuilder: (fCtx, ctrl, focus, onFieldSubmitted) {
                  if (ctrl.text.isEmpty && titleCtrl.text.isNotEmpty) ctrl.text = titleCtrl.text;
                  ctrl.addListener(() => titleCtrl.text = ctrl.text);
                  return TextField(
                    controller: ctrl, 
                    focusNode: focus, 
                    decoration: const InputDecoration(labelText: "제목 (#프로젝트)", hintText: "업무 제목 입력 중 #을 눌러 프로젝트 선택"),
                  );
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Project>(
                value: selectedProject,
                items: projects.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                onChanged: (v) => setModalState(() => selectedProject = v),
                decoration: const InputDecoration(labelText: "또는 직접 프로젝트 선택", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: FilledButton(
                    onPressed: () async {
                      String title = titleCtrl.text.trim();
                      if (title.isEmpty) return;

                      if (selectedProject == null && title.contains('#')) {
                        final parts = title.split('#');
                        final newProjectName = parts.last.trim();
                        title = parts.first.trim();

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text("새 프로젝트 생성"),
                            content: Text("'#$newProjectName' 프로젝트가 없습니다. 새로 만드시겠습니까?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("취소")),
                              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("생성")),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          selectedProject = Project(id: DateTime.now().toString(), name: newProjectName, color: controller.getRandomProjectColor());
                          controller.addProject(selectedProject!);
                        } else {
                          return;
                        }
                      }

                      controller.addTask(Task(
                        id: DateTime.now().toString(),
                        title: title.split('#').first.trim(),
                        assigneeId: 'me', assigneeName: '나', assigneeEmoji: '👩‍💻',
                        projectId: selectedProject?.id ?? projects.first.id,
                        createdAt: DateTime.now(), dueDate: DateTime.now().add(const Duration(days: 1)),
                      ));
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("업무 등록하기", style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                _filterCell("프로젝트", controller.taskProjectId == 'all' ? "전체" : projects.firstWhere((p) => p.id == controller.taskProjectId).name, 
                  ['전체', ...projects.map((p) => p.name)], (v) => controller.setTaskFilter(projectId: v == '전체' ? 'all' : projects.firstWhere((p) => p.name == v).id), color: const Color(0xFF2563EB)),
                _vDivider(),
                _filterCell("상태", controller.taskStatusFilter, ['전체', '진행 중', '완료됨'], (v) => controller.setTaskFilter(status: v), 
                  color: controller.taskStatusFilter == '진행 중' ? Colors.orange : (controller.taskStatusFilter == '완료됨' ? Colors.green : null)),
                _vDivider(),
                _filterCell("중요도", _pText(controller.taskPriorityFilter), ['전체', '상', '중', '하', '없음'], 
                  (v) => controller.setTaskFilter(priority: v == '전체' ? null : _parsePriority(v)), 
                  color: controller.taskPriorityFilter != null ? _pColor(controller.taskPriorityFilter!) : null),
                _vDivider(),
                _filterCell("기한", _dFilterText(controller.taskDateFilter), ['전체', '오늘', '이번 주', '2주', '1달'], (v) {
                  DateFilter f = DateFilter.all;
                  if (v == '오늘') f = DateFilter.today;
                  else if (v == '이번 주') f = DateFilter.week;
                  else if (v == '2주') f = DateFilter.twoWeeks;
                  else if (v == '1달') f = DateFilter.oneMonth;
                  controller.setTaskFilter(date: f);
                }),
              ],
            ),
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? const Center(child: Text("필터에 맞는 업무가 없습니다.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tasks.length,
                  itemBuilder: (ctx, i) {
                    final task = tasks[i];
                    final project = projects.firstWhere((p) => p.id == task.projectId, orElse: () => Project(id: '?', name: '알 수 없음', color: Colors.grey));
                    const labelStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B));

                    return GestureDetector(
                      onTap: () => _showTaskDetailDialog(context, task),
                      child: Card(
                        elevation: 0, margin: const EdgeInsets.only(bottom: 12),
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
                                      onChanged: (val) => controller.updateTaskStatus(task, val!),
                                    ),
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: () => controller.cycleTaskPriority(task),
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
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: FilledButton(
              onPressed: () => _showAddTaskDialog(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        itemBuilder: (ctx) => options.map((o) => PopupMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))).toList(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w900)),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color ?? const Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => const VerticalDivider(width: 1, indent: 15, endIndent: 15, color: Color(0xFFF1F5F9));
  String _pText(TaskPriority? p) { if (p == TaskPriority.high) return "상"; if (p == TaskPriority.medium) return "중"; if (p == TaskPriority.low) return "하"; return "-"; }
  Color _pColor(TaskPriority p) { if (p == TaskPriority.high) return Colors.red; if (p == TaskPriority.medium) return Colors.orange; if (p == TaskPriority.low) return Colors.blue; return Colors.grey; }
  TaskPriority _parsePriority(String v) { if (v == "상") return TaskPriority.high; if (v == "중") return TaskPriority.medium; return TaskPriority.low; }
  String _dFilterText(DateFilter f) { if (f == DateFilter.today) return "오늘"; if (f == DateFilter.week) return "이번 주"; if (f == DateFilter.twoWeeks) return "2주"; if (f == DateFilter.oneMonth) return "1달"; return "전체"; }
}
