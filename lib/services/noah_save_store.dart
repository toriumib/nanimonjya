/// 💾 ストーリーモードの途中セーブを SharedPreferences に置く。
///
/// 保存するのは**進行中の一周ぶんだけ**。コインや実績は
/// PlayerProfile の担当なので、ここには入れない。
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/noah_save.dart';

class NoahSaveStore {
  NoahSaveStore._();
  static final NoahSaveStore instance = NoahSaveStore._();

  static const _key = 'noahStorySave';

  /// 読み込み済みのセーブ。無ければ null。
  NoahSaveData? _cached;
  bool _loaded = false;

  NoahSaveData? get cached => _cached;
  bool get hasSave => _cached != null;

  Future<NoahSaveData?> load() async {
    if (_loaded) return _cached;
    final prefs = await SharedPreferences.getInstance();
    // 版が違う／壊れている場合は decode が null を返すので、そのまま捨てる
    _cached = NoahSaveData.decode(prefs.getString(_key));
    _loaded = true;
    return _cached;
  }

  Future<void> save(NoahSaveData data) async {
    _cached = data;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, data.encode());
  }

  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
