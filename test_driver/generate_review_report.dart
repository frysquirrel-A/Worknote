import 'dart:convert';
import 'dart:io';

const _home = '\uD648';
const _tasks = '\uD560\uC77C';
const _schedule = '\uC77C\uC815';
const _journal = '\uC77C\uC9C0';
const _gallery = '\uAC24\uB7EC\uB9AC';
const _messenger = '\uBA54\uC2E0\uC800';
const _externalAuth = '\uC678\uBD80 \uC778\uC99D';
const _blank = '\uBE48 \uD654\uBA74';
const _errorAnr = '\uC624\uB958/\uBA48\uCDA4';
const _unknown = '\uC54C \uC218 \uC5C6\uC74C';

String _twoDigits(int value) => value.toString().padLeft(2, '0');

class _CapturedStep {
  const _CapturedStep({
    required this.stepNumber,
    required this.name,
    required this.pngFileName,
    required this.classification,
    required this.action,
    required this.summary,
    required this.sizeBytes,
  });

  final int stepNumber;
  final String name;
  final String pngFileName;
  final String classification;
  final String action;
  final String summary;
  final int sizeBytes;

  Map<String, Object?> toJson() => <String, Object?>{
        'stepNumber': stepNumber,
        'name': name,
        'pngFileName': pngFileName,
        'classification': classification,
        'classificationLabel': _classificationLabel(classification),
        'action': action,
        'summary': summary,
        'sizeBytes': sizeBytes,
      };
}

Future<void> _writeJsonPretty(File file, Object data) async {
  const encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString('${encoder.convert(data)}\n', flush: true);
}

int _stepNumberFromName(String screenshotName) {
  final match = RegExp(r'^step_(\d+)_').firstMatch(screenshotName);
  if (match == null) return 0;
  return int.tryParse(match.group(1) ?? '') ?? 0;
}

String _tokenFromName(String screenshotName) {
  final match = RegExp(r'^step_\d+_(.+)$').firstMatch(screenshotName);
  return match?.group(1) ?? screenshotName;
}

String _classify(String screenshotName) {
  final token = _tokenFromName(screenshotName);
  if (token.contains('home')) return 'Home';
  if (token.contains('task')) return 'Tasks';
  if (token.contains('schedule')) return 'Schedule';
  if (token.contains('journal')) return 'Journal';
  if (token.contains('gallery')) return 'Gallery';
  if (token.contains('chat')) return 'Messenger';
  if (token.contains('auth') || token.contains('google')) return 'External/Auth';
  if (token.contains('blank')) return 'Blank';
  if (token.contains('error') || token.contains('anr')) return 'Error/ANR';
  return 'Unknown';
}

String _classificationLabel(String classification) {
  switch (classification) {
    case 'Home':
      return _home;
    case 'Tasks':
      return _tasks;
    case 'Schedule':
      return _schedule;
    case 'Journal':
      return _journal;
    case 'Gallery':
      return _gallery;
    case 'Messenger':
      return _messenger;
    case 'External/Auth':
      return _externalAuth;
    case 'Blank':
      return _blank;
    case 'Error/ANR':
      return _errorAnr;
    default:
      return _unknown;
  }
}

String _actionFor(String screenshotName) {
  final token = _tokenFromName(screenshotName);
  switch (token) {
    case 'home_root':
      return '\uC571 \uC2E4\uD589 \uD6C4 $_home \uB8E8\uD2B8 \uD654\uBA74 \uCEA1\uCC98';
    case 'tasks_root':
      return '$_tasks \uD0ED \uC9C4\uC785';
    case 'task_add_form':
      return '\uC5C5\uBB34 \uCD94\uAC00 \uBC84\uD2BC\uC73C\uB85C \uC785\uB825 \uD3FC \uC5F4\uAE30';
    case 'tasks_populated':
      return '\uD14C\uC2A4\uD2B8 \uC5C5\uBB34 \uC800\uC7A5 \uD6C4 \uBAA9\uB85D \uC7AC\uCEA1\uCC98';
    case 'schedule_root':
      return '$_schedule \uD0ED \uC9C4\uC785';
    case 'journal_root':
      return '$_journal \uD0ED \uC9C4\uC785';
    case 'gallery_root':
      return '$_gallery \uD0ED \uC9C4\uC785';
    case 'chat_root':
      return '$_messenger \uD0ED \uC9C4\uC785';
    default:
      return '${token.replaceAll('_', ' ')} \uC0C1\uD0DC \uCEA1\uCC98';
  }
}

