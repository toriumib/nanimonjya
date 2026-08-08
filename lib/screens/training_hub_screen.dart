import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/meta_strings.dart';
import '../models/person.dart';
import '../services/review_queue.dart';
import '../services/sfx.dart';
import '../services/speech.dart';
import '../widgets/memory_tip_ticker.dart';
import 'custom_roster_screen.dart';
import 'package:flutter/foundation.dart';
import 'cognitive_info_screen.dart';
import 'line_match_screen.dart';
import 'match_game_screen.dart';
import 'name_battle_screen.dart';
import 'online_lobby_screen.dart';
import 'recall_training_screen.dart';
import 'rulebook_screen.dart';
import '../widgets/themed_background.dart';
import '../widgets/banner_ad_slot.dart';
import '../services/app_analytics.dart';

/// 「とっくん」タブ: 一人特訓（神経衰弱ベース）と記憶術トレーニング。
class TrainingHubScreen extends StatefulWidget {
  /// このタブが今えらばれているか。
  ///
  /// HomeShell は IndexedStack なので、**開いていないタブの initState も
  /// アプリ起動と同時に走る**。これを見ずに説明ダイアログを出すと、
  /// 初回起動時にチュートリアルの上に重なって出てしまう。
  final bool active;

  const TrainingHubScreen({super.key, this.active = true});

  @override
  State<TrainingHubScreen> createState() => _TrainingHubScreenState();
}

class _TrainingHubScreenState extends State<TrainingHubScreen> {
  int _level = 1;

  @override
  void initState() {
    super.initState();
    AppAnalytics.screen('training_hub');
    ReviewQueue.instance.load(); // 期限が来ている人がいるか読み込む
    if (widget.active) _maybeExplain();
  }

  @override
  void didUpdateWidget(TrainingHubScreen old) {
    super.didUpdateWidget(old);
    // タブが選ばれた瞬間に初めて説明を出す
    if (!old.active && widget.active) _maybeExplain();
  }

