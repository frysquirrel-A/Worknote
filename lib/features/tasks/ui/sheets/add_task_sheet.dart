import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 업무 추가 바텀시트를 표시하는 함수
Future<void> showAddTaskSheet({required BuildContext context}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _AddTaskSheet(),
  );
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet({super.key});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  // [요구사항 1] 컨트롤러를 State 내부에서 관리하여 생명주기 안전성 확보
  late TextEditingController _titleCtrl;
  
  String? projectId;
  late String assigneeId;
  DateTime dueDate = DateTime.now();
  bool includeInSchedule = true;
  DateTimeRange scheduleRange = DateTimeRange(start: DateTime.now(), end: DateTime.now());
  TaskPriority priority = TaskPriority.none;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    // 초기 담당자 설정을 위해 read 사용 (불필요한 리빌드 방지)
    final authProv = context.read<AuthProvider>();
    assigneeId = authProv.currentUser?.id ?? 'me';
  }

  @override
  void dispose() {
    // [요구사항 1] 위젯 소멸 시 컨트롤러도 함께 안전하게 해제
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final taskProv = context.watch<TaskProvider>();
    final authProv = context.watch<AuthProvider>();

    final myId = authProv.currentUser?.id ?? 'me';
    final myName = authProv.currentUser?.name ?? '관리자';
    
    // Hive에서 사용자 목록 가져오기
    final userBox = Hive.box<AppUser>('users');
    final members = teamProv.currentTeam.memberIds.map((id) => userBox.get(id)).whereType<AppUser>().toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('새 업무 등록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text)),
            const SizedBox(height: 16),
            
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
              decoration: InputDecoration(
                hintText: '업무 제목을 입력하세요',
                hintStyle: const TextStyle(color: AppColors.hint, fontWeight: FontWeight.normal),
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: assigneeId,
                    style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800),
                    iconEnabledColor: AppColors.text2,
                    dropdownColor: AppColors.surface,
                    decoration: InputDecoration(
                      labelText: '담당자', 
                      labelStyle: const TextStyle(color: AppColors.text2),
                      filled: true, 
                      fillColor: Colors.white, 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border))
                    ),
                    items: members.map((m) => DropdownMenuItem(value: m.id, child: Text(m.id == myId ? '나 (${m.name})' : m.name, style: const TextStyle(color: AppColors.text)))).toList(),
                    onChanged: (v) => setState(() => assigneeId = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800),
                    iconEnabledColor: AppColors.text2,
                    initialValue: projectId,
                    dropdownColor: AppColors.surface,
                    decoration: InputDecoration(
                      labelText: '프로젝트', 
                      labelStyle: const TextStyle(color: AppColors.text2),
                      filled: true, 
                      fillColor: Colors.white, 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border))
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('일반 업무', style: TextStyle(color: AppColors.text))),
                      ...taskProv.projects
                          .where((p) => p.teamId == teamProv.currentTeamId)
                          .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: const TextStyle(color: AppColors.text)))),
                    ],
                    onChanged: (v) => setState(() => projectId = v),
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
                      final picked = await showDatePicker(context: context, initialDate: dueDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (picked != null) setState(() => dueDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('기한', style: TextStyle(fontSize: 10, color: AppColors.hint)), Text(DateFormat('yyyy.MM.dd').format(dueDate), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.text))]),
                          const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<TaskPriority>(
                    style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800),
                    iconEnabledColor: AppColors.text2,
                    initialValue: priority,
                    dropdownColor: AppColors.surface,
                    decoration: InputDecoration(
                      labelText: '중요도', 
                      labelStyle: const TextStyle(color: AppColors.text2),
                      filled: true, 
                      fillColor: Colors.white, 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border))
                    ),
                    items: const [
                      DropdownMenuItem(value: TaskPriority.none, child: Text('없음', style: TextStyle(color: AppColors.text))),
                      DropdownMenuItem(value: TaskPriority.low, child: Text('낮음', style: TextStyle(color: AppColors.text))),
                      DropdownMenuItem(value: TaskPriority.medium, child: Text('중간', style: TextStyle(color: AppColors.text))),
                      DropdownMenuItem(value: TaskPriority.high, child: Text('높음', style: TextStyle(color: AppColors.danger))),
                    ],
                    onChanged: (v) => setState(() => priority = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('달력(계획)에 표시하기', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
                  Switch(
                    value: includeInSchedule,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.25),
                    onChanged: (v) => setState(() => includeInSchedule = v),
                  ),
                ],
              ),
            ),
            if (includeInSchedule) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2030), initialDateRange: scheduleRange);
                  if (picked != null) setState(() => scheduleRange = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(12), color: AppColors.primary.withValues(alpha: 0.05)),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('${DateFormat('yy.MM.dd').format(scheduleRange.start)} ~ ${DateFormat('yy.MM.dd').format(scheduleRange.end)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
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
                  
                  // [요구사항 3] 저장 시점의 Provider 참조 최적화
                  final currentTaskProv = context.read<TaskProvider>();
                  final currentTeamProv = context.read<TeamProvider>();
                  
                  final assigneeName = (assigneeId == myId) ? myName : assigneeId;
                  final newTaskId = const Uuid().v4();
                  final task = Task(
                    id: newTaskId, 
                    teamId: currentTeamProv.currentTeamId, 
                    title: title, 
                    creatorId: myId, 
                    creatorName: myName,
                    assigneeId: assigneeId, 
                    assigneeName: assigneeName, 
                    assigneeEmoji: assigneeId == myId ? '👷' : '👤',
                    projectId: projectId, 
                    createdAt: DateTime.now(), 
                    dueDate: dueDate, 
                    updatedAt: DateTime.now(), 
                    priority: priority,
                  );
                  
                  await currentTaskProv.addTask(task);
                  await currentTaskProv.setScheduleOptions(taskId: newTaskId, includeInSchedule: includeInSchedule, range: includeInSchedule ? scheduleRange : null);
                  
                  // [요구사항 2] 비동기 작업 후 mounted 체크 필수
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppPalette.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                icon: const Icon(Icons.save_rounded),
                label: const Text('저장', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
