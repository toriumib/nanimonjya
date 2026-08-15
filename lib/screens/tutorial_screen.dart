import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cpu_difficulty.dart';
import '../services/player_profile.dart';
import '../services/speech.dart';
import '../widgets/banner_ad_slot.dart';
import '../services/app_analytics.dart';

/// チュートリアルを見終えたかどうかの保存キー。
/// 初回起動時だけ自動で開き、一度終えたら二度と出さない。
const String kTutorialDoneKey = 'tutorialDone';

/// どのページまで見たか。次に開いたとき続きから読めるようにする。
/// 途中でアプリを閉じた人に、最初からやり直させないための保険。
const String kTutorialPageKey = 'tutorialPage';

Future<int> savedTutorialPage() async {
  final p = await SharedPreferences.getInstance();
  return p.getInt(kTutorialPageKey) ?? 0;
}

Future<void> saveTutorialPage(int page) async {
  final p = await SharedPreferences.getInstance();
  await p.setInt(kTutorialPageKey, page);
}

/// 初回起動かどうか（= まだチュートリアルを見ていないか）。
Future<bool> shouldShowTutorial() async {
  final p = await SharedPreferences.getInstance();
  return !(p.getBool(kTutorialDoneKey) ?? false);
}

Future<void> markTutorialDone() async {
  final p = await SharedPreferences.getInstance();
  await p.setBool(kTutorialDoneKey, true);
}

/// 途中で閉じた回数。
///
/// 最後まで読まずに閉じた人には、次の起動で「続きから」もう一度出す。
/// ただし何度も出すと、それ自体が嫌われて離脱の原因になるので、
/// [kMaxTutorialRetries] 回であきらめて二度と出さない。
const String kTutorialSkipsKey = 'tutorialSkips';
const int kMaxTutorialRetries = 2;

/// 🎁 読み切ったごほうびを受け取り済みか。二重取りを止めるための鍵。
const String kTutorialRewardKey = 'tutorialRewardGiven';
const int kTutorialRewardCoins = 60;

Future<void> markTutorialSkipped() async {
  final p = await SharedPreferences.getInstance();
  final n = (p.getInt(kTutorialSkipsKey) ?? 0) + 1;
  await p.setInt(kTutorialSkipsKey, n);
  // あきらめる回数に達したら「見終えた」ことにして、もう出さない
  if (n >= kMaxTutorialRetries) await p.setBool(kTutorialDoneKey, true);
}

