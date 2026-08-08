/// ADV本体の画面。SPEC 3.1〜3.3。
///
/// レイヤは Stack で重ねる: 背景 → 立ち絵 → 演出 → テキスト窓 → UI。
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../engine/asset_repository.dart';
import '../engine/config_store.dart';
import '../engine/save_manager.dart';
import '../engine/scene_player.dart';
import '../models/noah_field.dart';
import '../models/save_data.dart';
import '../models/scene_script.dart';
import '../systems/ending.dart';
import 'backlog_sheet.dart';
import 'placeholder.dart';
import 'save_sheet.dart';
import 'encyclopedia_screen.dart';
import 'ledger_screen.dart';
import 'settings_screen.dart';

class AdvScreen extends StatefulWidget {
  /// 続きから始めるときのセーブ。null なら最初から。
  final SaveData? resume;

  const AdvScreen({super.key, this.resume});

  @override
  State<AdvScreen> createState() => _AdvScreenState();
}

class _AdvScreenState extends State<AdvScreen> {
  ScenePlayer? _player;
  NoahCast? _cast;
  SystemData _system = const SystemData();

  /// タイプライターで「いま何文字目まで出したか」。
  int _shown = 0;
  Timer? _typeTimer;

  /// オート送り。
  bool _auto = false;
  Timer? _autoTimer;

