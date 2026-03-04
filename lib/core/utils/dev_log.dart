import 'package:flutter/material.dart';

class DevLog {
  static final DevLog instance = DevLog._internal();
  DevLog._internal();

  final ValueNotifier<List<String>> logs = ValueNotifier([]);

  void addLog(String msg) {
    final timestamp = DateTime.now().toLocal().toString().split('.').first;
    logs.value = [...logs.value, '[$timestamp] $msg'];
    
    // 메모리 관리를 위해 최근 200개만 유지
    if (logs.value.length > 200) {
      logs.value = logs.value.sublist(logs.value.length - 200);
    }
  }

  void clear() {
    logs.value = [];
  }
}
