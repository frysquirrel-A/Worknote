import 'package:flutter/material.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/task_sort_field.dart';

/// 상단 필터/컨트롤 바
/// - 1줄 고정: 프로젝트 / 분류 / 기간 / 정렬순서 / 뷰 토글
///
/// 디자인 규칙:
/// - 둥근 아웃라인 박스
/// - 선택 여부와 무관하게 테두리는 진하게(가독성)
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
    return Row(
      children: [
        Expanded(
          child: _twoLineBox(
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
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _twoLineBox(
            label: '분류',
            value: groupValue,
            onTap: () => _pickFromSheet(
              context: context,
              title: '분류 선택',
              current: groupValue,
              items: groupItems,
              itemLabel: (s) => s,
              onPicked: (v) => onGroupChanged(v),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _twoLineBox(
            label: '기간',
            value: _sortLabel(sortValue),
            onTap: () => _pickFromSheet(
              context: context,
              title: '정렬 선택',
              current: sortValue,
              items: sortItems,
              itemLabel: (s) => _sortLabel(s),
              onPicked: (v) => onSortChanged(v),
            ),
          ),
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
        const SizedBox(width: 8),
        _iconBtn(
          icon: isGallery ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
          tooltip: isGallery ? '리스트 보기' : '갤러리 보기',
          selected: true,
          onTap: onToggleGallery,
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
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
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
        width: 40,
        height: 40,
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
            size: 19,
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
