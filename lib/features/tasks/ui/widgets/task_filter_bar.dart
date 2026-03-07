import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/task_sort_field.dart';
import 'package:worknote/features/team/state/team_provider.dart';

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
    final palette = _FilterPalette.fromMode(
      context.watch<TeamProvider>().currentThemeMode.toLowerCase(),
    );

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.groupBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.groupBorder),
        boxShadow: palette.groupShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _segmentedField(
                  palette: palette,
                  icon: Icons.folder_open_rounded,
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
              const SizedBox(width: 8),
              Expanded(
                child: _segmentedField(
                  palette: palette,
                  icon: Icons.segment_rounded,
                  label: '분류',
                  value: groupValue,
                  onTap: () => _pickFromSheet(
                    context: context,
                    title: '분류 기준 선택',
                    current: groupValue,
                    items: groupItems,
                    itemLabel: (item) => item,
                    onPicked: onGroupChanged,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _segmentedField(
                  palette: palette,
                  icon: Icons.sort_rounded,
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
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              _iconBtn(
                palette: palette,
                icon: newestFirst
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                tooltip: newestFirst ? '최신순' : '오래된순',
                selected: false,
                onTap: onToggleNewestFirst,
              ),
              const SizedBox(width: 8),
              _iconBtn(
                palette: palette,
                icon: isGallery
                    ? Icons.view_agenda_rounded
                    : Icons.grid_view_rounded,
                tooltip: isGallery ? '리스트 보기' : '카드 보기',
                selected: true,
                onTap: onToggleGallery,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _projectItems() {
    final items = <String>['all', 'none'];
    for (final project in taskProv.projects) {
      items.add(project.id);
    }
    return items;
  }

  String _projectLabel(String id) {
    if (id == 'all') return '전체';
    if (id == 'none') return '미분류';
    for (final project in taskProv.projects) {
      if (project.id == id) return project.name;
    }
    return '전체';
  }

  String _sortLabel(TaskSortField field) => field.label;

  Widget _segmentedField({
    required _FilterPalette palette,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: palette.surfaceColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: palette.borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: palette.accent),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: palette.iconColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: palette.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn({
    required _FilterPalette palette,
    required IconData icon,
    required String tooltip,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected ? palette.selectedFill : palette.surfaceColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? palette.accent : palette.borderColor,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: selected ? palette.accent : palette.iconColor,
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
    final palette = _FilterPalette.fromMode(
      context.read<TeamProvider>().currentThemeMode.toLowerCase(),
    );

    final picked = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: palette.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: palette.borderColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: palette.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      final selected = item == current;
                      return ListTile(
                        title: Text(
                          itemLabel(item),
                          style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: selected
                                ? palette.accent
                                : palette.textColor,
                          ),
                        ),
                        trailing: selected
                            ? Icon(Icons.check_rounded, color: palette.accent)
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
      HapticFeedback.selectionClick();
      onPicked(picked);
    }
  }
}

class _FilterPalette {
  const _FilterPalette({
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.iconColor,
    required this.accent,
    required this.selectedFill,
    required this.groupBackground,
    required this.groupBorder,
    required this.groupShadow,
  });

  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color iconColor;
  final Color accent;
  final Color selectedFill;
  final Color groupBackground;
  final Color groupBorder;
  final List<BoxShadow> groupShadow;

  factory _FilterPalette.fromMode(String mode) {
    switch (mode) {
      case 'dark':
        return const _FilterPalette(
          surfaceColor: AppColors.darkSurface2,
          borderColor: AppColors.darkBorder,
          textColor: AppColors.darkText,
          iconColor: AppColors.darkHint,
          accent: AppColors.premiumBlue,
          selectedFill: AppColors.darkSurface,
          groupBackground: Color(0xCC122347),
          groupBorder: AppColors.darkBorder,
          groupShadow: [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        );
      case 'blue':
        return const _FilterPalette(
          surfaceColor: Color(0xFFF9FBFF),
          borderColor: Color(0xFFB9D2FF),
          textColor: AppColors.text,
          iconColor: Color(0xFF527199),
          accent: AppColors.premiumBlueStrong,
          selectedFill: Color(0xFFDDEAFF),
          groupBackground: Color(0xFFF0F7FF),
          groupBorder: Color(0xFFD5E5FF),
          groupShadow: [
            BoxShadow(
              color: Color(0x102E5FAF),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        );
      default:
        return const _FilterPalette(
          surfaceColor: Colors.white,
          borderColor: Color(0xFFE5E7EB),
          textColor: AppColors.text,
          iconColor: Color(0xFF6B7280),
          accent: AppColors.primary,
          selectedFill: Color(0xFFE8F0FF),
          groupBackground: Color(0xFFF8FAFC),
          groupBorder: Color(0xFFE5E7EB),
          groupShadow: [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        );
    }
  }
}
