import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nanimonjya/services/bgm.dart';
import 'package:nanimonjya/services/player_profile.dart';

/// 🎵 BGMサービスの「順番待ち（チェーン）」が固まらないことを守るテスト。
///
/// 音そのものはテスト環境では鳴らせない（just_audio はプラットフォーム側の
/// プレイヤーを使うので必ず例外になる）。ここで守りたいのは音ではなく、
/// **操作が返ってくること**。
///
/// 以前 `restartCurrent()` が、チェーンの中からチェーンに積む `_play()` を
/// 呼んでいた。内側は外側の完了待ちに並び、外側は内側の完了を待つので、
/// 両者が永久に待ち合ってチェーンが二度と進まなくなっていた。
/// 症状は「マイページやショップで曲を選び直すと、それ以降どの画面でも
/// BGMが鳴らない（アプリを再起動するまで戻らない）」。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // テスト環境では実際の音を読み込めない（just_audio の setAsset が
    // プラットフォーム側を待って返ってこない）ので、音は鳴らさない設定にする。
    // ここで見たいのは音ではなく、**操作がちゃんと返ってくるか**。
    PlayerProfile.instance.bgmEnabled = false;
  });

  test('restartCurrent() が返ってくる（チェーンが自分を待たない）', () async {
    await Bgm.instance
        .restartCurrent()
        .timeout(const Duration(seconds: 5), onTimeout: () {
      fail('restartCurrent() が返ってこない（チェーンのデッドロック）');
    });
  });

  test('restartCurrent() のあとも、続けてBGM操作ができる', () async {
    await Bgm.instance.restartCurrent().timeout(const Duration(seconds: 5));
    // 曲を選び直したあとにゲームへ入る、という実際の流れ
    await Bgm.instance
        .restartGameBgm()
        .timeout(const Duration(seconds: 5), onTimeout: () {
      fail('曲を選び直したあと、BGM操作が固まったまま戻らない');
    });
    await Bgm.instance.stop().timeout(const Duration(seconds: 5), onTimeout: () {
      fail('stop() が返ってこない');
    });
  });

  test('assetKey は素のファイル名を assets/audio/ 付きに直す', () {
    expect(Bgm.assetKey('op9-2-Nocturne.mp3'), 'assets/audio/op9-2-Nocturne.mp3');
    // すでにアセットキーならそのまま（二重に付けない）
    expect(Bgm.assetKey('assets/audio/x.mp3'), 'assets/audio/x.mp3');
  });
}
