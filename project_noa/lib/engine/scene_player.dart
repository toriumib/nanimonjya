/// シーンを1行ずつ進める本体。
///
/// **画面（Widget）を持たない**。ここを純粋なロジックにしておくと、
/// タップ送り・オート・スキップ・セーブ復帰のような
/// 「間違えるとユーザーには理由が分からない」部分をテストで固定できる。
library;

import 'dart:math';

import '../models/noah_field.dart';
import '../models/save_data.dart';
import '../models/scene_script.dart';
import '../systems/memory_store.dart';

/// いま画面が何を待っているか。
enum PlayerMode {
  /// 文字を送っている途中（タップで全文表示）。
  typing,

  /// 全文が出て、次の入力待ち。
  waiting,

  /// 選択肢を出している。
  choice,

  /// 3択の記憶テスト中。
  memtest,

  /// 名前入力中。
  nameInput,

  /// このシーンの最後まで来た。
  sceneEnd,
}

/// バックログ1行。
///
/// ⚠️ [text] には**正典（本来の文）をそのまま**入れる。
///    汚染（4.5）は描画のときだけ被せる。ここを書き換えてしまうと、
///    セーブ・ロードのたびに文章が壊れて元に戻せなくなる。
class BacklogEntry {
  final String speaker;
  final String text;
  const BacklogEntry({required this.speaker, required this.text});
}

/// シーン進行の状態。
class ScenePlayer {
  final NoahCast cast;
  final MemoryStore memory;
  final Random _rng;

  Scene _scene;
  int _index = -1;

  PlayerMode _mode = PlayerMode.waiting;
  String _speaker = '';
  String _text = '';

  LineChoice? _choice;
  MemQuestion? _question;
  LineNameInput? _nameInput;

  final List<BacklogEntry> _backlog = [];
  final Set<String> _flags = {};
  final Map<String, int> _affection = {};

  int _cycle = 0;
  int _aging = 0;

  /// 背景と曲。UI はこれを見て描き替える。
  String _bg = '';
  int _bgAge = 0;
  String _bgm = '';

  /// 直近の演出・効果音。UI が拾ったら消す。
  String? pendingFx;
  String? pendingSe;

  ScenePlayer({
    required Scene scene,
    required this.cast,
    MemoryStore? memory,
    Random? random,
  })  : _scene = scene,
        memory = memory ?? MemoryStore(),
        _rng = random ?? Random() {
    _bg = scene.bg;
    _bgAge = scene.bgAge;
    _bgm = scene.bgm;
  }

  // ── いまの状態 ──
  Scene get scene => _scene;
  int get index => _index;
  PlayerMode get mode => _mode;
  String get speaker => _speaker;
  String get text => _text;
  LineChoice? get choice => _choice;
  MemQuestion? get question => _question;
  LineNameInput? get nameInput => _nameInput;
  List<BacklogEntry> get backlog => List.unmodifiable(_backlog);
  Set<String> get flags => Set.unmodifiable(_flags);
  Map<String, int> get affection => Map.unmodifiable(_affection);
  int get cycle => _cycle;
  int get aging => _aging;
  String get bg => _bg;
  int get bgAge => _bgAge;
  String get bgm => _bgm;

  /// タップ送りができるか。選択肢や入力の最中は勝手に進めない。
  bool get canAdvance =>
      _mode == PlayerMode.typing || _mode == PlayerMode.waiting;

  /// 最初の行へ。
  void start() {
    _index = -1;
    advance();
  }

  /// 1つ進める。
  ///
  /// - 文字送り中なら**全文表示**（1タップ目）
  /// - 表示しきっていれば次の行へ（2タップ目）
  void advance() {
    if (_mode == PlayerMode.typing) {
      _mode = PlayerMode.waiting; // 1タップ目は全文表示だけ
      return;
    }
    if (!canAdvance && _mode != PlayerMode.sceneEnd) return;
    _step();
  }

