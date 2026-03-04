import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// 개인 일정/메모용 스케줄 Provider
///
/// - Hive TypedAdapter를 추가하지 않고(untyped box) Map 형태로 저장
/// - 팀 단위(teamId)로 분리
///
/// Schema (Map):
/// - id: String
/// - teamId: String
/// - userId: String
/// - userName: String
/// - title: String
/// - note: String?
/// - start: String (ISO8601)
/// - end: String (ISO8601)
/// - isAllDay: bool
/// - createdAt: String (ISO8601)
/// - updatedAt: String (ISO8601)
class ScheduleProvider extends ChangeNotifier {
  Box get _box => Hive.box('schedules');

  List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  Future<void> load() async {
    _items = _box.values
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m.cast()))
        .toList();
    _items.sort((a, b) => _parseDateTime(b['start']).compareTo(_parseDateTime(a['start'])));
    notifyListeners();
  }

  /// 특정 팀의 일정을 반환하거나, [teamId]가 null이면 전체 팀의 일정을 반환합니다.
  List<Map<String, dynamic>> itemsForTeam(String? teamId) {
    if (teamId == null) return [..._items];
    return _items.where((m) => (m['teamId'] ?? '').toString() == teamId).toList();
  }

  DateTimeRange? getRange(Map<String, dynamic> item) {
    final s = _tryParse(item['start']);
    final e = _tryParse(item['end']);
    if (s == null || e == null) return null;
    return DateTimeRange(start: s, end: e);
  }

  Future<String> add({
    required String teamId,
    required String userId,
    required String userName,
    required String title,
    String? note,
    required DateTimeRange range,
    bool isAllDay = true,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final map = <String, dynamic>{
      'id': id,
      'teamId': teamId,
      'userId': userId,
      'userName': userName,
      'title': title.trim(),
      'note': (note ?? '').trim(),
      'start': range.start.toIso8601String(),
      'end': range.end.toIso8601String(),
      'isAllDay': isAllDay,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    await _box.put(id, map);
    _items.insert(0, map);
    notifyListeners();
    return id;
  }

  Future<void> update({
    required String id,
    String? title,
    String? note,
    DateTimeRange? range,
    bool? isAllDay,
  }) async {
    final raw = _box.get(id);
    final Map<String, dynamic> current = (raw is Map)
        ? Map<String, dynamic>.from(raw.cast())
        : <String, dynamic>{'id': id};

    if (title != null) current['title'] = title.trim();
    if (note != null) current['note'] = note.trim();
    if (range != null) {
      current['start'] = range.start.toIso8601String();
      current['end'] = range.end.toIso8601String();
    }
    if (isAllDay != null) current['isAllDay'] = isAllDay;
    current['updatedAt'] = DateTime.now().toIso8601String();

    await _box.put(id, current);
    final idx = _items.indexWhere((m) => (m['id'] ?? '').toString() == id);
    if (idx >= 0) {
      _items[idx] = current;
    } else {
      _items.insert(0, current);
    }
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
    _items.removeWhere((m) => (m['id'] ?? '').toString() == id);
    notifyListeners();
  }
}

DateTime _parseDateTime(dynamic v) {
  return _tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _tryParse(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}