  /// 遊んだ秒数（セーブに残す）。
  int _playSec = 0;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _boot();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _playSec += 1);
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _autoTimer?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _boot() async {
    await ConfigStore.instance.load();
    final cast = await AssetRepository.instance.loadCast();
    _system = await SaveManager.instance.readSystem();
    _readBefore = {..._system.readScenes}; // 起動時点の既読を控える

    final resume = widget.resume;
    final sceneId = resume?.sceneId.isNotEmpty == true
        ? resume!.sceneId
        : 'act1_sc01';
    final scene = await AssetRepository.instance.loadScene(sceneId) ??
        await AssetRepository.instance.loadScene('act1_sc01');
    if (scene == null || !mounted) return;

    final p = ScenePlayer(scene: scene, cast: cast);
    if (resume != null) {
      p.restore(resume);
      _playSec = resume.playSec;
    } else {
      p.start();
    }
    setState(() {
      _cast = cast;
      _player = p;
    });
    _onLineShown();
  }

  AdvConfig get _cfg => ConfigStore.instance.config;

  /// 新しい行が出たとき: タイプライターを回し、既読に記録する。
  void _onLineShown() {
    _typeTimer?.cancel();
    _shown = 0;
    final p = _player;
    if (p == null) return;

    // 既読管理（スキップの判定に使う）
    _system = _system.copyWith(readScenes: {..._system.readScenes, p.scene.id});
    SaveManager.instance.writeSystem(_system);

    // 未読の話に入ったらスキップを解除する（SPEC 3.2）
    if (_skip && !_canSkipHere) {
      _skip = false;
      _snack('ここから先は初めてなので、スキップをやめます');
    }

    if (_cfg.charMs <= 0) {
      setState(() => _shown = p.text.length);
      p.advance(); // 即時表示なら「全文表示済み」にしておく
      _scheduleAuto();
      return;
    }
    _typeTimer = Timer.periodic(Duration(milliseconds: _cfg.charMs), (t) {
      final cur = _player;
      if (cur == null) {
        t.cancel();
        return;
      }
      if (_shown >= cur.text.length) {
        t.cancel();
        // 全文出たので「待ち」状態へ（タップ1回ぶんを消化）
        if (cur.mode == PlayerMode.typing) cur.advance();
        _scheduleAuto();
        setState(() {});
        return;
      }
      setState(() => _shown += 1);
    });
  }

  void _scheduleAuto() {
    _autoTimer?.cancel();
    if (_skip) {
      // スキップ中は待たずに次へ。速すぎると選択肢を踏み越えるので、
      // 1フレームぶんだけ間を置く。
      _autoTimer = Timer(const Duration(milliseconds: 16), () {
        if (mounted && _skip) _tap();
      });
      return;
    }
    if (!_auto) return;
    _autoTimer = Timer(Duration(milliseconds: _cfg.autoWaitMs), () {
      if (mounted && _auto) _tap();
    });
  }

  /// ⏩ スキップ（SPEC 3.2）。
  bool _skip = false;

  /// このシーンを飛ばしてよいか。
  ///
  /// 「既読のみスキップ」がONなら、**まだ読んでいない話は飛ばさない**。
  /// ここを見ないと、初見の人がボタンひとつで本編を全部消し飛ばせてしまう。
  bool get _canSkipHere {
    final p = _player;
    if (p == null) return false;
    if (!_cfg.skipReadOnly) return true;
    return _readBefore.contains(p.scene.id);
  }

  /// この起動より前に読み終えていたシーン。
  ///
  /// ⚠️ `_system.readScenes` は**いま読んでいる行でも増える**ので、
  ///    そのまま見ると「初見なのに既読」になってスキップが素通りする。
  ///    起動時の内容を別に取っておく。
  Set<String> _readBefore = const {};

  void _toggleSkip() {
    setState(() => _skip = !_skip);
    if (_skip && !_canSkipHere) {
      // 押した瞬間に理由を言う。黙って効かないのがいちばん困る。
      _snack('ここはまだ読んでいないので飛ばしません');
      setState(() => _skip = false);
      return;
    }
    _scheduleAuto();
  }

  /// 画面タップ（＝送り）。
  Future<void> _tap() async {
    final p = _player;
    if (p == null) return;

    // 文字送り中なら、まず全文表示
    if (_shown < p.text.length) {
      _typeTimer?.cancel();
      setState(() => _shown = p.text.length);
      if (p.mode == PlayerMode.typing) p.advance();
      _scheduleAuto();
      return;
    }
    if (!p.canAdvance && p.mode != PlayerMode.sceneEnd) return;

    p.advance();
    await _afterAdvance();
  }

  Future<void> _afterAdvance() async {
    final p = _player;
    if (p == null) return;

    // 決めごとが出たらスキップを止める。飛ばして選ばれると事故になる。
    if (_skip &&
        (p.mode == PlayerMode.choice ||
            p.mode == PlayerMode.memtest ||
            p.mode == PlayerMode.nameInput)) {
      setState(() => _skip = false);
    }

    if (p.mode == PlayerMode.sceneEnd) {
      // ① 結末が決まっていれば、そのエンドへ。
      final end = p.endingJump;
      if (end != null) {
        p.endingJump = null;
        await _goEnding(end);
        return;
      }
      // ② jump 行の飛び先へ。無ければタイトルへ戻る。
      final jump = _pendingJump(p);
      if (jump != null) {
        final next = await AssetRepository.instance.loadScene(jump);
        if (next != null && mounted) {
          p.loadScene(next);
          _onLineShown();
          return;
        }
      }
      await _autoSave();
      if (mounted) _showSceneEnd();
      return;
    }
    _onLineShown();
  }

  /// いま止まっている位置が jump 行なら、その飛び先。
  String? _pendingJump(ScenePlayer p) {
    if (p.index < 0 || p.index >= p.scene.lines.length) return null;
    final l = p.scene.lines[p.index];
    return l is LineJump ? l.to : null;
  }

  /// 結末のシーンへ入る。ここで1周おわりなので、システムデータも更新する。
  Future<void> _goEnding(EndingResult end) async {
    final p = _player!;

    // 最高記憶率とクリア回数はシステムデータ側に積む（SPEC 4.3 / 4.6）。
    final rate = memoryRate(
      correct: p.memory.correctCount,
      totalPairs: totalPairsFor(_cast?.all.length ?? 0),
    );
    _system = _system.reportMemoryRate(rate).reportCleared();
    await SaveManager.instance.writeSystem(_system);

    final scene = await AssetRepository.instance.loadScene(end.ending.sceneId);
    if (!mounted) return;
    if (scene == null) {
      _showSceneEnd();
      return;
    }
    setState(() {
      _ending = end;
      p.loadScene(scene);
    });
    _onLineShown();
  }

  /// いま迎えている結末（結末のシーンでだけ入る）。
  EndingResult? _ending;

  Future<void> _autoSave() async {
    final p = _player;
    if (p == null) return;
    await SaveManager.instance
        .write(p.toSave(slot: SaveManager.autoSlot, playSec: _playSec));
  }

  void _showSceneEnd() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ここまで'),
        content: const Text('この先はまだ書かれていません。\n'
            'ここまでの進みはオートセーブに残しました。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('タイトルへ'),
          ),
        ],
      ),
    );
  }

  // ── メニュー ──

  Future<void> _openBacklog() async {
    final p = _player;
    if (p == null) return;
    await showBacklogSheet(
      context,
      p.backlog,
      contamination: p.contamination,
      names: p.familyNames,
    );
  }

  Future<void> _openSave({required bool loading}) async {
    final p = _player;
    if (p == null) return;
    final picked = await showSaveSheet(
      context,
      loading: loading,
      // 選択肢の最中はセーブできない（SPEC 3.4）
      current: p.mode == PlayerMode.choice
          ? null
          : p.toSave(slot: 0, playSec: _playSec),
      chapter: p.scene.chapter,
      memoryRateLabel: memoryRateLabel(
        memoryRate(
          correct: p.memory.correctCount,
          totalPairs: totalPairsFor(_cast?.all.length ?? 0),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    // ロードで選ばれた
    final scene = await AssetRepository.instance.loadScene(picked.sceneId);
    if (scene == null || !mounted) return;
    setState(() {
      _player!.loadScene(scene);
      _player!.restore(picked);
      _playSec = picked.playSec;
    });
    _onLineShown();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => const SettingsScreen()));
    if (mounted) setState(() {}); // 文字速度が変わっているかもしれない
  }

  @override
  Widget build(BuildContext context) {
    final p = _player;
    if (p == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF05080F),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final rate = memoryRate(
      correct: p.memory.correctCount,
      totalPairs: totalPairsFor(_cast?.all.length ?? 0),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF05080F),
      body: GestureDetector(
        onTap: _tap,
        // 上スワイプでバックログ（SPEC 3.3）
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) < -200) _openBacklog();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ① 背景
            BackdropLayer(id: p.bg, age: p.bgAge),

            // ② 立ち絵
            SpriteLayer(player: p, cast: _cast),

            // ③ 上のUI（章・記憶率）
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 6, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.scene.chapter,
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF9FB4D8),
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    _MemoryMeter(rate: rate),
                    IconButton(
                      tooltip: 'ログ',
                      onPressed: _openBacklog,
                      icon: const Icon(Icons.menu_book_rounded,
                          color: Color(0xFFD7E2FF)),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert,
                          color: Color(0xFFD7E2FF)),
                      onSelected: (v) => switch (v) {
                        'save' => _openSave(loading: false),
                        'load' => _openSave(loading: true),
                        'ledger' => Navigator.of(context)
                            .push(MaterialPageRoute<void>(
                                builder: (_) => LedgerScreen(
                                      cast: _cast!,
                                      memory: p.memory,
                                      affection: p.affection,
                                    ))),
                        'encyclopedia' => Navigator.of(context)
                            .push(MaterialPageRoute<void>(
                                builder: (_) => EncyclopediaScreen(
                                      system: _system,
                                      // いま気づいた謎も開けるように、
                                      // この周のフラグを渡す
                                      flags: p.flags,
                                    ))),
                        'config' => _openSettings(),
                        'title' => Navigator.pop(context),
                        _ => null,
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'save', child: Text('セーブ')),
                        PopupMenuItem(value: 'load', child: Text('ロード')),
                        PopupMenuItem(value: 'ledger', child: Text('台帳')),
                        PopupMenuItem(
                            value: 'encyclopedia', child: Text('船内百科')),
                        PopupMenuItem(value: 'config', child: Text('コンフィグ')),
                        PopupMenuItem(value: 'title', child: Text('タイトルへ')),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ④ テキスト窓／選択肢／記憶テスト／名前入力
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: switch (p.mode) {
                  PlayerMode.choice => _ChoiceBox(
                      options: p.choice!.options,
                      onPick: (i) async {
                        final jump = p.pickChoice(i);
                        if (jump.isEmpty) {
                          await _afterAdvanceAfterChoice();
                          return;
                        }
                        final next =
                            await AssetRepository.instance.loadScene(jump);
                        if (next != null && mounted) {
                          setState(() => p.loadScene(next));
                          _onLineShown();
                        } else {
                          await _afterAdvanceAfterChoice();
                        }
                      },
                    ),
                  PlayerMode.memtest => _MemTestBox(
                      question: p.question!,
                      onPick: (v) {
                        final ok = p.answerMemTest(v);
                        _snack(ok ? '思い出せた' : '……ちがった');
                        setState(() {});
                        _tap();
                      },
                    ),
                  PlayerMode.nameInput => _NameInputBox(
                      onSubmit: (v) {
                        final jump = p.submitName(v);
                        if (jump == null) {
                          _snack('その名前ではないようだ');
                          return;
                        }
                        _tap();
                      },
                    ),
                  _ => _TextWindow(
                      skip: _skip,
                      onToggleSkip: _toggleSkip,
                      speaker: p.speaker,
                      text: _fill(p.text)
                          .substring(0, _shown.clamp(0, _fill(p.text).length)),
                      auto: _auto,
                      onToggleAuto: () {
                        setState(() => _auto = !_auto);
                        _scheduleAuto();
                      },
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 選択肢を選んだあと、同じシーンを続ける場合。
  Future<void> _afterAdvanceAfterChoice() async {
    final p = _player;
    if (p == null) return;
    p.advance();
    await _afterAdvance();
  }

  /// 差し込み語を埋める。
  ///
  /// 結末の本文は「誰と結ばれたか」で変わるが、
  /// 相手ごとにシーンを書き分けると同じ文章が8本並ぶ。
  /// `{partner}` `{regret}` を置いておいて、ここで差し替える。
  String _fill(String src) {
    if (!src.contains('{')) return src;
    final e = _ending;
    final partner = e?.partner;
    final names = e == null || e.partners.isEmpty
        ? (partner?.name ?? 'あの人')
        : e.partners.map((c) => c.name).join('、');
    return src
        .replaceAll('{partner}', partner?.name ?? names)
        .replaceAll('{partners}', names)
        .replaceAll('{regret}', partner?.regret ?? '');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)),
    );
  }
}

