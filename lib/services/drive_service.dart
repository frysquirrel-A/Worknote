import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class DriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [drive.DriveApi.driveFileScope]);
  drive.DriveApi? _api;
  GoogleSignInAccount? _account;

  // 1. 로그인 및 API 초기화
  Future<void> signIn() async {
    try {
      _account = await _googleSignIn.signIn();
      if (_account != null) {
        final httpClient = await _googleSignIn.authenticatedClient();
        if (httpClient != null) {
          _api = drive.DriveApi(httpClient);
          if (kDebugMode) print("✅ 구글 드라이브 연결 성공: ${_account!.email}");
        }
      }
    } catch (e) {
      if (kDebugMode) print("❌ 로그인 실패: $e");
    }
  }

  // 2. JSON 데이터 동기화 (다운로드 -> 병합 -> 업로드)
  Future<List<dynamic>?> syncJsonData(List<dynamic> localData, String fileName) async {
    if (_api == null) await signIn();
    if (_api == null) return null;

    try {
      // A. 드라이브에서 파일 찾기
      final fileList = await _api!.files.list(q: "name = '$fileName' and trashed = false");
      final files = fileList.files;
      
      List<dynamic> serverData = [];
      String? fileId;

      if (files != null && files.isNotEmpty) {
        fileId = files.first.id;
        // B. 파일 다운로드
        final media = await _api!.files.get(fileId!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
        final jsonString = await utf8.decodeStream(media.stream);
        serverData = jsonDecode(jsonString);
      }

      // C. 병합 (Merge): 로컬 데이터 우선 + 없는 서버 데이터 추가
      final mergedMap = <String, dynamic>{};
      for (var item in serverData) { mergedMap[item['id']] = item; }
      for (var item in localData) { mergedMap[item['id']] = item; } // 로컬이 덮어씀

      final mergedList = mergedMap.values.toList();

      // D. 병합된 데이터 다시 업로드 (최신화)
      final jsonContent = jsonEncode(mergedList);
      final uploadMedia = drive.Media(Stream.value(utf8.encode(jsonContent)), utf8.encode(jsonContent).length);
      
      if (fileId != null) {
        // 기존 파일 업데이트
        await _api!.files.update(drive.File(), fileId, uploadMedia: uploadMedia);
      } else {
        // 새 파일 생성
        await _api!.files.create(drive.File()..name = fileName, uploadMedia: uploadMedia);
      }

      return mergedList;

    } catch (e) {
      if (kDebugMode) print("❌ 동기화 실패: $e");
      return null;
    }
  }

  // 3. 이미지 업로드 (와이파이 체크 + 압축)
  Future<String?> uploadPhoto(String filePath, bool isWifiOnly) async {
    if (_api == null) await signIn();
    if (_api == null) return null;

    // A. 와이파이 체크
    if (isWifiOnly) {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.mobile) {
        if (kDebugMode) print("⚠️ [Data Saver] 모바일 데이터 사용 중이라 업로드를 건너뜁니다.");
        return null;
      }
    }

    try {
      // B. 이미지 압축 (HD급)
      final file = File(filePath);
      final dir = await getTemporaryDirectory();
      final targetPath = "${dir.path}/${DateTime.now().millisecondsSinceEpoch}_hd.jpg";
      
      var compressedXFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path, targetPath,
        quality: 85, minWidth: 1920,
      );
      
      final uploadFile = File(compressedXFile?.path ?? file.path);

      // C. 업로드
      final media = drive.Media(uploadFile.openRead(), uploadFile.lengthSync());
      final driveFile = drive.File()..name = "worknote_img_${DateTime.now().millisecondsSinceEpoch}.jpg";
      
      final result = await _api!.files.create(driveFile, uploadMedia: media);
      
      // D. ID만 반환
      return result.id;
      
    } catch (e) {
      if (kDebugMode) print("❌ 이미지 업로드 실패: $e");
      return null;
    }
  }
}
