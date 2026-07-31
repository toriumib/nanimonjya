import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nanimonjya/screens/tutorial_screen.dart';

/// 📖 チュートリアルの離脱まわり。
/// 「途中で閉じた人に続きから見せる」「しつこくしない」は
/// 起動をまたぐ挙動なので手では確かめにくい。ここで固める。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('初回は表示する', () async {
    expect(await shouldShowTutorial(), isTrue);
  });

  test('最後まで読んだら二度と出ない', () async {
    await markTutorialDone();
    expect(await shouldShowTutorial(), isFalse);
  });

  test('読んだページが保存され、続きから開ける', () async {
    expect(await savedTutorialPage(), 0);
    await saveTutorialPage(3);
    expect(await savedTutorialPage(), 3);
  });

  test('途中で閉じても、上限までは次回また出る', () async {
    await markTutorialSkipped(); // 1回目
    expect(await shouldShowTutorial(), isTrue,
        reason: '1回閉じただけなら続きからもう一度出す');
  });

  test('しつこくしない: 上限に達したらもう出さない', () async {
    for (var i = 0; i < kMaxTutorialRetries; i++) {
      await markTutorialSkipped();
    }
    expect(await shouldShowTutorial(), isFalse,
        reason: '何度も出すと、それ自体が離脱の原因になる');
  });
}
