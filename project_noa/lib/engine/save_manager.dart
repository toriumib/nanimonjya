/// SPEC 3.4 / 7章 — スロットセーブとシステムデータの読み書き。
///
/// スロットは JSON ファイル（path_provider 配下）。
/// システムデータは shared_preferences。
///
/// ⚠️ Web には path_provider の実装が無い。Web でも遊べるように、
///    ファイルが使えない環境では shared_preferences に逃がす。
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/save_data.dart';

class SaveManager {
  SaveManager._();
  static final SaveManager instance = SaveManager._();

  /// 手で選べるスロット数（SPEC は10以上）。
  static const int slotCount = 12;

  /// オートセーブ専用の枠。手動スロットと混ざらないよう負の番号にする。
  static const int autoSlot = -1;

  Future<Directory?> _dir() async {
    if (kIsWeb) return null;
    try {
      final base = await getApplicationDocumentsDirectory();
      final d = Directory('${base.path}/noa_saves');
      if (!d.existsSync()) d.createSync(recursive: true);
      return d;
    } catch (_) {
      return null; // 使えない環境では prefs へ逃がす
    }
  }

  String _prefsKey(int slot) => 'save.$slot';

  Future<void> write(SaveData data) async {
    final text = jsonEncode(data.toJson());
    final d = await _dir();
    if (d != null) {
      await File('${d.path}/${data.slot}.json').writeAsString(text);
      return;
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefsKey(data.slot), text);
  }

  Future<SaveData?> read(int slot) async {
    String? text;
    final d = await _dir();
    if (d != null) {
      final f = File('${d.path}/$slot.json');
      if (f.existsSync()) text = await f.readAsString();
    } else {
      final p = await SharedPreferences.getInstance();
      text = p.getString(_prefsKey(slot));
    }
    if (text == null || text.isEmpty) return null;
    try {
      return SaveData.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      // 壊れたセーブで一覧ごと開けなくなるのを避ける。その枠だけ空に見せる。
      return null;
    }
  }

  Future<void> delete(int slot) async {
    final d = await _dir();
    if (d != null) {
      final f = File('${d.path}/$slot.json');
      if (f.existsSync()) f.deleteSync();
      return;
    }
    final p = await SharedPreferences.getInstance();
    await p.remove(_prefsKey(slot));
  }

  /// 一覧（空き枠は null）。オートセーブ枠は含めない。
  Future<List<SaveData?>> listSlots() async {
    return Future.wait([for (var i = 0; i < slotCount; i++) read(i)]);
  }

  // ── システムデータ ──

  static const _sysKey = 'systemData';

  Future<SystemData> readSystem() async {
    final p = await SharedPreferences.getInstance();
    final text = p.getString(_sysKey);
    if (text == null || text.isEmpty) return const SystemData();
    try {
      return SystemData.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      return const SystemData();
    }
  }

  Future<void> writeSystem(SystemData s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_sysKey, jsonEncode(s.toJson()));
  }

  /// つづきから遊べるか（オートセーブか、どれかのスロットがあるか）。
  Future<bool> hasAnySave() async {
    if (await read(autoSlot) != null) return true;
    final all = await listSlots();
    return all.any((s) => s != null);
  }
}
