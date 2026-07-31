import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../models/character_catalog.dart';
import '../models/person.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../services/speech.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/face_view.dart';
import 'rulebook_screen.dart';
import 'training_report_screen.dart';

/// 🖇 一人特訓（線むすび）。
/// 左に顔、右に名前を並べ、指でドラッグして線でつなぐ。
/// 実生活の「顔を見て名前を引き出す」に近い形で、めくる運の要素がない。
///
/// フロー: ①おぼえタイム（顔＋名前をセットで見る）→ ②線むすび → ③判定＋レポート
class LineMatchScreen extends StatefulWidget {
  final int level; // 1/2/3 = 4/6/8人
  const LineMatchScreen({super.key, this.level = 1});

  @override
  State<LineMatchScreen> createState() => _LineMatchScreenState();
}

enum _Phase { memorize, connect, result }

class _LineMatchScreenState extends State<LineMatchScreen> {
  final Random _rng = Random();
  final Stopwatch _clock = Stopwatch();

  late List<Person> _people; // 顔の並び（左列）
  late List<Person> _nameOrder; // 名前の並び（右列・シャッフル済み）
  _Phase _phase = _Phase.memorize;

  /// 顔index → 名前index の対応づけ（ユーザーが引いた線）
  final Map<int, int> _links = {};

  /// ドラッグ中の始点（顔index）と現在の指の位置
  int? _dragFrom;
  Offset? _dragPoint;

  /// 判定用に確定した「正解だったか」
  final Map<int, bool> _judged = {};

  final GlobalKey _boardKey = GlobalKey();
  final Map<int, GlobalKey> _faceKeys = {};
  final Map<int, GlobalKey> _nameKeys = {};

  int get _count => const {1: 4, 2: 6, 3: 8}[widget.level] ?? 4;

