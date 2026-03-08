import 'package:flutter/material.dart';

import 'package:worknote/core/ui/app_palette.dart';

class JournalViewModeToggle extends StatelessWidget {
  final String viewMode;
  final ValueChanged<String> onChanged;
  final AppModePalette palette;

  const JournalViewModeToggle({
    super.key,
    required this.viewMode,
    required this.onChanged,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _segment('일자별', viewMode == '일자별'),
        _segment('전체 리스트', viewMode == '전체 리스트'),
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
                color: isSelected ? palette.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? palette.accent : palette.hint,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
