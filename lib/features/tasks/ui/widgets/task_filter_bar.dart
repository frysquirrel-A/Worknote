import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/task_tab.dart'; 
import 'package:worknote/features/team/state/team_provider.dart';

class Member {
  final String id;
  final String name;
  Member({required this.id, required this.name});
}

class TaskFilterBar extends StatelessWidget {
  const TaskFilterBar({
    super.key,
    required this.taskProv,
    required this.teamProv,
    required this.myId,
    required this.groupValue,
    required this.groupItems,
    required this.onGroupChanged,
    required this.sortValue,
    required this.sortItems,
    required this.onSortChanged,
    required this.newestFirst,
    required this.onToggleNewestFirst,
    required this.isGallery,
    required this.onToggleGallery,
    required this.selProjectId,
    required this.onProjectChanged,
    required this.selStatus,
    required this.onStatusChanged,
    required this.selPriority,
    required this.onPriorityChanged,
    required this.selAssignee,
    required this.onAssigneeChanged,
    required this.showGroupHeaders,
    required this.onToggleGroupHeaders,
  });

  final TaskProvider taskProv;
  final TeamProvider teamProv;
  final String myId;

  final String groupValue;
  final List<String> groupItems;
  final ValueChanged<String?> onGroupChanged;

  final TaskSortField sortValue;
  final List<TaskSortField> sortItems;
  final ValueChanged<TaskSortField?> onSortChanged;

  final bool newestFirst;
  final VoidCallback onToggleNewestFirst;

  final bool isGallery;
  final VoidCallback onToggleGallery;

  final String selProjectId;
  final ValueChanged<String?> onProjectChanged;

  final String selStatus;
  final ValueChanged<String?> onStatusChanged;

  final TaskPriority? selPriority;
  final ValueChanged<TaskPriority?> onPriorityChanged;

  final String selAssignee;
  final ValueChanged<String?> onAssigneeChanged;

  final bool showGroupHeaders;
  final VoidCallback onToggleGroupHeaders;