String _summaryFor(String screenshotName) {
  final token = _tokenFromName(screenshotName);
  switch (token) {
    case 'home_root':
      return '$_home \uB8E8\uD2B8 \uD654\uBA74\uC774\uB2E4. \uC778\uC0AC \uD5E4\uB354, \uD604\uC7AC \uD300 \uCE74\uB4DC, \uD504\uB85C\uC81D\uD2B8 \uC9C4\uD589 \uD604\uD669, \uC624\uB298 \uD560\uC77C, \uD558\uB2E8 6\uD0ED \uAD6C\uC870\uB97C \uD55C \uD654\uBA74\uC5D0\uC11C \uD655\uC778\uD560 \uC218 \uC788\uB2E4.';
    case 'tasks_root':
      return '$_tasks \uD0ED \uB8E8\uD2B8 \uD654\uBA74\uC774\uB2E4. \uC0C1\uB2E8 \uD544\uD130 \uC601\uC5ED, \uADF8\uB8F9 \uD5E4\uB354, \uBAA9\uB85D \uB610\uB294 \uBE48 \uC0C1\uD0DC \uAD6C\uC131\uC744 \uAC80\uC218\uD558\uB294 \uAE30\uC900 \uD654\uBA74\uC774\uB2E4.';
    case 'task_add_form':
      return '\uC5C5\uBB34 \uCD94\uAC00 \uD3FC \uD654\uBA74\uC774\uB2E4. \uC81C\uBAA9 \uC785\uB825, \uC800\uC7A5 CTA, \uD558\uB2E8 \uC2DC\uD2B8 \uB808\uC774\uC544\uC6C3\uACFC \uC785\uB825 \uB3D9\uC120\uC744 \uAC80\uC218\uD55C\uB2E4.';
    case 'tasks_populated':
      return '\uD14C\uC2A4\uD2B8 \uC5C5\uBB34 \uC0DD\uC131 \uB4A4 \uB2E4\uC2DC \uC5F4\uB9B0 $_tasks \uBAA9\uB85D\uC774\uB2E4. \uCE74\uB4DC\uAC00 \uC2E4\uC81C \uB370\uC774\uD130\uB85C \uCC44\uC6CC\uC9C4 \uC0C1\uD0DC\uC5D0\uC11C \uB0A0\uC9DC, \uBC30\uC9C0, \uC815\uBCF4 \uBC00\uB3C4\uB97C \uD655\uC778\uD55C\uB2E4.';
    case 'schedule_root':
      return '$_schedule \uD0ED \uB8E8\uD2B8 \uD654\uBA74\uC774\uB2E4. \uC6D4\uAC04 \uB2EC\uB825, \uC774\uC804/\uB2E4\uC74C \uC6D4 \uC774\uB3D9 \uBC84\uD2BC, \uC77C\uC815 \uBAA9\uB85D \uB610\uB294 \uBE48 \uC0C1\uD0DC CTA\uB97C \uD655\uC778\uD55C\uB2E4.';
    case 'journal_root':
      return '$_journal \uD0ED \uB8E8\uD2B8 \uD654\uBA74\uC774\uB2E4. \uADF8\uB8F9 \uD5E4\uB354, \uD544\uD130/\uAC80\uC0C9, \uBE48 \uC0C1\uD0DC CTA \uB610\uB294 \uBAA9\uB85D \uCE74\uB4DC \uAD6C\uC131\uC744 \uAC80\uC218\uD55C\uB2E4.';
    case 'gallery_root':
      return '$_gallery \uD0ED \uB8E8\uD2B8 \uD654\uBA74\uC774\uB2E4. \uBBF8\uB514\uC5B4 \uADF8\uB9AC\uB4DC \uB610\uB294 \uBE48 \uC0C1\uD0DC UI, \uB85C\uB529/\uC624\uB958 \uCC98\uB9AC \uBC29\uD5A5\uC744 \uD655\uC778\uD55C\uB2E4.';
    case 'chat_root':
      return '$_messenger \uD0ED \uB8E8\uD2B8 \uD654\uBA74\uC774\uB2E4. \uC2A4\uB808\uB4DC \uB9AC\uC2A4\uD2B8 \uB610\uB294 \uBE48 \uC0C1\uD0DC, \uD558\uB2E8 \uC785\uB825 \uD328\uB110, \uB2E4\uD06C \uD328\uB110 \uD1A4\uC744 \uAC80\uC218\uD55C\uB2E4.';
    default:
      return '${token.replaceAll('_', ' ')} \uC0C1\uD0DC\uB97C \uCEA1\uCC98\uD55C \uD654\uBA74\uC774\uB2E4.';
  }
}

