import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';

Future<void> showAddTaskSheet({required BuildContext context}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _AddTaskSheet(),
  );
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  late final TextEditingController _titleCtrl;

  String? projectId;
  late String assigneeId;
  DateTime dueDate = DateTime.now();
  bool includeInSchedule = true;
  DateTimeRange scheduleRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );
  TaskPriority priority = TaskPriority.none;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    final authProv = context.read<AuthProvider>();
    assigneeId = authProv.currentUser?.id ?? 'me';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final taskProv = context.watch<TaskProvider>();
    final authProv = context.watch<AuthProvider>();
    final palette = AppModePalette.fromMode(teamProv.currentThemeMode);

    final myId = authProv.currentUser?.id ?? 'me';
    final myName = authProv.currentUser?.name ?? '관리자';
    final userBox = Hive.box<AppUser>('users');
    final members = teamProv.currentTeam.memberIds
        .map((id) => userBox.get(id))
        .whereType<AppUser>()
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '새 업무 등록',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: palette.text,
              ),
              decoration: InputDecoration(
                hintText: '업무 제목을 입력해 주세요',
                hintStyle: TextStyle(
                  color: palette.hint,
                  fontWeight: FontWeight.normal,
                ),
                filled: true,
                fillColor: palette.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: palette.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: palette.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: palette.accent, width: 1.4),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: assigneeId,
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w800,
                    ),
                    iconEnabledColor: palette.hint,
                    dropdownColor: palette.surface,
                    decoration: _dropdownDecoration(palette),
                    hint: Text('담당자', style: TextStyle(color: palette.hint)),
                    items: members
                        .map(
                          (member) => DropdownMenuItem(
                            value: member.id,
                            child: Text(
                              member.id == myId
                                  ? '나 (${member.name})'
                                  : member.name,
                              style: TextStyle(color: palette.text),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => assigneeId = value!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: projectId,
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w800,
                    ),
                    iconEnabledColor: palette.hint,
                    dropdownColor: palette.surface,
                    decoration: _dropdownDecoration(palette),
                    hint: Text('프로젝트', style: TextStyle(color: palette.hint)),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(
                          '일반 업무',
                          style: TextStyle(color: palette.text),
                        ),
                      ),
                      ...taskProv.projects
                          .where((project) => project.teamId == teamProv.currentTeamId)
                          .map(
                            (project) => DropdownMenuItem(
                              value: project.id,
                              child: Text(
                                project.name,
                                style: TextStyle(color: palette.text),
                              ),
                            ),
                          ),
                    ],
                    onChanged: (value) => setState(() => projectId = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => dueDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceAlt,
                        border: Border.all(color: palette.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '기한',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: palette.hint,
                                ),
                              ),
                              Text(
                                DateFormat('yyyy.MM.dd').format(dueDate),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: palette.text,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: palette.accent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<TaskPriority>(
                    initialValue: priority,
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w800,
                    ),
                    iconEnabledColor: palette.hint,
                    dropdownColor: palette.surface,
                    decoration: _dropdownDecoration(palette),
                    hint: Text('중요도', style: TextStyle(color: palette.hint)),
                    items: [
                      DropdownMenuItem(
                        value: TaskPriority.none,
                        child: Text('없음', style: TextStyle(color: palette.text)),
                      ),
                      DropdownMenuItem(
                        value: TaskPriority.low,
                        child: Text('하', style: TextStyle(color: palette.text)),
                      ),
                      DropdownMenuItem(
                        value: TaskPriority.medium,
                        child: Text('중', style: TextStyle(color: palette.text)),
                      ),
                      const DropdownMenuItem(
                        value: TaskPriority.high,
                        child: Text('상', style: TextStyle(color: AppColors.destructive)),
                      ),
                    ],
                    onChanged: (value) => setState(() => priority = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                border: Border.all(color: palette.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '일정(계획)에 표시하기',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: palette.text,
                    ),
                  ),
                  Switch(
                    value: includeInSchedule,
                    activeThumbColor: palette.accent,
                    activeTrackColor: palette.accent.withValues(alpha: 0.25),
                    onChanged: (value) => setState(() => includeInSchedule = value),
                  ),
                ],
              ),
            ),
            if (includeInSchedule) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDateRange: scheduleRange,
                  );
                  if (!mounted) return;
                  if (picked != null) {
                    setState(() => scheduleRange = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: palette.accent.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: palette.accent.withValues(alpha: 0.08),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: 18,
                        color: palette.accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('yy.MM.dd').format(scheduleRange.start)} ~ ${DateFormat('yy.MM.dd').format(scheduleRange.end)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: palette.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final title = _titleCtrl.text.trim();
                  if (title.isEmpty) return;

                  final currentTaskProv = context.read<TaskProvider>();
                  final currentTeamProv = context.read<TeamProvider>();
                  final assigneeName = _memberName(
                    members,
                    assigneeId,
                    fallback: assigneeId == myId ? myName : assigneeId,
                  );
                  final newTaskId = const Uuid().v4();

                  final task = Task(
                    id: newTaskId,
                    teamId: currentTeamProv.currentTeamId,
                    title: title,
                    creatorId: myId,
                    creatorName: myName,
                    assigneeId: assigneeId,
                    assigneeName: assigneeName,
                    assigneeEmoji: assigneeId == myId ? '🙂' : '👤',
                    projectId: projectId,
                    createdAt: DateTime.now(),
                    dueDate: dueDate,
                    updatedAt: DateTime.now(),
                    priority: priority,
                  );

                  await currentTaskProv.addTask(task);
                  await currentTaskProv.setScheduleOptions(
                    taskId: newTaskId,
                    includeInSchedule: includeInSchedule,
                    range: includeInSchedule ? scheduleRange : null,
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.save_rounded),
                label: const Text(
                  '저장',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(AppModePalette palette) {
    return InputDecoration(
      filled: true,
      fillColor: palette.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.accent, width: 1.4),
      ),
    );
  }

  String _memberName(
    List<AppUser> members,
    String id, {
    required String fallback,
  }) {
    for (final member in members) {
      if (member.id == id) return member.name;
    }
    return fallback;
  }
}
