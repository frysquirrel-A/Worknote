import 'package:flutter/material.dart';

import 'package:worknote/core/ui/app_palette.dart';

/// Toolbar for date-grouped views.
///
/// Provides:
/// - Date TOC (horizontal chips) show/hide
/// - Date section header show/hide
/// - Sort order toggle (newest/oldest)
/// - Pin a date to the top (reorder)
///
/// NOTE
/// - This component is intentionally stateless.
/// - Persisting choices (e.g. in Hive) can be done at the feature layer.
class DateGroupControls extends StatelessWidget {
  final String title;
  final List<String> dateKeys;
  final String? pinnedDateKey;
  final bool showToc;
  final bool showSectionHeaders;
  final bool newestFirst;

  final VoidCallback onToggleToc;
  final VoidCallback onToggleSectionHeaders;
  final VoidCallback onToggleSortOrder;
  final ValueChanged<String> onSelectDate;
  final VoidCallback onClearPin;

  const DateGroupControls({
    super.key,
    this.title = '날짜',
    required this.dateKeys,
    required this.pinnedDateKey,
    required this.showToc,
    required this.showSectionHeaders,
    required this.newestFirst,
    required this.onToggleToc,
    required this.onToggleSectionHeaders,
    required this.onToggleSortOrder,
    required this.onSelectDate,
    required this.onClearPin,
  });

  @override
  Widget build(BuildContext context) {
    final hasDates = dateKeys.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppPalette.textDark,
                ),
              ),
              const SizedBox(width: 8),
              if (pinnedDateKey != null) _pinnedBadge(pinnedDateKey!),
              const Spacer(),
              Tooltip(
                message: showToc ? '날짜 목차 숨기기' : '날짜 목차 보이기',
                child: IconButton(
                  iconSize: 20,
                  onPressed: hasDates ? onToggleToc : null,
                  icon: Icon(showToc ? Icons.toc_rounded : Icons.toc_outlined),
                  color: AppPalette.primary,
                ),
              ),
              Tooltip(
                message: showSectionHeaders ? '날짜 헤더 숨기기' : '날짜 헤더 보이기',
                child: IconButton(
                  iconSize: 20,
                  onPressed: hasDates ? onToggleSectionHeaders : null,
                  icon: Icon(showSectionHeaders ? Icons.label_rounded : Icons.label_outline_rounded),
                  color: AppPalette.primary,
                ),
              ),
              Tooltip(
                message: newestFirst ? '정렬: 최신순(↓)' : '정렬: 오래된순(↑)',
                child: IconButton(
                  iconSize: 20,
                  onPressed: hasDates ? onToggleSortOrder : null,
                  icon: Icon(newestFirst ? Icons.south_rounded : Icons.north_rounded),
                  color: AppPalette.primary,
                ),
              ),
            ],
          ),
          if (showToc && hasDates) ...[
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(
                    label: '전체',
                    selected: pinnedDateKey == null,
                    onTap: onClearPin,
                    leading: Icons.all_inclusive_rounded,
                  ),
                  const SizedBox(width: 8),
                  for (final k in dateKeys) ...[
                    _chip(
                      label: _shortDate(k),
                      selected: pinnedDateKey == k,
                      onTap: () => onSelectDate(k),
                      leading: pinnedDateKey == k ? Icons.push_pin_rounded : Icons.calendar_today_rounded,
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  static Widget _pinnedBadge(String dateKey) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppPalette.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppPalette.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.push_pin_rounded, size: 14, color: AppPalette.primary),
          const SizedBox(width: 6),
          Text(
            dateKey,
            style: const TextStyle(color: AppPalette.primary, fontWeight: FontWeight.w900, fontSize: 11),
          ),
        ],
      ),
    );
  }

  static Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? leading,
  }) {
    final bg = selected ? AppPalette.primary : Colors.white;
    final fg = selected ? Colors.white : AppPalette.textDark;
    final borderColor = selected ? AppPalette.primary : AppPalette.border;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              Icon(leading, size: 14, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  static String _shortDate(String dateKey) {
    // Expecting yyyy-MM-dd
    if (dateKey.length >= 10) {
      final mm = dateKey.substring(5, 7);
      final dd = dateKey.substring(8, 10);
      return '$mm/$dd';
    }
    return dateKey;
  }
}
