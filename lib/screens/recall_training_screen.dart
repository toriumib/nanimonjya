import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/memory_tips.dart';
import '../l10n/meta_strings.dart';
import '../models/character_catalog.dart';
import '../models/person.dart';
import '../models/shop_items.dart';
import '../services/interstitial_ad_helper.dart';
import '../services/player_profile.dart';
import '../services/review_prompt.dart';
import '../services/review_queue.dart';
import '../services/sfx.dart';
import '../services/speech.dart';
import '../widgets/double_coins_button.dart';
import '../widgets/store_cta.dart';
import '../widgets/themed_background.dart';
import '../widgets/banner_ad_slot.dart';

/// 🧠 思い出しトレーニング
///
/// 実生活の「この人だれだっけ？」を再現する特訓。
/// 1) であう … 実写の人物（顔＋体）と名前・出会った場所を1人ずつ記銘
/// 2) 時間がたつ … 少し間をおく（すぐ答えさせない）
/// 3) 思い出す … 顔を見て名前を4択で想起。出会った場所がヒント
///
/// 顔はフリー素材の実写（char*.jpg / FaceKind.asset）を使い、体まで写して現実に近づける。
class RecallTrainingScreen extends StatefulWidget {
  final int level; // 1..3 → 人数 4/6/8（people未指定のとき）
  /// 出題する項目。デフォルトは名前＋会社。未指定時は {name, company}。
  final Set<RecallField> fields;
  /// 事前に用意した人物（カスタム名簿など）。null なら架空の実写を生成。
  final List<Person>? people;

  const RecallTrainingScreen({
    super.key,
    this.level = 1,
    this.fields = const {RecallField.name, RecallField.company},
    this.people,
  });

  @override
  State<RecallTrainingScreen> createState() => _RecallTrainingScreenState();
}

enum _Phase { meet, gap, recall, result }

/// 1問分（誰の・どの項目を当てるか）。
class _Question {
  final Person person;
  final RecallField field;
  const _Question(this.person, this.field);
}

class _RecallTrainingScreenState extends State<RecallTrainingScreen> {
  final Random _rng = Random();
  late final bool _ja =
      WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'ja';
  // 待ち時間・結果に出す研究ベースTips（出典つき）
  late final MemoryShortTip _tip =
      kNameScienceTips[_rng.nextInt(kNameScienceTips.length)];
  late List<Person> _people; // 出会った順

  // 出題項目の順序（name, company, title, phone, email の順で選択されたもの）
  late final List<RecallField> _fields = [
    for (final f in RecallField.values)
      if (widget.fields.contains(f)) f,
  ];

  _Phase _phase = _Phase.meet;
  int _meetIndex = 0;

  // 思い出すフェーズ（項目別クイズ）
  late List<_Question> _questions;
  int _qIndex = 0;
  List<String> _choices = [];
  bool _answered = false;
  String? _picked;
  int _correct = 0;
  DateTime _questionShownAt = DateTime.now();
  int _totalReactionMs = 0;
  int _coinsEarned = 0;
  bool _shieldUsed = false; // 🛡️まちがえ守りを今ゲームで使ったか

  // 🔁 弱点の即時復習: まちがえた問題を溜めて、本編のあとにもう1周する
  final List<_Question> _reviewQueue = [];
  bool _inReview = false; // 復習ラウンド中か（スコアには加算しない）
  int _reviewRecovered = 0; // 復習で思い出せた数（結果に表示）
  int _mainTotal = 0; // 本編の出題数（復習で_questionsが差し替わるため別に保持）

  /// 装備中のお守り（ゲーム開始時に固定して、途中で変わらないようにする）
  late final LuckyCharm _charm =
      luckyCharmById(PlayerProfile.instance.selectedCharm);

  int get _peopleCount {
    switch (widget.level) {
      case 3:
        return 8;
      case 2:
        return 6;
      default:
        return 4;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.people != null && widget.people!.isNotEmpty) {
      _people = [...widget.people!]..shuffle(_rng);
    } else {
      _people = generateRecallPeople(_peopleCount,
          ja: _ja, random: _rng, charAssets: _photoPool());
    }
    // 最初の人が名刺を差し出して自己紹介（音声）
    WidgetsBinding.instance.addPostFrameCallback((_) => _announceMeet());
  }

  @override
  void dispose() {
    Speech.instance.stop();
    super.dispose();
  }