List<String> _designSummary() {
  return const <String>[
    '\uC804\uCCB4 \uBC29\uD5A5\uC740 \uBC1D\uC740 \uAE30\uBCF8 \uD654\uBA74 \uC704\uC5D0 \uD575\uC2EC \uC561\uC158\uB9CC \uAC15\uD55C \uBE14\uB8E8 \uD3EC\uC778\uD2B8\uB97C \uC5B9\uB294 \uAD6C\uC870\uB2E4. \uD648\uACFC \uD560\uC77C\uC740 \uB77C\uC774\uD2B8 \uD1A4, \uBA54\uC2E0\uC800\uB294 \uD504\uB9AC\uBBF8\uC5C4 \uB2E4\uD06C \uD1A4\uC73C\uB85C \uBD84\uB9AC\uB418\uC5B4 \uC788\uB2E4.',
    '\uCE74\uB4DC\uD615 \uB808\uC774\uC544\uC6C3\uC774 \uC911\uC2EC\uC774\uB2E4. \uB465\uADFC \uBAA8\uC11C\uB9AC\uC640 \uC595\uC740 \uADF8\uB9BC\uC790\uB97C \uC0AC\uC6A9\uD574 \uC815\uBCF4 \uBE14\uB85D\uC744 \uB098\uB204\uACE0, \uC0C1\uB2E8 \uD5E4\uB354\uC640 \uD558\uB2E8 \uD0ED\uC740 \uACE0\uC815\uB41C \uB0B4\uBE44\uAC8C\uC774\uC158 \uCD95 \uC5ED\uD560\uC744 \uD55C\uB2E4.',
    '\uD560\uC77C/\uC77C\uC9C0\uC758 \uBE48 \uC0C1\uD0DC\uB294 \uC77C\uB7EC\uC2A4\uD2B8\uC640 \uC911\uC559 CTA \uC870\uD569\uC73C\uB85C \uC815\uB9AC\uB418\uC5B4 \uC788\uACE0, \uC0AC\uC6A9\uC790\uAC00 \uB2E4\uC74C \uD589\uB3D9\uC744 \uBC14\uB85C \uC774\uD574\uD558\uB3C4\uB85D \uBC84\uD2BC \uBB38\uAD6C\uB97C \uC9C1\uC811\uC801\uC73C\uB85C \uB178\uCD9C\uD55C\uB2E4.',
    '\uC77C\uC815 \uD654\uBA74\uC740 \uC6D4\uAC04 \uB2EC\uB825\uACFC \uB9AC\uC2A4\uD2B8\uB97C \uACB0\uD569\uD55C \uAD6C\uC870\uB2E4. \uC6D4 \uC774\uB3D9 \uD654\uC0B4\uD45C\uC758 \uD130\uCE58 \uC601\uC5ED\uC744 \uD655\uC7A5\uD574 \uC2E4\uC81C \uAE30\uAE30\uC5D0\uC11C \uD0ED \uB204\uB77D\uC744 \uC904\uC774\uB3C4\uB85D \uBCF4\uC815\uD588\uB2E4.',
    '\uBA54\uC2E0\uC800\uB294 darkBg, darkSurface, premiumBlue \uACC4\uC5F4 \uD1A0\uD070\uC744 \uC0AC\uC6A9\uD574 \uB2E4\uB978 \uD0ED\uACFC \uAD6C\uBD84\uB418\uB294 \uC804\uC6A9 \uB300\uD654 \uACF5\uAC04 \uB290\uB08C\uC744 \uC720\uC9C0\uD55C\uB2E4.',
  ];
}

