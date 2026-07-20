import 'dart:math';

import 'person.dart';

/// メインモード「なまえコール」のルールロジック。
///
/// 独自ルール（既存のいかなるカードゲームとも異なる流れ）:
/// 1. ゲーム開始時に全員の顔を一覧し、プレイヤーが順番に名前をつける（命名）
/// 2. つけた名前は「名簿」にひみつで記録される（ゲーム終了まで見られない）
/// 3. 本編ではカードが出てくる（基本は1枚ずつ／オプションで2枚同時）
/// 4. 名前を思い出せたら獲得。2枚同時のときは両方言えたら「りょうどり」で2枚
/// 5. 思い出せなかったカードは没収（こぼれ札）。獲得枚数で勝敗
class NameCallGame {
  /// 登場人数のデフォルト（画面側でサイズ選択可能）。
  static const int peopleCount = 12;

  /// 使える顔の最大数（フリー素材キャラ画像の枚数）。
  static const int maxPeople = 12;

  /// 山札は各人物×2枚。
  static const int copiesPerPerson = 2;

  /// 1カードの回答制限時間（秒）。
  static const int answerSeconds = 10;

  final List<Person> people;
  final Random rng;

  /// 1ラウンドに出すカード枚数（1=基本 / 2=りょうどりオプション）。
  final int cardsPerRound;

  /// 名簿: 人物 → プレイヤーがつけた名前（命名フェーズで埋まる）
  final Map<Person, String> roster = {};

  /// 山札（人物の重複あり）。
  late final List<Person> deck;

  NameCallGame({
    required this.people,
    required this.rng,
    this.cardsPerRound = 1,
  }) {
    deck = [
      for (final p in people)
        for (var i = 0; i < copiesPerPerson; i++) p,
    ]..shuffle(rng);
  }

  int get totalCards => people.length * copiesPerPerson;

  /// 次のラウンドのカードを引く（cardsPerRound枚）。
  /// 同じラウンドに同一人物が2枚出ないようにする（2枚同時=りょうどりのとき、
  /// 同じ顔が並ぶ不自然さを防ぐ）。残り枚数が足りなければその分だけ。
  List<Person> drawRound() {
    final round = <Person>[];
    final skipped = <Person>[];
    while (round.length < cardsPerRound && deck.isNotEmpty) {
      final c = deck.removeAt(0);
      if (round.contains(c)) {
        skipped.add(c); // 同一人物は同ラウンドに出さない → いったん退避
      } else {
        round.add(c);
      }
    }
    // 退避したカードは山札の先頭に戻す（次ラウンド以降で出る）
    deck.insertAll(0, skipped);
    return round;
  }

  bool get isFinished => deck.isEmpty;

  /// クイズの選択肢: 正解＋名簿のほかの名前から最大3つ（通常4択）。
  /// 名簿の名前だけで作るので「自分がつけたはずの名前」から選ぶことになる。
  /// 登録人数が少ない（カスタム名簿など）場合は選択肢が4未満になることもある。
  List<String> choicesFor(Person target, {int total = 4}) {
    final correct = roster[target]!;
    final others = roster.entries
        .where((e) => e.key != target && e.value != correct)
        .map((e) => e.value)
        .toSet()
        .toList()
      ..shuffle(rng);
    final choices = <String>{correct, ...others.take(total - 1)}.toList()
      ..shuffle(rng);
    return choices;
  }
}
