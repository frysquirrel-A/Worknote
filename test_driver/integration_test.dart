import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _runFolderName() {
  final now = DateTime.now();
  final yyyy = now.year.toString();
  final mm = _twoDigits(now.month);
  final dd = _twoDigits(now.day);
  final hh = _twoDigits(now.hour);
  final min = _twoDigits(now.minute);
  final ss = _twoDigits(now.second);
  return '$yyyy-$mm-$dd'
      '_$hh$min$ss';
}

Future<void> main() async {
  final runFolder = Directory('screenshots/${_runFolderName()}');
  await runFolder.create(recursive: true);

  await integrationDriver(
    onScreenshot:
        (
          String screenshotName,
          List<int> screenshotBytes, [
          Map<String, Object?>? _,
        ]) async {
          final file = File('${runFolder.path}/$screenshotName.png');
          await file.writeAsBytes(screenshotBytes, flush: true);
          return true;
        },
  );
}