  /// 出演プール = 基本12＋購入済みキャラ（キャラデッキでOFFにした人は除く）。
  List<String> _photoPool() => applyDeckFilter(
        [
          ...kCharImageAssets,
          ...unlockedExtraAssets(PlayerProfile.instance.unlockedCharacters),
        ],
        PlayerProfile.instance.deckExcluded,
      );

  /// 敬称なしの苗字（例: 佐藤さん→佐藤）。自己紹介の「私は○○と申します」用。
  String _bareName(Person p) =>
      p.name.endsWith('さん') ? p.name.substring(0, p.name.length - 2) : p.name;

  /// いま出会っている人に自己紹介を読み上げさせる（会社名＋名前＋肩書）。
  void _announceMeet() {
    if (_phase != _Phase.meet) return;
    final p = _people[_meetIndex];
    Speech.instance.introduce(_bareName(p),
        ja: _ja, company: p.company, title: p.title);
  }

  // ---- であうフェーズ ----
  void _meetNext() {
    Sfx.instance.pop();
    if (_meetIndex + 1 < _people.length) {
      setState(() => _meetIndex += 1);
      _announceMeet();
    } else {
      Speech.instance.stop();
      setState(() => _phase = _Phase.gap);
    }
  }

  // ---- 思い出すフェーズ ----
  /// 出題リストを作る。人物ごとに、選択された項目のうち値があるものを出題。
  void _buildQuestions() {
    final order = [..._people]..shuffle(_rng);
    _questions = [
      for (final p in order)
        for (final f in _fields)
          if (recallFieldValue(p, f).trim().isNotEmpty) _Question(p, f),
    ];
  }

  void _startRecall() {
    Sfx.instance.pop();
    _buildQuestions();
    // 出題できる項目が1つも無い（例: 名前しか登録されていない名簿で名前を除外した）
    // 場合に _questions[0] を触るとクラッシュするため、結果画面へ逃がす。
    if (_questions.isEmpty) {
      _finish();
      return;
    }
    _mainTotal = _questions.length;
    setState(() {
      _phase = _Phase.recall;
      _qIndex = 0;
      _prepareChoices();
    });
  }

  _Question get _q => _questions[_qIndex];
  String get _answerText => recallFieldValue(_q.person, _q.field);

  void _prepareChoices() {
    final answer = _answerText;
    final others = <String>{
      for (final p in _people)
        if (!identical(p, _q.person)) recallFieldValue(p, _q.field),
    }..removeWhere((v) => v.trim().isEmpty || v == answer);
    final pool = others.toList()..shuffle(_rng);
    // 🧭「絞りこみコンパス」のお守りを装備していると、まちがいの選択肢が1つ減る
    final wrongCount =
        _charm.effect == CharmEffect.fewerChoices ? 2 : 3;
    _choices = [answer, ...pool.take(wrongCount)]..shuffle(_rng);
    _answered = false;
    _picked = null;
    _questionShownAt = DateTime.now();
  }

  void _answer(String choice) {
    if (_answered) return;
    _totalReactionMs += DateTime.now().difference(_questionShownAt).inMilliseconds;
    var correct = choice == _answerText;
    // 🛡️「まちがえ守り」は1ゲーム1回だけ、まちがいを正解あつかいにする
    if (!correct &&
        _charm.effect == CharmEffect.oneMistakeShield &&
        !_shieldUsed) {
      _shieldUsed = true;
      correct = true;
      _shieldJustUsed = true;
    }
    if (correct) {
      // 復習ラウンドの正解はスコアに入れず、「思い出せた数」として別に数える
      if (_inReview) {
        _reviewRecovered += 1;
      } else {
        _correct += 1;
      }
      Sfx.instance.correct();
      Speech.instance.praise(ja: _ja); // 🎉 ほめボイス
      // 🔁 日をまたぐ復習: 名前を当てられたら次の間隔へ送る（卒業もここ）
      if (_q.field == RecallField.name) {
        ReviewQueue.instance.recordSuccess(_q.person);
      }
    } else {
      Sfx.instance.wrong();
      // まちがえた問題は復習キューへ（本編で外したものだけ。復習で外しても無限には続けない）
      if (!_inReview) _reviewQueue.add(_q);
      // 🔁 日をまたぐ復習にも登録して、後日もう一度出す
      if (_q.field == RecallField.name) {
        ReviewQueue.instance.recordMiss(_q.person);
      }
    }
    setState(() {
      _answered = true;
      _picked = choice;
    });
    Future.delayed(const Duration(milliseconds: 950), () {
      _shieldJustUsed = false;
      _recallNext();
    });
  }