List<Map<String, String>> _sourceStructure() {
  return const <Map<String, String>>[
    <String, String>{
      'path': 'lib/app/main_shell.dart',
      'summary': '6\uAC1C \uBA54\uC778 \uD0ED(Home, Tasks, Schedule, Journal, Gallery, Messenger)\uC744 IndexedStack\uC73C\uB85C \uC720\uC9C0\uD558\uACE0 \uD558\uB2E8 NavigationBar\uB97C \uAD00\uB9AC\uD55C\uB2E4.',
    },
    <String, String>{
      'path': 'lib/features/home/ui/home_tab.dart',
      'summary': '\uD648 \uB300\uC2DC\uBCF4\uB4DC \uD654\uBA74\uC774\uB2E4. \uC778\uC0AC \uD5E4\uB354, \uD300 \uCE74\uB4DC, \uD504\uB85C\uC81D\uD2B8 \uC9C4\uD589 \uD604\uD669, \uC624\uB298 \uD560\uC77C, \uBE60\uB978 \uC9C4\uC785 UI\uB97C \uB80C\uB354\uB9C1\uD55C\uB2E4.',
    },
    <String, String>{
      'path': 'lib/features/tasks/ui/task_tab.dart',
      'summary': '\uD560\uC77C \uD544\uD130, \uADF8\uB8F9 \uC139\uC158, \uBE44\uC5B4 \uC788\uB294 \uC0C1\uD0DC CTA, \uD558\uB2E8 \uCD94\uAC00 \uBC84\uD2BC\uC744 \uAD00\uB9AC\uD55C\uB2E4.',
    },
    <String, String>{
      'path': 'lib/features/schedule/ui/schedule_tab.dart',
      'summary': '\uC6D4\uAC04 \uB2EC\uB825, \uC774\uC804/\uB2E4\uC74C \uC6D4 \uC774\uB3D9 \uBC84\uD2BC, \uC77C\uC815 \uBAA9\uB85D\uACFC \uBE48 \uC0C1\uD0DC \uB808\uC774\uC544\uC6C3\uC744 \uD568\uAED8 \uADF8\uB9B0\uB2E4.',
    },
    <String, String>{
      'path': 'lib/features/journal/ui/journal_tab.dart',
      'summary': '\uC77C\uC9C0 \uBAA9\uB85D, \uADF8\uB8F9 \uC815\uB82C, \uAC80\uC0C9/\uD544\uD130, \uBE48 \uC0C1\uD0DC CTA\uB97C \uAD00\uB9AC\uD55C\uB2E4.',
    },
    <String, String>{
      'path': 'lib/features/gallery/ui/gallery_tab.dart',
      'summary': '\uC774\uBBF8\uC9C0/\uBBF8\uB514\uC5B4 \uBAA9\uB85D\uC744 \uADF8\uB9AC\uB4DC\uB85C \uB80C\uB354\uB9C1\uD558\uACE0 \uB85C\uB529/\uC624\uB958 \uCC98\uB9AC\uB97C \uB2F4\uB2F9\uD55C\uB2E4.',
    },
    <String, String>{
      'path': 'lib/features/chat/ui/messenger_tab.dart',
      'summary': '\uBA54\uC2E0\uC800 \uC2A4\uB808\uB4DC, \uBE48 \uC0C1\uD0DC, \uC785\uB825 \uD328\uB110, \uB2E4\uD06C \uD14C\uB9C8 \uD328\uB110\uC744 \uAD00\uB9AC\uD55C\uB2E4.',
    },
    <String, String>{
      'path': 'lib/core/ui/widgets/empty_state_placeholder.dart',
      'summary': '\uBE48 \uC0C1\uD0DC \uACF5\uD1B5 \uC704\uC82F\uC774\uB2E4. \uC544\uC774\uCF58, \uC81C\uBAA9, \uC124\uBA85, CTA \uBC84\uD2BC\uC744 \uAC19\uC740 \uAD6C\uC870\uB85C \uC7AC\uC0AC\uC6A9\uD55C\uB2E4.',
    },
    <String, String>{
      'path': 'integration_test/ui_recon_test.dart',
      'summary': '\uB85C\uCEEC \uC9C4\uC785, \uD14C\uC2A4\uD2B8 \uC5C5\uBB34 \uC0DD\uC131, \uAC01 \uD0ED \uC21C\uD68C \uC2A4\uD06C\uB9B0\uC0F7 \uCEA1\uCC98 \uD750\uB984\uC744 \uB2F4\uB2F9\uD558\uB294 \uD1B5\uD569 \uD14C\uC2A4\uD2B8\uB2E4.',
    },
    <String, String>{
      'path': 'test_driver/generate_review_report.dart',
      'summary': '\uCD5C\uC2E0 \uC2A4\uD06C\uB9B0\uC0F7 \uC138\uC158\uC744 \uC77D\uC5B4 notes, review_data, session_manifest, review.html\uC744 \uD6C4\uCC98\uB9AC \uC0DD\uC131\uD55C\uB2E4.',
    },
  ];
}

Map<String, int> _countByClassification(List<_CapturedStep> steps) {
  final counts = <String, int>{};
  for (final step in steps) {
    counts.update(step.classification, (value) => value + 1, ifAbsent: () => 1);
  }
  return counts;
}

int _repeatedCount(List<_CapturedStep> steps) {
  var count = 0;
  for (var index = 1; index < steps.length; index++) {
    final prev = steps[index - 1];
    final current = steps[index];
    if (prev.classification == current.classification &&
        prev.summary == current.summary) {
      count++;
    }
  }
  return count;
}

List<String> _unsafeActionsAvoided() {
  return const <String>[
    '\uAD6C\uAE00 \uB85C\uADF8\uC778, \uACC4\uC815 \uC120\uD0DD, \uBE0C\uB77C\uC6B0\uC800/\uC6F9\uBDF0 \uC778\uC99D \uD654\uBA74\uC740 \uB204\uB974\uC9C0 \uC54A\uC74C',
    '\uB85C\uADF8\uC544\uC6C3, \uCD08\uAE30\uD654, \uC0AD\uC81C, \uACB0\uC81C, \uC678\uBD80 \uACC4\uC815 \uC5F0\uACB0 \uAC19\uC740 \uD30C\uAD34\uC801 \uB3D9\uC791\uC740 \uC2E4\uD589\uD558\uC9C0 \uC54A\uC74C',
    '\uCE74\uBA54\uB77C/\uC800\uC7A5\uC18C \uAD8C\uD55C \uD31D\uC5C5\uC774 \uC678\uBD80 \uD750\uB984\uC73C\uB85C \uC774\uC5B4\uC9C8 \uC218 \uC788\uB294 \uACBD\uC6B0 \uAC15\uC81C\uB85C \uC9C4\uD589\uD558\uC9C0 \uC54A\uC74C',
  ];
}