  /// 次の「止まる行」まで進む。
  /// fx / se / flag / bg のような**止まらない行**は続けて処理する。
  void _step() {
    while (true) {
      _index += 1;
      if (_index >= _scene.lines.length) {
        _mode = PlayerMode.sceneEnd;
        return;
      }
      final line = _scene.lines[_index];

      switch (line) {
        case LineMono(:final text):
          _show('', text);
          return;

        case LineSay(:final name, :final text):
          _show(name, text);
          return;

        case LineChoice c:
          _choice = c;
          _mode = PlayerMode.choice;
          return;

        case LineMemTest(:final charId, :final field):
          final target = cast.byId(charId);
          final f = NoahField.fromKey(field);
          // シナリオの打ち間違いでゲームを止めない。読み飛ばす。
          if (target == null || f == null) continue;
          _question = buildQuestion(
            target: target,
            field: f,
            pool: cast.all,
            all: cast.all,
            random: _rng,
          );
          _mode = PlayerMode.memtest;
          return;

        case LineNameInput n:
          _nameInput = n;
          _mode = PlayerMode.nameInput;
          return;

        // ── ここから下は「止まらない行」 ──
        case LineFx(:final kind):
          pendingFx = kind;
        case LineSe(:final id):
          pendingSe = id;
        case LineBgm(:final id):
          _bgm = id;
        case LineBg(:final id, :final age):
          _bg = id;
          _bgAge = age;
        case LineFlag(:final set):
          _flags.add(set);
        case LineSkip28y():
          _cycle += 1;
          // 老化は10で頭打ち。背景バリアントが bg_*_age0..10 しかない。
          _aging = min(10, _aging + 1);
        case LineJump():
          // シーンをまたぐ移動は外側（SceneRouter）が担当する。
          _mode = PlayerMode.sceneEnd;
          return;
        case LineUnknown():
          break; // 知らない行は無視して次へ
      }
    }
  }

  void _show(String speaker, String text) {
    _speaker = speaker;
    _text = text;
    _mode = PlayerMode.typing;
    _backlog.add(BacklogEntry(speaker: speaker, text: text));
  }

  /// 選択肢を選ぶ。次に行くシーンIDを返す（空なら同じシーンを続行）。
  String pickChoice(int i) {
    final c = _choice;
    if (c == null || i < 0 || i >= c.options.length) return '';
    _choice = null;
    _mode = PlayerMode.waiting;
    return c.options[i].jump;
  }

  /// 記憶テストに答える。正解なら好感度が少し上がる（SPEC 4.2）。
  bool answerMemTest(String picked) {
    final q = _question;
    if (q == null) return false;
    final ok = memory.answer(q, picked);
    if (ok) {
      _affection[q.target.id] = (_affection[q.target.id] ?? 0) + 1;
    }
    _question = null;
    _mode = PlayerMode.waiting;
    return ok;
  }

  /// 名前入力に答える。成功なら飛び先を返す。
  String? submitName(String input) {
    final n = _nameInput;
    if (n == null) return null;
    if (!looseNameMatch(input, n.expect)) return null;
    _nameInput = null;
    _mode = PlayerMode.waiting;
    return n.onSuccess;
  }

  /// 次のシーンへ差し替える。
  void loadScene(Scene next) {
    _scene = next;
    _bg = next.bg;
    _bgAge = next.bgAge;
    if (next.bgm.isNotEmpty) _bgm = next.bgm;
    start();
  }

  // ── セーブ・ロード ──

  SaveData toSave({required int slot, required int playSec}) => SaveData(
        slot: slot,
        savedAt: DateTime.now(),
        playSec: playSec,
        sceneId: _scene.id,
        lineIndex: _index,
        cycle: _cycle,
        aging: _aging,
        flags: {..._flags},
        affection: {..._affection},
        memory: memory.memory,
      );

  /// セーブから復帰する。**その行をもう一度表示する**ところまで戻す。
  ///
  /// ⚠️ `_index = save.lineIndex` としてから advance() を呼ぶと
  ///    1行進んでしまい、保存した行が読めないまま次へ飛ぶ。
  ///    1つ手前に置いてから進めること。
  void restore(SaveData save) {
    _index = save.lineIndex - 1;
    _cycle = save.cycle;
    _aging = save.aging;
    _flags
      ..clear()
      ..addAll(save.flags);
    _affection
      ..clear()
      ..addAll(save.affection);
    _backlog.clear();
    _mode = PlayerMode.waiting;
    _step();
  }
}

/// 名前入力のゆるい一致（SPEC 4.7）。
///
/// 漢字でもかなでも通す。空白・記号の違いで落とさない。
/// 「正しく打てたか」を測りたいのではなく、
/// **覚えているか**を測りたいので、表記のゆれは許す。
bool looseNameMatch(String input, String expect) {
  String norm(String s) => s
      .replaceAll(RegExp(r'[\s　・,.、。]'), '')
      .toLowerCase();
  final a = norm(input);
  final b = norm(expect);
  if (a.isEmpty) return false;
  return a == b;
}