/// あそびかたチュートリアル。
/// ナナちゃんとはなちゃんが交互に案内してくれる。
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialPage {
  final String guideEmoji; // 案内キャラ（SVGが無いページのフォールバック）
  /// ホームにいる応援キャラのSVG。ここを指定すると絵文字より優先される。
  final String? guideAsset;
  final String guideName;
  final String title;

  /// 本文。**1行＝1メッセージ**の箇条書きにする。
  ///
  /// 以前は改行入りの長い文章を中央そろえで出していたが、
  /// 日本語の中央そろえの多行はどこを読めばいいか分からず読み飛ばされる。
  /// 短い行を左そろえで並べたほうが、目で追える。
  final List<String> points;

  /// 補足（小さめの文字で最後に添える）。
  final String? note;

  final String illustration; // ページの大きな挿絵（絵文字）
  /// 実際のゲーム画面のスクショ。あると絵文字の代わりにこれを大きく出す。
  final String? screenshot;
  final List<Color> gradient;

  /// 表など、箇条書きでは伝わらないものを差し込む枠（難易度の説明で使う）。
  final Widget? extra;

  const _TutorialPage({
    required this.guideEmoji,
    this.guideAsset,
    required this.guideName,
    required this.title,
    required this.points,
    this.note,
    required this.illustration,
    this.screenshot,
    this.extra,
    required this.gradient,
  });

  /// 読み上げ用のテキスト。箇条書きを続けて読ませる。
  String get spoken => '$title。${points.join('。')}';
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  List<_TutorialPage> _pages(bool ja) => [
        _TutorialPage(
          guideEmoji: '👧',
          guideAsset: 'assets/images/supporters/cheer_girl.svg',
          guideName: ja ? 'ナナちゃん' : 'Nana',
          title: ja ? 'ようこそ！' : 'Welcome!',
          points: ja
              ? [
                  '顔と名前をおぼえる ゲームだよ',
                  'メインは「なまえがお」',
                  'ひとりでも、みんなでも あそべる',
                ]
              : [
                  'A face-and-name memory game',
                  'The main mode is Name Call',
                  'Play alone or with friends',
                ],
          note: ja
              ? 'やりかたを じゅんばんに せつめいするね！'
              : "Let's go through it step by step!",
          illustration: '🏷️✨',
          screenshot: 'assets/images/tutorial/hook_lab.png',
          gradient: const [Color(0xFFFFE3EE), Color(0xFFFFF6D8)],
        ),
        _TutorialPage(
          guideEmoji: '👧',
          guideAsset: 'assets/images/supporters/cheer_girl2.svg',
          guideName: ja ? 'はなちゃん' : 'Hana',
          title: ja ? '① あそびかたを えらぶ' : '1. Choose how to play',
          points: ja
              ? [
                  '🤖CPUとたいせん … ひとりであそぶ',
                  '🎉みんなで（1台） … 2〜4人であそぶ',
                  '👥スライダーで 出てくる人数を きめる',
                ]
              : [
                  '🤖 vs CPU — play alone',
                  '🎉 Party (1 phone) — 2-4 players',
                  '👥 Use the slider to set how many faces',
                ],
          note: ja
              ? 'はじめては 4人。なれたら 15人まで ふやせるよ。'
                  '🎴1人あたりの枚数も 2〜5枚で えらべる😊'
              : 'Start with 4 faces (up to 15), and 2-5 cards each 😊',
          illustration: '👥',
          screenshot: 'assets/images/tutorial/step_home.png',
          gradient: const [Color(0xFFD8F0FF), Color(0xFFE8FFF7)],
        ),
        _TutorialPage(
          guideEmoji: '👧',
          guideAsset: 'assets/images/supporters/cheer_girl.svg',
          guideName: ja ? 'ナナちゃん' : 'Nana',
          title: ja ? '② はじめての子に 名前をつける' : '2. Name each newcomer',
          points: ja
              ? [
                  'カードが 1まいずつ 出てくるよ',
                  'はじめて出た子には 名前がつく',
                  '口に出して「〇〇さん！」と 言うのがコツ',
                ]
              : [
                  'Cards appear one at a time',
                  'Each new face gets a name',
                  'Say it out loud — that helps',
                ],
          note: ja
              ? 'ひとり・CPU戦では アプリが名前を きめてくれる。'
              'みんなであそぶときは じぶんたちで つけよう。'
              'ここでは まだ 点は入らないよ。おぼえる じかん だからね。'
              : 'Solo and CPU games name them for you. '
                  'No points yet — this is the memorizing step.',
          illustration: '✏️',
          screenshot: 'assets/images/tutorial/step_naming.png',
          gradient: const [Color(0xFFFFF6D8), Color(0xFFD8F6F0)],
        ),
        _TutorialPage(
          guideEmoji: '👧',
          guideAsset: 'assets/images/supporters/cheer_girl2.svg',
          guideName: ja ? 'はなちゃん' : 'Hana',
          title: ja ? '③ また出てきたら 名前をこたえる' : '3. Answer when they return',
          points: ja
              ? [
                  'さっき名前がついた子が また出てくる',
                  'ひとり・CPU戦 … 4つの中から えらぶ',
                  'みんなであそぶ … いっせいに 名前をさけぶ📣',
                ]
              : [
                  'A face that was named comes back',
                  'Solo / CPU — pick from four choices',
                  'Party — everyone shouts the name 📣',
                ],
          note: ja
              ? 'せいかいすると カードがもらえる🎉 まちがえると 相手のもの。'
              'みんなであそぶときは 早く言えた人の P1・P2… を おしてね。'
              : 'Correct answers win the card 🎉 In party mode tap P1/P2… '
                  'for whoever said it first.',
          illustration: '📣',
          screenshot: 'assets/images/tutorial/step_recall.png',
          gradient: const [Color(0xFFE8E3FF), Color(0xFFFFE3F0)],
        ),
        _TutorialPage(
          guideEmoji: '👧',
          guideAsset: 'assets/images/supporters/cheer_girl.svg',
          guideName: ja ? 'ナナちゃん' : 'Nana',
          title: ja ? '④ カードを 多くあつめた人の勝ち' : '4. Most cards wins!',
          points: ja
              ? [
                  '「つける → 思い出す」を くりかえす',
                  'カードが なくなったら おしまい',
                  'たくさん あつめた人の勝ち🏆',
                ]
              : [
                  'The game ends when cards run out',
                  'Most cards collected wins 🏆',
                  'Every name is revealed at the end',
                ],
          note: ja
              ? 'さいごに みんなの名前が ぜんぶ出る。'
              '「そんな名前だったっけ！？」で もりあがるよ😆'
              : 'Every name is revealed at the end 😆',
          illustration: '🏆',
          screenshot: 'assets/images/tutorial/hook_school.png',
          gradient: const [Color(0xFFFFE3EE), Color(0xFFD8F0FF)],
        ),
        // 🤖 難易度の説明。「つよい＝相手が速いだけ」だと思われがちなので、
        //    実際は "何人まとめて覚えるか" が変わることを表で見せる。
        //    表の中身は models/cpu_difficulty.dart から作るので、
        //    数字を変えてもこのページの説明がズレない。
        _TutorialPage(
          guideEmoji: '👧',
          guideAsset: 'assets/images/supporters/cheer_girl2.svg',
          guideName: ja ? 'はなちゃん' : 'Hana',
          title: ja ? '🤖 むずかしさの しくみ' : '🤖 How difficulty works',
          points: ja
              ? [
                  'まとめて おぼえる人数が ふえる',
                  'こたえる じかんが みじかくなる',
                  'そのぶん もらえるコインが ふえる',
                ]
              : [
                  'You memorize more people at once',
                  'You get less time to answer',
                  'And you earn more coins',
                ],
          note: ja
              ? 'かんたんは「1人おぼえて すぐこたえる」。鬼は「4人おぼえてから 4人ぶんこたえる」。あいだに ほかの人が はさまるほど むずかしい。'
              : 'Easy: memorize 1, answer right away. Oni: memorize 4, then answer all 4.',
          illustration: '🤖',
          extra: _difficultyTable(ja),
          gradient: const [Color(0xFFE8F0FF), Color(0xFFFFE8E8)],
        ),
        _TutorialPage(
          guideEmoji: '👧',
          guideAsset: 'assets/images/supporters/cheer_girl.svg',
          guideName: ja ? 'ナナちゃん' : 'Nana',
          // 💼 ここだけは仕事で使う人向けなので、漢字混じりの大人の文章にする。
          //    ほかのページは子どもも一緒に遊ぶ「なまえがお」の説明なので
          //    ひらがな中心のまま。
          title: ja ? '💼 一人のときは「名刺覚え」' : '🖇 Alone? Card Memory',
          points: ja
              ? [
                  '🖇 線結び … 顔から名前へ指で線を引く',
                  '🧠 思い出し訓練 … 名刺の相手を覚えて、時間を置いて答える',
                  '📷 自分の写真と名簿を登録できる（スマートフォン版）',
                ]
              : [
                  '🖇 Line Match — connect faces to names',
                  '🧠 Recall — remember people from cards',
                  '📷 Add your own photos too',
                ],
          note: ja
              ? '📇 もらった名刺と顔写真を登録すれば、そのまま出題できます。誕生日・出身・自分との関係・自由記入メモまで残せるので名簿としても使えます（端末内にのみ保存）。📊 定着の度合いはマイページの成績レポートで確認できます。'
              : 'Check the report on My Page to see how much you retain.',
          illustration: '🖇️',
          screenshot: 'assets/images/tutorial/hook_office.png',
          gradient: const [Color(0xFFFFF6D8), Color(0xFFE8E3FF)],
        ),
        // 🧑‍🎨 顔メモ。ここがこのアプリのいちばんの機能なので、
        //    「名刺覚え」のすぐ後ろに置いて、大人向けの話から続けて見せる。
        //    ただし文章は子ども向けに書く。学校の友だちでも同じように使える。
        _TutorialPage(
          guideEmoji: '🧑‍🎨',
          guideAsset: 'assets/images/supporters/cheer_girl2.svg',
          guideName: ja ? 'はなちゃん' : 'Hana',
          title: ja ? '🧑‍🎨 顔メモ ― かおを つくって おぼえる'
              : '🧑‍🎨 Face Notes — build a face',
          points: ja
              ? [
                  '👦 おぼえたい人の かおを じぶんで つくれるよ',
                  '💇 かみがた・めがね・ほくろ を えらぶだけ',
                  '🃏 つくった人は そのまま ゲームに 出てくる',
                ]
              : [
                  '👦 Build the face of someone you want to remember',
                  '💇 Just pick hair, glasses, a mole and more',
                  '🃏 They show up in your games right away',
                ],
          note: ja
              ? '「めがねで、かみが みじかくて、せが たかい人」——'
                  'そうやって えらんでいくと、かおを よく見ることに なるよ。\n\n'
                  '💼 大人の方へ：会社の同僚・取引先・お客様の登録にも使えます。'
                  '顔写真での登録、名刺を撮っての自動読み取り（会社名・氏名）にも対応。'
                  '名前・会社・誕生日・関係など18項目を残せます。'
                  '登録した内容は端末の中だけに保存され、外部へ送信されません。'
              : 'Picking the features makes you look at the face properly.\n\n'
                  'For work: register colleagues and clients, snap a business '
                  'card to auto-fill, keep 18 fields. Stored on your device only.',
          illustration: '🧑‍🎨',
          gradient: const [Color(0xFFE8FBE8), Color(0xFFFFF6D8)],
        ),
        // 🌐 オンラインは3つあって、それぞれ「誰と」「どう進むか」が違う。
        //    どれを押せばいいのか分からないまま知らない人と当たると、
        //    途中で抜けられて相手にも迷惑がかかるので、先に区別を見せる。
        _TutorialPage(
          guideEmoji: '👧',
          guideAsset: 'assets/images/supporters/cheer_girl2.svg',
          guideName: ja ? 'はなちゃん' : 'Hana',
          title: ja ? '🌐 オンラインで あそぶ' : '🌐 Play online',
          points: ja
              ? [
                  '🤝フレンド … 合言葉で 友だちと。1台のときと 同じルール',
                  '🏆ランク … 知らない人と 早押し。通話は いらない',
                  '🔁ターン制 … 交互にめくる。急かされずに あそべる',
                ]
              : [
                  '🤝 Friend — a room code; same rules as one phone',
                  '🏆 Ranked — buzz against a stranger, no voice chat',
                  '🔁 Turn-based — take turns flipping, no rush',
                ],
          note: ja
              ? 'フレンドは 部屋をつくった人が 人数をきめて、相手にも おなじ人数が 出るよ。くわしくは 📖ルール を見てね。'
              : 'In Friend match the host picks how many faces, and the guest gets the same. See 📖 Rules for details.',
          illustration: '🌐',
          gradient: const [Color(0xFFD8F0FF), Color(0xFFFFF6D8)],
        ),
        // 📚 よみもの。ゲームだけだと「なぜ覚えられるのか」が分からないまま
        //    上手くならない。コツを読める場所があることを先に知らせる。
        _TutorialPage(
          guideEmoji: '📚',
          guideAsset: 'assets/images/supporters/cheer_girl.svg',
          guideName: ja ? 'ナナちゃん' : 'Nana',
          title: ja ? '📚 よみもの ― おぼえる コツ' : '📚 Reading — how memory works',
          points: ja
              ? [
                  '🧠 なまえを おぼえる コツが よめるよ',
                  '🔬 けんきゅうで わかった ことを やさしく かいてある',
                  '😴 「おぼえたら ねる」と いい って ホント？',
                ]
              : [
                  '🧠 Tips for remembering names',
                  '🔬 Based on published research, explained simply',
                  '😴 Is it true that sleeping helps you remember?',
                ],
          note: ja
              ? 'テスト効果、精緻化、自己関連づけ、ベイカー錯誤、睡眠と記憶の関係など。'
                  '出典は著者・発表年・掲載誌まで書いてあります。'
                  '効果には個人差があり、医療目的のものではありません。'
              : 'Testing effect, elaboration, self-reference, the Baker/baker '
                  'paradox, sleep and memory — each with its source cited. '
                  'Results vary; this is not medical advice.',
          illustration: '📚',
          gradient: const [Color(0xFFE8E3FF), Color(0xFFD8F0FF)],
        ),
        // 🚀 ものがたりモードは「覚えること」がそのまま物語を動かす。
        //    遊び方のページの最後に置いて、ひと通り分かった人に紹介する。
        _TutorialPage(
          guideEmoji: '👧',
          guideAsset: 'assets/images/supporters/cheer_girl.svg',
          guideName: ja ? 'ナナちゃん' : 'Nana',
          title: ja ? '🚀 ものがたりモード' : '🚀 Story Mode',
          points: ja
              ? [
                  '📇 出会った人から 名刺をもらって 名前と趣味を きく',
                  '🧠 また会ったとき 3つの中から えらんで 思い出す',
                  '💞 覚えているほど なかよくなって 結末が かわる',
                ]
              : [
                  '📇 Meet people and receive their cards',
                  '🧠 Recall their name and hobby from 3 choices',
                  '💞 The more you remember, the better the ending',
                ],
          note: ja
              ? '太陽がふくらんだ 遠い未来。地球をはなれる 船にのって、49光年さきの星をめざす お話です。覚えた人の数だけ、いっしょに行ける人が ふえていきます。'
              : 'A story set in the far future: board a ship bound for a star 49 light-years away. The more names you remember, the more people can come along.',
          illustration: '🚀',
          gradient: const [Color(0xFF0B1020), Color(0xFF12203C)],
        ),
      ];

  /// 難易度の比較表。値は models/cpu_difficulty.dart が一次情報。
  static Widget _difficultyTable(bool ja) {
    const order = ['easy', 'normal', 'hard', 'oni'];
    const namesJa = {
      'easy': 'かんたん',
      'normal': 'ふつう',
      'hard': 'つよい',
      'oni': '鬼',
    };
    const namesEn = {
      'easy': 'Easy',
      'normal': 'Normal',
      'hard': 'Hard',
      'oni': 'Oni',
    };
    const head = TextStyle(
        fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF2B5CA5));
    const cell = TextStyle(fontSize: 12.5);

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.5),
        1: FlexColumnWidth(1.6),
        2: FlexColumnWidth(1.0),
        3: FlexColumnWidth(1.2),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0x14000000)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Text(ja ? 'つよさ' : 'Level', style: head),
            ),
            Text(ja ? 'おぼえる' : 'Memorize', style: head),
            Text(ja ? 'じかん' : 'Time', style: head),
            Text(ja ? '勝つと' : 'Win', style: head),
          ],
        ),
        for (final k in order)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                child: Text(
                  '${kCpuDifficulties[k]!.emoji} ${ja ? namesJa[k] : namesEn[k]}',
                  style: cell,
                ),
              ),
              Text(
                ja
                    ? '${kCpuDifficulties[k]!.groupSize}人ずつ'
                    : '${kCpuDifficulties[k]!.groupSize} at once',
                style: cell,
              ),
              Text('${kCpuDifficulties[k]!.answerSeconds}${ja ? '秒' : 's'}',
                  style: cell),
              Text('🪙${kCpuDifficulties[k]!.winBonus}', style: cell),
            ],
          ),
      ],
    );
  }

  bool _voiceOn = true;
  bool _spokeFirstPage = false;

  @override
  void initState() {
    super.initState();
    AppAnalytics.screen('tutorial');
    // 途中で閉じた人を最初からやり直させない（離脱の大きな原因）
    savedTutorialPage().then((saved) {
      if (!mounted || saved <= 0) return;
      setState(() => _page = saved);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) _pageController.jumpToPage(saved);
      });
    });
  }

  @override
  void dispose() {
    Speech.instance.stop();
    _pageController.dispose();
    super.dispose();
  }

  /// 案内キャラのセリフを読み上げる。小学生でも読み飛ばさずに済むよう、
  /// タイトルと本文をそのまま声にする。
  Future<void> _speak(_TutorialPage page, bool ja) async {
    if (!_voiceOn) return;
    await Speech.instance.stop();
    await Speech.instance.speak(page.spoken, ja: ja);
  }

  /// スキップは1タップで消さず、いつでも読み直せることを伝えてから閉じる。
  /// 「読まずに閉じた＝ルールが分からないまま遊ぶ」を減らすための一拍。
  Future<void> _confirmSkip() async {
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    await Speech.instance.stop();
    if (!mounted) return;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ja ? 'あそびかたを とじる？' : 'Close the guide?'),
        content: Text(ja
            ? 'とちゅうまで 読んだところは おぼえてあるよ。\n'
                'あとで 📖ルール から いつでも 読めます。'
            : 'Your place is saved. You can read it any time from the 📖 Rulebook.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ja ? 'つづける' : 'Keep reading'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ja ? 'とじる' : 'Close'),
          ),
        ],
      ),
    );
    if (leave == true) await _finish(skipped: true);
  }

  Future<void> _finish({bool skipped = false}) async {
    await Speech.instance.stop();
    if (skipped) {
      // 途中で閉じた → 次の起動で続きから出す（上限あり）
      await markTutorialSkipped();
    } else {
      await markTutorialDone();
      await saveTutorialPage(0); // 読み切ったので進捗は畳む
      await _grantReward();
    }
    if (mounted) Navigator.pop(context);
  }

  /// 🎁 最後まで読んだ人へのごほうび。
  ///
  /// 説明を読むのは、それ自体は楽しくない。読み切った瞬間に何も起きないと
  /// 「読んで損した」で終わるので、その場でコインを渡して次の行動につなげる。
  ///
  /// ⚠️ 一度きり。`kTutorialRewardKey` で二重取りを止める。
  ///    ここを外すと、チュートリアルを開き直すだけでコインが無限に増える。
  Future<void> _grantReward() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(kTutorialRewardKey) ?? false) return;
    await p.setBool(kTutorialRewardKey, true);
    await PlayerProfile.instance.grantBonusCoins(kTutorialRewardCoins);
    if (!mounted) return;

    final ja = Localizations.localeOf(context).languageCode == 'ja';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E6),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 10),
            Text(
              ja ? 'ぜんぶ よめたね！' : 'You read it all!',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFB4326E)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE9A8),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '🪙 +$kTutorialRewardCoins',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8A6100)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              ja
                  ? 'コインは 🛍ショップで あたらしい なかまと こうかんできるよ'
                  : 'Spend coins in the shop to unlock new characters',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ja ? 'やった！' : 'Nice!',
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    final pages = _pages(ja);
    final isLast = _page == pages.length - 1;

    // 最初のページだけは自動で話しかける（以降はページ送りのたびに話す）
    if (!_spokeFirstPage) {
      _spokeFirstPage = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _speak(pages[0], ja));
    }

    // ⚠️ Androidの戻るボタンで抜けられると markTutorialDone() を通らず、
    //    「見終えた」記録が残らないまま毎回起動のたびに出続けてしまう。
    //    戻るで閉じるときも必ず記録してから閉じる。
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmSkip();
      },
      child: _buildScaffold(ja, pages, isLast),
    );
  }

  Widget _buildScaffold(
      bool ja, List<_TutorialPage> pages, bool isLast) {
    return Scaffold(
      bottomNavigationBar: const BannerAdSlot(placement: 'tutorial'),
      appBar: AppBar(
        title: Text(ja ? 'あそびかた' : 'How to Play'),
        automaticallyImplyLeading: false,
        actions: [
          // 🔊 声のON/OFF（うるさいときや電車の中で切れるように）
          IconButton(
            tooltip: ja ? 'こえ' : 'Voice',
            icon: Icon(_voiceOn ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() => _voiceOn = !_voiceOn);
              if (_voiceOn) {
                _speak(pages[_page], ja);
              } else {
                Speech.instance.stop();
              }
            },
          ),
          TextButton(
            onPressed: _confirmSkip,
            // AppBarの地色がピンクなので、既定色のままだとピンク文字になって
            // 事実上見えなかった。白で固定する。
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text(ja ? 'スキップ ▶' : 'Skip ▶',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 15)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: (i) {
                setState(() => _page = i);
                saveTutorialPage(i); // 途中で閉じても続きから読める
                _speak(pages[i], ja);
              },
              itemBuilder: (context, i) => _buildPage(pages[i]),
            ),
          ),
          // ページインジケータ＋次へボタン
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                // ⭐ 進みぐあいを星で見せる。
                //    以前は小さな点だったが、点が増えても「進んでいる」
                //    感じがせず、最後まで読む人が少なかった。
                //    読んだページが星で埋まっていくほうが、次を押したくなる。
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(pages.length, (i) {
                    final done = i <= _page;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: TweenAnimationBuilder<double>(
                        // key を進捗で変えて、埋まった瞬間だけ跳ねさせる
                        key: ValueKey('star$i$done'),
                        tween: Tween(begin: done ? 0.4 : 1.0, end: 1.0),
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.elasticOut,
                        builder: (_, v, child) =>
                            Transform.scale(scale: v, child: child),
                        child: Icon(
                          done ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: i == _page ? 26 : 20,
                          color: done
                              ? const Color(0xFFFFC02E)
                              : Colors.grey.shade300,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Text(
                  isLast
                      ? (ja ? 'ぜんぶ よんだ！🎉' : 'All done! 🎉')
                      : (ja
                          ? 'あと ${pages.length - 1 - _page} ページ！'
                          : '${pages.length - 1 - _page} to go!'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB4326E),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isLast) {
                        _finish();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    child: Text(
                      isLast
                          ? (ja ? 'あそびにいく！🎮' : "Let's play! 🎮")
                          : (ja ? 'つぎへ →' : 'Next →'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_TutorialPage p) {
    // ⚠️ 以前は Column + Expanded で組んでいたため、
    //    文字を大きくしている端末や画面の低い端末で本文がはみ出し、
    //    肝心の説明が読めないことがあった。全体をスクロールできるようにする。
    return LayoutBuilder(
      builder: (context, box) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: p.gradient,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 実際のゲーム画面があれば、絵文字よりそちらを大きく見せる。
              // 「どのボタンを押すのか」は文章より画面のほうが早く伝わる。
              if (p.screenshot != null)
                ConstrainedBox(
                  // 画面の4割までに抑える。挿絵が主役になって
                  // 説明が画面の外へ押し出されるのを防ぐ。
                  constraints: BoxConstraints(maxHeight: box.maxHeight * 0.4),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 8,
                            offset: Offset(0, 3)),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(p.screenshot!, fit: BoxFit.contain),
                  ),
                )
              else ...[
                Text(p.illustration, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 14),
              ],
              // 案内キャラの吹き出しカード
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (p.guideAsset != null)
                          SvgPicture.asset(p.guideAsset!, width: 40, height: 40)
                        else
                          Text(p.guideEmoji,
                              style: const TextStyle(fontSize: 30)),
                        const SizedBox(width: 8),
                        Text(
                          p.guideName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFB4326E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // 1行＝1メッセージ。左そろえにして目で追えるようにする。
                    for (final line in p.points)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 7, right: 8),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF4FA3),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                line,
                                style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (p.extra != null) ...[
                      const SizedBox(height: 6),
                      p.extra!,
                    ],
                    if (p.note != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF6D8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          p.note!,
                          style: const TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