List<String> _recommendedReviewActions() {
  return const <String>[
    '\uD560\uC77C \uCE74\uB4DC\uAC00 \uCC44\uC6CC\uC9C4 \uC0C1\uD0DC\uC5D0\uC11C \uC815\uBCF4 \uAC04\uACA9\uACFC \uD14D\uC2A4\uD2B8 \uC798\uB9BC \uC5EC\uBD80\uB97C \uC2E4\uC81C \uAE30\uAE30 \uBE44\uC728\uB85C \uB2E4\uC2DC \uD655\uC778',
    '\uC77C\uC815 \uD0ED \uC6D4 \uC774\uB3D9 \uD654\uC0B4\uD45C\uB97C \uC2E4\uC81C \uC190\uAC00\uB77D \uD0ED\uC73C\uB85C \uC5EC\uB7EC \uBC88 \uB20C\uB7EC \uD788\uD2B8\uBC15\uC2A4 \uAC1C\uC120 \uD6A8\uACFC \uD655\uC778',
    '\uBE48 \uC0C1\uD0DC CTA\uAC00 \uC2DC\uAC01\uC801\uC73C\uB85C \uACFC\uD558\uAC70\uB098 \uC57D\uD558\uC9C0 \uC54A\uC740\uC9C0 \uD648/\uD560\uC77C/\uC77C\uC9C0/\uBA54\uC2E0\uC800 \uAE30\uC900\uC73C\uB85C \uBE44\uAD50',
    '\uBA54\uC2E0\uC800 \uB2E4\uD06C \uD328\uB110\uACFC \uB2E4\uB978 \uD0ED\uC758 \uB77C\uC774\uD2B8 \uD328\uB110\uC774 \uC758\uB3C4\uB41C \uB300\uBE44\uB85C \uBCF4\uC774\uB294\uC9C0 \uCEEC\uB7EC \uC77C\uAD00\uC131 \uAC80\uC218',
  ];
}

String _escapeHtml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

String _fileUri(String path) => Uri.file(path).toString();

List<_CapturedStep> _collectSteps(Directory runFolder) {
  final pngFiles = runFolder
      .listSync()
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.png'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  return pngFiles.map((file) {
    final name = file.uri.pathSegments.last.replaceAll('.png', '');
    return _CapturedStep(
      stepNumber: _stepNumberFromName(name),
      name: name,
      pngFileName: file.uri.pathSegments.last,
      classification: _classify(name),
      action: _actionFor(name),
      summary: _summaryFor(name),
      sizeBytes: file.lengthSync(),
    );
  }).toList()
    ..sort((a, b) => a.stepNumber.compareTo(b.stepNumber));
}

