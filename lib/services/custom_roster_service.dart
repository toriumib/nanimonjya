import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/person.dart';

/// 自分でアップロードした「人物」1人分（顔写真＋名前＋名刺情報＋人メモ）。
///
/// ビジネス実用: 会社名・肩書・電話・メール、実物の名刺画像も保存できる。
/// さらに読み方・ニックネーム・誕生日・出身・自分との関係・SNS・自由メモまで
/// 持てるようにして、「名刺入れ＋人メモ」として使えるようにしている。
///
/// ⚠️ ここに入る情報は**他人の個人情報**。端末内にだけ保存し、
/// 外部へは一切送信しない（この方針を変えるときはストアのデータセーフティ申告も要変更）。
class CustomEntry {
  final String id;
  final String imagePath; // 顔写真（アプリのドキュメントディレクトリ内のコピー）
  final String cardImagePath; // 実物の名刺画像（任意）

  // ── 基本 ──
  final String name;
  final String reading; // 読み方（ふりがな）
  final String nickname; // ニックネーム
  final String gender; // 性別（自由入力。決めうちの選択肢は作らない）
  final String birthday; // 誕生日（自由入力。年なしでも書けるようにする）

  // ── 仕事 ──
  final String company; // 会社名
  final String title; // 役職
  final String occupation; // 職業

  // ── プロフィール ──
  final String origin; // 出身
  final String address; // 住所
  final String relation; // 自分との関係

  // ── 連絡先 ──
  final String phone;
  final String email;
  final String x; // X
  final String instagram; // Instagram
  final String line; // LINE ID
  final String facebook; // Facebook

  final String memo; // 自由記入メモ

  const CustomEntry({
    required this.id,
    required this.imagePath,
    required this.name,
    this.cardImagePath = '',
    this.reading = '',
    this.nickname = '',
    this.gender = '',
    this.birthday = '',
    this.company = '',
    this.title = '',
    this.occupation = '',
    this.origin = '',
    this.address = '',
    this.relation = '',
    this.phone = '',
    this.email = '',
    this.x = '',
    this.instagram = '',
    this.line = '',
    this.facebook = '',
    this.memo = '',
  });

  CustomEntry copyWith({
    String? id,
    String? imagePath,
    String? cardImagePath,
  }) =>
      CustomEntry(
        id: id ?? this.id,
        imagePath: imagePath ?? this.imagePath,
        cardImagePath: cardImagePath ?? this.cardImagePath,
        name: name,
        reading: reading,
        nickname: nickname,
        gender: gender,
        birthday: birthday,
        company: company,
        title: title,
        occupation: occupation,
        origin: origin,
        address: address,
        relation: relation,
        phone: phone,
        email: email,
        x: x,
        instagram: instagram,
        line: line,
        facebook: facebook,
        memo: memo,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'name': name,
        'company': company,
        'title': title,
        'phone': phone,
        'email': email,
        'cardImagePath': cardImagePath,
        'reading': reading,
        'nickname': nickname,
        'gender': gender,
        'birthday': birthday,
        'occupation': occupation,
        'origin': origin,
        'address': address,
        'relation': relation,
        'x': x,
        'instagram': instagram,
        'line': line,
        'facebook': facebook,
        'memo': memo,
      };

  /// 旧データ（v1: 名前だけ / v2: ＋会社・肩書・電話・メール）から読めるように、
  /// **無いキーはすべて既定値**にする。ここを崩すと既存ユーザーの名簿が消える。
  factory CustomEntry.fromJson(Map<String, dynamic> j) {
    String s(String key) => (j[key] as String?) ?? '';
    return CustomEntry(
      id: j['id'] as String,
      imagePath: j['imagePath'] as String,
      name: j['name'] as String,
      company: s('company'),
      title: s('title'),
      phone: s('phone'),
      email: s('email'),
      cardImagePath: s('cardImagePath'),
      reading: s('reading'),
      nickname: s('nickname'),
      gender: s('gender'),
      birthday: s('birthday'),
      occupation: s('occupation'),
      origin: s('origin'),
      address: s('address'),
      relation: s('relation'),
      x: s('x'),
      instagram: s('instagram'),
      line: s('line'),
      facebook: s('facebook'),
      memo: s('memo'),
    );
  }

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

