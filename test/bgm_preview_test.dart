import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nanimonjya/models/bgm_catalog.dart';
import 'package:nanimonjya/services/bgm.dart';
import 'package:nanimonjya/services/player_profile.dart';

/// 🎵 試聴（プレビュー）まわりの決まりごとを守るテスト。
///
/// 実際の音はテスト環境では鳴らせないので、ここで見るのは
/// **設定を無視していないか／操作が返ってくるか**の2点。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlayerProfile.instance.bgmEnabled = false;
  });

  test('音楽オフのときは試聴しても鳴らさない（操作は返ってくる）', () async {
    // 音楽をオフにしている人にとって、ショップの▶で音が出るのは設定の裏切り。
    await Bgm.instance
        .preview('for_siciliano.mp3')
        .timeout(const Duration(seconds: 5), onTimeout: () {
      fail('preview() が返ってこない');
    });
  });

  test('試聴はチェーンを占有しない（続けて別の操作ができる）', () async {
    // 以前は `await play()`（＝曲が終わるまで返らない）をチェーンの中で
    // 待っていたため、試聴中は他の曲の試聴もタブ移動のBGM切り替えも、
    // 曲が終わるまで一切効かなかった。
    await Bgm.instance.preview('for_siciliano.mp3');
    await Bgm.instance
        .preview('beethoven_5th.mp3')
        .timeout(const Duration(seconds: 5), onTimeout: () {
      fail('試聴中に次の操作が通らない（チェーンが占有されている）');
    });
    await Bgm.instance.stop().timeout(const Duration(seconds: 5));
  });

  test('リザルトの「おまかせ」は、実在する曲に解決される', () {
    // 目印の文字列をそのまま鳴らそうとすると、無いファイルを読みにいって
    // 無音になり、しかも鳴っていた曲まで止まる。
    PlayerProfile.instance.selectedResultBgm = kResultBgmRandom;
    final resolved = Bgm.instance.resultAsset();
    expect(resolved, isNot(kResultBgmRandom));
    expect(kVictoryRandomPool.contains(resolved), isTrue,
        reason: '勝利曲プールの中から選ばれる');
  });

  test('リザルトの曲を1曲えらんだら、その曲だけが鳴る', () {
    PlayerProfile.instance.selectedResultBgm = 'victory_march.mp3';
    expect(Bgm.instance.resultAsset(), 'victory_march.mp3');
  });
}
