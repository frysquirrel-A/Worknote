import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:worknote/main.dart' as app;

Future<void> _tapTab(
  WidgetTester tester, {
  required String label,
  required IconData icon,
}) async {
  final byLabel = find.text(label);
  if (byLabel.evaluate().isNotEmpty) {
    await tester.tap(byLabel.first);
  } else {
    final byIcon = find.byIcon(icon);
    expect(byIcon, findsWidgets);
    await tester.tap(byIcon.first);
  }
  await tester.pumpAndSettle();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('WorkNote UI 자동 정찰 드론', (WidgetTester tester) async {
    await binding.convertFlutterSurfaceToImage();
    app.main();
    await tester.pumpAndSettle();

    await binding.takeScreenshot('01_home_tab');

    await _tapTab(
      tester,
      label: '할일',
      icon: Icons.check_circle_outline_rounded,
    );
    await binding.takeScreenshot('02_tasks_tab');

    await _tapTab(tester, label: '일정', icon: Icons.calendar_month_outlined);
    await binding.takeScreenshot('03_schedule_tab');
  });
}
