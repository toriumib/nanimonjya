import 'dart:math';

import 'person.dart';

/// メインモード「なまえコール」のルールロジック。
///
/// 独自ルール（既存のいかなるカードゲームとも異なる流れ）:
/// 1. ゲーム開始時に全員の顔を一覧し、プレイヤーが順番に名前をつける（命名）
/// 2. つけた名前は「名簿」にひみつで記録される（ゲーム終了まで見られない）
/// 3. 本編ではランダムに2枚ずつカードが出る
/// 4. 2枚とも名前を思い出せたら「りょうどり」(2枚獲得)、片方だけなら1枚獲得
/// 5. 思い出せなかったカードは没収（こぼれ札）。獲得枚数で勝敗
class NameCallGame {
  /// 1ゲームの登場人数（顔の種類）。
  static const int peopleCount = 8;

  /// 山札は各人物×2枚 = 16枚 → 8ラウンド。
  static const int copiesPerPerson = 2;

  /// 1カードの回答制限時間（秒）。
  static const int answerSeconds = 10;

  final List<Person> people;
  final Random rng;

  /// 名簿: 人物 → プレイヤーがつけた名前（命名フェーズで埋まる）
  final Map<Person, String> roster = {};

  /// 山札（人物の重複あり）。
  late final List<Person> deck;

  NameCallGame({required this.people, required this.rng}) {
    deck = [
      for (final p in people)
        for (var i = 0; i < copiesPerPerson; i++) p,
    ]..shuffle(rng);
  }

  int get totalCards => people.length * copiesPerPerson;

  /// 次のラウンドの2枚を引く（残り1枚なら1枚だけ）。
  List<Person> drawRound() {
    final n = min(2, deck.length);
    final round = deck.take(n).toList();
    deck.removeRange(0, n);
    return round;
  }

  bool get isFinished => deck.isEmpty;

  /// クイズの選択肢: 正解＋名簿のほかの名前から3つ（4択）。
  /// 名簿の名前だけで作るので「自分がつけたはずの名前」から選ぶことになる。
  List<String> choicesFor(Person target, {int total = 4}) {
    final correct = roster[target]!;
    final others = roster.entries
        .where((e) => e.key != target && e.value != correct)
        .map((e) => e.value)
        .toSet()
        .toList()
      ..shuffle(rng);
    final choices = [correct, ...others.take(total - 1)]..shuffle(rng);
    return choices;
  }
}
