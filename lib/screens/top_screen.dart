
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/custom_roster_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart'; // ロゴ・演出アニメーション
import 'package:flutter_svg/flutter_svg.dart'; // マスコットイラスト
import 'package:url_launcher/url_launcher.dart'; // Google Play 評価リンク
import 'package:nanimonjya/l10n/app_localizations.dart';
import 'name_call_screen.dart'; // メインモード「なまえがお」
import 'memory_tips_screen.dart';
import 'training_hub_screen.dart';
import 'cpu_entry_screen.dart'; // CPU対戦まえの参戦演出
import 'match_game_screen.dart' show CpuLevel;
import 'custom_roster_screen.dart'; // 🧑‍🎨 顔メモ
import 'online_lobby_screen.dart'; // オンライン対戦の待合室
import 'profile_screen.dart'; // マイページ・戦績
import 'tutorial_screen.dart'; // あそびかたチュートリアル
import 'rulebook_screen.dart'; // 📖 ルールブック
import '../services/player_profile.dart';
import '../models/cpu_difficulty.dart';
import '../models/name_call.dart';
import '../models/character_catalog.dart';
import '../models/cosmetics.dart'; // 着せ替えテーマ・称号
import '../services/sfx.dart'; // タップ音
import '../services/review_prompt.dart'; // ⭐ ストアのレビューを開く
import '../services/reward_ad_helper.dart'; // 無料コインチェストの広告
import '../l10n/meta_strings.dart'; // マイページ導線の文言
import '../l10n/memory_tips.dart'; // 名前を覚えるTips
import '../widgets/seasonal_decor.dart'; // 季節の舞い落ち装飾
import '../widgets/app_style.dart'; // 🎨 見た目の決まりごと
import '../widgets/game_ui.dart'; // 立体ボタン・縁取り文字・後光
import '../widgets/guide_talk.dart'; // 🗣 ナナちゃん・はなちゃんの声かけ
import '../services/app_analytics.dart';
import 'package:share_plus/share_plus.dart'; // 📣 SNSシェア

// 多言語対応のために追加

class TopScreen extends StatefulWidget {
  const TopScreen({super.key});

  @override
  State<TopScreen> createState() => _TopScreenState();
}