  /// 🏋️ このタブを初めて開いた人に、何をする場所なのかを1回だけ説明する。
  /// （「ビジネス特訓」という名前だけでは中身が想像できないため）
  Future<void> _maybeExplain() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(_explainedKey) ?? false) return;
    if (!mounted) return;
    final m = MetaStrings.of(context);
    await p.setBool(_explainedKey, true);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            SvgPicture.asset('assets/images/supporters/cheer_girl2.svg',
                width: 40, height: 40),
            const SizedBox(width: 8),
            Expanded(
              child: Text(m.trainingIntroTitle,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        content: Text(m.trainingIntroBody,
            style: const TextStyle(fontSize: 13.5, height: 1.6)),
        actions: [
          TextButton(
            onPressed: () {
              Speech.instance.stop();
              Navigator.pop(ctx);
            },
            child: Text(m.trainingIntroOk),
          ),
        ],
      ),
    );
    // 読み上げは小学生でも内容がつかめるように（チュートリアルと同じ方針）
    Speech.instance.speak('${m.trainingIntroTitle}。${m.trainingIntroBody}',
        ja: m.ja);
  }

  static const String _explainedKey = 'trainingHubExplained';
  // 覚える項目。会社名＋名前が基本、他はオプション。
  final Set<RecallField> _fields = {RecallField.name, RecallField.company};

  void _start({bool mnemonic = false}) {
    Sfx.instance.pop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchGameScreen(
          level: _level,
          mnemonicGuide: mnemonic,
        ),
      ),
    );
  }

  /// 🃏 1台で2人で遊ぶとき、カードの作りをえらんでから始める。
  ///
  /// 「顔札×名札」は顔と名前を結びつけていないと取れず、練習として効くが
  /// 難しい。「トランプ式」は同じ札を2枚そろえるだけなので、
  /// 小さい子や初めての人とでも成立する。どちらも残す。
  void _pickBattleStyle() {
    final m = MetaStrings.of(context);
    Sfx.instance.pop();
    void start(BattleCardStyle style) {
      Navigator.pop(context);
      Sfx.instance.fanfare();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NameBattleScreen(humanPlayers: 2, cardStyle: style),
        ),
      );
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(m.battleStylePickTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              _styleTile(
                label: m.battleStyleSplit,
                desc: m.battleStyleSplitDesc,
                color: const Color(0xFF3A7BD5),
                onTap: () => start(BattleCardStyle.faceAndName),
              ),
              const SizedBox(height: 10),
              _styleTile(
                label: m.battleStyleCombined,
                desc: m.battleStyleCombinedDesc,
                color: const Color(0xFFE8663C),
                onTap: () => start(BattleCardStyle.combined),
              ),
              const SizedBox(height: 10),
              _styleTile(
                label: m.battleStyleFaceOnly,
                desc: m.battleStyleFaceOnlyDesc,
                color: const Color(0xFF2E9E5B),
                onTap: () => start(BattleCardStyle.faceOnly),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _styleTile({
    required String label,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: color)),
            const SizedBox(height: 4),
            Text(desc,
                style: const TextStyle(fontSize: 12, height: 1.5)),
          ],
        ),
      ),
    );
  }

  /// 🖇 線むすび特訓。めくる運に左右されず、顔から名前を引き出す形で判定する。
  void _startLineMatch() {
    Sfx.instance.pop();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LineMatchScreen(level: _level)),
    );
  }

  /// 🔁 期限が来ている人だけで思い出しトレーニングを始める。
  /// 顔と名前だけを問うので、出題項目は name に絞る。
  void _startSpacedReview() {
    final people = ReviewQueue.instance.duePeople();
    if (people.isEmpty) return;
    Sfx.instance.fanfare();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecallTrainingScreen(
          people: people,
          fields: const {RecallField.name},
        ),
      ),
    );
  }

  void _startRecall() {
    Sfx.instance.fanfare();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecallTrainingScreen(level: _level, fields: {..._fields}),
      ),
    );
  }

  // 覚える項目トグル（名前は必須、会社はデフォルトON、他はオプション）
  Widget _fieldChip(RecallField f, String label, {bool fixed = false}) {
    final on = _fields.contains(f);
    // 🏷️ 名前は「覚える項目」の主役なので、他の項目より一段目立たせる
    // （会社名・肩書などのビジネス項目と横並びだと埋もれてトーンダウンして見えるため）
    if (fixed) {
      return Chip(
        label: Text(label,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2B5CA5))),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      );
    }
    return FilterChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: on ? const Color(0xFF2B5CA5) : Colors.white)),
      selected: on,
      showCheckmark: false,
      backgroundColor: Colors.white.withValues(alpha: 0.18),
      selectedColor: Colors.white,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
      onSelected: (v) {
        Sfx.instance.pop();
        setState(() {
          if (v) {
            _fields.add(f);
          } else {
            _fields.remove(f);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Scaffold(
      bottomNavigationBar: const BannerAdSlot(),
      appBar: AppBar(
        title: Text(m.tabTraining),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(
                child: RulebookButton(
                    focus: RuleTopic.cardMemory, onDark: true)),
          ),
        ],
      ),
      // 買った着せ替えテーマをこの画面にも反映する
      body: ThemedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MemoryTipTicker(),
                const SizedBox(height: 16),
                // 🔁 日をまたいだ復習（期限が来ている人がいるときだけ出す）
                AnimatedBuilder(
                  animation: ReviewQueue.instance,
                  builder: (context, _) {
                    final due = ReviewQueue.instance.dueCount();
                    if (due == 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE8A400), Color(0xFFE8663C)],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.spacedReviewTitle(due),
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(m.spacedReviewDesc,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.4,
                                    color: Colors.white)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _startSpacedReview,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFB35A00),
                                minimumSize: const Size.fromHeight(48),
                              ),
                              child: Text(m.spacedReviewStart,
                                  style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🎚️ ${m.levelLabel}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(m.levelHint,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 10),
                      Row(children: [
                        _levelChip(1, 4),
                        _levelChip(2, 6),
                        _levelChip(3, 8),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 🧠 実写で「この人だれだっけ？」を思い出す特訓（とっくんの主役）
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3A7BD5), Color(0xFF00C2A8)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3A7BD5).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.recallTitle,
                          style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      const SizedBox(height: 6),
                      Text(m.recallHubDesc,
                          style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: Colors.white)),
                      const SizedBox(height: 12),
                      Text(m.recallFieldsTitle,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _fieldChip(RecallField.name, m.nameFieldChipLabel,
                              fixed: true),
                          _fieldChip(
                              RecallField.company, m.fieldLabel(RecallField.company)),
                          _fieldChip(
                              RecallField.title, m.fieldLabel(RecallField.title)),
                          _fieldChip(
                              RecallField.phone, m.fieldLabel(RecallField.phone)),
                          _fieldChip(
                              RecallField.email, m.fieldLabel(RecallField.email)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: _startRecall,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2B5CA5),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: Text(m.recallStart,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.soloTrainingTitle,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(m.soloTrainingDesc,
                          style: const TextStyle(
                              fontSize: 12.5, color: Colors.black54)),
                      const SizedBox(height: 12),
                      // 🖇 線むすびを一人特訓の主役に（顔→名前を自力で引き出す形）
                      ElevatedButton(
                        onPressed: _startLineMatch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4ECDC4),
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: Text(m.lineMatchButton),
                      ),
                      // 🗑「特訓スタート！」は撤去。同じカードに似たボタンが
                      //    3つ並んでいて、何が違うのか分からない状態だった。
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _start(mnemonic: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8A400),
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: Text(m.mnemonicTrainingButton),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m.mnemonicTrainingDesc,
                        style: const TextStyle(
                            fontSize: 11.5, color: Colors.black45),
                        textAlign: TextAlign.center,
                      ),
                      // 🔁 同じ盤面をオンラインの相手と交互にめくる。
                      //    同時レースだと急かされて記憶術を試す間がないので、
                      //    記憶術トレーニングにはターン制のほうを用意する。
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Sfx.instance.fanfare();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OnlineLobbyScreen(
                                  game: 'turnpairs'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8A5AC2),
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: Text(m.turnPairsButton),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m.turnPairsDesc,
                        style: const TextStyle(
                            fontSize: 11.5, color: Colors.black45),
                        textAlign: TextAlign.center,
                      ),
                      // ⚔️ ベータ: 覚えたことがそのまま強さになるモード
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Sfx.instance.fanfare();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NameBattleScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8663C),
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: Text('${m.battleTitle}（${m.betaBadge}）'),
                      ),
                      const SizedBox(height: 8),
                      // 👫 1台を回して2人で。神経衰弱を交互にめくって
                      //    取り合い、そのままふたり同時にバトルする。
                      OutlinedButton(
                        onPressed: _pickBattleStyle,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE8663C),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: Text(m.battleTwoPlayerButton),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m.battleDesc,
                        style: const TextStyle(
                            fontSize: 11.5, color: Colors.black45),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 📇 実物の名刺＋顔写真で特訓する導線。
                // ホーム画面の小さなボタンからしか行けず気づかれにくかったので、
                // 名刺特訓の本拠地であるここにも置く（モバイル限定機能）。
                if (!kIsWeb)
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.realCardTrainingTitle,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(m.realCardTrainingDesc,
                            style: const TextStyle(
                                fontSize: 12.5, color: Colors.black54)),
                        const SizedBox(height: 10),
                        // 🧑‍🎨 顔メモ（アバター）。写真が撮れない相手はこちら。
                        //    Web でも使えるので kIsWeb で隠さない。
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Sfx.instance.pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const CustomRosterScreen(startAvatar: true)),
                              );
                            },
                            icon: const Icon(Icons.face_retouching_natural),
                            label: const Text('🧑‍🎨 顔メモをつくる'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8A5AC2),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              textStyle: const TextStyle(
                                  fontSize: 14.5, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Sfx.instance.pop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CustomRosterScreen()),
                            );
                          },
                          icon: const Text('📇',
                              style: TextStyle(fontSize: 16)),
                          label: Text(m.realCardTrainingButton),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2B5CA5),
                            minimumSize: const Size.fromHeight(46),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CognitiveInfoScreen()),
                    );
                  },
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: Text(m.cognitiveInfoButton),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1E7BA6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _levelChip(int level, int pairs) {
    final m = MetaStrings.of(context);
    final selected = _level == level;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _level = level),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3A7BD5) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF3A7BD5), width: 2),
          ),
          child: Column(
            children: [
              Text('Lv.$level',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color:
                          selected ? Colors.white : const Color(0xFF3A7BD5))),
              Text(m.levelDesc(pairs),
                  style: TextStyle(
                      fontSize: 10.5,
                      color:
                          selected ? Colors.white : const Color(0xFF3A7BD5))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E4F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
