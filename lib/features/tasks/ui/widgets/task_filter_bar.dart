import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/task_sort_field.dart';
import 'package:worknote/features/team/state/team_provider.dart';
import 'package:worknote/domain/models.dart';

/// 상단 필터/컨트롤 바
/// - 좌측: (프로젝트/상태/중요도/담당자) 필터 박스 (가로 스크롤)
/// - 중앙: 구분선(세로 막대)
/// - 우측: 그룹/정렬 박스 + 순서/보기 아이콘(텍스트 없음)
///
/// 디자인 규칙:
/// - 둥근 모서리 박스 + 약한 음영
/// - 선택 여부와 무관하게 테두리는 진하게(가독성)
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
  final ValueChanged<String> onProjectChanged;

  final String selStatus; // '진행중' | '완료'
  final ValueChanged<String> onStatusChanged;

  final TaskPriority? selPriority; // 'all' | 'high' | 'medium' | 'low'
  final ValueChanged<TaskPriority?> onPriorityChanged;

  final String selAssignee; // 'all' | 'me' | memberId
  final ValueChanged<String> onAssigneeChanged;

  final bool showGroupHeaders;
  final VoidCallback onToggleGroupHeaders;

  // --- Assignee helpers ----------------------------------------------------
  // TaskProvider.assigneeFilter 는 'all' | 'me' | '<memberId>' 형태로 저장합니다.
  List<String> _assigneeItems() {
    final ids = List<String>.from(teamProv.currentTeam.memberIds)..sort();
    final items = <String>['all', 'me'];
    items.addAll(ids.where((id) => id != myId));
    return items;
  }

  String _assigneeLabel(String assigneeKey) {
    if (assigneeKey == 'all') return '전체';
    if (assigneeKey == 'me') return '나';

    // 사용자 이름이 있으면 표시 (없으면 id 그대로)
    try {
      final usersBox = Hive.box<AppUser>('users');
      final u = usersBox.get(assigneeKey);
      return (u?.name ?? '').isNotEmpty ? u!.name : assigneeKey;
    } catch (_) {
      return assigneeKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _twoLineBox(
                label: '프로젝트',
                value: _projectLabel(selProjectId),
                onTap: () => _pickFromSheet(
                  context: context,
                  title: '프로젝트 선택',
                  current: selProjectId,
                  items: _projectItems(),
                  itemLabel: (id) => _projectLabel(id),
                  onPicked: (v) => onProjectChanged(v),
                ),
              ),
              const SizedBox(width: 8),
              _twoLineBox(
                label: '상태',
                value: selStatus,
                onTap: () => _pickFromSheet(
                  context: context,
                  title: '상태 선택',
                  current: selStatus,
                  items: const ['진행중', '완료'],
                  itemLabel: (s) => s,
                  onPicked: (v) => onStatusChanged(v),
                ),
              ),
              const SizedBox(width: 8),
              _twoLineBox(
                label: '중요도',
                value: _priorityDisplay(selPriority),
                onTap: () => _pickFromSheet<Object>(
                  context: context,
                  title: '중요도 선택',
                  current: selPriority ?? _SheetItem.all,
                  items: const [
                    _SheetItem.all,
                    TaskPriority.high,
                    TaskPriority.medium,
                    TaskPriority.low,
                    TaskPriority.none,
                  ],
                  itemLabel: (v) {
                    if (v == _SheetItem.all) return '전체';
                    if (v is TaskPriority) return _priorityDisplay(v);
                    return v.toString();
                  },
                  onPicked: (picked) {
                    if (picked == _SheetItem.all) {
                      onPriorityChanged(null);
                    } else {
                      onPriorityChanged(picked as TaskPriority);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              _twoLineBox(
                label: '담당자',
                value: _assigneeLabel(selAssignee),
                onTap: () => _pickFromSheet(
                  context: context,
                  title: '담당자 선택',
                  current: selAssignee,
                  items: _assigneeItems(),
                  itemLabel: (id) => _assigneeLabel(id),
                  onPicked: (v) => onAssigneeChanged(v),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _twoLineBox(
                label: '분류',
                value: groupValue,
                minWidth: 96,
                onTap: () => _pickFromSheet(
                  context: context,
                  title: '분류 선택',
                  current: groupValue,
                  items: groupItems,
                  itemLabel: (s) => s,
                  onPicked: (v) => onGroupChanged(v),
                ),
              ),
              const SizedBox(width: 8),
              _twoLineBox(
                label: '기간',
                value: _sortLabel(sortValue),
                minWidth: 104,
                onTap: () => _pickFromSheet(
                  context: context,
                  title: '정렬 선택',
                  current: sortValue,
                  items: sortItems,
                  itemLabel: (s) => _sortLabel(s),
                  onPicked: (v) => onSortChanged(v),
                ),
              ),
              const SizedBox(width: 8),
              _iconBtn(
                icon: Icons.grid_view_rounded,
                tooltip: '갤러리 보기',
                selected: isGallery,
                onTap: isGallery ? () {} : onToggleGallery,
              ),
              const SizedBox(width: 8),
              _iconBtn(
                icon: Icons.view_agenda_rounded,
                tooltip: '리스트 보기',
                selected: !isGallery,
                onTap: isGallery ? onToggleGallery : () {},
              ),
              const SizedBox(width: 8),
              _iconBtn(
                icon: Icons.label_rounded,
                tooltip: showGroupHeaders ? '그룹 보기 켜짐' : '그룹 보기 꺼짐',
                selected: showGroupHeaders,
                onTap: onToggleGroupHeaders,
              ),
              const SizedBox(width: 8),
              _iconBtn(
                icon: newestFirst
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                tooltip: newestFirst ? '내림차순' : '오름차순',
                selected: false,
                onTap: onToggleNewestFirst,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _projectItems() {
    // project list from provider
    final items = <String>['all', 'none'];
    for (final p in taskProv.projects) {
      items.add(p.id);
    }
    return items;
  }

  String _projectLabel(String id) {
    if (id == 'all') return '전체';
    if (id == 'none') return '없음';
    for (final p in taskProv.projects) {
      if (p.id == id) return p.name;
    }
    return '전체';
  }

  String _priorityDisplay(TaskPriority? p) {
    switch (p) {
      case null:
        return '전체';
      case TaskPriority.high:
        return '상';
      case TaskPriority.medium:
        return '중';
      case TaskPriority.low:
        return '하';
      case TaskPriority.none:
        return '없음';
    }
  }

  String _sortLabel(TaskSortField f) {
    switch (f) {
      case TaskSortField.createdAt:
        return '작성일';
      case TaskSortField.updatedAt:
        return '수정일';
      case TaskSortField.dueDate:
        return '기한';
      case TaskSortField.scheduleStart:
        return '계획';
      case TaskSortField.completedAt:
        return '완료일';
    }
  }

  Widget _twoLineBox({
    required String label,
    required String value,
    required VoidCallback onTap,
    double minWidth = 98,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minWidth: minWidth),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4B5563), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required String tooltip,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F0FF) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppPalette.primary : const Color(0xFF4B5563),
            width: 1,
          ),
        ),
        child: Tooltip(
          message: tooltip,
          child: Icon(
            icon,
            size: 20,
            color: selected ? AppPalette.primary : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromSheet<T>({
    required BuildContext context,
    required String title,
    required T current,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T> onPicked,
  }) async {
    final picked = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final it = items[i];
                      final isSel = it == current;
                      return ListTile(
                        title: Text(
                          itemLabel(it),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        trailing: isSel
                            ? const Icon(
                                Icons.check_rounded,
                                color: Color(0xFF2563EB),
                              )
                            : null,
                        onTap: () => Navigator.pop(ctx, it),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null) {
      onPicked(picked);
    }
  }
}

/// BottomSheet에서 "전체"를 표현하기 위한 sentinel.
enum _SheetItem { all }
