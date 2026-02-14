import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;

class DriveService {
  // Singleton pattern
  static final DriveService _instance = DriveService._internal();
  factory DriveService() => _instance;
  DriveService._internal();

  drive.DriveApi? _driveApi;
  
  bool get isReady => _driveApi != null;

  void setClient(http.Client client) {
    _driveApi = drive.DriveApi(client);
    print("✅ Drive API initialized (Shared Instance)");
  }

  void clearClient() {
    _driveApi = null;
    print("🧹 Drive API Client cleared");
  }

  /// JSON 데이터 동기화 (병합 + 항상 업로드)
  Future<List<dynamic>?> syncJsonData(List<dynamic> localData, String fileName) async {
    if (_driveApi == null) return null;

    try {
      // 1. Google Drive에서 fileName 파일 검색 -> fileId 확보
      final fileList = await _driveApi!.files.list(
        q: "name = '$fileName' and trashed = false",
        $fields: "files(id, name)",
      );

      String? fileId;
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        fileId = fileList.files!.first.id;
      }

      // 2. remote JSON 다운로드 및 파싱
      List<dynamic> remoteList = [];
      if (fileId != null) {
        final media = await _driveApi!.files.get(
          fileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
        ) as drive.Media;
        
        final content = await utf8.decodeStream(media.stream);
        if (content.isNotEmpty) {
          remoteList = jsonDecode(content) as List<dynamic>;
        }
      }

      // 3. remoteList + localData를 'id' 기준으로 병합(Union)
      final Map<String, dynamic> mergedMap = {};

      // 우선순위 timestamp 키: updatedAt > sentAt > date > createdAt
      DateTime? getTimestamp(dynamic item) {
        if (item is! Map) return null;
        final keys = ['updatedAt', 'sentAt', 'date', 'createdAt'];
        for (var key in keys) {
          if (item.containsKey(key) && item[key] != null) {
            return DateTime.tryParse(item[key].toString());
          }
        }
        return null;
      }

      void addToMergedMap(dynamic item) {
        if (item is! Map) return;
        final String id = item['id']?.toString() ?? '';
        if (id.isEmpty) return;

        if (!mergedMap.containsKey(id)) {
          mergedMap[id] = item;
        } else {
          // 충돌 시 최신 데이터 선택
          final existing = mergedMap[id];
          final existingTs = getTimestamp(existing) ?? DateTime(1970);
          final currentTs = getTimestamp(item) ?? DateTime(1970);

          if (currentTs.isAfter(existingTs)) {
            mergedMap[id] = item;
          }
        }
      }

      for (var item in remoteList) addToMergedMap(item);
      for (var item in localData) addToMergedMap(item);

      final mergedList = mergedMap.values.toList();

      // 4. 병합된 mergedList를 Drive에 "항상 업로드"
      await _uploadToDrive(mergedList, fileName, fileId);
      
      // 5. return mergedList
      return mergedList;
    } catch (e) {
      print("❌ Drive Sync Error ($fileName): $e");
      return null; // 6. 예외 발생 시 null 리턴
    }
  }

  Future<List<dynamic>?> readJsonData(String fileName) async {
    if (_driveApi == null) return null;
    try {
      final fileList = await _driveApi!.files.list(q: "name = '$fileName' and trashed = false");
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final fileId = fileList.files!.first.id;
        final media = await _driveApi!.files.get(fileId!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
        final content = await utf8.decodeStream(media.stream);
        if (content.isNotEmpty) return jsonDecode(content) as List<dynamic>;
      }
    } catch (e) { print("❌ Drive Read Error: $e"); }
    return null;
  }

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
      print("❌ Photo Upload Error: $e");
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
