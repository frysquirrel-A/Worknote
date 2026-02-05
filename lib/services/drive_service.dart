import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;

class DriveService {
  drive.DriveApi? _driveApi;
  
  // 1. 클라이언트 설정
  void setClient(http.Client client) {
    _driveApi = drive.DriveApi(client);
    print("✅ 구글 드라이브 API 연결 성공");
  }

  // 2. JSON 데이터 동기화
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
          return jsonDecode(content) as List<dynamic>;
        }
      }

      final jsonString = jsonEncode(localData);
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
      
      return localData;
    } catch (e) {
      print("❌ Drive Sync Error: $e");
      return null;
    }
  }

  // 3. 사진 업로드
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
      print("❌ 사진 업로드 실패: $e");
      return null;
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
