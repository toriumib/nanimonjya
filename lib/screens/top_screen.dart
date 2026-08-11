
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'tutorial_play_screen.dart';
import '../services/custom_roster_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'noah_story_screen.dart'; // 🚀 SFストーリー
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
import '../widgets/game_ui.dart'; // 立体ボタン・縁取り文字・後光
import '../widgets/guide_talk.dart'; // 🗣 ナナちゃん・はなちゃんの声かけ
import '../services/app_analytics.dart';

/// 🔁 ホームに「つぎの一歩」を出し直させる合図。
///
/// ⚠️ TopScreen の initState は、初回起動のチュートリアルより**先に**走る。
///    その時点ではまだ「おためし未プレイ」なので、判定が必ず false になる。
///    チュートリアルを終えた HomeShell 側からここを叩いてもらう。
final ValueNotifier<int> kHomeNextStepTick = ValueNotifier<int>(0);

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

  /// 🧭 ホーム下部のまとめ導線1つぶん。
  ///
  /// 顔メモ・マイページ・チュートリアル・レビュー・支援を
  /// 同じ見た目の小さなタイルにして並べる。
  /// 縦長のボタンを積むより、ずっと少ない高さで収まる。
  /// 「つぎは顔メモ」を出すか。登録が1人でもあれば、もう出さない。
  bool _showNextStep = false;
  static const String _kNextStepKey = 'nextStepFaceMemoDone';

  Future<void> _refreshNextStep() async {
    if (kIsWeb) return; // 顔メモの写真登録はモバイル限定
    final p = await SharedPreferences.getInstance();
    if (p.getBool(_kNextStepKey) ?? false) return;
    // おためしを終えた人にだけ。初回起動の1画面目からは出さない。
    if (await shouldPlayTutorial()) return;
    await CustomRosterService.instance.load();
    final empty = CustomRosterService.instance.entries.isEmpty;
    if (!mounted) return;
    setState(() => _showNextStep = empty);
    if (!empty) await p.setBool(_kNextStepKey, true);
  }

  Future<void> _dismissNextStep() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNextStepKey, true);
    if (mounted) setState(() => _showNextStep = false);
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: active ? fgColor : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nextStepCard(MetaStrings m) => Container(
        margin: const EdgeInsets.fromLTRB(4, 4, 4, 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE0F7F4), Color(0xFFFFF6D8)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF1E8A82), width: 1.6),
        ),
        child: Row(
          children: [
            const Text('🧑‍🎨', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.nextStepTitle,
                      style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF12645E))),
                  const SizedBox(height: 2),
                  Text(
                    m.nextStepBody,
                    style: const TextStyle(fontSize: 12, height: 1.45),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () async {
                        AppAnalytics.modePick('face_memo_nextstep');
                        await _dismissNextStep();
                        if (!mounted) return;
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CustomRosterScreen(
                                  startAvatar: true)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E8A82),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        textStyle: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w900),
                      ),
                      child: Text(m.nextStepButton),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: m.closeLabel,
              icon: const Icon(Icons.close, size: 18, color: Colors.black38),
              onPressed: _dismissNextStep,
            ),
          ],
        ),
      );

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
      Color(0xFFFFD700),
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
                  Text(
                    m.howManyPlayers,
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
    _refreshNextStep();
    kHomeNextStepTick.addListener(_refreshNextStep);
    _giftAd.load();
    _gachaAd.load();
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
    kHomeNextStepTick.removeListener(_refreshNextStep);
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
              const Positioned.fill(child: SeasonalDecor()),
              Positioned(top: 8, right: 8, child: _topBar()),
              Positioned(top: 8, left: 8, child: _webLocaleToggle()),
              SingleChildScrollView(child: Column(
                children: [
                  const SizedBox(height: 6),
                  // タイトルロゴ＋キャッチコピー（コンパクト）
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: OutlinedText(
                      localizations.appTitle,
                      strokeWidth: 4,
                      strokeColor: Colors.white,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'MochiyPopOne',
                        fontSize: 24,
                        color: homeTheme.titleColor,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            offset: const Offset(2, 2),
                            blurRadius: 0,
                            color: homeTheme.titleShadow,
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                        duration: 400.ms,
                        curve: Curves.elasticOut,
                      ),
                  Text(
                    m.tagline,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: homeTheme.titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
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
                  // 📊 いまの実績（継続の動機づけ）
                  AnimatedBuilder(
                    animation: PlayerProfile.instance,
                    builder: (context, _) {
                      final p = PlayerProfile.instance;
                      final line = m.weeklyStatsLine(p.weeklyLearned, p.dailyStreak);
                      // 次のログインキャラまでの進捗
                      final loginCharHint = _loginCharProgress(p.dailyStreak);
                      if (line.isEmpty && loginCharHint == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
                        child: Column(
                          children: [
                            if (line.isNotEmpty)
                              Text(
                                line,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF8A6A1E),
                                ),
                              ),
                            if (loginCharHint != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                loginCharHint,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFC26A00),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  // 離脱防止ダイアログ
                  // 💡 ルールひとこと＋📖 詳細リンク
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              m.ruleSummary,
                              style: const TextStyle(fontSize: 10, height: 1.35, color: Color(0xFF555555)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            Sfx.instance.pop();
                            AppAnalytics.modePick('rulebook');
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const RulebookScreen(),
                            ));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A7BD5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              m.viewFullRules,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 🎉 みんなで対戦（ジャイアントボタン）
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: JuicyButton(
                      onTap: () => _pickLocalPlayers(context),
                      colors: const [Color(0xFFF08A5D), Color(0xFFE8663C)],
                      height: 72,
                      radius: 20,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            m.partyButtonLabel,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: [Shadow(offset: Offset(0, 1.5), color: Color(0x55000000))],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m.partyButtonHint,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 2×2 グリッド
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(child: _gradientButton(
                          label: m.cpuButtonCompact,
                          colors: const [Color(0xFF8A5AC2), Color(0xFF6E44A8)],
                          height: 48,
                          fontSize: 13,
                          onTap: () => _pickCpuLevel(context),
                        )),
                        const SizedBox(width: 6),
                        Expanded(child: _gradientButton(
                          label: m.onlineButtonCompact,
                          colors: const [Color(0xFFFFB65C), Color(0xFFFF9F45)],
                          height: 48,
                          fontSize: 13,
                          onTap: () {
                            Sfx.instance.fanfare();
                            AppAnalytics.modePick('online_friend');
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => OnlineLobbyScreen(game: 'namecall', initialPeople: _peopleCount),
                            ));
                          },
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 🌐 Web: ランク/特訓の代わりにGoogle Playバッジ
                  // 📱 それ以外: ランクマッチ＋ビジネス特訓
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: kIsWeb
                        ? _playStoreBadge()
                        : Row(
                      children: [
                        Expanded(child: _gradientButton(
                          label: m.rankButtonCompact,
                          colors: const [Color(0xFFFFD46B), Color(0xFFE8A400)],
                          height: 46,
                          fontSize: 13,
                          onTap: () {
                            Sfx.instance.fanfare();
                            AppAnalytics.modePick('rank');
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const OnlineLobbyScreen(game: 'rank'),
                            ));
                          },
                        )),
                        const SizedBox(width: 6),
                        Expanded(child: _gradientButton(
                          label: m.trainingButtonCompact,
                          colors: const [Color(0xFF4ECDC4), Color(0xFF2EAAA4)],
                          height: 46,
                          fontSize: 13,
                          onTap: () {
                            Sfx.instance.pop();
                            AppAnalytics.modePick('training_hub');
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const TrainingHubScreen(),
                            ));
                          },
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 🚀 プロジェクト・ノア（SFストーリー）
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: JuicyButton(
                      onTap: () {
                        Sfx.instance.fanfare();
                        AppAnalytics.modePick('story');
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const NoahStoryScreen()));
                      },
                      colors: const [Color(0xFF1D3A6B), Color(0xFF0F1D3D)],
                      height: 52,
                      radius: 14,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🚀', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Text(m.ja ? 'SFノベルを読む' : 'Read SF Novel',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
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
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F8F5), Color(0xFFFFF8E6)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E8A82), width: 2),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                const Text('🧑‍🎨', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m.faceMemoCardTitle,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w900,
                              color: Color(0xFF12645E))),
                      const SizedBox(height: 3),
                      Text(m.faceMemoCardBody,
                          style: const TextStyle(
                              fontSize: 11.5, height: 1.35,
                              color: Color(0xFF555555))),
                      const SizedBox(height: 3),
                      Text(m.faceMemoCardHint(count),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: Color(0xFF1E8A82)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF1E8A82)),
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
