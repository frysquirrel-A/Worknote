import 'dart:convert';
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
      return '홈';
    case 'Tasks':
      return '할일';
    case 'Schedule':
      return '일정';
    case 'Journal':
      return '일지';
    case 'Gallery':
      return '갤러리';
    case 'Messenger':
      return '메신저';
    case 'External/Auth':
      return '외부 인증';
    case 'Blank':
      return '빈 화면';
    case 'Error/ANR':
      return '오류/멈춤';
    default:
      return '알 수 없음';
  }
}

String _actionFor(String screenshotName) {
  final token = _tokenFromName(screenshotName);
  switch (token) {
    case 'home_root':
      return '앱 실행 후 홈 루트 화면 캡처';
    case 'tasks_root':
      return '할일 탭 진입';
    case 'task_add_form':
      return '업무 추가 버튼으로 입력 폼 열기';
    case 'tasks_populated':
      return '테스트 업무 저장 후 목록 재캡처';
    case 'schedule_root':
      return '일정 탭 진입';
    case 'journal_root':
      return '일지 탭 진입';
    case 'gallery_root':
      return '갤러리 탭 진입';
    case 'chat_root':
      return '메신저 탭 진입';
    default:
      return '${token.replaceAll('_', ' ')} 상태 캡처';
  }
}

String _summaryFor(String screenshotName) {
  final token = _tokenFromName(screenshotName);
  switch (token) {
    case 'home_root':
      return '홈 루트 화면이다. 인사 헤더, 현재 팀 카드, 프로젝트 진행 현황, 오늘 할일, 하단 6탭 구조를 한 화면에서 확인할 수 있다.';
    case 'tasks_root':
      return '할일 탭 루트 화면이다. 상단 필터 영역, 그룹 헤더, 목록 또는 빈 상태 구성을 검수하는 기준 화면이다.';
    case 'task_add_form':
      return '업무 추가 폼 화면이다. 제목 입력, 저장 CTA, 하단 시트 레이아웃과 입력 동선을 검수한다.';
    case 'tasks_populated':
      return '테스트 업무 생성 뒤 다시 열린 할일 목록이다. 카드가 실제 데이터로 채워진 상태에서 날짜, 배지, 정보 밀도를 확인한다.';
    case 'schedule_root':
      return '일정 탭 루트 화면이다. 월간 달력, 이전/다음 월 이동 버튼, 일정 목록 또는 빈 상태 CTA를 확인한다.';
    case 'journal_root':
      return '일지 탭 루트 화면이다. 그룹 헤더, 필터/검색, 빈 상태 CTA 또는 목록 카드 구성을 검수한다.';
    case 'gallery_root':
      return '갤러리 탭 루트 화면이다. 미디어 그리드 또는 빈 상태 UI, 로딩/오류 처리 방향을 확인한다.';
    case 'chat_root':
      return '메신저 탭 루트 화면이다. 스레드 리스트 또는 빈 상태, 하단 입력 패널, 다크 패널 톤을 검수한다.';
    default:
      return '${token.replaceAll('_', ' ')} 상태를 캡처한 화면이다.';
  }
}

List<String> _designSummary() {
  return const <String>[
    '전체 방향은 밝은 기본 화면 위에 핵심 액션만 강한 블루 포인트를 얹는 구조다. 홈과 할일은 라이트 톤, 메신저는 프리미엄 다크 톤으로 분리되어 있다.',
    '카드형 레이아웃이 중심이다. 둥근 모서리와 얕은 그림자를 사용해 정보 블록을 나누고, 상단 헤더와 하단 탭은 고정된 내비게이션 축 역할을 한다.',
    '할일/일지의 빈 상태는 일러스트 + 중앙 CTA 조합으로 정리되어 있고, 사용자가 다음 행동을 바로 이해하도록 버튼 문구를 직접적으로 노출한다.',
    '일정 화면은 월간 캘린더와 리스트를 결합한 구조다. 월 이동 화살표의 터치 영역을 확장해 실제 기기에서 탭 누락을 줄이도록 보정했다.',
    '메신저는 darkBg, darkSurface, premiumBlue 계열 토큰을 사용해 다른 탭과 구분되는 전용 대화 공간 느낌을 유지한다.',
  ];
}

