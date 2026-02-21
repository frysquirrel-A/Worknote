import 'package:hive/hive.dart';

/// Outbox pattern for eventual consistency / remote sync.
///
/// Every local mutation that should be synced remotely is appended here.
/// This prevents "silent data loss" when the app gains cloud sync later.
///
/// Storage:
/// - Hive box: `sync_outbox` (Map entries; adapter-free)
///
/// Schema (Map):
/// - ts: ISO string
/// - teamId: string
/// - entity: string (task/journal/chat/...)
/// - action: string (put/delete/meta/...)
/// - entityId: string
/// - payload: stringified json-ish map
class SyncOutbox {
  SyncOutbox._();

  static final SyncOutbox instance = SyncOutbox._();

  static const String boxName = 'sync_outbox';

  Box<Map>? _box;

  bool get isReady => _box != null && _box!.isOpen;

  Future<void> init() async {
    if (isReady) return;
    _box = await Hive.openBox<Map>(boxName);
  }

  Future<void> enqueue({
    required String teamId,
    required String entity,
    required String action,
    required String entityId,
    Map<String, Object?> payload = const {},
  }) async {
    final entry = <String, dynamic>{
      'ts': DateTime.now().toIso8601String(),
      'teamId': teamId,
      'entity': entity,
      'action': action,
      'entityId': entityId,
      'payload': payload.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    };

    if (!isReady) {
      // Best effort: attempt to init lazily.
      try {
        await init();
      } catch (_) {
        // If init fails, drop entry (avoid crashing app for sync infra).
        return;
      }
    }

    try {
      await _box!.add(entry);
    } catch (_) {
      // Swallow: outbox should never crash UX.
    }
  }

  int get count => _box?.length ?? 0;

  Future<void> clear() async {
    final box = _box;
    if (box == null || !box.isOpen) return;
    await box.clear();
  }
}
