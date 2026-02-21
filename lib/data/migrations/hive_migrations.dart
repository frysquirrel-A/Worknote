import 'package:hive/hive.dart';

/// Versioned Hive migrations.
///
/// This is **not** a refactor tool.
/// It exists to prevent:
/// - crashes after model/field rename
/// - stale meta keys accumulating forever
/// - data corruption when shipping updates
class HiveMigrations {
  static const String metaBoxName = 'app_meta';
  static const String schemaKey = 'schema_version';

  /// Increment when a data migration is introduced.
  static const int latestSchemaVersion = 2;

  /// Runs required migrations exactly once per version.
  static Future<void> run() async {
    final meta = await Hive.openBox<int>(metaBoxName);
    final current = meta.get(schemaKey, defaultValue: 1) ?? 1;

    if (current >= latestSchemaVersion) return;

    for (var v = current; v < latestSchemaVersion; v++) {
      final next = v + 1;
      await _migrate(v, next);
      await meta.put(schemaKey, next);
    }
  }

  static Future<void> _migrate(int from, int to) async {
    // Add new migrations here.
    if (from == 1 && to == 2) {
      await _migrateTaskMetaScheduleDate();
    }
  }

  /// Migrates legacy `scheduleDate` meta into `scheduleStart`/`scheduleEnd`.
  ///
  /// Old builds stored a single date; new builds store an optional range.
  static Future<void> _migrateTaskMetaScheduleDate() async {
    // Meta box is untyped intentionally.
    final metaBox = await Hive.openBox('task_meta');

    // Iterate through all keys to find maps containing scheduleDate.
    for (final dynamic key in metaBox.keys) {
      final dynamic raw = metaBox.get(key);
      if (raw is! Map) continue;

      final map = Map<String, dynamic>.from(raw);
      if (!map.containsKey('scheduleDate')) {
        // Ensure defaults exist.
        map.putIfAbsent('scheduleInclude', () => true);
        await metaBox.put(key, map);
        continue;
      }

      final sched = map['scheduleDate'];
      map.remove('scheduleDate');

      // Only write new fields if absent.
      map.putIfAbsent('scheduleStart', () => sched);
      map.putIfAbsent('scheduleEnd', () => sched);
      map.putIfAbsent('scheduleInclude', () => true);

      await metaBox.put(key, map);
    }
  }
}