Future<void> _generateArtifacts(Directory runFolder) async {
  final steps = _collectSteps(runFolder);
  final counts = _countByClassification(steps);
  final repeatedCount = _repeatedCount(steps);
  final generatedAt = DateTime.now().toIso8601String();
  final recommendedActions = _recommendedReviewActions();
  final unsafeActions = _unsafeActionsAvoided();
  final designSummary = _designSummary();
  final sourceStructure = _sourceStructure();
  final unresolvedBlockers =
      steps.isEmpty ? <String>['\uC2A4\uD06C\uB9B0\uC0F7\uC774 \uC0DD\uC131\uB418\uC9C0 \uC54A\uC558\uB2E4.'] : <String>[];

  final reviewDataFile = File('${runFolder.path}/review_data.json');
  final manifestFile = File('${runFolder.path}/session_manifest.json');
  final notesFile = File('${runFolder.path}/notes.txt');
  final reviewFile = File('${runFolder.path}/review.html');

  final reviewData = <String, Object?>{
    'sessionFolder': runFolder.absolute.path,
    'sessionName': runFolder.uri.pathSegments[runFolder.uri.pathSegments.length - 2],
    'generatedAt': generatedAt,
    'stepCount': steps.length,
    'classificationCounts': counts,
    'repeatedCount': repeatedCount,
    'recommendedReviewActions': recommendedActions,
    'unsafeActionsAvoided': unsafeActions,
    'unresolvedBlockers': unresolvedBlockers,
    'designSummary': designSummary,
    'sourceStructure': sourceStructure,
    'steps': steps.map((step) => step.toJson()).toList(),
  };

  final manifest = <String, Object?>{
    'sessionFolder': runFolder.absolute.path,
    'currentStepNumber': steps.isEmpty ? 0 : steps.last.stepNumber,
    'totalScreenshots': steps.length,
    'classificationCounts': counts,
    'repeatedCount': repeatedCount,
  };

  await _writeJsonPretty(reviewDataFile, reviewData);
  await _writeJsonPretty(manifestFile, manifest);

  final notes = StringBuffer()
    ..writeln('\uC138\uC158 \uD3F4\uB354: ${runFolder.absolute.path}')
    ..writeln('\uC0DD\uC131 \uC2DC\uAC01: $generatedAt')
    ..writeln('\uCD1D \uC2A4\uD06C\uB9B0\uC0F7: ${steps.length}')
    ..writeln()
    ..writeln('[\uCD94\uCC9C \uC218\uB3D9 \uAC80\uC218]')
    ..writeln(recommendedActions.map((item) => '- $item').join('\n'))
    ..writeln()
    ..writeln('[\uD68C\uD53C\uD55C \uC704\uD5D8 \uB3D9\uC791]')
    ..writeln(unsafeActions.map((item) => '- $item').join('\n'))
    ..writeln()
    ..writeln('[\uB514\uC790\uC778 \uAD6C\uC131 \uC694\uC57D]')
    ..writeln(designSummary.map((item) => '- $item').join('\n'))
    ..writeln()
    ..writeln('[\uC18C\uC2A4\uCF54\uB4DC \uAD6C\uC870 \uC694\uC57D]')
    ..writeln(
      sourceStructure
          .map((item) => '- ${item['path']}: ${item['summary']}')
          .join('\n'),
    )
    ..writeln();

  for (final step in steps) {
    notes
      ..writeln('step_${_twoDigits(step.stepNumber)}')
      ..writeln('- \uBD84\uB958: ${_classificationLabel(step.classification)}')
      ..writeln('- \uB3D9\uC791: ${step.action}')
      ..writeln('- \uC694\uC57D: ${step.summary}')
      ..writeln();
  }
  await notesFile.writeAsString(notes.toString(), flush: true);

  final sectionOrder = <String>[
    'Home',
    'Tasks',
    'Schedule',
    'Journal',
    'Gallery',
    'Messenger',
    'External/Auth',
    'Error/ANR',
    'Blank',
    'Unknown',
  ];
  final grouped = <String, List<_CapturedStep>>{
    for (final section in sectionOrder) section: <_CapturedStep>[],
  };
  for (final step in steps) {
    grouped.putIfAbsent(step.classification, () => <_CapturedStep>[]).add(step);
  }

  final warnings = <String>[];
  if ((counts['External/Auth'] ?? 0) > 0) {
    warnings.add('\uC678\uBD80 \uC778\uC99D \uD654\uBA74\uC774 ${counts['External/Auth']}\uD68C \uAC10\uC9C0\uB418\uC5C8\uB2E4.');
  }
  if ((counts['Blank'] ?? 0) > 0) {
    warnings.add('\uBE48 \uD654\uBA74\uC774 ${counts['Blank']}\uD68C \uAC10\uC9C0\uB418\uC5C8\uB2E4.');
  }
  if ((counts['Error/ANR'] ?? 0) > 0) {
    warnings.add('\uC624\uB958 \uB610\uB294 \uBA48\uCD98 \uD654\uBA74\uC774 ${counts['Error/ANR']}\uD68C \uAC10\uC9C0\uB418\uC5C8\uB2E4.');
  }
  if (repeatedCount > 0) {
    warnings.add('\uC758\uBBF8\uC0C1 \uBC18\uBCF5\uC73C\uB85C \uBCFC \uC218 \uC788\uB294 \uD654\uBA74\uC774 $repeatedCount\uD68C \uC788\uC5C8\uB2E4.');
  }

  final html = StringBuffer()
    ..writeln('<!doctype html>')
    ..writeln('<html lang="ko">')
    ..writeln('<head>')
    ..writeln('  <meta charset="utf-8">')
    ..writeln('  <meta name="viewport" content="width=device-width, initial-scale=1">')
    ..writeln('  <title>WorkNote UI \uC790\uB3D9 \uAC80\uC218 \uBCF4\uACE0\uC11C</title>')
    ..writeln('  <style>')
    ..writeln('    :root { --bg:#08111f; --panel:#0f1b33; --line:#243653; --text:#eef4ff; --muted:#9fb2d1; --accent:#5b8cff; --warn:#ffb454; --ok:#2bd4a7; }')
    ..writeln('    * { box-sizing:border-box; }')
    ..writeln('    body { margin:0; background:radial-gradient(circle at top, #122347 0%, #08111f 60%); color:var(--text); font-family:"Segoe UI","Malgun Gothic",sans-serif; }')
    ..writeln('    a { color:#9ec0ff; }')
    ..writeln('    .wrap { max-width:1480px; margin:0 auto; padding:28px; }')
    ..writeln('    .hero,.card { background:rgba(12,22,41,0.94); border:1px solid var(--line); border-radius:20px; box-shadow:0 24px 80px rgba(0,0,0,0.28); }')
    ..writeln('    .hero { padding:24px; }')
    ..writeln('    .hero h1 { margin:0 0 10px; font-size:30px; }')
    ..writeln('    .hero p { margin:0; color:var(--muted); line-height:1.7; }')
    ..writeln('    .grid { display:grid; gap:18px; grid-template-columns:repeat(12,1fr); margin-top:18px; }')
    ..writeln('    .card { padding:18px; }')
    ..writeln('    .span-4 { grid-column:span 4; }')
    ..writeln('    .span-6 { grid-column:span 6; }')
    ..writeln('    .span-12 { grid-column:span 12; }')
    ..writeln('    .stats { display:grid; grid-template-columns:repeat(auto-fit,minmax(140px,1fr)); gap:12px; margin-top:16px; }')
    ..writeln('    .stat { background:rgba(255,255,255,0.03); border:1px solid rgba(255,255,255,0.06); border-radius:16px; padding:12px; }')
    ..writeln('    .label { color:var(--muted); font-size:12px; margin-bottom:6px; }')
    ..writeln('    .value { font-size:24px; font-weight:800; }')
    ..writeln('    h2 { margin:0 0 12px; font-size:20px; }')
    ..writeln('    h3 { margin:0 0 10px; font-size:17px; }')
    ..writeln('    ul { margin:0; padding-left:18px; line-height:1.7; }')
    ..writeln('    .section { margin-top:26px; }')
    ..writeln('    .shots { display:grid; gap:16px; grid-template-columns:repeat(auto-fit,minmax(320px,1fr)); }')
    ..writeln('    .shot { background:rgba(255,255,255,0.025); border:1px solid rgba(255,255,255,0.08); border-radius:18px; overflow:hidden; }')
    ..writeln('    .shot img { display:block; width:100%; background:#000; }')
    ..writeln('    .shot-body { padding:14px; }')
    ..writeln('    .eyebrow { display:inline-block; padding:4px 8px; border-radius:999px; background:rgba(91,140,255,0.15); color:#bdd3ff; font-size:12px; font-weight:700; }')
    ..writeln('    .meta { color:var(--muted); font-size:13px; line-height:1.7; margin-top:8px; }')
    ..writeln('    .files { margin-top:10px; font-size:13px; display:flex; gap:10px; flex-wrap:wrap; }')
    ..writeln('    .warn { color:var(--warn); }')
    ..writeln('    .ok { color:var(--ok); }')
    ..writeln('    code { background:rgba(255,255,255,0.06); padding:2px 6px; border-radius:8px; }')
    ..writeln('    .empty { color:var(--muted); }')
    ..writeln('    @media (max-width:960px) { .span-4,.span-6,.span-12 { grid-column:span 12; } .wrap { padding:18px; } }')
    ..writeln('  </style>')
    ..writeln('</head>')
    ..writeln('<body>')
    ..writeln('  <div class="wrap">')
    ..writeln('    <section class="hero">')
    ..writeln('      <h1>WorkNote UI \uC790\uB3D9 \uAC80\uC218 \uBCF4\uACE0\uC11C</h1>')
    ..writeln('      <p>\uC138\uC158 \uD3F4\uB354: ${_escapeHtml(runFolder.absolute.path)}<br>\uC0DD\uC131 \uC2DC\uAC01: ${_escapeHtml(generatedAt)}</p>')
    ..writeln('      <div class="stats">')
    ..writeln('        <div class="stat"><div class="label">\uCD1D \uB2E8\uACC4</div><div class="value">${steps.length}</div></div>')
    ..writeln('        <div class="stat"><div class="label">$_home</div><div class="value">${counts['Home'] ?? 0}</div></div>')
    ..writeln('        <div class="stat"><div class="label">$_tasks</div><div class="value">${counts['Tasks'] ?? 0}</div></div>')
    ..writeln('        <div class="stat"><div class="label">$_schedule</div><div class="value">${counts['Schedule'] ?? 0}</div></div>')
    ..writeln('        <div class="stat"><div class="label">$_journal</div><div class="value">${counts['Journal'] ?? 0}</div></div>')
    ..writeln('        <div class="stat"><div class="label">$_gallery</div><div class="value">${counts['Gallery'] ?? 0}</div></div>')
    ..writeln('        <div class="stat"><div class="label">$_messenger</div><div class="value">${counts['Messenger'] ?? 0}</div></div>')
    ..writeln('        <div class="stat"><div class="label">\uBC18\uBCF5 \uCD94\uC815</div><div class="value">$repeatedCount</div></div>')
    ..writeln('      </div>')
    ..writeln('    </section>')
    ..writeln('    <div class="grid">');

  void writeListCard(String title, List<String> items, String cssClass) {
    html.writeln('      <section class="card $cssClass">');
    html.writeln('        <h2>${_escapeHtml(title)}</h2>');
    if (items.isEmpty) {
      html.writeln('        <p class="empty">\uC5C6\uC74C</p>');
    } else {
      html.writeln('        <ul>');
      for (final item in items) {
        html.writeln('          <li>${_escapeHtml(item)}</li>');
      }
      html.writeln('        </ul>');
    }
    html.writeln('      </section>');
  }

  writeListCard('\uCD94\uCC9C \uC218\uB3D9 \uAC80\uC218', recommendedActions, 'span-4');
  writeListCard('\uD68C\uD53C\uD55C \uC704\uD5D8 \uB3D9\uC791', unsafeActions, 'span-4');
  writeListCard('\uBBF8\uD574\uACB0 \uD56D\uBAA9', unresolvedBlockers, 'span-4');
  writeListCard('\uB514\uC790\uC778 \uAD6C\uC131 \uC694\uC57D', designSummary, 'span-6');

  html
    ..writeln('      <section class="card span-6">')
    ..writeln('        <h2>\uC18C\uC2A4\uCF54\uB4DC \uAD6C\uC870 \uC694\uC57D</h2>')
    ..writeln('        <ul>');

  for (final item in sourceStructure) {
    final fullPath =
        '${Directory.current.path}\\${item['path']!}'.replaceAll('/', '\\');
    html.writeln(
      '          <li><a href="${_fileUri(fullPath)}"><code>${_escapeHtml(item['path']!)}</code></a> - ${_escapeHtml(item['summary']!)}</li>',
    );
  }

  html
    ..writeln('        </ul>')
    ..writeln('      </section>')
    ..writeln('      <section class="card span-12">')
    ..writeln('        <h2>\uACBD\uACE0/\uC8FC\uC758</h2>');

  if (warnings.isEmpty) {
    html.writeln('        <p class="ok">\uCEA1\uCC98 \uC911 \uBA85\uD655\uD55C \uACBD\uACE0 \uD56D\uBAA9\uC774 \uAC10\uC9C0\uB418\uC9C0 \uC54A\uC558\uB2E4.</p>');
  } else {
    html.writeln('        <ul>');
    for (final warning in warnings) {
      html.writeln('          <li class="warn">${_escapeHtml(warning)}</li>');
    }
    html.writeln('        </ul>');
  }

  html.writeln('      </section>');
  html.writeln('    </div>');

  for (final section in sectionOrder) {
    final items = grouped[section] ?? const <_CapturedStep>[];
    if (items.isEmpty) continue;
    html
      ..writeln('    <section class="section">')
      ..writeln('      <h2>${_escapeHtml(_classificationLabel(section))}</h2>')
      ..writeln('      <div class="shots">');

    for (final step in items) {
      final png = File('${runFolder.path}/${step.pngFileName}');
      final xmlName = step.pngFileName.replaceAll(RegExp(r'\.png$'), '.xml');
      final xml = File('${runFolder.path}/$xmlName');
      final hasXml = xml.existsSync();

      html
        ..writeln('        <article class="shot">')
        ..writeln('          <a href="${_fileUri(png.absolute.path)}"><img src="${_fileUri(png.absolute.path)}" alt="${_escapeHtml(step.name)}"></a>')
        ..writeln('          <div class="shot-body">')
        ..writeln('            <span class="eyebrow">step ${_twoDigits(step.stepNumber)}</span>')
        ..writeln('            <h3>${_escapeHtml(step.name)}</h3>')
        ..writeln('            <div class="meta">')
        ..writeln('              <div><strong>\uB3D9\uC791</strong>: ${_escapeHtml(step.action)}</div>')
        ..writeln('              <div><strong>\uC694\uC57D</strong>: ${_escapeHtml(step.summary)}</div>')
        ..writeln('              <div><strong>\uBD84\uB958</strong>: ${_escapeHtml(_classificationLabel(step.classification))}</div>')
        ..writeln('              <div><strong>\uD30C\uC77C \uD06C\uAE30</strong>: ${step.sizeBytes} bytes</div>')
        ..writeln('            </div>')
        ..writeln('            <div class="files">')
        ..writeln('              <a href="${_fileUri(png.absolute.path)}">\uC6D0\uBCF8 PNG \uC5F4\uAE30</a>');

      if (hasXml) {
        html.writeln(
          '              <a href="${_fileUri(xml.absolute.path)}">\uC6D0\uBCF8 XML \uC5F4\uAE30</a>',
        );
      } else {
        html.writeln('              <span class="empty">\uC6D0\uBCF8 XML \uC5C6\uC74C</span>');
      }

      html
        ..writeln('            </div>')
        ..writeln('          </div>')
        ..writeln('        </article>');
    }

    html
      ..writeln('      </div>')
      ..writeln('    </section>');
  }

  html
    ..writeln('  </div>')
    ..writeln('</body>')
    ..writeln('</html>');

  await reviewFile.writeAsString(html.toString(), flush: true);
}

Future<void> main(List<String> args) async {
  final screenshotsDir = Directory('screenshots');
  final sessionName = args.isNotEmpty
      ? args.first
      : (await File('${screenshotsDir.path}/CURRENT_SESSION.txt').readAsLines())
          .first
          .trim();
  final runFolder = Directory('${screenshotsDir.path}/$sessionName');
  if (!runFolder.existsSync()) {
    stderr.writeln('\uC138\uC158 \uD3F4\uB354\uB97C \uCC3E\uC744 \uC218 \uC5C6\uC2B5\uB2C8\uB2E4: ${runFolder.path}');
    exitCode = 1;
    return;
  }

  await _generateArtifacts(runFolder);
  stdout.writeln('review.html \uC0DD\uC131 \uC644\uB8CC: ${runFolder.absolute.path}');
}