List<Map<String, String>> _sourceStructure() {
  return const <Map<String, String>>[
    <String, String>{
      'path': 'lib/app/main_shell.dart',
      'summary': '6개 메인 탭(Home, Tasks, Schedule, Journal, Gallery, Messenger)을 IndexedStack으로 유지하고 하단 NavigationBar를 관리한다.',
    },
    <String, String>{
      'path': 'lib/features/home/ui/home_tab.dart',
      'summary': '홈 대시보드 화면이다. 인사 헤더, 팀 카드, 프로젝트 진행 현황, 오늘 할일, 빠른 진입 UI를 렌더링한다.',
    },
    <String, String>{
      'path': 'lib/features/tasks/ui/task_tab.dart',
      'summary': '할일 필터, 그룹 섹션, 비어 있는 상태 CTA, 하단 추가 버튼을 관리한다.',
    },
    <String, String>{
      'path': 'lib/features/schedule/ui/schedule_tab.dart',
      'summary': '월간 캘린더, 이전/다음 월 이동 버튼, 일정 목록과 빈 상태 레이아웃을 함께 그린다.',
    },
    <String, String>{
      'path': 'lib/features/journal/ui/journal_tab.dart',
      'summary': '일지 목록, 그룹 정렬, 검색/필터, 빈 상태 CTA를 관리한다.',
    },
    <String, String>{
      'path': 'lib/features/gallery/ui/gallery_tab.dart',
      'summary': '이미지/미디어 목록을 그리드로 렌더링하고 로딩/오류 처리를 담당한다.',
    },
    <String, String>{
      'path': 'lib/features/chat/ui/messenger_tab.dart',
      'summary': '메신저 스레드, 빈 상태, 입력 패널, 다크 테마 패널을 관리한다.',
    },
    <String, String>{
      'path': 'lib/core/ui/widgets/empty_state_placeholder.dart',
      'summary': '빈 상태 공통 위젯이다. 아이콘, 제목, 설명, CTA 버튼을 같은 구조로 재사용한다.',
    },
    <String, String>{
      'path': 'integration_test/ui_recon_test.dart',
      'summary': '로컬 진입, 테스트 업무 생성, 각 탭 순회 스크린샷 캡처 흐름을 담당하는 통합 테스트다.',
    },
    <String, String>{
      'path': 'test_driver/integration_test.dart',
      'summary': '스크린샷 파일 저장, 세션 메타데이터 기록, notes/review_data/review.html 생성까지 담당하는 테스트 드라이버다.',
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
    '구글 로그인, 계정 선택, 브라우저/웹뷰 인증 화면은 누르지 않음',
    '로그아웃, 초기화, 삭제, 결제, 외부 계정 연결 같은 파괴적 동작은 실행하지 않음',
    '카메라/저장소 권한 팝업이 외부 흐름으로 이어질 수 있는 경우 강제로 진행하지 않음',
  ];
}

List<String> _recommendedReviewActions() {
  return const <String>[
    '할일 카드가 채워진 상태에서 정보 간격과 텍스트 잘림 여부를 실제 기기 비율로 다시 확인',
    '일정 탭 월 이동 화살표를 실제 손가락 탭으로 여러 번 눌러 히트박스 개선 효과 확인',
    '빈 상태 CTA가 시각적으로 과하거나 약하지 않은지 홈/할일/일지/메신저 기준으로 비교',
    '메신저 다크 패널과 다른 탭의 라이트 패널이 의도된 대비로 보이는지 컬러 일관성 검수',
  ];
}

List<String> _unresolvedBlockers(List<_CapturedStep> steps, Object? failure) {
  final blockers = <String>[];
  if (failure != null) {
    blockers.add('통합 테스트 종료 중 예외가 발생했다: $failure');
  }
  if (steps.isEmpty) {
    blockers.add('스크린샷이 생성되지 않았다.');
  }
  return blockers;
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

Future<void> _generateArtifacts(
  Directory runFolder,
  List<_CapturedStep> steps, {
  Object? failure,
}) async {
  final reviewDataFile = File('${runFolder.path}/review_data.json');
  final manifestFile = File('${runFolder.path}/session_manifest.json');
  final notesFile = File('${runFolder.path}/notes.txt');
  final reviewFile = File('${runFolder.path}/review.html');

  final counts = _countByClassification(steps);
  final repeatedCount = _repeatedCount(steps);
  final generatedAt = DateTime.now().toIso8601String();
  final recommendedActions = _recommendedReviewActions();
  final unsafeActions = _unsafeActionsAvoided();
  final unresolvedBlockers = _unresolvedBlockers(steps, failure);
  final designSummary = _designSummary();
  final sourceStructure = _sourceStructure();

  final reviewData = <String, Object?>{
    'sessionFolder': runFolder.absolute.path,
    'sessionName': runFolder.uri.pathSegments.isNotEmpty
        ? runFolder.uri.pathSegments[runFolder.uri.pathSegments.length - 2]
        : runFolder.path,
    'generatedAt': generatedAt,
    'stepCount': steps.length,
    'failure': failure?.toString(),
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
    'failure': failure?.toString(),
  };

  await _writeJsonPretty(reviewDataFile, reviewData);
  await _writeJsonPretty(manifestFile, manifest);

  final notes = StringBuffer()
    ..writeln('세션 폴더: ${runFolder.absolute.path}')
    ..writeln('생성 시각: $generatedAt')
    ..writeln('총 스크린샷: ${steps.length}')
    ..writeln()
    ..writeln('[추천 수동 검수]')
    ..writeln(recommendedActions.map((item) => '- $item').join('\n'))
    ..writeln()
    ..writeln('[회피한 위험 동작]')
    ..writeln(unsafeActions.map((item) => '- $item').join('\n'))
    ..writeln()
    ..writeln('[디자인 구성 요약]')
    ..writeln(designSummary.map((item) => '- $item').join('\n'))
    ..writeln()
    ..writeln('[소스코드 구조 요약]')
    ..writeln(
      sourceStructure
          .map((item) => '- ${item['path']}: ${item['summary']}')
          .join('\n'),
    )
    ..writeln();

  if (unresolvedBlockers.isNotEmpty) {
    notes
      ..writeln('[미해결 항목]')
      ..writeln(unresolvedBlockers.map((item) => '- $item').join('\n'))
      ..writeln();
  }

  if (failure != null) {
    notes
      ..writeln('[실패/주의]')
      ..writeln('- 테스트 종료 중 예외: $failure')
      ..writeln();
  }

  for (final step in steps) {
    notes
      ..writeln('step_${_twoDigits(step.stepNumber)}')
      ..writeln('- 분류: ${_classificationLabel(step.classification)}')
      ..writeln('- 동작: ${step.action}')
      ..writeln('- 요약: ${step.summary}')
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
    warnings.add('외부 인증 화면이 ${counts['External/Auth']}회 감지되었다.');
  }
  if ((counts['Blank'] ?? 0) > 0) {
    warnings.add('빈 화면이 ${counts['Blank']}회 감지되었다.');
  }
  if ((counts['Error/ANR'] ?? 0) > 0) {
    warnings.add('오류 또는 멈춤 화면이 ${counts['Error/ANR']}회 감지되었다.');
  }
  if (repeatedCount > 0) {
    warnings.add('의미상 반복으로 볼 수 있는 화면이 $repeatedCount회 있었다.');
  }
  if (failure != null) {
    warnings.add('테스트 종료 중 예외가 기록되었다.');
  }

  final html = StringBuffer();
  html.writeln('<!doctype html>');
  html.writeln('<html lang="ko">');
  html.writeln('<head>');
  html.writeln('  <meta charset="utf-8">');
  html.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1">');
  html.writeln('  <title>WorkNote UI 자동 검수 보고서</title>');
  html.writeln('  <style>');
  html.writeln('    :root {');
  html.writeln('      --bg: #08111f;');
  html.writeln('      --panel: #0f1b33;');
  html.writeln('      --panel-2: #132443;');
  html.writeln('      --line: #243653;');
  html.writeln('      --text: #eef4ff;');
  html.writeln('      --muted: #9fb2d1;');
  html.writeln('      --accent: #5b8cff;');
  html.writeln('      --warn: #ffb454;');
  html.writeln('      --danger: #ff6a70;');
  html.writeln('      --ok: #2bd4a7;');
  html.writeln('    }');
  html.writeln('    * { box-sizing: border-box; }');
  html.writeln('    body { margin: 0; background: radial-gradient(circle at top, #122347 0%, #08111f 60%); color: var(--text); font-family: "Segoe UI", "Malgun Gothic", sans-serif; }');
  html.writeln('    a { color: #9ec0ff; }');
  html.writeln('    .wrap { max-width: 1480px; margin: 0 auto; padding: 28px; }');
  html.writeln('    .hero { background: linear-gradient(180deg, rgba(91,140,255,0.22), rgba(9,19,36,0.92)); border: 1px solid rgba(255,255,255,0.08); border-radius: 24px; padding: 24px; box-shadow: 0 24px 80px rgba(0,0,0,0.35); }');
  html.writeln('    .hero h1 { margin: 0 0 10px; font-size: 30px; }');
  html.writeln('    .hero p { margin: 0; color: var(--muted); line-height: 1.7; }');
  html.writeln('    .grid { display: grid; gap: 18px; grid-template-columns: repeat(12, 1fr); margin-top: 18px; }');
  html.writeln('    .card { background: rgba(12, 22, 41, 0.94); border: 1px solid var(--line); border-radius: 20px; padding: 18px; }');
  html.writeln('    .span-4 { grid-column: span 4; }');
  html.writeln('    .span-6 { grid-column: span 6; }');
  html.writeln('    .span-12 { grid-column: span 12; }');
  html.writeln('    .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 12px; margin-top: 16px; }');
  html.writeln('    .stat { background: rgba(255,255,255,0.03); border: 1px solid rgba(255,255,255,0.06); border-radius: 16px; padding: 12px; }');
  html.writeln('    .stat .label { color: var(--muted); font-size: 12px; margin-bottom: 6px; }');
  html.writeln('    .stat .value { font-size: 24px; font-weight: 800; }');
  html.writeln('    h2 { margin: 0 0 12px; font-size: 20px; }');
  html.writeln('    h3 { margin: 0 0 10px; font-size: 17px; }');
  html.writeln('    ul { margin: 0; padding-left: 18px; line-height: 1.7; }');
  html.writeln('    .section { margin-top: 26px; }');
  html.writeln('    .shots { display: grid; gap: 16px; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); }');
  html.writeln('    .shot { background: rgba(255,255,255,0.025); border: 1px solid rgba(255,255,255,0.08); border-radius: 18px; overflow: hidden; }');
  html.writeln('    .shot img { display: block; width: 100%; background: #000; }');
  html.writeln('    .shot-body { padding: 14px; }');
  html.writeln('    .eyebrow { display: inline-block; padding: 4px 8px; border-radius: 999px; background: rgba(91,140,255,0.15); color: #bdd3ff; font-size: 12px; font-weight: 700; }');
  html.writeln('    .meta { color: var(--muted); font-size: 13px; line-height: 1.7; margin-top: 8px; }');
  html.writeln('    .files { margin-top: 10px; font-size: 13px; display: flex; gap: 10px; flex-wrap: wrap; }');
  html.writeln('    .warn { color: var(--warn); }');
  html.writeln('    .danger { color: var(--danger); }');
  html.writeln('    .ok { color: var(--ok); }');
  html.writeln('    code { background: rgba(255,255,255,0.06); padding: 2px 6px; border-radius: 8px; }');
  html.writeln('    .empty { color: var(--muted); }');
  html.writeln('    @media (max-width: 960px) { .span-4, .span-6, .span-12 { grid-column: span 12; } .wrap { padding: 18px; } }');
  html.writeln('  </style>');
  html.writeln('</head>');
  html.writeln('<body>');
  html.writeln('  <div class="wrap">');
  html.writeln('    <section class="hero">');
  html.writeln('      <h1>WorkNote UI 자동 검수 보고서</h1>');
  html.writeln('      <p>세션 폴더: ${_escapeHtml(runFolder.absolute.path)}<br>생성 시각: ${_escapeHtml(generatedAt)}</p>');
  html.writeln('      <div class="stats">');
  html.writeln('        <div class="stat"><div class="label">총 단계</div><div class="value">${steps.length}</div></div>');
  html.writeln('        <div class="stat"><div class="label">홈</div><div class="value">${counts['Home'] ?? 0}</div></div>');
  html.writeln('        <div class="stat"><div class="label">할일</div><div class="value">${counts['Tasks'] ?? 0}</div></div>');
  html.writeln('        <div class="stat"><div class="label">일정</div><div class="value">${counts['Schedule'] ?? 0}</div></div>');
  html.writeln('        <div class="stat"><div class="label">일지</div><div class="value">${counts['Journal'] ?? 0}</div></div>');
  html.writeln('        <div class="stat"><div class="label">갤러리</div><div class="value">${counts['Gallery'] ?? 0}</div></div>');
  html.writeln('        <div class="stat"><div class="label">메신저</div><div class="value">${counts['Messenger'] ?? 0}</div></div>');
  html.writeln('        <div class="stat"><div class="label">반복 추정</div><div class="value">$repeatedCount</div></div>');
  html.writeln('      </div>');
  html.writeln('    </section>');
  html.writeln('    <div class="grid">');

  void writeListCard(String title, List<String> items, String cssClass) {
    html.writeln('      <section class="card $cssClass">');
    html.writeln('        <h2>${_escapeHtml(title)}</h2>');
    if (items.isEmpty) {
      html.writeln('        <p class="empty">없음</p>');
    } else {
      html.writeln('        <ul>');
      for (final item in items) {
        html.writeln('          <li>${_escapeHtml(item)}</li>');
      }
      html.writeln('        </ul>');
    }
    html.writeln('      </section>');
  }

  writeListCard('추천 수동 검수', recommendedActions, 'span-4');
  writeListCard('회피한 위험 동작', unsafeActions, 'span-4');
  writeListCard('미해결 항목', unresolvedBlockers, 'span-4');
  writeListCard('디자인 구성 요약', designSummary, 'span-6');

  html.writeln('      <section class="card span-6">');
  html.writeln('        <h2>소스코드 구조 요약</h2>');
  html.writeln('        <ul>');
  for (final item in sourceStructure) {
    final fullPath =
        '${Directory.current.path}\\${item['path']!}'.replaceAll('/', '\\');
    html.writeln(
      '          <li><a href="${_fileUri(fullPath)}"><code>${_escapeHtml(item['path']!)}</code></a> - ${_escapeHtml(item['summary']!)}</li>',
    );
  }
  html.writeln('        </ul>');
  html.writeln('      </section>');

  html.writeln('      <section class="card span-12">');
  html.writeln('        <h2>경고/주의</h2>');
  if (warnings.isEmpty) {
    html.writeln('        <p class="ok">캡처 중 명확한 경고 항목이 감지되지 않았다.</p>');
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
    html.writeln('    <section class="section">');
    html.writeln('      <h2>${_escapeHtml(_classificationLabel(section))}</h2>');
    html.writeln('      <div class="shots">');

    for (final step in items) {
      final png = File('${runFolder.path}/${step.pngFileName}');
      final xmlName = step.pngFileName.replaceAll(RegExp(r'\.png$'), '.xml');
      final xml = File('${runFolder.path}/$xmlName');
      final hasXml = xml.existsSync();

      html.writeln('        <article class="shot">');
      html.writeln(
        '          <a href="${_fileUri(png.absolute.path)}"><img src="${_fileUri(png.absolute.path)}" alt="${_escapeHtml(step.name)}"></a>',
      );
      html.writeln('          <div class="shot-body">');
      html.writeln(
        '            <span class="eyebrow">step ${_twoDigits(step.stepNumber)}</span>',
      );
      html.writeln('            <h3>${_escapeHtml(step.name)}</h3>');
      html.writeln('            <div class="meta">');
      html.writeln(
        '              <div><strong>동작</strong>: ${_escapeHtml(step.action)}</div>',
      );
      html.writeln(
        '              <div><strong>요약</strong>: ${_escapeHtml(step.summary)}</div>',
      );
      html.writeln(
        '              <div><strong>분류</strong>: ${_escapeHtml(_classificationLabel(step.classification))}</div>',
      );
      html.writeln('              <div><strong>파일 크기</strong>: ${step.sizeBytes} bytes</div>');
      html.writeln('            </div>');
      html.writeln('            <div class="files">');
      html.writeln(
        '              <a href="${_fileUri(png.absolute.path)}">원본 PNG 열기</a>',
      );
      if (hasXml) {
        html.writeln(
          '              <a href="${_fileUri(xml.absolute.path)}">원본 XML 열기</a>',
        );
      } else {
        html.writeln('              <span class="empty">원본 XML 없음</span>');
      }
      html.writeln('            </div>');
      html.writeln('          </div>');
      html.writeln('        </article>');
    }

    html.writeln('      </div>');
    html.writeln('    </section>');
  }

  html.writeln('  </div>');
  html.writeln('</body>');
  html.writeln('</html>');

  await reviewFile.writeAsString(html.toString(), flush: true);
}

Future<void> main() async {
  final screenshotsDir = Directory('screenshots');
  await screenshotsDir.create(recursive: true);

  final runFolderName = _runFolderName();
  final runFolder = Directory('screenshots/$runFolderName');
  await runFolder.create(recursive: true);
  await File('${screenshotsDir.path}/CURRENT_SESSION.txt')
      .writeAsString('$runFolderName\n', flush: true);

  final capturedSteps = <_CapturedStep>[];
  Object? failure;
  StackTrace? failureStack;

  try {
    await integrationDriver(
      onScreenshot:
          (
            String screenshotName,
            List<int> screenshotBytes, [
            Map<String, Object?>? _,
          ]) async {
            final fileName = '$screenshotName.png';
            final file = File('${runFolder.path}/$fileName');
            await file.writeAsBytes(screenshotBytes, flush: true);

            capturedSteps.add(
              _CapturedStep(
                stepNumber: _stepNumberFromName(screenshotName),
                name: screenshotName,
                pngFileName: fileName,
                classification: _classify(screenshotName),
                action: _actionFor(screenshotName),
                summary: _summaryFor(screenshotName),
                sizeBytes: screenshotBytes.length,
              ),
            );
            return true;
          },
    );
  } catch (error, stackTrace) {
    failure = error;
    failureStack = stackTrace;
  } finally {
    await _generateArtifacts(runFolder, capturedSteps, failure: failure);
  }

  if (failure != null) {
    Error.throwWithStackTrace(failure, failureStack!);
  }
}