  bool _built = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_built) return;
    _built = true;
    // ロケールは context が要るのでここで解決する（initState では読めない）
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    final pool = applyDeckFilter(
      [
        ...kCharImageAssets,
        ...unlockedExtraAssets(PlayerProfile.instance.unlockedCharacters),
      ],
      PlayerProfile.instance.deckExcluded,
    );
    // ⚠️ generateImagePeople は name が空文字（なまえコールは各自が命名する
    //    仕様のため）。線むすびは名前を表示して結ぶので、名前が入る
    //    generateRecallPeople を使う。
    // デッキが少ないときは出演人数をデッキに合わせる（基本12人への
    // フォールバックでOFFにしたキャラが復活するのを防ぐ）
    final n = min(_count, pool.length);
    _people =
        generateRecallPeople(n, ja: ja, random: _rng, charAssets: pool);
    // 名前が空だと「線でむすぶ相手」が見えなくなる。生成器を取り違えたら
    // その場で気づけるように、デバッグ時は必ず落とす。
    assert(_people.every((p) => p.name.trim().isNotEmpty),
        '線むすびには名前が必要（generateImagePeople は name が空）');
    _nameOrder = [..._people]..shuffle(_rng);
    for (var i = 0; i < _count; i++) {
      _faceKeys[i] = GlobalKey();
      _nameKeys[i] = GlobalKey();
    }
  }

  @override
  void dispose() {
    Speech.instance.stop();
    super.dispose();
  }

  void _startConnecting() {
    Sfx.instance.pop();
    _clock.start();
    setState(() => _phase = _Phase.connect);
  }

  /// 顔の中心座標（ボード座標系）。線を描くのに使う。
  Offset? _centerOf(GlobalKey key) {
    final board = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (board == null || box == null) return null;
    final global = box.localToGlobal(box.size.center(Offset.zero));
    return board.globalToLocal(global);
  }

  /// 指の位置に最も近い名前カードのindexを返す（一定距離内のみ）。
  int? _nameHitTest(Offset point) {
    for (var i = 0; i < _count; i++) {
      final box =
          _nameKeys[i]!.currentContext?.findRenderObject() as RenderBox?;
      final board =
          _boardKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || board == null) continue;
      final topLeft = board.globalToLocal(box.localToGlobal(Offset.zero));
      final rect = topLeft & box.size;
      if (rect.inflate(8).contains(point)) return i;
    }
    return null;
  }

  void _finish() {
    _clock.stop();
    Sfx.instance.pop();
    var correct = 0;
    for (var i = 0; i < _count; i++) {
      final linked = _links[i];
      final ok = linked != null && _nameOrder[linked].name == _people[i].name;
      _judged[i] = ok;
      if (ok) correct++;
    }
    setState(() => _phase = _Phase.result);

    final avgMs = _count > 0 ? _clock.elapsedMilliseconds ~/ _count : 0;
    // 線むすびはめくり手数の概念がないので、正解数をそのまま成績として渡す
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TrainingReportScreen(
          cardsNamed: correct,
          correctQuizzes: correct,
          totalQuizzes: _count,
          avgReactionMs: avgMs,
          bestStreak: correct,
          level: widget.level,
          score: correct * 100,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(m.lineMatchTitle),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(
                child: RulebookButton(
                    focus: RuleTopic.lineMatch, onDark: true)),
          ),
        ],
      ),
      bottomNavigationBar: const BannerAdSlot(),
      body: SafeArea(
        child: _phase == _Phase.memorize
            ? _memorizeView(m)
            : _connectView(m),
      ),
    );
  }

  Widget _memorizeView(MetaStrings m) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(m.lineMatchMemorizeTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(m.lineMatchMemorizeDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12.5, color: Colors.black54)),
            ],
          ),
        ),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              for (final p in _people)
                Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) => FaceView(
                            person: p,
                            size: min(c.maxWidth, c.maxHeight),
                            radius: 14),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900)),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startConnecting,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900),
              ),
              child: Text(m.lineMatchStart),
            ),
          ),
        ),
      ],
    );
  }

  Widget _connectView(MetaStrings m) {
    final linkedCount = _links.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              Text(m.lineMatchConnectTitle,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(m.lineMatchConnectDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) {
              final board =
                  _boardKey.currentContext?.findRenderObject() as RenderBox?;
              if (board == null) return;
              final local = board.globalToLocal(d.globalPosition);
              for (var i = 0; i < _count; i++) {
                final box = _faceKeys[i]!.currentContext?.findRenderObject()
                    as RenderBox?;
                if (box == null) continue;
                final topLeft =
                    board.globalToLocal(box.localToGlobal(Offset.zero));
                if ((topLeft & box.size).inflate(8).contains(local)) {
                  Sfx.instance.pop();
                  setState(() {
                    _dragFrom = i;
                    _dragPoint = local;
                  });
                  return;
                }
              }
            },
            onPanUpdate: (d) {
              if (_dragFrom == null) return;
              final board =
                  _boardKey.currentContext?.findRenderObject() as RenderBox?;
              if (board == null) return;
              setState(() =>
                  _dragPoint = board.globalToLocal(d.globalPosition));
            },
            onPanEnd: (_) {
              final from = _dragFrom;
              final point = _dragPoint;
              setState(() {
                _dragFrom = null;
                _dragPoint = null;
              });
              if (from == null || point == null) return;
              final target = _nameHitTest(point);
              if (target == null) return;
              Sfx.instance.pop();
              setState(() {
                // 1つの名前は1人にしか結べない（すでに使われていたら奪う）
                _links.removeWhere((_, v) => v == target);
                _links[from] = target;
              });
            },
            child: Stack(
              key: _boardKey,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _LinePainter(
                      links: _links,
                      faceCenter: (i) => _centerOf(_faceKeys[i]!),
                      nameCenter: (i) => _centerOf(_nameKeys[i]!),
                      dragFrom: _dragFrom,
                      dragPoint: _dragPoint,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (var i = 0; i < _count; i++)
                              Container(
                                key: _faceKeys[i],
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _links.containsKey(i)
                                        ? const Color(0xFF00C2A8)
                                        : Colors.black12,
                                    width: 2.5,
                                  ),
                                ),
                                child: FaceView(
                                    person: _people[i], size: 58, radius: 10),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 90), // 線を引くスペース
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (var i = 0; i < _count; i++)
                              Container(
                                key: _nameKeys[i],
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  color: _links.containsValue(i)
                                      ? const Color(0xFFE6FBF7)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _links.containsValue(i)
                                        ? const Color(0xFF00C2A8)
                                        : Colors.black12,
                                    width: 2.5,
                                  ),
                                ),
                                child: Text(
                                  _nameOrder[i].name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // 全員つなぐまでは判定させない（消化不良の結果を防ぐ）
              onPressed: linkedCount == _count ? _finish : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A7BD5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900),
              ),
              child: Text(linkedCount == _count
                  ? m.lineMatchJudge
                  : m.lineMatchProgress(linkedCount, _count)),
            ),
          ),
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final Map<int, int> links;
  final Offset? Function(int) faceCenter;
  final Offset? Function(int) nameCenter;
  final int? dragFrom;
  final Offset? dragPoint;

  _LinePainter({
    required this.links,
    required this.faceCenter,
    required this.nameCenter,
    this.dragFrom,
    this.dragPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00C2A8)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    links.forEach((faceIdx, nameIdx) {
      final a = faceCenter(faceIdx);
      final b = nameCenter(nameIdx);
      if (a != null && b != null) canvas.drawLine(a, b, paint);
    });

    if (dragFrom != null && dragPoint != null) {
      final a = faceCenter(dragFrom!);
      if (a != null) {
        canvas.drawLine(
          a,
          dragPoint!,
          paint..color = const Color(0xFF3A7BD5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => true;
}
