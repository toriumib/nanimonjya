import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/person.dart';

/// 自分でアップロードした「人物」1人分（写真ファイル＋名前）。
class CustomEntry {
  final String id;
  final String imagePath; // アプリのドキュメントディレクトリ内のコピー
  final String name;

  const CustomEntry({
    required this.id,
    required this.imagePath,
    required this.name,
  });

  Map<String, dynamic> toJson() => {'id': id, 'imagePath': imagePath, 'name': name};

  factory CustomEntry.fromJson(Map<String, dynamic> j) => CustomEntry(
        id: j['id'] as String,
        imagePath: j['imagePath'] as String,
        name: j['name'] as String,
      );

  Person toPerson() =>
      Person(face: imagePath, kind: FaceKind.file, name: name, hobby: '');
}

/// 自分の名簿（アップロードした写真＋名前）を管理するサービス。
/// 写真はアプリのドキュメントディレクトリ配下 custom_faces/ にコピーして永続化し、
/// メタデータ（id/パス/名前の一覧）を SharedPreferences にJSONで保存する。
/// ※写真アップロードはモバイル限定（Webでは無効）。
class CustomRosterService extends ChangeNotifier {
  CustomRosterService._();
  static final CustomRosterService instance = CustomRosterService._();

  static const _prefsKey = 'custom_roster_v1';
  final _uuid = const Uuid();

  List<CustomEntry> _entries = [];
  List<CustomEntry> get entries => List.unmodifiable(_entries);

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_prefsKey);
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List)
            .map((e) => CustomEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        // 実ファイルが残っているものだけ採用（アンインストール後の再インストール等に備える）
        _entries = list.where((e) => File(e.imagePath).existsSync()).toList();
      } catch (_) {
        _entries = [];
      }
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _prefsKey, jsonEncode(_entries.map((e) => e.toJson()).toList()));
  }

  /// 撮影/選択した一時ファイルを永続ディレクトリにコピーして名簿に追加する。
  Future<void> add({required String sourcePath, required String name}) async {
    final dir = await getApplicationDocumentsDirectory();
    final facesDir = Directory('${dir.path}/custom_faces');
    if (!facesDir.existsSync()) facesDir.createSync(recursive: true);
    final id = _uuid.v4();
    final ext = sourcePath.contains('.')
        ? sourcePath.substring(sourcePath.lastIndexOf('.'))
        : '.jpg';
    final destPath = '${facesDir.path}/$id$ext';
    await File(sourcePath).copy(destPath);
    _entries = [..._entries, CustomEntry(id: id, imagePath: destPath, name: name)];
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    final entry = _entries.firstWhere((e) => e.id == id, orElse: () => throw 'not found');
    try {
      final f = File(entry.imagePath);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
    _entries = _entries.where((e) => e.id != id).toList();
    await _persist();
    notifyListeners();
  }

  List<Person> toPeople() => _entries.map((e) => e.toPerson()).toList();
}