  /// 入力済みの項目（ラベル, 値）を表示順に並べて返す。空欄は除く。
  List<MapEntry<String, String>> filledFieldsJa() {
    final all = <String, String>{
      'よみ': reading,
      'ニックネーム': nickname,
      '性別': gender,
      '誕生日': birthday,
      '会社名': company,
      '役職': title,
      '職業': occupation,
      '出身': origin,
      '住所': address,
      '自分との関係': relation,
      '電話': phone,
      'メール': email,
      'X': x,
      'Instagram': instagram,
      'LINE ID': line,
      'Facebook': facebook,
      'メモ': memo,
    };
    return [
      for (final e in all.entries)
        if (e.value.trim().isNotEmpty) e,
    ];
  }
}

/// 自分の名簿（アップロードした写真＋名前＋名刺情報）を管理するサービス。
/// 写真はアプリのドキュメントディレクトリ配下 custom_faces/ にコピーして永続化し、
/// メタデータ（id/パス/各項目の一覧）を SharedPreferences にJSONで保存する。
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

  Future<Directory> _facesDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final facesDir = Directory('${dir.path}/custom_faces');
    if (!facesDir.existsSync()) facesDir.createSync(recursive: true);
    return facesDir;
  }

  static String _ext(String p) =>
      p.contains('.') ? p.substring(p.lastIndexOf('.')) : '.jpg';

  /// 撮影/選択した一時ファイルを永続ディレクトリにコピーして名簿に追加する。
  ///
  /// [draft] は入力フォームが作った項目一式（id と imagePath は無視される）。
  /// [cardSourcePath] があれば実物の名刺画像も保存する。
  Future<void> add({
    required String sourcePath,
    required CustomEntry draft,
    String? cardSourcePath,
  }) async {
    final facesDir = await _facesDir();
    final id = _uuid.v4();
    final destPath = '${facesDir.path}/$id${_ext(sourcePath)}';
    await File(sourcePath).copy(destPath);
    String cardPath = '';
    if (cardSourcePath != null && cardSourcePath.isNotEmpty) {
      cardPath = '${facesDir.path}/${id}_card${_ext(cardSourcePath)}';
      await File(cardSourcePath).copy(cardPath);
    }
    _entries = [
      ..._entries,
      draft.copyWith(id: id, imagePath: destPath, cardImagePath: cardPath),
    ];
    await _persist();
    notifyListeners();
  }

  /// 登録済みの人の項目を書き換える。
  ///
  /// [draft] の id は既存のものを使う。写真を選び直したときだけ
  /// [newSourcePath] / [newCardSourcePath] を渡す（古いファイルは消す）。
  Future<void> update(
    CustomEntry draft, {
    String? newSourcePath,
    String? newCardSourcePath,
  }) async {
    final idx = _entries.indexWhere((e) => e.id == draft.id);
    if (idx < 0) return;
    final old = _entries[idx];
    var imagePath = old.imagePath;
    var cardPath = old.cardImagePath;
    final facesDir = await _facesDir();

    if (newSourcePath != null && newSourcePath.isNotEmpty) {
      final dest = '${facesDir.path}/${old.id}_${DateTime.now().millisecondsSinceEpoch}${_ext(newSourcePath)}';
      await File(newSourcePath).copy(dest);
      _deleteQuietly(old.imagePath);
      imagePath = dest;
    }
    if (newCardSourcePath != null && newCardSourcePath.isNotEmpty) {
      final dest = '${facesDir.path}/${old.id}_card_${DateTime.now().millisecondsSinceEpoch}${_ext(newCardSourcePath)}';
      await File(newCardSourcePath).copy(dest);
      _deleteQuietly(old.cardImagePath);
      cardPath = dest;
    }

    _entries = [
      for (final e in _entries)
        if (e.id == draft.id)
          draft.copyWith(imagePath: imagePath, cardImagePath: cardPath)
        else
          e,
    ];
    await _persist();
    notifyListeners();
  }

  void _deleteQuietly(String path) {
    if (path.isEmpty) return;
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  Future<void> remove(String id) async {
    final entry =
        _entries.firstWhere((e) => e.id == id, orElse: () => throw 'not found');
    _deleteQuietly(entry.imagePath);
    _deleteQuietly(entry.cardImagePath);
    _entries = _entries.where((e) => e.id != id).toList();
    await _persist();
    notifyListeners();
  }

  List<Person> toPeople() => _entries.map((e) => e.toPerson()).toList();
}