  bool _shieldJustUsed = false; // 直前の1問がお守りで救われたか（表示用）

  Future<void> _recallNext() async {
    // 回答直後に「戻る」で離脱した場合、破棄済みStateへのsetStateになるのでガードする
    if (!mounted) return;
    if (_qIndex + 1 < _questions.length) {
      setState(() {
        _qIndex += 1;
        _prepareChoices();
      });
      return;
    }
    // 🔁 弱点の即時復習: まちがえた問題だけをもう1周する。
    // 「思い出せなかったものをもう一度思い出す」のが記憶に効くとされるため、
    // 苦手を残したまま終わらせない（復習の正解は集計に含めない＝スコアは水増ししない）。
    if (_reviewQueue.isNotEmpty && !_inReview) {
      setState(() {
        _inReview = true;
        _questions = [..._reviewQueue];
        _reviewQueue.clear();
        _qIndex = 0;
        _prepareChoices();
      });
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    // スコアは本編の出題数で数える（復習ラウンドは加点対象外）
    final total = _mainTotal > 0 ? _mainTotal : _questions.length;
    final answered = total + _reviewRecovered;
    final avgMs = answered > 0 ? _totalReactionMs ~/ answered : 0;
    // 記録＆コイン付与（正解数×8＋全問正解ボーナス）
    await PlayerProfile.instance.recordSoloTraining(
      correctQuizzes: _correct,
      totalQuizzes: total,
      avgReactionMs: avgMs,
    );
    // 復習で取り返した分も半額で報酬にする（間違いを放置せず直す行動を評価）
    final coins = _correct * 8 +
        _reviewRecovered * 4 +
        (total > 0 && _correct == total ? 20 : 0);
    if (coins > 0) await PlayerProfile.instance.grantBonusCoins(coins);
    _coinsEarned = coins;
    if (total > 0 && _correct == total) {
      Sfx.instance.victory();
      // 🎉 締めのほめボイス（勝利SEと重ならないよう少し待つ）
      Future.delayed(const Duration(milliseconds: 900),
          () => Speech.instance.praise(ja: _ja, finale: true));
      // 全問正解の好タイミングでレビュー依頼（1回きり）
      if (total >= 4) maybeAskReview(minGames: 0);
    } else if (_correct >= (total / 2).ceil()) {
      Sfx.instance.fanfare();
    } else {
      Sfx.instance.coin();
    }
    InterstitialAdHelper.instance.onGameFinished(); // 3プレイに1回、全画面広告
    if (mounted) setState(() => _phase = _Phase.result);
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Scaffold(
      bottomNavigationBar: const BannerAdSlot(),
      appBar: AppBar(title: Text(m.recallTitle)),
      // 買った着せ替えテーマをこの画面にも反映する
      body: ThemedBackground(
        child: SafeArea(
          child: switch (_phase) {
            _Phase.meet => _buildMeet(m),
            _Phase.gap => _buildGap(m),
            _Phase.recall => _buildRecall(m),
            _Phase.result => _buildResult(m),
          },
        ),
      ),
    );
  }

  // 実写の人物（顔＋体）を大きく見せるカード。頭が切れないよう上寄せでクロップ。
  // アセット画像（架空）とアップロード写真（カスタム名簿）の両方に対応。
  Widget _personPhoto(Person p, {double height = 300}) {
    Widget fallback() => Container(
          height: height,
          color: const Color(0xFFEAF3FF),
          child: const Icon(Icons.person, size: 90, color: Color(0xFF8FB4DC)),
        );
    final Widget img;
    if (p.kind == FaceKind.file && !kIsWeb) {
      img = Image.file(File(p.face),
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => fallback());
    } else if (p.kind == FaceKind.asset) {
      img = Image.asset(p.face,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => fallback());
    } else {
      img = fallback();
    }
    return ClipRRect(borderRadius: BorderRadius.circular(22), child: img);
  }

  Widget _buildMeet(MetaStrings m) {
    final p = _people[_meetIndex];
    final isLast = _meetIndex + 1 >= _people.length;
    final introText = _ja
        ? (p.company.isNotEmpty
            ? '${p.company}の${_bareName(p)}と申します。'
            : '私は${_bareName(p)}と申します。')
        : (p.company.isNotEmpty
            ? "Hello, I'm ${_bareName(p)} from ${p.company}."
            : "Hello, I'm ${_bareName(p)}.");
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_meetIndex + 1) / _people.length,
            minHeight: 6,
            backgroundColor: Colors.white,
            color: const Color(0xFF3A7BD5),
          ),
          const SizedBox(height: 6),
          Text('${m.recallMeetTitle}  ${_meetIndex + 1} / ${_people.length}',
              style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
          const SizedBox(height: 6),
          Text(m.recallMeetHint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black45)),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                key: ValueKey(_meetIndex), // 人が変わるたび登場アニメを再生
                children: [
                  _personPhoto(p, height: 230),
                  const SizedBox(height: 10),
                  // ふきだしで自己紹介（🔊で読み上げ再生）
                  _speechBubble(introText, () => _announceMeet())
                      .animate()
                      .fadeIn(duration: 260.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
                  const SizedBox(height: 14),
                  // 名刺を差し出される
                  _businessCard(p, m)
                      .animate()
                      .fadeIn(duration: 360.ms, delay: 120.ms)
                      .slideY(
                          begin: 0.5,
                          end: 0,
                          duration: 460.ms,
                          curve: Curves.easeOutBack),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _meetNext,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15)),
              child: Text(isLast ? m.recallRemembered : m.recallMeetNext,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  // 自己紹介のふきだし（上向きのしっぽ＋読み上げボタン）。
  Widget _speechBubble(String text, VoidCallback onReplay) {
    const bubbleColor = Color(0xFF2B5CA5);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: bubbleColor.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(text,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onReplay,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.volume_up_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
        // 上向きのしっぽ（相手が話している合図）
        Positioned(
          top: -6,
          left: 30,
          child: Transform.rotate(
            angle: pi / 4,
            child: Container(width: 16, height: 16, color: bubbleColor),
          ),
        ),
      ],
    );
  }

