import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';

/// 업무 추가 바텀시트를 표시하는 함수
Future<void> showAddTaskSheet({required BuildContext context}) {
  final titleCtrl = TextEditingController();

  final future = showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AddTaskSheet(titleCtrl: titleCtrl),
  );

  return future.whenComplete(() {
    titleCtrl.dispose();
  });
}

class _AddTaskSheet extends StatefulWidget {
  final TextEditingController titleCtrl;
  const _AddTaskSheet({required this.titleCtrl});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  String? projectId;
  late String assigneeId;
  DateTime dueDate = DateTime.now();
  bool includeInSchedule = true;
  DateTimeRange scheduleRange = DateTimeRange(start: DateTime.now(), end: DateTime.now());
  TaskPriority priority = TaskPriority.none;

  @override
  void initState() {
    super.initState();
    final authProv = context.read<AuthProvider>();
    assigneeId = authProv.currentUser?.id ?? 'me';
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final teamProv = context.watch<TeamProvider>();
    final prov = context.watch<TaskProvider>();

    final myId = authProv.currentUser?.id ?? 'me';
    final myName = authProv.currentUser?.name ?? '관리자';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('업무 추가', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text)),
              const SizedBox(height: 14),
              TextField(
                controller: widget.titleCtrl,
                style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '업무 제목',
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: projectId,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: '프로젝트',
                        labelStyle: const TextStyle(color: AppColors.text2),
                        filled: true,
                        fillColor: AppColors.bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('없음')),
                        ...prov.projects
                            .where((p) => p.teamId == teamProv.currentTeamId)
                            .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                      ],
                      onChanged: (v) => setState(() => projectId = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<TaskPriority>(
                      value: priority,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: '중요도',
                        labelStyle: const TextStyle(color: AppColors.text2),
                        filled: true,
                        fillColor: AppColors.bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(_priorityText(p)))).toList(),
                      onChanged: (v) => setState(() => priority = v ?? TaskPriority.none),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: assigneeId,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: '담당자',
                        labelStyle: const TextStyle(color: AppColors.text2),
                        filled: true,
                        fillColor: AppColors.bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      items: [
                        DropdownMenuItem(value: myId, child: Text('나 ($myName)')),
                        ...teamProv.currentTeam.memberIds
                            .where((id) => id != myId)
                            .map((id) => DropdownMenuItem(value: id, child: Text(id))),
                      ],
                      onChanged: (v) => setState(() => assigneeId = v ?? myId),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => dueDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            const Icon(Icons.event_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(DateFormat('yyyy.MM.dd').format(dueDate), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.text)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeColor: AppColors.primary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      value: includeInSchedule,
                      onChanged: (v) => setState(() => includeInSchedule = v),
                      title: const Text('일정에 포함', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text)),
                      subtitle: const Text('일정 탭에서 표시', style: TextStyle(color: AppColors.hint)),
                    ),
                    if (includeInSchedule)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              initialDateRange: scheduleRange,
                            );
                            if (picked != null) setState(() => scheduleRange = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                const Text('일정', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text)),
                                const Spacer(),
                                Text('${DateFormat('yy.MM.dd').format(scheduleRange.start)} ~ ${DateFormat('yy.MM.dd').format(scheduleRange.end)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final title = widget.titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    final assigneeName = (assigneeId == myId) ? myName : assigneeId;
                    final newTaskId = const Uuid().v4();
                    final task = Task(
                      id: newTaskId, teamId: teamProv.currentTeamId, title: title, creatorId: myId, creatorName: myName,
                      assigneeId: assigneeId, assigneeName: assigneeName, assigneeEmoji: assigneeId == myId ? '👷' : '👤',
                      projectId: projectId, createdAt: DateTime.now(), dueDate: dueDate, updatedAt: DateTime.now(), priority: priority,
                    );
                    await prov.addTask(task);
                    await prov.setScheduleOptions(taskId: newTaskId, includeInSchedule: includeInSchedule, range: includeInSchedule ? scheduleRange : null);
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('저장', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _priorityText(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return '상';
      case TaskPriority.medium: return '중';
      case TaskPriority.low: return '하';
      case TaskPriority.none: return '-';
    }
  }
}
