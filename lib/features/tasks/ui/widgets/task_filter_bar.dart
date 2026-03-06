import 'package:flutter/material.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/task_sort_field.dart';

/// 상단 필터/컨트롤 바
/// - 1줄 유지
/// - 프로젝트 / 묶음 / 정렬 / 정렬순서 / 뷰 토글
/// - 작은 화면에서는 가로 스크롤로 압축을 피한다.
class TaskFilterBar extends StatelessWidget {
  const TaskFilterBar({
    super.key,
    required this.taskProv,
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
  });

  final TaskProvider taskProv;

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 108,
            child: _twoLineBox(
              label: '프로젝트',
              value: _projectLabel(selProjectId),
              onTap: () => _pickFromSheet(
                context: context,
                title: '프로젝트 선택',
                current: selProjectId,
                items: _projectItems(),
                itemLabel: (id) => _projectLabel(id),
                onPicked: onProjectChanged,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: _twoLineBox(
              label: '묶음',
              value: groupValue,
              onTap: () => _pickFromSheet(
                context: context,
                title: '묶음 기준 선택',
                current: groupValue,
                items: groupItems,
                itemLabel: (s) => s,
                onPicked: onGroupChanged,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: _twoLineBox(
              label: '정렬',
              value: _sortLabel(sortValue),
              onTap: () => _pickFromSheet(
                context: context,
                title: '정렬 기준 선택',
                current: sortValue,
                items: sortItems,
                itemLabel: _sortLabel,
                onPicked: onSortChanged,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _iconBtn(
            icon: newestFirst
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            tooltip: newestFirst ? '내림차순' : '오름차순',
            selected: false,
            onTap: onToggleNewestFirst,
          ),
          const SizedBox(width: 10),
          _iconBtn(
            icon: isGallery ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
            tooltip: isGallery ? '리스트 보기' : '갤러리 보기',
            selected: true,
            onTap: onToggleGallery,
          ),
        ],
      ),
    );
  }

  List<String> _projectItems() {
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
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF4B5563), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F0FF) : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
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
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      final selected = item == current;
                      return ListTile(
                        title: Text(
                          itemLabel(item),
                          style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: selected
                                ? AppPalette.primary
                                : Colors.black87,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppPalette.primary,
                              )
                            : null,
                        onTap: () => Navigator.pop(ctx, item),
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
