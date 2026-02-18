import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/task_tab.dart'; // TaskSortField enum
import 'package:worknote/features/team/state/team_provider.dart';

// Member 클래스
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

  @override
  Widget build(BuildContext context) {
    // Hive에서 직접 멤버 정보 조회하여 Member 리스트 생성
    final userBox = Hive.box<AppUser>('users');
    final members = teamProv.currentTeam.memberIds.map((id) {
      final user = userBox.get(id);
      return Member(id: id, name: user?.name ?? id);
    }).toList();

    // [핵심 변경] 가로 스크롤(SingleChildScrollView) 제거
    // 대신 Column + Row(Expanded) 조합으로 화면에 딱 맞춤
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white, // 배경색 추가하여 깔끔하게
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- 1단: 필터 영역 (프로젝트, 상태, 중요도, 담당자) ---
          Row(
            children: [
              _filterItem(
                context: context,
                label: _projectDisplay(selProjectId, taskProv.projects),
                isActive: selProjectId != 'all',
                items: ['all', ...taskProv.projects.where((p) => p.teamId == teamProv.currentTeamId).map((e) => e.id)],
                value: selProjectId,
                itemLabel: (v) => v == 'all' ? '전체 프로젝트' : (taskProv.projects.firstWhere((p) => p.id == v, orElse: () => Project(id: '', teamId: '', name: '알 수 없음', colorValue: 0)).name),
                onSelected: onProjectChanged,
              ),
              const SizedBox(width: 8),
              _filterItem(
                context: context,
                label: _statusDisplay(selStatus),
                isActive: selStatus != 'all',
                items: ['all', '진행중', '완료'],
                value: selStatus,
                itemLabel: (v) => v == 'all' ? '전체 상태' : v,
                onSelected: onStatusChanged,
              ),
              const SizedBox(width: 8),
              _filterItem(
                context: context,
                label: _priorityDisplay(selPriority),
                isActive: selPriority != null,
                items: [null, ...TaskPriority.values.where((p) => p != TaskPriority.none)],
                value: selPriority,
                itemLabel: (v) => v == null ? '전체 중요도' : _priorityDisplay(v),
                onSelected: onPriorityChanged,
              ),
              const SizedBox(width: 8),
              _filterItem(
                context: context,
                label: _assigneeDisplay(selAssignee, members, myId),
                isActive: selAssignee != 'all',
                items: ['all', ...members.map((m) => m.id)],
                value: selAssignee,
                itemLabel: (v) => _assigneeDisplay(v, members, myId),
                onSelected: onAssigneeChanged,
              ),
            ],
          ),

          const SizedBox(height: 8), // 줄바꿈 간격

          // --- 2단: 보기 설정 영역 (그룹, 정렬, 순서, 뷰모드) ---
          Row(
            children: [
              _dropdownItem(
                context: context,
                value: groupValue,
                items: groupItems,
                onChanged: onGroupChanged,
              ),
              const SizedBox(width: 8),
              _dropdownItem(
                context: context,
                value: sortValue,
                items: sortItems,
                onChanged: onSortChanged,
                labelBuilder: (v) => _sortLabel(v),
              ),
              const SizedBox(width: 8),
              
              // 순서 변경 버튼 (Expanded로 너비 맞춤)
              Expanded(
                child: InkWell(
                  onTap: onToggleNewestFirst,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      newestFirst ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: AppColors.text2,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 뷰 모드 변경 버튼 (Expanded로 너비 맞춤)
              Expanded(
                child: InkWell(
                  onTap: onToggleGallery,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: isGallery ? AppPalette.primary.withValues(alpha: 0.1) : AppColors.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isGallery ? AppPalette.primary : AppColors.border),
                    ),
                    child: Icon(
                      isGallery ? Icons.grid_view_rounded : Icons.list_alt_rounded,
                      color: isGallery ? AppPalette.primary : AppColors.text2,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

  // Expanded를 사용하여 1/N 크기로 강제 배분
  Widget _filterItem<T>({
    required BuildContext context,
    required String label,
    required bool isActive,
    required List<T> items,
    required T value,
    required String Function(T) itemLabel,
    required ValueChanged<T> onSelected,
  }) {
    final fg = isActive ? AppPalette.primary : AppColors.text2;
    final bg = isActive ? AppPalette.primary.withValues(alpha: 0.1) : AppColors.bg;
    final border = isActive ? AppPalette.primary : AppColors.border;
    final fontWeight = isActive ? FontWeight.bold : FontWeight.normal;

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
                children: items.map((item) => ListTile(
                  title: Text(itemLabel(item), style: TextStyle(
                    fontWeight: item == value ? FontWeight.bold : FontWeight.normal,
                    color: item == value ? AppPalette.primary : AppColors.text,
                  )),
                  trailing: item == value ? const Icon(Icons.check, color: AppPalette.primary) : null,
                  onTap: () => Navigator.pop(ctx, item),
                )).toList(),
              ),
            ),
          );
          if (picked != null) onSelected(picked);
        },
        child: Container(
          height: 36, // 높이 고정
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Text(
            label, 
            style: TextStyle(color: fg, fontWeight: fontWeight, fontSize: 11),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _dropdownItem<T>({
    required BuildContext context,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T)? labelBuilder,
  }) {
    // 드롭다운도 Expanded로 공간 차지
    return Expanded(
      flex: 2, // 드롭다운은 버튼보다 조금 더 넓게 (글자가 길어서)
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true, // 내부 텍스트 꽉 차게
            isDense: true,
            icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.hint),
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11, color: AppColors.text),
            items: items.map((e) => DropdownMenuItem(
              value: e, 
              child: Text(
                labelBuilder != null ? labelBuilder(e) : e.toString(),
                overflow: TextOverflow.ellipsis,
              ),
            )).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  // --- Display Logics ---

  String _projectDisplay(String id, List<Project> projects) {
    if (id == 'all') return '프로젝트';
    final name = projects.firstWhere((p) => p.id == id, orElse: () => Project(id: '', teamId: '', name: '-', colorValue: 0)).name;
    return name;
  }

  String _statusDisplay(String status) {
    if (status == 'all') return '상태';
    return status;
  }

  String _priorityDisplay(TaskPriority? p) {
    if (p == null) return '중요도';
    return switch (p) {
      TaskPriority.high => '높음',
      TaskPriority.medium => '중간',
      TaskPriority.low => '낮음',
      TaskPriority.none => '없음',
    };
  }

  String _assigneeDisplay(String id, List<Member> members, String myId) {
    if (id == 'all') return '담당자';
    if (id == myId) return '나';
    final m = members.firstWhere((m) => m.id == id, orElse: () => Member(id: '', name: '미정'));
    return m.name;
  }

  String _sortLabel(TaskSortField f) {
    return switch (f) {
      TaskSortField.dueDate => '마감일순',
      TaskSortField.createdAt => '생성일순',
      TaskSortField.updatedAt => '수정일순',
      TaskSortField.scheduleStart => '일정순',
      TaskSortField.completedAt => '완료일순',
      _ => '정렬',
    };
  }
}