  // 差し出される名刺。少し傾けて手渡し感を出す。
  // アップロードした実物の名刺があればそれを表示、なければ項目からレイアウト。
  Widget _businessCard(Person p, MetaStrings m) {
    // 💳 購入した名刺スキンの配色を反映
    final skin = cardSkinById(PlayerProfile.instance.selectedSkin);
    return Transform.rotate(
      angle: -0.04,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(skin.bgTop), Color(skin.bgBottom)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Color(skin.accent).withValues(alpha: 0.45), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: (p.cardImage.isNotEmpty && !kIsWeb)
            ? _uploadedCard(p)
            : Padding(
                padding: const EdgeInsets.all(14),
                child: _cardFields(p, m),
              ),
      ),
    );
  }

  // アップロードした実物名刺の画像を表示。
  Widget _uploadedCard(Person p) {
    return Image.file(
      File(p.cardImage),
      width: double.infinity,
      fit: BoxFit.fitWidth,
      errorBuilder: (_, __, ___) => Padding(
        padding: const EdgeInsets.all(14),
        child: _cardFields(p, MetaStrings.of(context)),
      ),
    );
  }

  // 項目から名刺レイアウトを組む（会社名・氏名・肩書・電話・メール）。
  // 色は購入した名刺スキンに合わせる。
  Widget _cardFields(Person p, MetaStrings m) {
    final skin = cardSkinById(PlayerProfile.instance.selectedSkin);
    final accent = Color(skin.accent);
    final text = Color(skin.textColor);
    final sub = text.withValues(alpha: 0.65);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 84,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p.company.isNotEmpty)
                Text(p.company,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accent)),
              if (p.title.isNotEmpty)
                Text(p.title, style: TextStyle(fontSize: 11, color: sub)),
              const SizedBox(height: 4),
              Text(_bareName(p),
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: text)),
              const SizedBox(height: 6),
              if (p.phone.isNotEmpty)
                Text('☎ ${p.phone}',
                    style: TextStyle(fontSize: 11.5, color: sub)),
              if (p.email.isNotEmpty)
                Text('✉ ${p.email}',
                    style: TextStyle(fontSize: 11.5, color: sub)),
              if (p.where.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('📍 ${m.metAt(p.where)}',
                      style: TextStyle(
                          fontSize: 11, color: text.withValues(alpha: 0.5))),
                ),
            ],
          ),
        ),
        Text(skin.emoji, style: const TextStyle(fontSize: 28)),
      ],
    );
  }

  // 研究ベースの名前記憶Tips（出典つき）カード。とっくん中に表示。
  Widget _tipCard(MetaStrings m) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC93C), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.researchTipHeader,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF8A6A1E))),
          const SizedBox(height: 6),
          Text(_tip.text(m.ja),
              style: const TextStyle(fontSize: 13.5, height: 1.5)),
          if (_tip.source != null) ...[
            const SizedBox(height: 6),
            Text('${m.sourceLabel}: ${_tip.source}',
                style: const TextStyle(
                    fontSize: 10.5,
                    color: Colors.black45,
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildGap(MetaStrings m) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⏳', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(m.recallGapTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2B5CA5))),
          const SizedBox(height: 10),
          Text(m.recallGapSub,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 24),
          // 待っているあいだに研究ベースのコツを1つ（出典つき）
          _tipCard(m),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startRecall,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(m.recallGapButton,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecall(MetaStrings m) {
    final p = _q.person;
    final answer = _answerText;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_qIndex + 1) / _questions.length,
            minHeight: 6,
            backgroundColor: Colors.white,
            color: _inReview ? const Color(0xFFE8A400) : const Color(0xFF3A7BD5),
          ),
          const SizedBox(height: 6),
          // 🔁 復習ラウンド中はひと目で分かるようにする
          if (_inReview)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3D6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(m.reviewRoundBadge,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF9A6A00))),
            )
          else
            Text('${_qIndex + 1} / ${_questions.length}',
                style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
          const SizedBox(height: 8),
          _personPhoto(p, height: 210),
          const SizedBox(height: 8),
          Text(m.recallFieldQuestion(m.fieldLabel(_q.field)),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2B5CA5))),
          // 🍀「思い出しのお守り」を装備しているとヒントがはっきり出る
          if (p.where.isNotEmpty)
            Text('💡 ${m.hintMetAt(p.where)}',
                textAlign: TextAlign.center,
                style: _charm.effect == CharmEffect.extraHint
                    ? const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E9C8E))
                    : const TextStyle(fontSize: 12, color: Colors.black45)),
          if (_shieldJustUsed)
            Text(m.charmSaved,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2E9E52))),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final c in _choices)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _answer(c),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !_answered
                                ? Colors.white
                                : (c == answer
                                    ? const Color(0xFFDFF5E1)
                                    : (c == _picked
                                        ? const Color(0xFFFCE4E4)
                                        : Colors.white)),
                            foregroundColor: const Color(0xFF2B5CA5),
                            elevation: _answered ? 0 : 3,
                            side: const BorderSide(
                                color: Color(0xFF3A7BD5), width: 2),
                            padding:
                                const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text(c,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(MetaStrings m) {
    final total = _mainTotal > 0 ? _mainTotal : _questions.length;
    final ratio = total > 0 ? _correct / total : 0.0;
    final encourage = ratio >= 1.0
        ? m.recallEncourageHigh
        : (ratio >= 0.5 ? m.recallEncourageMid : m.recallEncourageLow);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const SizedBox(height: 4),
          Text(m.recallResultTitle,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2B5CA5))),
          const SizedBox(height: 6),
          Text(m.recallCorrectOf(_correct, total),
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w900)),
          // 🔁 復習で取り返せた数（「思い出せなかったものを思い出せた」体験を可視化）
          if (_reviewRecovered > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(m.reviewRecovered(_reviewRecovered),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF9A6A00))),
            ),
          const SizedBox(height: 6),
          Text(encourage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(m.recallReview,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _people.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = _people[i];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: _personPhoto(p, height: 64),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF2B5CA5))),
                            if (p.company.isNotEmpty)
                              Text(
                                  p.title.isNotEmpty
                                      ? '${p.company} / ${p.title}'
                                      : p.company,
                                  style: const TextStyle(
                                      fontSize: 11.5, color: Colors.black54)),
                            if (p.where.isNotEmpty)
                              Text('📍 ${m.metAt(p.where)}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.black45)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          DoubleCoinsButton(coinsEarned: _coinsEarned),
          const StoreCtaCard(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(m.recallClose,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Sfx.instance.pop();
                    setState(() {
                      if (widget.people != null && widget.people!.isNotEmpty) {
                        _people = [...widget.people!]..shuffle(_rng);
                      } else {
                        _people = generateRecallPeople(_peopleCount,
                            ja: _ja, random: _rng, charAssets: _photoPool());
                      }
                      _phase = _Phase.meet;
                      _meetIndex = 0;
                      _qIndex = 0;
                      _correct = 0;
                      _totalReactionMs = 0;
                      _coinsEarned = 0;
                      _shieldUsed = false; // お守りの回数も再挑戦でリセット
                    });
                    _announceMeet();
                  },
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(m.recallAgain,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