  @override
  Widget build(BuildContext context) {
    final userBox = Hive.box<AppUser>('users');
    final members = teamProv.currentTeam.memberIds.map((id) {
      final user = userBox.get(id);
      return Member(id: id, name: user?.name ?? id);
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _filterItem<String>(
                context: context,
                label: _projectDisplay(selProjectId, taskProv.projects),
                icon: Icons.folder_open_rounded,
                isActive: selProjectId != 'all',
                items: ['all', 'none', ...taskProv.projects.where((p) => p.teamId == teamProv.currentTeamId).map((e) => e.id)],
                value: selProjectId,
                itemLabel: (v) => v == 'all' ? '전체' : (v == 'none' ? '없음' : taskProv.projects.firstWhere((p) => p.id == v).name),
                onSelected: onProjectChanged,
              ),
              const SizedBox(width: 8),
              _filterItem<String>(
                context: context,
                label: _statusDisplay(selStatus),
                icon: Icons.check_circle_outline_rounded,
                isActive: selStatus != 'all',
                items: ['all', '진행중', '완료'],
                value: selStatus,
                itemLabel: (v) => v == 'all' ? '전체' : v,
                onSelected: onStatusChanged,
              ),
              const SizedBox(width: 8),
              _filterItem<TaskPriority?>(
                context: context,
                label: _priorityDisplay(selPriority),
                icon: Icons.flag_outlined,
                isActive: selPriority != null,
                items: [null, ...TaskPriority.values.where((p) => p != TaskPriority.none)],
                value: selPriority,
                itemLabel: (v) => v == null ? '전체' : _priorityDisplay(v),
                onSelected: (v) => onPriorityChanged(v),
              ),
              const SizedBox(width: 8),
              _filterItem<String>(
                context: context,
                label: _assigneeDisplay(selAssignee, members, myId),
                icon: Icons.person_outline_rounded,
                isActive: selAssignee != 'all',
                items: ['all', ...members.map((m) => m.id)],
                value: selAssignee,
                itemLabel: (v) => _assigneeDisplay(v, members, myId),
                onSelected: onAssigneeChanged,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _dropdownItem(
                context: context,
                icon: Icons.dns_rounded,
                value: groupValue,
                items: groupItems,
                onChanged: onGroupChanged,
              ),
              const SizedBox(width: 8),
              _dropdownItem(
                context: context,
                icon: Icons.sort_rounded,
                value: sortValue,
                items: sortItems,
                onChanged: onSortChanged,
                labelBuilder: (v) => _sortLabel(v as TaskSortField),
              ),
              const SizedBox(width: 8),
              _iconBtnItem(
                icon: newestFirst ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                isActive: false,
                onTap: onToggleNewestFirst,
              ),
              const SizedBox(width: 8),
              _iconBtnItem(
                icon: isGallery ? Icons.grid_view_rounded : Icons.list_alt_rounded,
                isActive: isGallery,
                onTap: onToggleGallery,
              ),
              const SizedBox(width: 8),
              _iconBtnItem(
                icon: showGroupHeaders ? Icons.label_rounded : Icons.label_outline_rounded,
                isActive: showGroupHeaders,
                onTap: onToggleGroupHeaders,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterItem<T>({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isActive,
    required List<T> items,
    required T value,
    required String Function(T) itemLabel,
    required ValueChanged<T> onSelected,
  }) {
    final fgColor = isActive ? AppPalette.primary : AppTextColor.secondary;
    final borderColor = isActive ? AppPalette.primary : AppPalette.border;

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          final picked = await showModalBottomSheet<T>(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (ctx) => Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = item == value;
                        return ListTile(
                          title: Text(itemLabel(item), style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppPalette.primary : AppTextColor.primary,
                          )),
                          trailing: isSelected ? const Icon(Icons.check, color: AppPalette.primary) : null,
                          onTap: () => Navigator.pop(ctx, item),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
          if (picked != null) onSelected(picked);
        },
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: fgColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label, 
                  style: TextStyle(color: fgColor, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_drop_down_rounded, size: 16, color: fgColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownItem<T>({
    required BuildContext context,
    required IconData icon,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T)? labelBuilder,
  }) {
    return Expanded(
      flex: 3, 
      child: Container(
        height: 38,
        padding: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppPalette.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true, 
            isDense: true,
            icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTextColor.hint),
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11, color: AppTextColor.primary),
            items: items.map((e) => DropdownMenuItem(
              value: e, 
              child: Row(
                children: [
                  Icon(icon, size: 14, color: AppTextColor.hint),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      labelBuilder != null ? labelBuilder(e) : e.toString(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _iconBtnItem({required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return Expanded(
      flex: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: isActive ? AppPalette.primary.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isActive ? AppPalette.primary : AppPalette.border),
          ),
          child: Icon(
            icon,
            color: isActive ? AppPalette.primary : AppTextColor.secondary,
            size: 18,
          ),
        ),
      ),
    );
  }

  String _projectDisplay(String id, List<Project> projects) {
    if (id == 'all') return '전체';
    final found = projects.where((p) => p.id == id).toList();
    if(found.isEmpty) return id == 'none' ? '없음' : '전체';
    return found.first.name;
  }

  String _statusDisplay(String status) {
    if (status == 'all') return '전체';
    return status;
  }

  String _priorityDisplay(TaskPriority? p) {
    if (p == null) return '전체';
    return switch (p) {
      TaskPriority.high => '높음',
      TaskPriority.medium => '중간',
      TaskPriority.low => '낮음',
      TaskPriority.none => '없음',
    };
  }

  String _assigneeDisplay(String id, List<Member> members, String myId) {
    if (id == 'all') return '전체';
    if (id == myId) return '나';
    final found = members.where((m) => m.id == id).toList();
    return found.isEmpty ? '미정' : found.first.name;
  }

  String _sortLabel(TaskSortField f) {
    return switch (f) {
      TaskSortField.dueDate => '마감',
      TaskSortField.createdAt => '생성',
      TaskSortField.updatedAt => '수정',
      TaskSortField.scheduleStart => '일정',
      TaskSortField.completedAt => '완료',
    };
  }
}
