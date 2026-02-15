import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter/foundation.dart';

class DriveService {
  // Singleton: DriveService()를 어디서 호출해도 동일 인스턴스 공유
  static final DriveService _instance = DriveService._internal();
  factory DriveService() => _instance;
  DriveService._internal();

  drive.DriveApi? _driveApi;
  
  // 클라이언트 설정 (AuthProvider에서 호출)
  void setClient(http.Client client) {
    _driveApi = drive.DriveApi(client);
    debugPrint("✅ Drive API initialized");
  }

  bool get isReady => _driveApi != null;

  void clearClient() {
    _driveApi = null;
  }

  // JSON 데이터 동기화 (다운로드 -> 병합 -> 업로드)
  // - remote + local을 id 기준으로 union
  // - 충돌 시 timestamp(updatedAt/sentAt/date/createdAt) 비교
  // - 항상 업로드하여 로컬 변경이 Drive에 반영되도록 함
  Future<List<dynamic>?> syncJsonData(List<dynamic> localData, String fileName) async {
    if (_driveApi == null) return null;

    try {
      final fileList = await _driveApi!.files.list(
        q: "name = '$fileName' and trashed = false",
        $fields: "files(id, name)",
      );

      String? fileId;
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        fileId = fileList.files!.first.id;
      }

      List<dynamic> remoteList = [];
      if (fileId != null) {
        final media = await _driveApi!.files.get(
          fileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
        ) as drive.Media;

        final content = await utf8.decodeStream(media.stream);
        if (content.trim().isNotEmpty) {
          final decoded = jsonDecode(content);
          if (decoded is List) remoteList = decoded;
        }
      }

      final merged = _mergeById(remoteList, localData);
      await _uploadToDrive(merged, fileName, fileId);
      return merged;
    } catch (e) {
      debugPrint("❌ Drive Sync Error: $e");
      return null;
    }
  }

  List<dynamic> _mergeById(List<dynamic> remoteList, List<dynamic> localList) {
    // id가 없는 데이터는 마지막에 그대로 붙인다(유실 방지)
    final List<dynamic> leftovers = [];

    final Map<String, Map<String, dynamic>> byId = {};
    final Set<String> remoteOrder = {};
    final List<String> order = [];

    void addAll(List<dynamic> src, {required bool isRemote}) {
      for (final e in src) {
        if (e is! Map) {
          leftovers.add(e);
          continue;
        }
        final map = Map<String, dynamic>.from(e as Map);
        final id = map['id']?.toString();
        if (id == null || id.trim().isEmpty) {
          leftovers.add(map);
          continue;
        }

        if (isRemote) {
          remoteOrder.add(id);
          if (!order.contains(id)) order.add(id);
        } else {
          if (!order.contains(id)) order.add(id);
        }

        if (!byId.containsKey(id)) {
          byId[id] = map;
          continue;
        }

        final existing = byId[id]!;
        final chosen = _resolveConflict(existing, map);
        byId[id] = chosen;
      }
    }

    // remote 먼저 넣고 local로 덮어쓰기/병합 (단, timestamp 비교로 최신 선택)
    addAll(remoteList, isRemote: true);
    addAll(localList, isRemote: false);

    final merged = <dynamic>[];
    for (final id in order) {
      final item = byId[id];
      if (item != null) merged.add(item);
    }
    merged.addAll(leftovers);
    return merged;
  }

  Map<String, dynamic> _resolveConflict(Map<String, dynamic> a, Map<String, dynamic> b) {
    final ta = _extractTimestamp(a);
    final tb = _extractTimestamp(b);
    if (ta != null && tb != null) {
      return tb.isAfter(ta) ? b : a;
    }
    if (tb != null && ta == null) return b;
    if (ta != null && tb == null) return a;

    // timestamp로 판단 불가 → 유실 방지 우선: a(기존) 위에 b를 안전 병합
    final out = Map<String, dynamic>.from(a);
    b.forEach((key, value) {
      final prev = out[key];
      if (prev is List && value is List) {
        out[key] = [...prev, ...value].toSet().toList();
      } else if (prev is Map && value is Map) {
        out[key] = {...Map<String, dynamic>.from(prev as Map), ...Map<String, dynamic>.from(value as Map)};
      } else {
        out[key] = value;
      }
    });
    return out;
  }

  DateTime? _extractTimestamp(Map<String, dynamic> m) {
    const keys = ['updatedAt', 'sentAt', 'date', 'createdAt'];
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      final dt = DateTime.tryParse(v.toString());
      if (dt != null) return dt;
    }
    return null;
  }

  // 데이터 읽기 전용 (팀 초대 등)
  Future<List<dynamic>?> readJsonData(String fileName) async {
    if (_driveApi == null) return null;
    try {
      final fileList = await _driveApi!.files.list(
        q: "name = '$fileName' and trashed = false",
      );
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final fileId = fileList.files!.first.id;
        final media = await _driveApi!.files.get(fileId!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
        final content = await utf8.decodeStream(media.stream);
        if (content.isNotEmpty) return jsonDecode(content) as List<dynamic>;
      }
    } catch (e) {
      debugPrint("❌ Drive Read Error: $e");
    }
    return null;
  }

  // 사진 업로드
  Future<String?> uploadPhoto(String localPath, String fileName) async {
    if (_driveApi == null) return null;
    try {
      final file = File(localPath);
      final length = await file.length();
      final uploadMedia = drive.Media(file.openRead(), length);
      final driveFile = drive.File()..name = fileName;
      final result = await _driveApi!.files.create(driveFile, uploadMedia: uploadMedia);
      return result.id;
    } catch (e) {
      debugPrint("❌ Photo Upload Error: $e");
      return null;
    }
  }

  Future<void> _uploadToDrive(List<dynamic> data, String fileName, String? fileId) async {
    final jsonString = jsonEncode(data);
    final uploadMedia = drive.Media(
      Stream.value(utf8.encode(jsonString)),
      utf8.encode(jsonString).length,
    );

    if (fileId == null) {
      final newFile = drive.File()..name = fileName;
      await _driveApi!.files.create(newFile, uploadMedia: uploadMedia);
    } else {
      await _driveApi!.files.update(drive.File(), fileId, uploadMedia: uploadMedia);
    }
  }
}

// 구글 인증 클라이언트
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  GoogleAuthClient(this._headers);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
