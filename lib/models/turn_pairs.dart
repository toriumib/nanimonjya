/// 🔁 ターン制対戦（オンラインの神経衰弱）の盤面ロジック。
///
/// オンラインのターン制では、Firestoreに載せるのを
/// **「めくった順のカード番号」だけ**にしている。盤面そのものは
/// 共有seedから両端末が同じものを生成できるので、この手順を
/// 先頭から再生すれば「どこが取れたか・いま誰の番か・得点はいくつか」が
/// すべて復元できる。得点や手番をそれぞれの端末で別々に持って同期すると、
/// 通信が1回抜けただけで食い違うが、この形なら食い違いようがない。
///
/// UIから切り離した純粋な関数にしてあるのは、
/// 「ペアが揃ったら手番が移らない」「揃わなければ相手の番」という
/// いちばん間違えやすいところをテストで固定するため。
library;

class TurnPairsState {
  /// 取られて伏せなくなったカード番号。
  final Set<int> matched;

  /// プレイヤーごとの獲得ペア数（インデックス＝players配列の並び順）。
  final List<int> scores;

  /// いま手番のプレイヤー。
  final int turn;

  const TurnPairsState({
    required this.matched,
    required this.scores,
    required this.turn,
  });
}

/// [moves] を先頭から再生して盤面を復元する。
///
/// - 2枚1組で判定する。**奇数枚目（めくりかけ）は無視**する
///   （＝まだ結果の出ていない手は状態に反映しない）
/// - 顔カードと名前カードで [pairId] が同じなら成立。同じ面どうしは成立しない
/// - 成立したら手番はそのまま（もう一度めくれる）、外したら次の人へ
///
/// [pairId] と [isFace] はカード番号順の配列。
TurnPairsState replayTurnPairs({
  required List<int> moves,
  required List<int> pairId,
  required List<bool> isFace,
  int players = 2,
}) {
  final matched = <int>{};
  final scores = List<int>.filled(players, 0);
  var turn = 0;
  for (var i = 0; i + 1 < moves.length; i += 2) {
    final a = moves[i];
    final b = moves[i + 1];
    final hit = a != b &&
        pairId[a] == pairId[b] &&
        isFace[a] != isFace[b];
    if (hit) {
      matched.add(a);
      matched.add(b);
      scores[turn] += 1; // ペア成立なら手番は移らない
    } else {
      turn = (turn + 1) % players;
    }
  }
  return TurnPairsState(matched: matched, scores: scores, turn: turn);
}
