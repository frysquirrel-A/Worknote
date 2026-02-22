import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:worknote/core/crash/crash_reporter.dart';

class DriveService {
  // 싱글톤 패턴 적용
  static final DriveService _instance = DriveService._internal();
  factory DriveService() => _instance;
  
  DriveService._internal() {
    // 앱이 켜질 때 이전에 로그인한 기록이 있으면 조용히(Silently) 자동 로그인
    _googleSignIn.signInSilently();
  }

  // 구글 로그인 및 드라이브 파일 읽기/쓰기 권한(Scope) 요청
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  bool get isReady => _googleSignIn.currentUser != null;
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// 구글 계정으로 로그인 (UI에서 버튼 누를 때 호출)
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account != null;
    } catch (e, stack) {
      unawaited(CrashReporter.instance.record(e, stack, hint: 'DriveService.signIn'));
      return false;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// 구글 API 통신을 위한 인증된 클라이언트 획득
  Future<drive.DriveApi?> _getApi() async {
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) return null;
    return drive.DriveApi(client);
  }

  /// 아웃박스에서 전달받은 JSON 데이터를 드라이브에 파일로 업로드(덮어쓰기)
  Future<List<Map<String, dynamic>>?> syncJsonData(List<Map<String, dynamic>> localData, String fileName) async {
    if (!isReady) return null;
    final api = await _getApi();
    if (api == null) return null;

    try {
      // 1. 내 드라이브 최상단(root)에서 파일 이름으로 기존 파일 검색
      final q = "name = '$fileName' and trashed = false";
      final fileList = await api.files.list(q: q, spaces: 'drive');
      final files = fileList.files;

      drive.File? targetFile;
      if (files != null && files.isNotEmpty) {
        targetFile = files.first;
      }

      // 2. 데이터를 JSON 문자열로 변환 후 Media 스트림 생성
      final jsonString = jsonEncode(localData);
      final media = drive.Media(
        Stream.value(utf8.encode(jsonString)),
        utf8.encode(jsonString).length,
      );

      if (targetFile == null) {
        // 3-A. 파일이 없으면 새로 생성
        final newFile = drive.File()..name = fileName;
        await api.files.create(newFile, uploadMedia: media);
      } else {
        // 3-B. 파일이 있으면 기존 파일 덮어쓰기 (버전 업데이트)
        await api.files.update(drive.File(), targetFile.id!, uploadMedia: media);
      }
      
      // 업로드 성공 시 확인용으로 로컬 데이터 반환
      return localData;
    } catch (e, stack) {
      unawaited(CrashReporter.instance.record(e, stack, hint: 'DriveService.syncJsonData'));
      rethrow;
    }
  }

  // --- 유실되었던 기존 호환성 메서드 복구 ---

  /// AuthProvider에서 호출하는 클라이언트 초기화 해제
  void clearClient() {
    signOut();
  }

  /// AuthProvider에서 호출하는 클라이언트 주입
  void setClient(dynamic client) {
    // 현재 DriveService가 자체적으로 인증을 관리하므로 빈 함수로 두어도 안전합니다.
  }

  /// TeamProvider 등에서 구글 드라이브의 JSON을 읽어올 때 사용
  Future<List<Map<String, dynamic>>?> readJsonData(String fileName) async {
    if (!isReady) return null;
    final api = await _getApi();
    if (api == null) return null;

    try {
      final q = "name = '$fileName' and trashed = false";
      final fileList = await api.files.list(q: q, spaces: 'drive');
      final files = fileList.files;

      if (files == null || files.isEmpty) return null;

      final targetFile = files.first;
      final media = await api.files.get(targetFile.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

      final stream = media.stream;
      final bytes = await stream.expand((x) => x).toList();
      final jsonString = utf8.decode(bytes);
      final dynamic decoded = jsonDecode(jsonString);

      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e, stack) {
      unawaited(CrashReporter.instance.record(e, stack, hint: 'DriveService.readJsonData'));
      return null;
    }
  }

  /// JournalProvider에서 일지 사진을 드라이브에 업로드할 때 사용
  Future<String?> uploadPhoto(String localPath, String fileName) async {
    if (!isReady) return null;
    final api = await _getApi();
    if (api == null) return null;

    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      final media = drive.Media(file.openRead(), await file.length());
      final driveFile = drive.File()..name = fileName;

      final result = await api.files.create(driveFile, uploadMedia: media);
      return result.id; // 구글 드라이브에 업로드된 파일의 ID 반환
    } catch (e, stack) {
      unawaited(CrashReporter.instance.record(e, stack, hint: 'DriveService.uploadPhoto'));
      return null;
    }
  }
}
