import 'dart:math';

import 'person.dart';

/// メインモード「なまえがお」のルールロジック。
///
/// 命名ルールは2種類:
///
/// **出たとき命名（既定）**
/// 1. 山札から1枚めくる
/// 2. 初めて出たカードなら、めくった人がその場で名前をつける（無得点）
/// 3. すでに名前がついているカードなら、思い出して名前を呼ぶ → 早かった人が獲得
/// 4. 誰も思い出せなければ、新しい名前をつけ直して山札に戻す（[returnToDeck]）
/// 5. 山札が尽きたら終了。獲得枚数で勝敗
///
/// **まとめて命名**
/// 1. ゲーム開始時に全員の顔を一覧し、プレイヤーが順番に名前をつける（命名）
/// 2. つけた名前は「名簿」にひみつで記録される（ゲーム終了まで見られない）
/// 3. 本編ではカードが出てくる（基本は1枚ずつ／オプションで2枚同時）
/// 4. 名前を思い出せたら獲得。2枚同時のときは両方言えたら「りょうどり」で2枚
/// 5. 思い出せなかったカードは没収（こぼれ札）。獲得枚数で勝敗
class NameCallGame {
  /// 登場人数のデフォルト。
  ///
  /// **6人**（× [defaultCopiesPerPerson] 4枚 ＝ 山札24枚）。
  ///
  /// 2026-08 の計測で完走率39%（12人）→ Analysis.md の改善計画で
  /// 最初の一手として6人に引き下げ。完走率60%を狙う。
  /// 物足りない人はホームのスライダーで24人まで上げられる。
  static const int peopleCount = 6;

  /// ホームのスライダーで選べる登場人数の範囲。
  /// 上限は使える顔の枚数（[maxPeople]）と同じ。
  static const int minSelectableCount = 4;
  static const int maxSelectableCount = 24;

  /// 使える顔の最大数（フリー素材キャラ画像の枚数）。
  /// ⚠️ [kCharImageAssets] の枚数と必ずそろえること。ここが多いと
  ///    生成器が足りない顔を要求してassertで落ちる。
  ///    （2026-08: char14〜22を基本に昇格し15→24）
  static const int maxPeople = 24;

  /// 1人あたりの札の枚数の既定値。
  ///
  /// **4枚**にしてある。1枚目は初登場（名前をつける）、2〜4枚目が想起になる。
  /// 同じ顔は合計4回出るので、覚える→思い出すの間隔が空いて定着しやすい。
  ///
  /// ⚠️ 2026-08 に「同じ人が何度も出てくる」と報告され一時2枚にしたが、
  ///     ゲームとしての張り（同じ人がまた出る→思い出す）が薄くなったため、
  ///     4枚に調整した。枚数を増やしたい人はホームのスライダーで上げられる。
  static const int defaultCopiesPerPerson = 4;

  /// ホームで選べる1人あたりの枚数。
  static const int minCopiesPerPerson = 2;
  static const int maxCopiesPerPerson = 5;

  /// 1カードの回答制限時間（秒）の既定値。
  /// CPU対戦では難易度ごとの値（`CpuDifficulty.answerSeconds`）で上書きされる。
  static const int answerSeconds = 10;

  final List<Person> people;
  final Random rng;

  /// 1ラウンドに出すカード枚数（1=基本 / 2=りょうどりオプション）。
  final int cardsPerRound;

  /// 1人あたり何枚の札を山札に入れるか。
  ///
  /// 1枚目は初登場（命名）、2枚目以降が想起になる。
  /// 多いほど1試合は長くなるが、同じ顔に何度も会うので定着しやすい。
  final int copiesPerPerson;

  /// 何人まとめて覚えてから思い出すか（0＝指定なし＝完全シャッフル）。
  ///
  /// CPU対戦の難易度で使う。1なら「1人おぼえて、すぐその人が出る」、
  /// 4なら「4人おぼえてから、4人ぶん答える」。
  /// 覚えてから思い出すまでに他の人が何人挟まるかが難しさそのものなので、
  /// 山札をランダムに切るのではなく、この単位で組み立てる。
  final int groupSize;

  /// 名簿: 人物 → プレイヤーがつけた名前（命名フェーズで埋まる）
  final Map<Person, String> roster = {};

  /// 山札（人物の重複あり）。
  late final List<Person> deck;

