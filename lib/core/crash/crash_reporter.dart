import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Lightweight crash reporter that persists fatal/non-fatal errors into Hive.
///
/// Why:
/// - Production debugging without remote crash tooling.
/// - Post-mortem analysis when users report "앱이 꺼져요".
///
/// Storage:
/// - Hive box: `crash_logs`
/// - Each entry is a small Map (stringly typed to keep Hive adapter-free).
///
/// NOTE: This is intentionally adapter-free to avoid typeId collisions.
class CrashReporter {
  CrashReporter._();

  static final CrashReporter instance = CrashReporter._();

  static const String boxName = 'crash_logs';

  Box<Map>? _box;
  final List<Map<String, dynamic>> _buffer = <Map<String, dynamic>>[];

  bool get isReady => _box != null && _box!.isOpen;

  Future<void> init() async {
    if (isReady) return;
    _box = await Hive.openBox<Map>(boxName);

    // Flush anything we captured before Hive was ready.
    if (_buffer.isNotEmpty) {
      for (final entry in List<Map<String, dynamic>>.from(_buffer)) {
        try {
          await _box!.add(entry);
        } catch (_) {
          // If even flushing fails, drop silently to avoid infinite loops.
        }
      }
      _buffer.clear();
    }
  }

  Future<void> record(
    Object error,
    StackTrace stack, {
    String? hint,
    String severity = 'error',
    Map<String, Object?> extra = const {},
  }) async {
    final entry = <String, dynamic>{
      'ts': DateTime.now().toIso8601String(),
      'severity': severity,
      'error': error.toString(),
      'stack': stack.toString(),
      'hint': hint ?? '',
      'extra': extra.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    };

    if (isReady) {
      try {
        await _box!.add(entry);
      } catch (_) {
        // Buffer if disk write fails.
        _buffer.add(entry);
      }
      return;
    }

    // Not ready yet.
    _buffer.add(entry);
  }

  /// Convenience helper for catching and persisting FlutterErrorDetails.
  Future<void> recordFlutterError(FlutterErrorDetails details, {String? hint}) async {
    final stack = details.stack ?? StackTrace.current;
    await record(
      details.exception,
      stack,
      hint: hint ?? details.context?.toDescription() ?? 'FlutterError',
      severity: details.exceptionAsString().contains('RenderFlex') ? 'ui' : 'error',
    );
  }

  /// Basic stats for UI.
  int get count => _box?.length ?? 0;

  /// Returns newest-first entries (best-effort).
  List<Map> latest({int limit = 20}) {
    final box = _box;
    if (box == null || !box.isOpen) return const [];

    final total = box.length;
    final start = (total - limit).clamp(0, total);

    final out = <Map>[];
    for (var i = total - 1; i >= start; i--) {
      final v = box.getAt(i);
      if (v != null) out.add(v);
    }
    return out;
  }

  Future<void> clear() async {
    final box = _box;
    if (box == null || !box.isOpen) return;
    await box.clear();
  }
}