class _TopScreenState extends State<TopScreen>
    with TickerProviderStateMixin {
  // true=出たとき命名（初登場でその場命名→再登場で想起）。こちらを既定にする
  // まとめて命名のとき、名前を自分で入力せず自動でつけるか
  // 登場人数。既定は6人＝短く終わる（完走率を上げるため）
  int _peopleCount = NameCallGame.peopleCount;
  /// CPU戦でなまえコールを選んでいるか（false = 神経衰弱、既定）。
  /// 1人あたりの札の枚数。2枚＝1往復、増やすほど同じ顔に何度も会う。
  int _copies = NameCallGame.defaultCopiesPerPerson;


  // ── 🖤 ホームの落ち着いた作り ──────────────────────────
  //
  // 色数を絞る。地は濃紺、文字は白、効かせる色はゴールド1色だけ。
  // 四角を色で塗り分けるのをやめ、**余white・区切り線・文字の大きさ**で
  // 順番を示す。絵文字は使わない。
  static const Color _gold = Color(0xFFE9C87A);
  static const Color _hairline = Color(0x22FFFFFF);

  /// 節の見出し。小さく、字間を広く、控えめに。
  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: Color(0x99FFFFFF),
          ),
        ),
      );

  /// 一覧の1行。左に名前と説明、右に細い矢印。
  Widget _modeRow({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        // 1画面に収めるため、行の高さは詰める。
        // 説明文は主役の行だけに残し、他は名前だけにする
        // （説明が全部の行に並ぶと、読むものが増えて逆に選びにくい）。
        padding: EdgeInsets.symmetric(vertical: primary ? 14 : 11),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: primary ? 20 : 16,
                      fontWeight: primary ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: 0.3,
                      color: primary ? _gold : Colors.white,
                    ),
                  ),
                  if (primary && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0x8CFFFFFF),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: primary ? _gold : const Color(0x66FFFFFF)),
          ],
        ),
      ),
    );
  }

  /// 遊びかたの一覧。区切りは髪の毛ほどの線1本だけ。
  Widget _modeList(MetaStrings m) {
    final rows = <Widget>[
      _modeRow(
        primary: true,
        title: m.partyButtonLabel,
        subtitle: m.partyButtonHint,
        onTap: () => _pickLocalPlayers(context),
      ),
      _modeRow(
        title: m.cpuButtonCompact,
        subtitle: m.ja ? 'CPUと1対1。難易度で人数と持ち時間が変わります' : 'One on one. Difficulty changes faces and time',
        onTap: () => _pickCpuLevel(context),
      ),
      _modeRow(
        title: m.onlineButtonCompact,
        subtitle: m.ja ? '合言葉で友だちと、または誰かと' : 'With a friend by passphrase, or a stranger',
        onTap: () {
          Sfx.instance.fanfare();
          AppAnalytics.modePick('online_friend');
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => OnlineLobbyScreen(
                      game: 'namecall', initialPeople: _peopleCount)));
        },
      ),
      if (!kIsWeb)
        _modeRow(
          title: m.rankButtonCompact,
          subtitle: m.ja ? '勝つとレートが上がります' : 'Win to raise your rating',
          onTap: () {
            Sfx.instance.fanfare();
            AppAnalytics.modePick('rank');
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const OnlineLobbyScreen(game: 'rank')));
          },
        ),
      _modeRow(
        title: m.trainingButtonCompact,
        subtitle: m.ja ? '名刺で自己紹介 → 時間をおく → 思い出す' : 'Meet by business card, wait, then recall',
        onTap: () {
          Sfx.instance.pop();
          AppAnalytics.modePick('training_hub');
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TrainingHubScreen()));
        },
      ),
    ];

    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i != rows.length - 1) {
        children.add(const Divider(height: 1, thickness: 1, color: _hairline));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel(m.ja ? '遊ぶ' : 'Play'),
          ...children,
          if (kIsWeb) ...[
            const SizedBox(height: 16),
            _playStoreBadge(),
          ],
        ],
      ),
    );
  }

  /// 立体（沈む）ボタン。ゲームらしい押し心地の共通部品を利用。
  Widget _gradientButton({
    required String label,
    required List<Color> colors,
    required VoidCallback onTap,
    double height = 48,
    double fontSize = 15,
  }) {
    return JuicyButton(
      onTap: onTap,
      colors: colors,
      height: height,
      child: Text(
        label,
        style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: const [
              Shadow(offset: Offset(0, 1.5), color: Color(0x55000000)),
            ]),
      ),
    );
  }


  /// 👥🎴 出てくる人数と、1人あたりの枚数を決めるスライダー。
  ///
  /// ⚠️ ホームには置かない。遊ぶ前に設定が2つ並んでいると、
  ///    「まず何を押せばいいのか」が分からないまま離脱する。
  ///    遊びかたを選んだあと（ボトムシートの中）で聞く。
  ///
  /// [setSheetState] はボトムシート側の setState。
  /// シートの中で動かしたスライダーをその場に反映するために渡してもらう。
  Widget _gameSettings(MetaStrings m, StateSetter setSheetState) {
    void update(VoidCallback f) {
      setSheetState(f);
      setState(f); // ホーム側にも覚えさせて、次に開いたとき同じ値にする
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          m.peopleCountTitle,
          style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2B5CA5)),
        ),
        Row(
          children: [
            Text(
              m.peopleCountValue(_peopleCount),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2B5CA5)),
            ),
            Expanded(
              child: Slider(
                value: _peopleCount.toDouble(),
                min: NameCallGame.minSelectableCount.toDouble(),
                max: NameCallGame.maxSelectableCount.toDouble(),
                divisions: NameCallGame.maxSelectableCount -
                    NameCallGame.minSelectableCount,
                label: m.peopleCountValue(_peopleCount),
                onChanged: (v) => update(() => _peopleCount = v.round()),
              ),
            ),
          ],
        ),
        Text(
          m.peopleCountHint(_peopleCount),
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        // 🎴 1人あたりの枚数。
        //    2枚＝命名1回＋想起1回で終わり。
        //    増やすと同じ顔に何度も会うので、
        //    間隔をあけた復習に近づいて定着しやすい。
        Text(
          m.copiesTitle,
          style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2B5CA5)),
        ),
        Row(
          children: [
            Text(
              m.copiesValue(_copies),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2B5CA5)),
            ),
            Expanded(
              child: Slider(
                value: _copies.toDouble(),
                min: NameCallGame.minCopiesPerPerson.toDouble(),
                max: NameCallGame.maxCopiesPerPerson.toDouble(),
                divisions: NameCallGame.maxCopiesPerPerson -
                    NameCallGame.minCopiesPerPerson,
                label: m.copiesValue(_copies),
                onChanged: (v) => update(() => _copies = v.round()),
              ),
            ),
          ],
        ),
        Text(
          m.copiesHint(_peopleCount * _copies, _copies - 1),
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F4FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            m.estimatedTime(_peopleCount, _copies),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3A7BD5),
            ),
          ),
        ),
      ],
    );
  }

  /// 🎁🪙📺 コンパクトなチップ型ボタン。ギフト・ガチャ・広告→キャラ用。
  Widget _chipButton({
    required VoidCallback onTap,
    required String emoji,
    required String label,
    required bool active,
    required Color activeColor,
    required Color fgColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            // 塗りつぶしをやめ、細い枠だけにする。
            // ここは主役ではないので、地の色に沈ませておく。
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? _gold.withValues(alpha: 0.55) : _hairline,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: active ? _gold : const Color(0x8CFFFFFF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎁 今日のキャラを1体引く（1日1回）。
  Future<void> _pullGacha() async {
    final m = MetaStrings.of(context);
    final p = PlayerProfile.instance;
    final id = await p.pullDailyGacha();
    if (!mounted) return;
    Sfx.instance.reward();
    final c = id == null ? null : extraCharacterById(id);
    if (c == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m.gachaAllOwned(80))),
      );
      return;
    }
    // 当たったキャラを顔つきで見せる（何をもらったか分からないと嬉しくない）
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(c.asset,
                  width: 150, height: 150, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            Text(m.gachaGot(c.emoji),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(m.trainingIntroOk),
          ),
        ],
      ),
    );
  }

  /// 🤖 CPU対戦の難易度を選んでスタート。
  ///
  /// 「むずかしいほど報酬が大きい」を選ぶ時点で見せて、
  /// コインを貯める動機づけにする。
  void _pickCpuLevel(BuildContext context) {
    Sfx.instance.pop();
    AppAnalytics.modePick('cpu');
    final m = MetaStrings.of(context);
    // 難易度の中身（覚える人数・持ち時間・コイン）は models/cpu_difficulty.dart が
    // 一次情報。ここに数字を直書きすると実際の報酬と食い違うので必ず参照する。
    // 難易度は**色ではなく濃さ**で示す。虹色に塗り分けると、
    // どれが強いのかが色から読み取れないうえ、画面だけ賑やかになる。
    // 上に行くほど濃く＝手ごわい、という並びにする。
    const colors = [
      Color(0xFF2A3346),
      Color(0xFF333E55),
      Color(0xFF3D4A66),
      Color(0xFF485777),
      Color(0xFF556488),
      Color(0xFF637199),
    ];
    final rows = [
      for (final (i, lv) in [
        CpuLevel.easy,
        CpuLevel.normal,
        CpuLevel.hard,
        CpuLevel.oni,
        CpuLevel.god,
      ].indexed)
        (lv, cpuDifficultyOf(lv), colors[i]),
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 👥🎴 ひとりでは なまえコール だけ。難易度を選ぶと始まる。
              //    難易度ごとに「覚える人数」と「持ち時間」が決まっていて
              //    （models/cpu_difficulty.dart が一次情報）、
              //    選ぶのは難易度ひとつだけにする。
              _stepLabel(1, m.ja ? '相手を選ぶ（押すと始まります）'
                  : 'Pick your rival — tap to start'),
              Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 12),
                child: Text(m.cpuPickHint,
                    style: const TextStyle(
                        fontSize: 12, height: 1.4, color: AppStyle.textMuted)),
              ),
              for (final (lv, diff, color) in rows) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      AppAnalytics.cpuGamePick(game: 'namecall', level: lv.name);
                      Sfx.instance.fanfare();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CpuEntryScreen(
                            level: lv,
                            nameCall: true,
                            peopleCount: _peopleCount,
                            copiesPerPerson: _copies,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Row(
                      children: [
                        Text(diff.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(m.cpuLevelName(lv),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900)),
                              // 何がどう難しくなるのかを選ぶ前に見せる。
                              // 「強い＝ただ相手が速い」ではなく、
                              // まとめて覚える人数と持ち時間が変わることを伝える。
                              Text(
                                m.cpuLevelDetail(
                                    diff.groupSize, diff.answerSeconds),
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        Text(m.cpuLevelReward(diff.winBonus),
                            style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      )),
      ),
    );
  }

  /// 「1.」「2.」と番号を振った手順の見出し。
  /// 選ぶものが2つある画面は、順番を示さないと手が止まる。
  Widget _stepLabel(int step, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: AppStyle.gold, shape: BoxShape.circle),
              child: Text('$step',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Text(text,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: AppStyle.text)),
          ],
        ),
      );

  /// みんなで対戦（なまえがお）の人数を選んでスタート
  void _pickLocalPlayers(BuildContext context) {
    Sfx.instance.pop();
    AppAnalytics.modePick('local');
    final m = MetaStrings.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 👥🎴 遊ぶ中身をここで決める（ホームには置かない）
                  _gameSettings(m, setSheetState),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  // 🧍 ひとりで遊ぶ入口。
                  //
                  // ⚠️ ここが**丸ごと無かった**。`NameCallScreen(humanPlayers: 1,
                  //    quizMode: true)` は実装済みなのに、ホームからは
                  //    2〜4人ぶんのボタンしか無く、ひとりでは主役モードに
                  //    たどり着けなかった（オンラインと顔メモ経由のみ）。
                  //    チュートリアルが「1分で遊べる」と言っている以上、
                  //    最初に押せるのはこれであるべき。
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      AppAnalytics.modePick('solo');
                      Sfx.instance.fanfare();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NameCallScreen(
                            humanPlayers: 1,
                            quizMode: true, // ひとりのときは4択で答える
                            peopleCount: _peopleCount,
                            copiesPerPerson: _copies,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A7BD5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Text(
                      m.ja ? '🧍 ひとりで遊ぶ' : '🧍 Play solo',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    m.ja
                        ? '出てきた顔に名前をつけて、また出てきたら4択で思い出す'
                        : 'Name each face, then recall it from four choices',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    m.ja ? '👥 ${m.howManyPlayers}' : '👥 ${m.howManyPlayers}',
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m.ja
                        ? 'スマホ1台を回して、名前を声に出して呼び合う'
                        : 'Pass one phone around and call the names out loud',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final n in [2, 3, 4]) ...[
                        if (n > 2) const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NameCallScreen(
                                    humanPlayers: n,
                                    peopleCount: _peopleCount,
                                    copiesPerPerson: _copies,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8663C),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(m.ja ? '$n人' : '${n}P'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  final RewardAdHelper _giftAd = RewardAdHelper(placement: 'home_gift');
  final RewardAdHelper _gachaAd = RewardAdHelper(placement: 'home_gacha'); // 広告→キャラゲット
  final Random _random = Random();
  Timer? _giftTicker;
  late AnimationController _bounceController; // マスコットのぴょこぴょこ

  @override
  void initState() {
    super.initState();
    AppAnalytics.screen('top');
    // 🎁 ホームの「動画でコイン」はいちばん押される導線なので、ここだけは先読みする。
    //    在庫は全画面で共有なので、2回呼んでも2本読むわけではない（_gachaAd.load() は
    //    同じ在庫を見にいくだけの無駄呼び出しだったので外した）。
    _giftAd.load();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    // 🎁の残り時間表示を1分ごとに更新（止まったままにならないように）
    _giftTicker = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _giftAd.dispose();
    _gachaAd.dispose();
    _bounceController.dispose();
    _giftTicker?.cancel();
    super.dispose();
  }

  // 🎁 無料コインチェスト: 動画を見てランダムなコイン(50〜200)をゲット
  Future<void> _claimGift() async {
    final m = MetaStrings.of(context);
    final profile = PlayerProfile.instance;
    if (!profile.canClaimGift) {
      final mins = profile.giftCooldownRemaining.inMinutes + 1;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m.giftWaitMin(mins))));
      return;
    }
    // 50〜200コインのランダム報酬（10刻みでワクワク感）
    final amount = 50 + _random.nextInt(16) * 10;
    final played = await _giftAd.showOrQueue(onReward: () async {
      await profile.claimGift(amount);
      Sfx.instance.fanfare();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(m.giftGot(amount))));
      }
    });
    if (!mounted) return;
    if (!played) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m.adQueued)));
    }
  }

  /// ⭐ Google Play ストアのレビュー画面を開く。
  /// モバイルではアプリ内で Play ストアを開き、Web ではブラウザで開く。
  Future<void> _launchPlayReview() async {
    final localizations = AppLocalizations.of(context)!;
    final uri = Uri.parse(
      kIsWeb
          ? 'https://play.google.com/store/apps/details?id=com.nanimonjya'
          : 'market://details?id=com.nanimonjya',
    );
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.couldNotOpenLink)),
      );
    }
  }

  /// Buy Me a Coffee のページを外部ブラウザで開く
  Future<void> _launchBuyMeACoffee() async {
    final localizations = AppLocalizations.of(context)!;
    final uri = Uri.parse('https://buymeacoffee.com/toriumi');
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.couldNotOpenLink)),
      );
    }
  }

  /// 🌐 Web管理ページを開く（プライバシーポリシー / プレスキット）
  Future<void> _openWebPage(String path) async {
    final uri = Uri.parse('https://web-sigma-drab-72.vercel.app$path');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  /// 📺 広告を見てキャラを1体もらう（ガチャとは別枠）。
  Future<void> _watchAdForCharacter() async {
    final m = MetaStrings.of(context);
    final played = await _gachaAd.showOrQueue(onReward: () async {
      final profile = PlayerProfile.instance;
      // 未所持の追加キャラからランダムに1体選ぶ
      final pool = [
        for (final c in kExtraCharacters)
          if (!profile.unlockedCharacters.contains(c.id)) c,
      ];
      if (pool.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(m.gachaAllOwned(0))),
          );
        }
        return;
      }
      final picked = pool[_random.nextInt(pool.length)];
      await profile.unlockCharacter(picked.id, 0);
      Sfx.instance.fanfare();
      if (mounted) {
        await showDialog<void>(
          context: this.context,
          builder: (ctx) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(picked.asset,
                      width: 150, height: 150, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                Text(m.characterJoined(picked.emoji),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(m.trainingIntroOk),
              ),
            ],
          ),
        );
      }
    });
    if (!mounted) return;
    if (!played) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m.adQueued)));
    }
  }

  // 右上のコイン残高（小型）
  Widget _topBar() {
    return AnimatedBuilder(
      animation: PlayerProfile.instance,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3D6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6B54A)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🪙', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 2),
              Text('${PlayerProfile.instance.coins}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8A6A1E))),
            ],
          ),
        );
      },
    );
  }

  /// 📱 Google Play バッジ。ランク＋特訓の代わりにWeb版ホームの目立つ位置へ。
  Widget _playStoreBadge() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A8C4A), width: 2.5),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E6B35), Color(0xFF1A8C4A)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _launchPlayReview,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text('▶',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('GET IT ON',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFA5D6B4),
                            letterSpacing: 1.5,
                          )),
                      const Text('Google Play',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                          )),
                      Text(MetaStrings.of(context).ja
                          ? 'アプリのほうがサクサク動きます'
                          : 'Smoother experience on mobile',
                          style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xE6FFFFFF),
                              height: 1.3)),
                    ],
                  ),
                ),
                const Icon(Icons.open_in_new,
                    size: 15, color: Color(0x88FFFFFF)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🌐 Web版で言語を切り替えるボタン（日 / EN）。
  Widget _webLocaleToggle() {
    if (!kIsWeb) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: PlayerProfile.instance,
      builder: (context, _) {
        final ja =
            PlayerProfile.instance.webLocaleCode != 'en'; // null or 'ja' → 日本語
        return GestureDetector(
          onTap: () {
            Sfx.instance.pop();
            PlayerProfile.instance.setWebLocale(ja ? 'en' : 'ja');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xEEFFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBCC8E0)),
            ),
            child: Text(
              ja ? '🇯🇵 日本語' : '🇺🇸 English',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2B5CA5),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final m = MetaStrings.of(context);
    final homeTheme = homeThemeById(PlayerProfile.instance.selectedTheme);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog();
      },
      child: Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: homeTheme.gradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 🍂 季節の飾りは、落ち着いた地の上では文字に重なって
              //    読みづらくなるだけなので出さない。
              if (!homeTheme.darkBackground)
                const Positioned.fill(child: SeasonalDecor()),
              Positioned(top: 8, right: 8, child: _topBar()),
              Positioned(top: 8, left: 8, child: _webLocaleToggle()),
              SingleChildScrollView(child: Column(
                children: [
                  const SizedBox(height: 6),
                  // 名前は大きく細く、字間を広げて置く。
                  // 縁取りや影で飾らない（飾るほど安く見える）。
                  const SizedBox(height: 14),
                  Text(
                    localizations.appTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 6.0,
                      color: homeTheme.titleColor,
                    ),
                  ).animate().fadeIn(duration: 500.ms, curve: Curves.easeOut),
                  const SizedBox(height: 8),
                  Container(width: 28, height: 1, color: _gold),
                  const SizedBox(height: 8),
                  Text(
                    m.tagline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.6,
                      color: Color(0x99FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 🗣 ななちゃん・はなちゃんのひとこと（マスコット左右）
                  AnimatedBuilder(
                    animation: _bounceController,
                    builder: (context, _) {
                      final t = _bounceController.value;
                      final wave = t < 0.5 ? t * 2 : (1 - t) * 2;
                      final dyL = -5.0 * wave;
                      final dyR = -5.0 * (1 - wave);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            Transform.translate(
                              offset: Offset(0, dyL),
                              child: SvgPicture.asset(
                                'assets/images/supporters/cheer_girl2.svg',
                                width: 40, height: 40,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(child: const GuideTalk()),
                            const SizedBox(width: 4),
                            Transform.translate(
                              offset: Offset(0, dyR),
                              child: SvgPicture.asset(
                                'assets/images/supporters/cheer_girl.svg',
                                width: 40, height: 40,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // 🎁 ギフト ／ 🎁 ガチャ ／ 📺 広告でキャラ
                  AnimatedBuilder(
                    animation: PlayerProfile.instance,
                    builder: (context, _) {
                      final p = PlayerProfile.instance;
                      final ready = p.canClaimGift;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            if (RewardAdHelper.available)
                              _chipButton(
                                onTap: _claimGift,
                                emoji: '🎁',
                                label: ready ? m.freeGift : m.giftWaitMin(p.giftCooldownRemaining.inMinutes + 1),
                                active: ready,
                                activeColor: const Color(0xFFFFC93C),
                                fgColor: const Color(0xFF5A3E00),
                              ),
                            if (p.canPullGacha)
                              _chipButton(
                                onTap: _pullGacha,
                                emoji: '🎁',
                                label: m.gachaReady,
                                active: true,
                                activeColor: const Color(0xFFFF4FA3),
                                fgColor: Colors.white,
                              ),
                            if (RewardAdHelper.available)
                              _chipButton(
                                onTap: _watchAdForCharacter,
                                emoji: '📺',
                                label: m.watchAdGetChar,
                                active: true,
                                activeColor: const Color(0xFF4ECDC4),
                                fgColor: Colors.white,
                              ),
                          ].expand((w) => [w, const SizedBox(width: 4)]).toList()
                            ..removeLast(),
                        ),
                      );
                    },
                  ),
                  // 👉 つぎの一歩
                  const SizedBox(height: 10),
                  // モードは一覧で見せる（色分けした四角を並べない）
                  _modeList(m),
                  const SizedBox(height: 12),
                  // 📖 あそびかた（大きなボタン。初めての人をここで受ける）
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Sfx.instance.pop();
                          Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const TutorialScreen()));
                        },
                        icon: const Icon(Icons.menu_book_outlined),
                        label: Text(m.ja ? 'あそびかた' : 'How to Play'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // 🧑‍🎨 顔メモ — 大きく常設
                  _faceMemoCard(m),
                  const SizedBox(height: 8),
                  // 📖⭐ ルール・チュートリアル・レビュー・マイページ・支援
                  _shortcutRow(m, localizations),
                  const SizedBox(height: 6),
                  // 🧠 名前を覚えるコツ（横スクロール）
                  _memoryTipsRow(m),
                  const SizedBox(height: 6),
                  // 🌐 Web版はここに管理リンク
                  if (kIsWeb) ...[
                    // 🔒 🔗 管理ページ（プライバシー・プレスキット）
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          _miniChip(
                            emoji: '🔒',
                            label: 'Privacy',
                            color: const Color(0xFF555555),
                            onTap: () => _openWebPage('/privacy.html'),
                          ),
                          _miniChip(
                            emoji: '📰',
                            label: 'Press Kit',
                            color: const Color(0xFF555555),
                            onTap: () => _openWebPage('/presskit.html'),
                          ),
                          _miniChip(
                            emoji: '☕',
                            label: 'Support',
                            color: const Color(0xFFBB6B2A),
                            onTap: () => _launchBuyMeACoffee(),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // ⭐ Google Play レビュー (モバイルのみ)
                  if (!kIsWeb) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: JuicyButton(
                      onTap: _launchPlayReview,
                      colors: const [Color(0xFF3A7BD5), Color(0xFF1E5CA5)],
                      height: 40,
                      radius: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('⭐', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            m.playReviewButton,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ],
                  // 📮📣 ご意見・不具合 ＋ SNSシェア
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openFeedbackSheet,
                            icon: const Text('📮', style: TextStyle(fontSize: 15)),
                            label: Text(m.feedbackHomeButton),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _shareApp,
                            icon: const Text('📣', style: TextStyle(fontSize: 15)),
                            label: Text(m.shareAppButton),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _shareOnX,
                            icon: const Text('𝕏', style: TextStyle(fontSize: 15)),
                            label: const Text('X'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
              ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  /// 🔥 次のログインキャラまでの進捗テキスト。未解放がなければ null。
  String? _loginCharProgress(int streak) {
    for (final c in kExtraCharacters) {
      if (!c.isLoginCharacter) continue;
      if (PlayerProfile.instance.unlockedCharacters.contains(c.id)) continue;
      final needed = loginDaysFor(c.feat!);
      if (streak < needed) {
        final m = MetaStrings.of(context);
        return m.loginCharProgress(streak, needed, c.emoji);
      }
    }
    return null;
  }

  /// 🚪 ホームの戻るボタンで「もう行っちゃうの？」を出す。
  Future<void> _showExitDialog() async {
    final m = MetaStrings.of(context);
    final stay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.exitDialogTitle),
        content: Text(m.exitDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.exitDialogLeave),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.exitDialogStay),
          ),
        ],
      ),
    );
    if (stay == true) return;
    // 本当に閉じる
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  /// 📮 ご意見・不具合をゲーム内から送る（Firestore の feedback コレクションへ）。
  /// 📮 ご意見・不具合をメールで送る（[kFeedbackEmail] 宛て）。
  /// メーラーが開き、あらかじめ件名・本文が入った状態で送れる。
  Future<void> _openFeedbackSheet() async {
    final m = MetaStrings.of(context);
    Sfx.instance.pop();
    final uri = Uri(
      scheme: 'mailto',
      path: kFeedbackEmail,
      query: 'subject=${Uri.encodeComponent(m.feedbackSubject)}'
          '&body=${Uri.encodeComponent(m.feedbackBody)}',
    );
    try {
      await launchUrl(uri);
    } catch (_) {
      // メーラーが無い端末では何もしない（落とさない）
    }
  }

  /// 📣 SNSでアプリの感想をシェアする（#なまえがお）。
  Future<void> _shareApp() async {
    final m = MetaStrings.of(context);
    Sfx.instance.pop();
    await Share.share(
        '${m.shareAppText}\nhttps://web-sigma-drab-72.vercel.app');
  }

  /// 𝕏（旧Twitter）で感想をシェアする。公式の intent URL を開く。
  Future<void> _shareOnX() async {
    final m = MetaStrings.of(context);
    Sfx.instance.pop();
    final text = Uri.encodeComponent(
        '${m.shareAppText}\nhttps://web-sigma-drab-72.vercel.app');
    final uri = Uri.parse('https://twitter.com/intent/tweet?text=$text');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  /// 📖🧑‍🎨⭐ ルール・チュートリアル・顔メモ・レビュー・マイページ・支援
  Widget _shortcutRow(MetaStrings m, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _miniChip(
            emoji: '📖',
            label: m.rulebookLabel,
            color: const Color(0xFF5A7A9A),
            onTap: () {
              Sfx.instance.pop();
              AppAnalytics.modePick('rulebook');
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const RulebookScreen(),
              ));
            },
          ),
          _miniChip(
            emoji: '👧👦',
            label: m.tutorialLabel,
            color: const Color(0xFF1E7BA6),
            onTap: () {
              Sfx.instance.pop();
              AppAnalytics.modePick('tutorial');
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const TutorialScreen(),
              ));
            },
          ),
          _miniChip(
            emoji: '⭐',
            label: m.reviewLabel,
            color: const Color(0xFFCE8A00),
            onTap: () {
              Sfx.instance.pop();
              AppAnalytics.modePick('review');
              openStoreReview();
            },
          ),
          _miniChip(
            emoji: '🏆',
            label: m.profileTitle,
            color: const Color(0xFFB8860B),
            onTap: () {
              Sfx.instance.pop();
              AppAnalytics.modePick('profile');
              _openProfile();
            },
          ),
          _miniChip(
            emoji: '☕',
            label: l10n.buyMeACoffee,
            color: const Color(0xFFBB6B2A),
            onTap: () {
              Sfx.instance.pop();
              AppAnalytics.modePick('support');
              _launchBuyMeACoffee();
            },
          ),
        ],
      ),
    );
  }

  /// アイコンのみの小型チップ。
  Widget _miniChip({
    required String emoji,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🧑‍🎨 顔メモ — 大きく目立たせるカード
  Widget _faceMemoCard(MetaStrings m) {
    final count = CustomRosterService.instance.entries.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Sfx.instance.pop();
            AppAnalytics.modePick('face_memo');
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const CustomRosterScreen(),
            ));
          },
          child: Container(
            decoration: BoxDecoration(
              // 塗りつぶしをやめ、地に沈む枠だけのカードにする。
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _hairline, width: 1),
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
            child: Row(
              children: [
                const Icon(Icons.person_add_alt_1_outlined,
                    size: 26, color: _gold),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m.faceMemoCardTitle,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: Colors.white)),
                      const SizedBox(height: 3),
                      Text(m.faceMemoCardBody,
                          style: const TextStyle(
                              fontSize: 12, height: 1.4,
                              color: Color(0x8CFFFFFF))),
                      const SizedBox(height: 3),
                      Text(m.faceMemoCardHint(count),
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _gold),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 13, color: Color(0x66FFFFFF)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🧠 名前を覚えるコツ（横スクロールのコンパクトカード）
  Widget _memoryTipsRow(MetaStrings m) {
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            Sfx.instance.pop();
            AppAnalytics.modePick('memory_tips');
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const MemoryTipsScreen(embedded: true),
            ));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    m.memoryTipHeader,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF555555),
                    ),
                  ),
                ),
                Text(
                  ja ? 'もっと読む →' : 'Read more →',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF3A7BD5)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: kMemoryShortTips.length,
            itemBuilder: (context, i) {
              final tip = kMemoryShortTips[i];
              return GestureDetector(
                onTap: () {
                  Sfx.instance.pop();
                  AppAnalytics.modePick('memory_tips');
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const MemoryTipsScreen(embedded: true),
                  ));
                },
                child: Container(
                  width: 220,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tip.text(ja),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, height: 1.35),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

}
