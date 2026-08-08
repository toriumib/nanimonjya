import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // ロゴ・演出アニメーション
import 'package:flutter_svg/flutter_svg.dart'; // マスコットイラスト
import 'package:google_fonts/google_fonts.dart'; // ロゴ専用フォント
import 'package:url_launcher/url_launcher.dart'; // Buy Me a Coffee のリンクを開くため
import 'package:nanimonjya/l10n/app_localizations.dart';
import 'name_call_screen.dart'; // メインモード「なまえがお」
import 'cpu_entry_screen.dart'; // CPU対戦まえの参戦演出
import 'match_game_screen.dart' show CpuLevel;
import 'custom_roster_screen.dart'; // 🧑‍🎨 顔メモ
import 'online_lobby_screen.dart'; // オンライン対戦の待合室
import 'profile_screen.dart'; // マイページ・戦績
import '../services/player_profile.dart';
import '../models/cpu_difficulty.dart';
import '../models/name_call.dart';
import '../models/character_catalog.dart';
import '../models/cosmetics.dart'; // 着せ替えテーマ・称号
import '../services/review_prompt.dart'; // ⭐ ストアのレビューを開く
import '../services/sfx.dart'; // タップ音
import '../services/reward_ad_helper.dart'; // 無料コインチェストの広告
import '../l10n/meta_strings.dart'; // マイページ導線の文言
import 'tutorial_screen.dart'; // あそびかたチュートリアル
import 'rulebook_screen.dart'; // 📖 いつでも見直せるルールブック
import '../widgets/seasonal_decor.dart'; // 季節の舞い落ち装飾
import '../widgets/game_ui.dart'; // 立体ボタン・縁取り文字・後光
import '../widgets/banner_ad_slot.dart';
import '../widgets/guide_talk.dart'; // 🗣 ナナちゃん・はなちゃんの声かけ
import '../services/app_analytics.dart';

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
  /// 1人あたりの札の枚数。2枚＝1往復、増やすほど同じ顔に何度も会う。
  int _copies = NameCallGame.defaultCopiesPerPerson;

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
      ],
    );
  }

  /// 🧭 ホーム下部のまとめ導線1つぶん。
  ///
  /// 顔メモ・マイページ・チュートリアル・レビュー・支援を
  /// 同じ見た目の小さなタイルにして並べる。
  /// 縦長のボタンを積むより、ずっと少ない高さで収まる。
  Widget _shortcutTile({
    required String emoji,
    required String label,
    required Color color,
    required VoidCallback onTap,
    /// 📊 押された数を数えるための固定の識別子。
    required String analyticsId,
    bool highlight = false,
  }) {
    return Material(
      color: highlight ? const Color(0xFFFFF3D0) : Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Sfx.instance.pop();
          AppAnalytics.modePick(analyticsId);
          onTap();
        },
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: color.withValues(alpha: highlight ? 0.9 : 0.45),
                width: highlight ? 2.2 : 1.6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📅 今週の記録・🎁 今日のキャラ をまとめたホームの状態表示。
  Widget _homeStatusRow(BuildContext context) {
    final m = MetaStrings.of(context);
    final p = PlayerProfile.instance;
    return Column(
      children: [
        Row(
          children: [
            // 🏆 段位（「一人前」などの称号）はホームから外した。
            //    ホームは「今日なにをするか」を出す場所で、
            //    格付けを見せる場所ではない。段位はマイページで見られる。
            // Expanded(
            //   child: Container(
            //     padding:
            //         const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            //     decoration: BoxDecoration(
            //       color: Colors.white.withValues(alpha: 0.92),
            //       borderRadius: BorderRadius.circular(14),
            //       border: Border.all(color: const Color(0xFFE6B54A), width: 2),
            //     ),
            //     child: Row(
            //       children: [
            //         Text(rank.emoji, style: const TextStyle(fontSize: 20)),
            //         const SizedBox(width: 6),
            //         Expanded(
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               Text(m.ja ? rank.nameJa : rank.nameEn, ...),
            //               Text('${p.cpuRating}', ...),
            //             ],
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            // 🎁 今日のキャラガチャ
            Expanded(
              child: ElevatedButton(
                onPressed: p.canPullGacha ? _pullGacha : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.canPullGacha
                      ? const Color(0xFFFF4FA3)
                      : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(m.gachaTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w900)),
                    Text(p.canPullGacha ? m.gachaReady : m.gachaDoneToday,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
        ),
        // 📅 今週おぼえた人数。
        // ⚠️ 0人のときは何も出さない。「今週はまだ0人」は、
        //    これから遊ぼうとしている人に冷たいだけで役に立たない。
        if (p.weeklyLearned > 0) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              m.weeklyLearnedLabel(p.weeklyLearned),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2B5CA5)),
            ),
          ),
        ],
      ],
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
    const colors = [
      Color(0xFF4ECDC4),
      Color(0xFF3A7BD5),
      Color(0xFFE8663C),
      Color(0xFF8A5AC2),
    ];
    final rows = [
      for (final (i, lv) in [
        CpuLevel.easy,
        CpuLevel.normal,
        CpuLevel.hard,
        CpuLevel.oni,
      ].indexed)
        (lv, cpuDifficultyOf(lv), colors[i]),
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 👥🎴 CPU戦では人数・枚数を選ばせない。
              //    難易度ごとに「覚える人数」と「持ち時間」が決まっていて
              //    （models/cpu_difficulty.dart が一次情報）、
              //    そこへ別の人数設定を重ねると報酬とつり合わなくなる。
              //    選ぶのは難易度ひとつだけにする。
              Text(m.cpuPickTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(m.cpuPickHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 14),
              for (final (lv, diff, color) in rows) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Sfx.instance.fanfare();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CpuEntryScreen(
                            level: lv,
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
    );
  }

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
                  const Text(
                    '何人であそぶ？',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
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
                            child: Text('$n人'),
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

  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _bounceController; // マスコットのぴょこぴょこ
  final RewardAdHelper _giftAd = RewardAdHelper(placement: 'home_gift'); // 無料コインチェスト用
  final Random _random = Random();
  Timer? _giftTicker; // 🎁残り時間表示の更新用

  @override
  void initState() {
    super.initState();
    AppAnalytics.screen('top');
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // アニメーションの時間
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut, // アニメーションのカーブ
      ),
    );
    _controller.forward(); // アニメーションを開始
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _giftAd.load();
    // 🎁の残り時間表示を1分ごとに更新（止まったままにならないように）
    _giftTicker = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _bounceController.dispose();
    _giftAd.dispose();
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

  // Buy Me a Coffee のページを外部ブラウザで開く
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

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    ).then((_) {
      if (mounted) setState(() {}); // 戻ってきたらコイン表示を更新
    });
  }

  // 右上のコイン残高＋マイページボタン（デイリーボーナス可なら赤バッジ）
  Widget _topBar() {
    final profile = PlayerProfile.instance;
    return AnimatedBuilder(
      animation: profile,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3D6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE6B54A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text('${profile.coins}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8A6A1E))),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.emoji_events_outlined),
                  tooltip: 'マイページ',
                  onPressed: _openProfile,
                ),
                if (profile.canClaimDaily)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 多言語対応の文字列にアクセスするためのインスタンス
    final localizations = AppLocalizations.of(context)!; // ★追加★

    // 選択中の着せ替えテーマ（コインでアンロック可能）
    final homeTheme = homeThemeById(PlayerProfile.instance.selectedTheme);

    return Scaffold(
      bottomNavigationBar: const BannerAdSlot(),
      body: Container(
        // ★選択中テーマのグラデーション背景★
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
            // 🍁 季節の装飾がゆっくり舞う（タッチ透過）
            const Positioned.fill(child: SeasonalDecor()),
            Positioned(top: 8, right: 8, child: _topBar()),
            Center(
        child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // ★ヒーロー（コンパクト版）★
            // 以前はマスコット130px＋後光230px＋キャッチ＋称号＋ギフトを縦に積んでいて、
            // 「あそぶ」ボタンまでスクロールが必要だった。
            // マスコットをロゴの左右に寄せ、称号とギフトを1行にまとめて高さを約半分にする。
            AnimatedBuilder(
              animation: _bounceController,
              builder: (context, _) {
                final t = _bounceController.value;
                final wave = t < 0.5 ? t * 2 : (1 - t) * 2; // 0→1→0
                final dyL = -7.0 * wave;
                final dyR = -7.0 * (1 - wave);
                return SizedBox(
                  height: 132,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // ロゴ背後でゆっくり回る後光
                      SunRays(
                        size: 168,
                        color: homeTheme.darkBackground
                            ? Colors.white
                            : homeTheme.titleColor,
                      ),
                      // 左右のマスコット（ロゴの外側でふわり浮遊）
                      Positioned(
                        left: 0,
                        bottom: 8,
                        child: Transform.translate(
                          offset: Offset(0, dyL),
                          child: SvgPicture.asset(
                            'assets/images/supporters/cheer_girl2.svg',
                            width: 66,
                            height: 66,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 8,
                        child: Transform.translate(
                          offset: Offset(0, dyR),
                          child: SvgPicture.asset(
                            'assets/images/supporters/cheer_girl.svg',
                            width: 66,
                            height: 66,
                          ),
                        ),
                      ),
                      // タイトルロゴ＋キャッチコピー
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 66),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: OutlinedText(
                                localizations.appTitle,
                                strokeWidth: 7,
                                strokeColor: Colors.white,
                                maxLines: 1,
                                style: GoogleFonts.mochiyPopOne(
                                  fontSize: 34,
                                  color: homeTheme.titleColor,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(2.5, 2.5),
                                      blurRadius: 0,
                                      color: homeTheme.titleShadow,
                                    ),
                                    const Shadow(
                                      offset: Offset(4.0, 4.0),
                                      blurRadius: 7,
                                      color: Color(0x33000000),
                                    ),
                                  ],
                                ),
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                                .scale(
                                  begin: const Offset(0.7, 0.7),
                                  end: const Offset(1.0, 1.0),
                                  duration: 500.ms,
                                  curve: Curves.elasticOut,
                                ),
                            const SizedBox(height: 5),
                            // キャッチコピー（何のゲームか一目でわかる）
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 3),
                              decoration: BoxDecoration(
                                color: homeTheme.darkBackground
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : homeTheme.titleColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  MetaStrings.of(context).tagline,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: homeTheme.darkBackground
                                        ? const Color(0xFF2B2D64)
                                        : Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // 🗣 ナナちゃん・はなちゃんの声かけ。
            //    いまのその人（復習どきの人数・連続日数・時間帯）に
            //    合わせた一言を出す。ロゴの直下＝いちばん最初に目が行く場所。
            AnimatedBuilder(
              animation: PlayerProfile.instance,
              builder: (context, _) => const GuideTalk(),
            ),
            // 称号バッジ と 🎁無料コイン を横1行に（以前は縦に積んでいた）
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: AnimatedBuilder(
                animation: PlayerProfile.instance,
                builder: (context, _) {
                  final title =
                      currentTitle(PlayerProfile.instance.lifetimeCoins);
                  final ja =
                      Localizations.localeOf(context).languageCode == 'ja';
                  final ready = PlayerProfile.instance.canClaimGift;
                  final m = MetaStrings.of(context);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: homeTheme.titleColor, width: 2),
                          ),
                          child: Text(
                            '${title.emoji} ${ja ? title.nameJa : title.nameEn}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: homeTheme.darkBackground
                                  ? const Color(0xFF2B2D64)
                                  : homeTheme.titleColor,
                            ),
                          ),
                        ),
                      ),
                      // 🎁 無料コインチェスト（受け取れるときだけ揺れて目立つ）
                      if (RewardAdHelper.available) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: AnimatedBuilder(
                            animation: _bounceController,
                            builder: (context, child) {
                              final wobble = ready
                                  ? (_bounceController.value - 0.5) * 0.08
                                  : 0.0;
                              return Transform.rotate(
                                  angle: wobble, child: child);
                            },
                            child: ElevatedButton.icon(
                              onPressed: _claimGift,
                              icon: const Text('🎁',
                                  style: TextStyle(fontSize: 16)),
                              label: Text(
                                ready
                                    ? m.freeGift
                                    : m.giftWaitMin(PlayerProfile.instance
                                            .giftCooldownRemaining.inMinutes +
                                        1),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ready
                                    ? const Color(0xFFFFC93C)
                                    : Colors.grey.shade400,
                                foregroundColor: const Color(0xFF5A3E00),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                textStyle: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                  side: const BorderSide(
                                      color: Colors.white, width: 2),
                                ),
                                elevation: 5,
                                shadowColor: const Color(0xAAFFC93C),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            // 🏆 段位と 📅 今週の記録と 🎁 今日のキャラ。
            // 段位(cpuRating)は前からあったのにホームに出ておらず、
            // 伸びている実感が持てなかったのでここに常設する。
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: AnimatedBuilder(
                animation: PlayerProfile.instance,
                builder: (context, _) => _homeStatusRow(context),
              ),
            ),
            // フェードインアニメーション付きのボタン
            FadeTransition(
              opacity: _animation,
              child: Column(
                children: [
                  // ★メインモード「なまえがお」カード★
                  Builder(builder: (context) {
                    final m = MetaStrings.of(context);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Color(0xFFF2FCFB)],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x2E4ECDC4),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          // 🗑 ヘッダー帯（「なまえがお」＋キャッチコピー）は外した。
                          //    すぐ上のロゴが同じことを言っていて二重だったうえ、
                          //    遊ぶボタンが下へ押し出されていた。
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                            child: Column(
                              children: [
                                // 🗑 「まとめて命名」と「2枚同時に出す」は撤去した。
                                // 遊ぶ前に3つも設定を選ばせていて、どれを選べば
                                // いいか分からないまま離脱する原因になっていた。
                                // ルールは「出たとき命名」1本にする。
                                //
                                // 👥🎴 出てくる人数・1人あたりの枚数のスライダーも
                                //    ここから外し、遊びかたを選んだあとの
                                //    ボトムシート（_gameSettings）へ移した。
                                //    ホームに設定が並んでいると、最初に押すべき
                                //    ボタンが埋もれてしまう。
                                // 📖 ルールをいつでも見直せるボタン。
                                // ⚠️ ボタン自身が「ルール」と表示するので、
                                //    横にラベルを足さないこと（以前
                                //    「ルール」「ルールブック」が並んで出ていた）。
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    RulebookButton(focus: RuleTopic.nameCall),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                // 並び順は「よく押されるもの順」。
                                // ⚠️ ホームが縦に長くてスクロールしないと
                                //    下のボタンに気づけなかったので、
                                //    説明文を削り、オンライン2種は横並びにして
                                //    1画面に収まる高さにしている。
                                //    ここにボタンを足すときは高さの合計に注意。
                                _gradientButton(
                                  label: m.nameCallLocalButton,
                                  colors: const [
                                    Color(0xFFF08A5D),
                                    Color(0xFFE8663C)
                                  ],
                                  height: 52,
                                  fontSize: 17,
                                  onTap: () => _pickLocalPlayers(context),
                                ),
                                const SizedBox(height: 8),
                                // 🤖 ひとりでも勝ち負けのある遊びができるように。
                                //    相手を呼べないときの受け皿で、実際に
                                //    いちばん遊ばれるので2番目に置く。
                                _gradientButton(
                                  label: m.nameCallCpuButton,
                                  colors: const [
                                    Color(0xFF8A5AC2),
                                    Color(0xFF6E44A8)
                                  ],
                                  height: 50,
                                  fontSize: 16,
                                  onTap: () => _pickCpuLevel(context),
                                ),
                                const SizedBox(height: 8),
                                // 🌐 オンラインは2種類を横並びに。
                                //    フレンド＝知り合いと、ランク＝知らない人と。
                                Row(
                                  children: [
                                    Expanded(
                                      child: _gradientButton(
                                        label: m.nameCallOnlineButton,
                                        colors: const [
                                          Color(0xFFFFB65C),
                                          Color(0xFFFF9F45)
                                        ],
                                        height: 46,
                                        fontSize: 13,
                                        onTap: () {
                                          Sfx.instance.fanfare();
                                          AppAnalytics.modePick(
                                              'online_friend');
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              // 👥 1台で遊ぶときの人数設定を
                                              //    そのままオンラインへ持っていく
                                              builder: (_) => OnlineLobbyScreen(
                                                game: 'namecall',
                                                initialPeople: _peopleCount,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _gradientButton(
                                        label: m.rankMatchTitle,
                                        colors: const [
                                          Color(0xFFFFD46B),
                                          Color(0xFFE8A400)
                                        ],
                                        height: 46,
                                        fontSize: 13,
                                        onTap: () {
                                          Sfx.instance.fanfare();
                                          AppAnalytics.modePick('rank');
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const OnlineLobbyScreen(
                                                      game: 'rank'),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                // 📸 顔メモ（自分の写真・アバター）は
                                //    下の「まとめ導線」へ移した。
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
                  // 🧭 まとめ導線。
                  //
                  // 以前はここから下に、マイページの大きなボタン・読み物・
                  // チュートリアル・支援ボタンが縦にずらっと並んでいて、
                  // 遊ぶボタンがスクロールの下に隠れていた。
                  // 2列のタイルにして、1画面に収まる高さにしている。
                  //
                  // ※読み物は下タブ（📚よみもの）から開けるので、ここには置かない。
                  AnimatedBuilder(
                    animation: PlayerProfile.instance,
                    builder: (context, _) {
                      final canClaim = PlayerProfile.instance.canClaimDaily;
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _shortcutTile(
                                  emoji: '🧑‍🎨',
                                  label: '顔メモ',
                                  analyticsId: 'face_memo',
                                  color: const Color(0xFF1E8A82),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CustomRosterScreen()),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _shortcutTile(
                                  emoji: canClaim ? '🎁' : '🏆',
                                  analyticsId: 'profile',
                                  label: canClaim
                                      ? MetaStrings.of(context).dailyBonus
                                      : MetaStrings.of(context).profileTitle,
                                  color: const Color(0xFFB8860B),
                                  highlight: canClaim,
                                  onTap: _openProfile,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _shortcutTile(
                                  emoji: '👧👦',
                                  analyticsId: 'tutorial',
                                  // 「あそびかた」から改称。
                                  // チュートリアルという言葉のほうが、
                                  // 何が始まるのか想像しやすい。
                                  label: 'チュートリアル',
                                  color: const Color(0xFF1E7BA6),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const TutorialScreen()),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _shortcutTile(
                                  // ⭐ 自分から書きに行ける場所。
                                  //    自動のレビュー依頼は Google の割り当てで
                                  //    出ないことがあるので、必ず1つ置いておく。
                                  emoji: '⭐',
                                  analyticsId: 'review',
                                  label: 'レビューする',
                                  color: const Color(0xFFCE8A00),
                                  onTap: openStoreReview,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _shortcutTile(
                            emoji: '☕',
                            analyticsId: 'support',
                            label: localizations.buyMeACoffee,
                            color: const Color(0xFFBB6B2A),
                            onTap: _launchBuyMeACoffee,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
        ), // SingleChildScrollView を閉じる
            ),
          ],
        ),
        ),
      ),
    );
  }
}
