import 'package:flutter/material.dart';

import 'package:worknote/core/ui/app_palette.dart';

class TaskViewModeToggle extends StatelessWidget {
  final String viewMode;
  final ValueChanged<String> onChanged;

  const TaskViewModeToggle({
    super.key,
    required this.viewMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _segment('리스트', viewMode == '리스트'),
        _segment('날짜별', viewMode == '날짜별'),
      ],
    );
  }

  Widget _segment(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppPalette.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppPalette.primary : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
