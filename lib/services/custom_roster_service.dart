import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/person.dart';

/// 自分でアップロードした「人物」1人分（顔写真＋名前＋名刺情報）。
/// ビジネス実用: 会社名・肩書・電話・メール、実物の名刺画像も保存できる。
class CustomEntry {
  final String id;
  final String imagePath; // 顔写真（アプリのドキュメントディレクトリ内のコピー）
  final String name;
  final String company;
  final String title;
  final String phone;
  final String email;
  final String cardImagePath; // 実物の名刺画像（任意）

  const CustomEntry({
    required this.id,
    required this.imagePath,
    required this.name,
    this.company = '',
    this.title = '',
    this.phone = '',
    this.email = '',
    this.cardImagePath = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'name': name,
        'company': company,
        'title': title,
        'phone': phone,
        'email': email,
        'cardImagePath': cardImagePath,
      };

  factory CustomEntry.fromJson(Map<String, dynamic> j) => CustomEntry(
        id: j['id'] as String,
        imagePath: j['imagePath'] as String,
        name: j['name'] as String,
        // 旧データ（v1）にキーが無くても壊れないよう既定値を使う
        company: (j['company'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        phone: (j['phone'] as String?) ?? '',
        email: (j['email'] as String?) ?? '',
        cardImagePath: (j['cardImagePath'] as String?) ?? '',
      );

  Person toPerson() => Person(
        face: imagePath,
        kind: FaceKind.file,
        name: name,
        hobby: '',
        company: company,
        title: title,
        phone: phone,
        email: email,
        cardImage: cardImagePath,
      );
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
  /// [cardSourcePath] があれば実物の名刺画像も保存する。
  Future<void> add({
    required String sourcePath,
    required String name,
    String company = '',
    String title = '',
    String phone = '',
    String email = '',
    String? cardSourcePath,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final facesDir = Directory('${dir.path}/custom_faces');
    if (!facesDir.existsSync()) facesDir.createSync(recursive: true);
    final id = _uuid.v4();
    String ext(String p) =>
        p.contains('.') ? p.substring(p.lastIndexOf('.')) : '.jpg';
    final destPath = '${facesDir.path}/$id${ext(sourcePath)}';
    await File(sourcePath).copy(destPath);
    String cardPath = '';
    if (cardSourcePath != null && cardSourcePath.isNotEmpty) {
      cardPath = '${facesDir.path}/${id}_card${ext(cardSourcePath)}';
      await File(cardSourcePath).copy(cardPath);
    }
    _entries = [
      ..._entries,
      CustomEntry(
        id: id,
        imagePath: destPath,
        name: name,
        company: company,
        title: title,
        phone: phone,
        email: email,
        cardImagePath: cardPath,
      ),
    ];
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    final entry = _entries.firstWhere((e) => e.id == id, orElse: () => throw 'not found');
    try {
      final f = File(entry.imagePath);
      if (f.existsSync()) f.deleteSync();
      if (entry.cardImagePath.isNotEmpty) {
        final c = File(entry.cardImagePath);
        if (c.existsSync()) c.deleteSync();
      }
    } catch (_) {}
    _entries = _entries.where((e) => e.id != id).toList();
    await _persist();
    notifyListeners();
  }

  List<Person> toPeople() => _entries.map((e) => e.toPerson()).toList();
}