  NameCallGame({
    required this.people,
    required this.rng,
    this.cardsPerRound = 1,
    this.groupSize = 0,
    int? copiesPerPerson,
  }) : copiesPerPerson = (copiesPerPerson ?? defaultCopiesPerPerson)
            .clamp(minCopiesPerPerson, maxCopiesPerPerson) {
    deck = groupSize > 0 ? _buildGroupedDeck() : _buildShuffledDeck();
  }

  List<Person> _buildShuffledDeck() => [
        for (final p in people)
          for (var i = 0; i < copiesPerPerson; i++) p,
      ]..shuffle(rng);

  /// [groupSize] 人ずつの「おぼえる → 思い出す」のかたまりで山札を組む。
  ///
  /// 例（groupSize=2, A〜D）: A B（命名）→ B A（想起）→ C D（命名）→ D C（想起）
  /// 想起の順番だけ入れ替えるので、「最後に出た人がすぐ出る」とは限らない。
  ///
  /// [copiesPerPerson] を増やしたときは、想起の周を枚数ぶん繰り返す。
  List<Person> _buildGroupedDeck() {
    final shuffled = [...people]..shuffle(rng);
    final deck = <Person>[];
    for (var i = 0; i < shuffled.length; i += groupSize) {
      final chunk = shuffled.sublist(
          i, (i + groupSize).clamp(0, shuffled.length));
      deck.addAll(chunk); // 1周目＝初登場（命名）
      for (var r = 1; r < copiesPerPerson; r++) {
        deck.addAll([...chunk]..shuffle(rng)); // 2周目以降＝想起
      }
    }
    return deck;
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

  /// 誰も名前を思い出せずに付け直したカードを山札に戻す。
  ///
  /// 付け直した名前を後で試せるようにするための処置。
  /// 山札が空のときは戻さない（戻すとゲームが終われなくなるため）。
  /// 戻したら true。
  bool returnToDeck(Person p) {
    if (deck.isEmpty) return false;
    // 直後にまた同じ顔が出ると覚える間がないので、少し後ろに差し込む
    final at = deck.length == 1 ? 1 : 1 + rng.nextInt(deck.length);
    deck.insert(at.clamp(0, deck.length), p);
    // 山札には同じ人物が2枚あるため、先頭がすでに同じ人物のこともある。
    // その場合は「直後に出さない」が守れないので、先頭を別の人物と入れ替える。
    if (deck.first == p) {
      final other = deck.indexWhere((c) => c != p);
      if (other > 0) {
        final tmp = deck[0];
        deck[0] = deck[other];
        deck[other] = tmp;
      }
    }
    return true;
  }

  bool get isFinished => deck.isEmpty;

  /// 消化したカード枚数（= totalCards - 残り山札）。
  /// 山札に戻したぶん進捗が戻ることがあるので、負にはならないよう丸める。
  int get consumedCards => (totalCards - deck.length).clamp(0, totalCards);

  /// どこまで進んだか（0-100）。離脱地点の分析に使う。
  int get progressPct =>
      totalCards == 0 ? 0 : (consumedCards * 100 / totalCards).round();

  /// クイズの選択肢: 正解＋名簿のほかの名前から最大3つ（通常4択）。
  /// 名簿の名前だけで作るので「自分がつけたはずの名前」から選ぶことになる。
  ///
  /// 名簿の名前が足りないとき（出たとき命名の序盤や、少人数のカスタム名簿）は
  /// [filler] から補充する。
  ///
  /// ⚠️ [filler] には**名簿の名前と見分けがつかない名前**を渡すこと。
  /// 以前は造語のカタカナ名（「モジャモン」など）で埋めていて、
  /// 明らかに正解でないと分かる選択肢が並び、4択が実質2択になっていた。
  List<String> choicesFor(
    Person target, {
    int total = 4,
    List<String> filler = const [],
  }) {
    final correct = roster[target]!;
    final others = roster.entries
        .where((e) => e.key != target && e.value != correct)
        .map((e) => e.value)
        .toSet()
        .toList()
      ..shuffle(rng);
    final choices = <String>{correct, ...others.take(total - 1)};
    if (choices.length < total && filler.isNotEmpty) {
      final pool = [...filler]..shuffle(rng);
      for (final f in pool) {
        if (choices.length >= total) break;
        choices.add(f);
      }
    }
    return choices.toList()..shuffle(rng);
  }
}
