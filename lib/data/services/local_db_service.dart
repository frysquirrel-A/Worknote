import 'package:hive_flutter/hive_flutter.dart';

class LocalDatabaseService {
  // [공통] 박스 가져오기 (main.dart에서 이미 열어둠)
  Box<T> _getBox<T>(String boxName) => Hive.box<T>(boxName);

  // --- 1. Generic Methods (범용) ---
  
  // 모든 데이터 가져오기
  List<T> getAll<T>(String boxName) {
    return _getBox<T>(boxName).values.toList();
  }

  // 데이터 1개 저장/수정
  Future<void> put<T>(String boxName, String key, T item) async {
    await _getBox<T>(boxName).put(key, item);
  }

  // 데이터 삭제
  Future<void> delete<T>(String boxName, String key) async {
    await _getBox<T>(boxName).delete(key);
  }

  // 전체 데이터 덮어쓰기 (서버 동기화 후 로컬 최신화용)
  Future<void> syncAll<T>(String boxName, List<T> items, String Function(T) idGetter) async {
    final box = _getBox<T>(boxName);
    await box.clear(); // 기존 데이터 비우고
    
    // ID를 키(Key)로 사용하여 저장
    final Map<String, T> entries = {
      for (var item in items) idGetter(item): item
    };
    await box.putAll(entries);
  }

  // --- 2. 설정(Settings) 관련 ---
  // 마지막으로 선택한 팀 ID, 로그인한 사용자 이름 등을 저장
  
  dynamic getSetting(String key, {dynamic defaultValue}) {
    return Hive.box('settings').get(key, defaultValue: defaultValue);
  }

  Future<void> saveSetting(String key, dynamic value) async {
    await Hive.box('settings').put(key, value);
  }
}