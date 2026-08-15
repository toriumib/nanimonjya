import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/meta_strings.dart';
import '../models/historical_figures.dart';
import '../models/person.dart';
import '../services/review_queue.dart';
import '../services/sfx.dart';
import '../services/speech.dart';
import '../widgets/memory_tip_ticker.dart';
import 'custom_roster_screen.dart';
import 'ai_clone_screen.dart';
import '../services/custom_roster_service.dart';
import 'package:flutter/foundation.dart';
import 'cognitive_info_screen.dart';
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
      bottomNavigationBar: const BannerAdSlot(placement: 'training_hub'),
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
                // 💼 WhoWas — ビジネスパーソン向け顔記憶。名刺→想起。
                _whoWasCard(m),
                const SizedBox(height: 16),
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
                            label: Text(MetaStrings.of(context).ja
                                ? '🧑‍🎨 顔メモをつくる（会社・学校の人）'
                                : '🧑‍🎨 Create Face Note (Work/School)'),
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
                        // 📚 歴史上の人物
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Sfx.instance.pop();
                              final people = generateHistoricalPeople(
                                  ja: MetaStrings.of(context).ja);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => RecallTrainingScreen(
                                        level: 1,
                                        fields: {
                                          RecallField.name,
                                          RecallField.company,
                                        },
                                        people: people)),
                              );
                            },
                            icon: const Icon(Icons.school_rounded),
                            label: Text(MetaStrings.of(context).ja
                                ? '📚 歴史上の人物をおぼえる'
                                : '📚 Learn Historical Figures'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B4513),
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

  /// 💼 WhoWas — ビジネス向け: 名刺を撮って顔と名前を覚える。
  /// 「会議前に5分でおさらい」を目指す導線。
  Widget _whoWasCard(MetaStrings m) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💼',
                  style: TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.ja ? 'WhoWas — 名刺を覚える' : 'WhoWas — Remember faces',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    Text(m.ja
                        ? '「この人だれだっけ？」にもう言わせない'
                        : 'Never say "who was that?" again',
                        style: const TextStyle(
                            fontSize: 11.5,
                            height: 1.3,
                            color: Color(0xFFA0B4D0))),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC02E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(m.ja ? 'NEW' : 'NEW',
                    style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A2E))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 3ステップの説明
          Row(
            children: [
              _stepBadge('1', const Color(0xFF5AD1FF)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    m.ja ? '写真を撮るか名刺を読み取る' : 'Scan a card or take a photo',
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFFD0D8E8))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _stepBadge('2', const Color(0xFF5AD1FF)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    m.ja ? '5分のクイズで顔と名前を覚える' : '5-min quiz to lock in the face & name',
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFFD0D8E8))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _stepBadge('3', const Color(0xFF5AD1FF)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    m.ja ? '会議の前におさらい通知が届く' : 'Get a refresher before your meeting',
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFFD0D8E8))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 🤖 AIクローン
          OutlinedButton.icon(
            onPressed: () {
              Sfx.instance.fanfare();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiCloneScreen()),
              );
            },
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: Text(m.ja ? '🤖 AIの自分を作る（新機能）' : '🤖 Create your AI clone (NEW)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5AD1FF),
              side: const BorderSide(color: Color(0xFF5AD1FF)),
              minimumSize: const Size.fromHeight(40),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Sfx.instance.fanfare();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const CustomRosterScreen(startAvatar: true)),
                    );
                  },
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: Text(m.ja ? '📸 名刺・顔を登録' : '📸 Register card & face',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5AD1FF),
                    foregroundColor: const Color(0xFF1A1A2E),
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Sfx.instance.fanfare();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => RecallTrainingScreen(
                              level: 1,
                              fields: const {RecallField.name, RecallField.company},
                              people: CustomRosterService.instance.toPeople())),
                    );
                  },
                  icon: const Icon(Icons.quiz, size: 18),
                  label: Text(m.ja ? '🧠 いますぐおさらい' : '🧠 Quick review now',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A1A2E),
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 📅 カレンダー連携ティーザー
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B33),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A3A5A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: Color(0xFF5AD1FF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      m.ja
                          ? '📅 近日: カレンダー連携で会議前に自動おさらい'
                          : '📅 Coming soon: auto-refresher before meetings',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF8899BB))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBadge(String text, Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(text,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color)),
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
