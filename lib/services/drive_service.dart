import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;

class DriveService {
  drive.DriveApi? _driveApi;
  
  // 클라이언트 설정 (AuthProvider에서 호출)
  void setClient(http.Client client) {
    _driveApi = drive.DriveApi(client);
    print("✅ Drive API initialized");
  }

  // JSON 데이터 동기화 (다운로드 -> 병합 -> 업로드)
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

      if (fileId != null) {
        final media = await _driveApi!.files.get(
          fileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
        ) as drive.Media;
        
        final stream = media.stream;
        final content = await utf8.decodeStream(stream);
        
        if (content.isNotEmpty) {
          // 서버 데이터 우선 정책 (필요시 병합 로직 추가 가능)
          return jsonDecode(content) as List<dynamic>;
        }
      }

      // 파일이 없거나 내용이 비었으면 로컬 데이터 업로드
      await _uploadToDrive(localData, fileName, fileId);
      return localData;
    } catch (e) {
      print("❌ Drive Sync Error: $e");
      return null;
    }
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
      print("❌ Drive Read Error: $e");
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
