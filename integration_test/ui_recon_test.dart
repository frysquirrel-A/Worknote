import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:worknote/main.dart' as app;

Finder? _firstFound(List<Finder> candidates) {
  for (final candidate in candidates) {
    if (candidate.evaluate().isNotEmpty) {
      return candidate.first;
    }
  }
  return null;
}

Future<void> _pumpFor(WidgetTester tester, [int seconds = 1]) async {
  await tester.pump(Duration(seconds: seconds));
}

Future<bool> _tapIfFound(
  WidgetTester tester,
  List<Finder> candidates, {
  Duration delay = const Duration(seconds: 1),
}) async {
  final target = _firstFound(candidates);
  if (target == null) return false;

  try {
    await tester.tap(target);
    await tester.pump(delay);
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> _enterLocalProfileIfNeeded(WidgetTester tester) async {
  final localEntry = _firstFound([
    find.textContaining('\uAC00\uC785 \uC5C6\uC774'),
    find.textContaining('\uAC1C\uC778\uC6A9'),
    find.byIcon(Icons.person_pin_circle_rounded),
  ]);
  if (localEntry == null) return;

  await tester.tap(localEntry);
  await _pumpFor(tester, 1);

  final nameField = _firstFound([
    find.byType(TextField),
    find.byType(EditableText),
  ]);
  if (nameField != null) {
    await tester.enterText(nameField, 'UI Test');
    await _pumpFor(tester, 1);
  }

  await _tapIfFound(tester, [
    find.text('\uC2DC\uC791\uD558\uAE30'),
    find.byType(ElevatedButton),
  ], delay: const Duration(seconds: 2));
}

Future<void> _waitForTaskTitle(
  WidgetTester tester,
  String title, {
  int maxSeconds = 8,
}) async {
  for (var i = 0; i < maxSeconds; i++) {
    if (_firstFound([find.textContaining(title), find.text(title)]) != null) {
      return;
    }
    await _pumpFor(tester, 1);
  }
}

Future<void> _waitForMainUi(WidgetTester tester, {int maxSeconds = 30}) async {
  for (var i = 0; i < maxSeconds; i++) {
    final ready = _firstFound([
      find.byIcon(Icons.menu_open_rounded),
      find.byIcon(Icons.check_circle_outline_rounded),
      find.byIcon(Icons.calendar_month_outlined),
      find.byIcon(Icons.edit_note_rounded),
      find.byIcon(Icons.photo_library_outlined),
      find.byIcon(Icons.chat_bubble_outline_rounded),
    ]);
    if (ready != null) return;
    await _pumpFor(tester, 1);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('WorkNote UI Integrated Recon Drone (V5)', (
    WidgetTester tester,
  ) async {
    await binding.convertFlutterSurfaceToImage();

    app.main();
    await _pumpFor(tester, 4);
    await _enterLocalProfileIfNeeded(tester);
    await _waitForMainUi(tester);
    await binding.takeScreenshot('step_01_home_root');

    await _tapIfFound(tester, [
      find.text('\uD560\uC77C'),
      find.byIcon(Icons.check_circle_outline_rounded),
    ]);
    await binding.takeScreenshot('step_02_tasks_root');

    await _tapIfFound(tester, [
      find.text('\uC5C5\uBB34 \uCD94\uAC00'),
      find.text('+ \uC5C5\uBB34 \uCD94\uAC00'),
      find.text('+ \uCCAB \uC5C5\uBB34 \uCD94\uAC00\uD558\uAE30'),
      find.byIcon(Icons.add_rounded),
    ], delay: const Duration(seconds: 2));
    await binding.takeScreenshot('step_03_task_add_form');

    final titleField = _firstFound([
      find.byType(TextField),
      find.byType(EditableText),
    ]);
    if (titleField != null) {
      await tester.enterText(
        titleField,
        '\uD14C\uC2A4\uD2B8 \uC5C5\uBB34 1',
      );
      await _pumpFor(tester, 1);
    }

    await _tapIfFound(tester, [
      find.byIcon(Icons.save_rounded),
      find.text('\uC800\uC7A5'),
      find.text('\uC644\uB8CC'),
    ], delay: const Duration(seconds: 2));
    await _waitForTaskTitle(
      tester,
      '\uD14C\uC2A4\uD2B8 \uC5C5\uBB34 1',
    );
    await binding.takeScreenshot('step_04_tasks_populated');

    await _tapIfFound(tester, [
      find.text('\uC77C\uC815'),
      find.byIcon(Icons.calendar_month_outlined),
    ]);
    await binding.takeScreenshot('step_05_schedule_root');

    await _tapIfFound(tester, [
      find.text('\uC77C\uC9C0'),
      find.byIcon(Icons.edit_note_rounded),
    ]);
    await binding.takeScreenshot('step_06_journal_root');

    await _tapIfFound(tester, [
      find.text('\uAC24\uB7EC\uB9AC'),
      find.byIcon(Icons.photo_library_outlined),
    ]);
    await binding.takeScreenshot('step_07_gallery_root');

    await _tapIfFound(tester, [
      find.text('\uCC44\uD305'),
      find.byIcon(Icons.chat_bubble_outline_rounded),
    ]);
    await binding.takeScreenshot('step_08_chat_root');
  });
}