/// 記憶率メーター（SPEC 5）。
class _MemoryMeter extends StatelessWidget {
  final double rate;
  const _MemoryMeter({required this.rate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0D121C),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Text(
        memoryRateLabel(rate),
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFF7DFFB0)),
      ),
    );
  }
}

/// テキスト窓（名前枠＋本文）。
class _TextWindow extends StatelessWidget {
  final String speaker;
  final String text;
  final bool auto;
  final VoidCallback onToggleAuto;
  final bool skip;
  final VoidCallback onToggleSkip;

  const _TextWindow({
    required this.speaker,
    required this.text,
    required this.auto,
    required this.onToggleAuto,
    required this.skip,
    required this.onToggleSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      constraints: const BoxConstraints(minHeight: 150),
      decoration: BoxDecoration(
        color: const Color(0xE60B1020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1D2A4A), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (speaker.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12203C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(speaker,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF5AD1FF))),
                ),
              const Spacer(),
              TextButton(
                onPressed: onToggleSkip,
                child: Text(skip ? 'SKIP ●' : 'SKIP',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: skip
                            ? const Color(0xFFE0A44C)
                            : const Color(0xFF6A7280))),
              ),
              TextButton(
                onPressed: onToggleAuto,
                child: Text(auto ? 'AUTO ●' : 'AUTO',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: auto
                            ? const Color(0xFF7DFFB0)
                            : const Color(0xFF6A7280))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
                fontSize: 15.5, height: 1.75, color: Color(0xFFE8ECF1)),
          ),
        ],
      ),
    );
  }
}

