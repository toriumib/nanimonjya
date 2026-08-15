/// アセット（キャラ・シナリオ）の読み込み。
///
/// SPEC 3.8 の方針: **絵と音が無くても動く**。
/// ここが投げるのは「シナリオが読めない」ときだけにして、
/// 画像・音声の欠落は描画側（placeholder）で吸収する。
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/noah_field.dart';
import '../models/scene_script.dart';

class AssetRepository {
  AssetRepository._();
  static final AssetRepository instance = AssetRepository._();

  NoahCast? _cast;
  final Map<String, Scene> _scenes = {};

  /// 17人ぶんのキャラデータ。
  Future<NoahCast> loadCast() async {
    final cached = _cast;
    if (cached != null) return cached;
    final text = await rootBundle.loadString('assets/characters.json');
    final j = jsonDecode(text) as Map<String, dynamic>;
    final list = [
      for (final c in (j['characters'] as List? ?? const []))
        NoahCharacter.fromJson(c as Map<String, dynamic>),
    ];
    return _cast = NoahCast(list);
  }

  /// シーンを1つ読む。**一度読んだものは覚えておく**（送るたびに読み直さない）。
  Future<Scene?> loadScene(String id) async {
    if (id.isEmpty) return null;
    final cached = _scenes[id];
    if (cached != null) return cached;
    try {
      final text = await rootBundle.loadString('assets/scenes/$id.json');
      return _scenes[id] = Scene.parse(text);
    } catch (e) {
      // まだ書かれていないシーンへ飛ぼうとした場合。
      // ここで例外を投げると、選択肢を選んだ瞬間に落ちる。
      debugPrint('scene not found: $id ($e)');
      return null;
    }
  }
}
