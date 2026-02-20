import 'package:flutter/material.dart';
import 'package:worknote/features/tasks/ui/task_tab.dart' as feature;

/// Legacy wrapper kept for backward compatibility.
///
/// Some older parts of the codebase (or external patches) may still import
/// `package:worknote/tabs/task_tab.dart`. To avoid "rollbacks" / broken imports,
/// this file now forwards to the new Tasks feature tab.
@Deprecated('Use package:worknote/features/tasks/ui/task_tab.dart')
class TeamTaskTab extends StatelessWidget {
  const TeamTaskTab({super.key});

  @override
  Widget build(BuildContext context) {
    // 레거시 경로(lib/tabs/...)는 새로운 feature 경로를 그대로 위임합니다.
    return const feature.TeamTaskTab();
  }
}