class _ChoiceBox extends StatelessWidget {
  final List<ChoiceOption> options;
  final ValueChanged<int> onPick;
  const _ChoiceBox({required this.options, required this.onPick});

  @override
  Widget build(BuildContext context) {
    // ⚠️ 選択肢が増えると縦に溢れる（デート先は6つある）。
    //    画面の6割までに収めて、あとはスクロールさせる。
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.62,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          for (final (i, o) in options.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => onPick(i),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF12203C),
                    foregroundColor: const Color(0xFFE8ECF1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF2B5CA5)),
                  ),
                  child: Text(o.text, style: const TextStyle(fontSize: 14.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemTestBox extends StatelessWidget {
  final dynamic question; // MemQuestion
  final ValueChanged<String> onPick;
  const _MemTestBox({required this.question, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final q = question;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xE60B1020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B5CA5), width: 1.6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${q.target.name} の ${q.field.labelJa} は？',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5AD1FF))),
          const SizedBox(height: 12),
          for (final c in q.choices as List<String>)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => onPick(c),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE8ECF1),
                    side: const BorderSide(color: Color(0xFF1D2A4A)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(c),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NameInputBox extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  const _NameInputBox({required this.onSubmit});

  @override
  State<_NameInputBox> createState() => _NameInputBoxState();
}

class _NameInputBoxState extends State<_NameInputBox> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xE60B1020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4A24C), width: 1.6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('その人の名前を、呼んでください',
              style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD4A24C))),
          const SizedBox(height: 10),
          TextField(
            controller: _c,
            autofocus: true,
            style: const TextStyle(color: Color(0xFFE8ECF1)),
            decoration: const InputDecoration(
              hintText: 'かなでも漢字でも',
              hintStyle: TextStyle(color: Color(0xFF6A7280)),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF1D2A4A))),
            ),
            onSubmitted: widget.onSubmit,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onSubmit(_c.text),
              child: const Text('呼ぶ'),
            ),
          ),
        ],
      ),
    );
  }
}
