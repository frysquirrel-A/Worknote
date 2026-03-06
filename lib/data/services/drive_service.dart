import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Google Drive sync service using JSON files.
///
/// Files:
/// - worknote_teams.json
/// - worknote_chats.json
class DriveService {
  static final DriveService _instance = DriveService._internal();
  factory DriveService() => _instance;
  DriveService._internal();

  drive.DriveApi? _api;
  bool get isReady => _api != null;

  void setClient(http.Client client) {
    _api = drive.DriveApi(client);
  }

  void clearClient() {
    _api = null;
  }

  /// Generic JSON sync: Read -> Merge -> Write
  /// - policy: union by 'id', timestamp priority
  Future<List<dynamic>?> syncJsonData(
    List<dynamic> localData,
    String fileName,
  ) async {
    if (!isReady) return null;

    try {
      final cloudData = await readJsonData(fileName) ?? [];
      final merged = _mergeById(localData, cloudData);
      await writeJsonData(fileName, merged);
      return merged;
    } catch (e) {
      debugPrint("❌ Drive Sync Error ($fileName): $e");
      return null;
    }
  }

  Future<List<dynamic>?> readJsonData(String fileName) async {
    if (!isReady) return null;

    final fileId = await _getFileId(fileName);
    if (fileId == null) return null;

    final response = await _api!.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );
    if (response is! drive.Media) {
      debugPrint("❌ Drive read failed ($fileName): non-media response");
      return null;
    }

    final List<int> data = [];
    await for (final chunk in response.stream) {
      data.addAll(chunk);
    }

    final content = utf8.decode(data);
    if (content.isEmpty) return [];

    return json.decode(content);
  }

  Future<void> writeJsonData(String fileName, List<dynamic> data) async {
    if (!isReady) return;

    final content = json.encode(data);
    final bytes = utf8.encode(content);
    final media = drive.Media(Stream.value(bytes), bytes.length);

    final fileId = await _getFileId(fileName);
    if (fileId != null) {
      await _api!.files.update(drive.File(), fileId, uploadMedia: media);
    } else {
      final folderId = await _getOrCreateFolder("WorkNote_Data");
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [folderId];
      await _api!.files.create(driveFile, uploadMedia: media);
    }
  }

  Future<String?> uploadPhoto(String localPath, String fileName) async {
    // Basic placeholder for future implementation
    // Requires dart:io for File reading (not provided in this restricted prompt)
    return null;
  }

  // --- Private Helpers ---

  Future<String?> _getFileId(String name) async {
    final list = await _api!.files.list(
      q: "name = '$name' and trashed = false",
      spaces: 'drive',
    );
    if (list.files == null || list.files!.isEmpty) return null;
    return list.files!.first.id;
  }

  Future<String> _getOrCreateFolder(String folderName) async {
    final list = await _api!.files.list(
      q: "name = '$folderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
    );
    if (list.files != null && list.files!.isNotEmpty) {
      return list.files!.first.id!;
    }

    final folder = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await _api!.files.create(folder);
    return created.id!;
  }

  /// Multi-source data merging logic
  List<dynamic> _mergeById(List<dynamic> a, List<dynamic> b) {
    final Map<String, Map<String, dynamic>> map = {};

    void process(dynamic item) {
      if (item is! Map<String, dynamic>) return;
      final id = item['id']?.toString();
      if (id == null) return;

      if (!map.containsKey(id)) {
        map[id] = item;
      } else {
        // Timestamp based update
        final existing = map[id]!;
        final existingTs = _getTimestamp(existing);
        final newTs = _getTimestamp(item);

        if (newTs.isAfter(existingTs)) {
          map[id] = item;
        } else {
          // Deep merge placeholder: keep existing, but ensure missing keys are filled
          item.forEach((key, value) {
            if (!existing.containsKey(key)) existing[key] = value;
          });
        }
      }
    }

    for (var x in a) {
      process(x);
    }
    for (var x in b) {
      process(x);
    }

    return map.values.toList();
  }

  DateTime _getTimestamp(Map<String, dynamic> item) {
    final keys = ['updatedAt', 'sentAt', 'date', 'createdAt'];
    for (final k in keys) {
      if (item.containsKey(k) && item[k] != null) {
        final dt = DateTime.tryParse(item[k].toString());
        if (dt != null) return dt;
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
