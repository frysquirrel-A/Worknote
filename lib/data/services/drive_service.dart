import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:worknote/core/crash/crash_reporter.dart';

class DriveService {
  static final DriveService _instance = DriveService._internal();
  factory DriveService() => _instance;
  
  DriveService._internal() {
    _googleSignIn.signInSilently();
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  // ✨ Worknote 전용 폴더 이름 지정
  static const String _folderName = 'Worknote_Data';

  bool get isReady => _googleSignIn.currentUser != null;
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account != null;
    } catch (e, stack) {
      unawaited(CrashReporter.instance.record(e, stack, hint: 'DriveService.signIn'));
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<drive.DriveApi?> _getApi() async {
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) return null;
    return drive.DriveApi(client);
  }

  // ✨ 핵심 로직: 전용 폴더를 찾거나 없으면 생성해서 Folder ID를 반환하는 함수
  Future<String?> _getOrCreateFolder(drive.DriveApi api) async {
    try {
      // 1. 폴더가 이미 있는지 검색
      final q = "mimeType = 'application/vnd.google-apps.folder' and name = '$_folderName' and trashed = false";
      final folderList = await api.files.list(q: q, spaces: 'drive');
      
      if (folderList.files != null && folderList.files!.isNotEmpty) {
        return folderList.files!.first.id; // 기존 폴더 ID 반환
      }

      // 2. 없으면 새 폴더 생성
      final newFolder = drive.File()
        ..name = _folderName
        ..mimeType = 'application/vnd.google-apps.folder';
      final createdFolder = await api.files.create(newFolder);
      return createdFolder.id; // 새 폴더 ID 반환
    } catch (e, stack) {
      unawaited(CrashReporter.instance.record(e, stack, hint: 'DriveService._getOrCreateFolder'));
      return null;
    }
  }

  /// 아웃박스에서 전달받은 JSON 데이터를 드라이브 [전용 폴더]에 파일로 업로드
  Future<List<Map<String, dynamic>>?> syncJsonData(List<Map<String, dynamic>> localData, String fileName) async {
    if (!isReady) return null;
    final api = await _getApi();
    if (api == null) return null;

    try {
      // 전용 폴더 ID 획득
      final folderId = await _getOrCreateFolder(api);
      if (folderId == null) throw Exception('전용 폴더를 생성할 수 없습니다.');

      // 최상단이 아닌 해당 '폴더 안'에서 파일 검색
      final q = "name = '$fileName' and '$folderId' in parents and trashed = false";
      final fileList = await api.files.list(q: q, spaces: 'drive');
      final files = fileList.files;

      drive.File? targetFile;
      if (files != null && files.isNotEmpty) {
        targetFile = files.first;
      }

      final jsonString = jsonEncode(localData);
      final media = drive.Media(
        Stream.value(utf8.encode(jsonString)),
        utf8.encode(jsonString).length,
      );

      if (targetFile == null) {
        // ✨ 파일 생성 시 부모 폴더(parents)를 전용 폴더로 지정!
        final newFile = drive.File()
          ..name = fileName
          ..parents = [folderId];
        await api.files.create(newFile, uploadMedia: media);
      } else {
        await api.files.update(drive.File(), targetFile.id!, uploadMedia: media);
      }
      return localData;
    } catch (e, stack) {
      unawaited(CrashReporter.instance.record(e, stack, hint: 'DriveService.syncJsonData'));
      rethrow;
    }
  }

  // --- 기존 호환성 메서드 ---

  void clearClient() {
    signOut();
  }

  void setClient(dynamic client) {}

  /// JSON 데이터 읽어오기 (전용 폴더 내에서 검색)
  Future<List<Map<String, dynamic>>?> readJsonData(String fileName) async {
    if (!isReady) return null;
    final api = await _getApi();
    if (api == null) return null;

    try {
      final folderId = await _getOrCreateFolder(api);
      if (folderId == null) return null;

      final q = "name = '$fileName' and '$folderId' in parents and trashed = false";
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

  /// 사진 업로드 (전용 폴더 안에 저장)
  Future<String?> uploadPhoto(String localPath, String fileName) async {
    if (!isReady) return null;
    final api = await _getApi();
    if (api == null) return null;

    try {
      final folderId = await _getOrCreateFolder(api);
      
      final file = File(localPath);
      if (!await file.exists()) return null;

      final media = drive.Media(file.openRead(), await file.length());
      final driveFile = drive.File()..name = fileName;
      
      if (folderId != null) {
        driveFile.parents = [folderId];
      }

      final result = await api.files.create(driveFile, uploadMedia: media);
      return result.id;
    } catch (e, stack) {
      unawaited(CrashReporter.instance.record(e, stack, hint: 'DriveService.uploadPhoto'));
      return null;
    }
  }
}
