import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:project_noa/engine/scene_player.dart';
import 'package:project_noa/models/noah_field.dart';
import 'package:project_noa/models/scene_script.dart';

/// シーン進行。ここが崩れると「タップしても進まない」「保存した行が
/// 読めないまま飛ぶ」といった、遊ぶ側には原因の分からない壊れ方をする。
void main() {
  NoahCharacter chara(String id, String name, String hobby) => NoahCharacter(
        id: id,
        name: name,
        reading: '',
        affiliation: '$name研究所',
        hobby: hobby,
        commId: 'ID-$id',
        school: '$name大学',
        regret: '',
        cast: 1,
        romance: true,
        color: 0,
        emoji: '🙂',
      );

  final cast = NoahCast([
    chara('a', '日比野', '陶芸'),
    chara('b', '桐生', '囲碁'),
    chara('c', '水原', 'メダカ'),
    chara('d', '橘', '盆栽'),
  ]);

  Scene scene(List<Map<String, dynamic>> lines) => Scene.fromJson({
        'id': 'test_sc',
        'chapter': 'ACT I',
        'bg': 'dome',
        'lines': lines,
      });

  group('タップ送り', () {
    test('1タップ目は全文表示、2タップ目で次の行へ', () {
      final p = ScenePlayer(
        scene: scene([
          {'t': 'mono', 'text': '一行目'},
          {'t': 'mono', 'text': '二行目'},
        ]),
        cast: cast,
      )..start();

      expect(p.text, '一行目');
      expect(p.mode, PlayerMode.typing, reason: '出はじめは文字送り中');

      p.advance();
      expect(p.mode, PlayerMode.waiting);
      expect(p.text, '一行目', reason: '1タップ目では次へ行かない');

      p.advance();
      expect(p.text, '二行目');
    });

    test('台詞は話し手の名前を持つ', () {
      final p = ScenePlayer(
        scene: scene([
          {'t': 'say', 'name': '土倉', 'text': '結論から言う。'},
        ]),
        cast: cast,
      )..start();
      expect(p.speaker, '土倉');
      expect(p.text, '結論から言う。');
    });

    test('最後まで行くと sceneEnd になる', () {
      final p = ScenePlayer(
        scene: scene([
          {'t': 'mono', 'text': 'おわり'},
        ]),
        cast: cast,
      )..start();
      p.advance(); // 全文
      p.advance(); // 次へ → 終端
      expect(p.mode, PlayerMode.sceneEnd);
    });
  });

  group('止まらない行は、まとめて処理される', () {
    test('fx / se / flag / bg は素通りして、次の台詞まで進む', () {
      final p = ScenePlayer(
        scene: scene([
          {'t': 'fx', 'kind': 'shake'},
          {'t': 'se', 'id': 'alarm'},
          {'t': 'flag', 'set': 'saw_alarm'},
          {'t': 'bg', 'id': 'silo', 'bgAge': 2},
          {'t': 'mono', 'text': '警報が鳴った'},
        ]),
        cast: cast,
      )..start();

      expect(p.text, '警報が鳴った', reason: '演出だけの行で止まらない');
      expect(p.pendingFx, 'shake');
      expect(p.pendingSe, 'alarm');
      expect(p.flags, contains('saw_alarm'));
      expect(p.bg, 'silo');
      expect(p.bgAge, 2);
    });

    test('skip28y でサイクルと老化が進む', () {
      final p = ScenePlayer(
        scene: scene([
          {'t': 'skip28y'},
          {'t': 'mono', 'text': '目が覚めた'},
        ]),
        cast: cast,
      )..start();
      expect(p.cycle, 1);
      expect(p.aging, 1);
    });

    test('老化は10で頭打ち（背景バリアントの範囲を超えない）', () {
      final p = ScenePlayer(
        scene: scene([
          for (var i = 0; i < 15; i++) {'t': 'skip28y'},
          {'t': 'mono', 'text': '着いた'},
        ]),
        cast: cast,
      )..start();
      expect(p.cycle, 15);
      expect(p.aging, 10);
    });

    test('知らない種類の行は読み飛ばす（落ちない）', () {
      final p = ScenePlayer(
        scene: scene([
          {'t': 'nanikaatarashii', 'text': '未対応'},
          {'t': 'mono', 'text': '続き'},
        ]),
        cast: cast,
      )..start();
      expect(p.text, '続き');
    });
  });

  group('選択肢', () {
    test('選択肢の最中は勝手に進まない', () {
      final p = ScenePlayer(
        scene: scene([
          {
            't': 'choice',
            'options': [
              {'text': '四名……？', 'jump': 'act1_sc01b'},
            ],
          },
        ]),
        cast: cast,
      )..start();

      expect(p.mode, PlayerMode.choice);
      expect(p.canAdvance, isFalse, reason: 'タップで飛ばせてしまうと選べない');
      p.advance();
      expect(p.mode, PlayerMode.choice);
    });

    test('選ぶと飛び先が返る', () {
      final p = ScenePlayer(
        scene: scene([
          {
            't': 'choice',
            'options': [
              {'text': 'A', 'jump': 'sc_a'},
              {'text': 'B', 'jump': 'sc_b'},
            ],
          },
        ]),
        cast: cast,
      )..start();
      expect(p.pickChoice(1), 'sc_b');
    });
  });

  group('記憶テスト', () {
    test('3択が出て、正解すると好感度が上がる', () {
      final p = ScenePlayer(
        scene: scene([
          {'t': 'memtest', 'char': 'a', 'field': 'hobby'},
        ]),
        cast: cast,
        random: Random(1),
      )..start();

      expect(p.mode, PlayerMode.memtest);
      final q = p.question!;
      expect(q.choices.length, 3);
      expect(q.choices, contains('陶芸'));

      expect(p.answerMemTest('陶芸'), isTrue);
      expect(p.affection['a'], 1);
      expect(p.memory.correctCount, 1);
    });

    test('まちがえても減点しない。ただし汚染として残る', () {
      final p = ScenePlayer(
        scene: scene([
          {'t': 'memtest', 'char': 'a', 'field': 'hobby'},
        ]),
        cast: cast,
        random: Random(2),
      )..start();

      expect(p.answerMemTest('囲碁'), isFalse);
      expect(p.affection['a'], isNull, reason: '好感度は下がらないし、増えもしない');
      expect(p.memory.correctCount, 0);
      expect(p.memory.contaminated['a.hobby'], '囲碁');
    });

    test('シナリオのIDが間違っていても止まらず、次へ進む', () {
      final p = ScenePlayer(
        scene: scene([
          {'t': 'memtest', 'char': 'いない人', 'field': 'hobby'},
          {'t': 'mono', 'text': '続き'},
        ]),
        cast: cast,
      )..start();
      expect(p.text, '続き');
    });
  });

  group('名前入力（SPEC 4.7）', () {
    test('表記がゆれても通る', () {
      expect(looseNameMatch('とくらげんぞう', 'とくらげんぞう'), isTrue);
      expect(looseNameMatch('とくら げんぞう', 'とくらげんぞう'), isTrue);
      expect(looseNameMatch('とくら　げんぞう', 'とくらげんぞう'), isTrue);
      expect(looseNameMatch('とくら・げんぞう', 'とくらげんぞう'), isTrue);
    });

    test('空欄や別人は通らない', () {
      expect(looseNameMatch('', 'とくらげんぞう'), isFalse);
      expect(looseNameMatch('ひびのかえで', 'とくらげんぞう'), isFalse);
    });

    test('正解すると飛び先が返る', () {
      final p = ScenePlayer(
        scene: scene([
          {'t': 'input', 'expect': 'とくらげんぞう', 'onSuccess': 'act5_true'},
        ]),
        cast: cast,
      )..start();
      expect(p.mode, PlayerMode.nameInput);
      expect(p.submitName('ちがう'), isNull);
      expect(p.submitName('とくら げんぞう'), 'act5_true');
    });
  });

  group('バックログとセーブ復帰', () {
    test('読んだ行がバックログに正典のまま積まれる', () {
      final p = ScenePlayer(
        scene: scene([
          {'t': 'mono', 'text': '一行目'},
          {'t': 'say', 'name': '土倉', 'text': '二行目'},
        ]),
        cast: cast,
      )..start();
      p.advance();
      p.advance();
      expect(p.backlog.length, 2);
      expect(p.backlog.last.speaker, '土倉');
      expect(p.backlog.last.text, '二行目');
    });

    test('セーブして復帰すると、保存した行がもう一度読める', () {
      final s = scene([
        {'t': 'mono', 'text': '一行目'},
        {'t': 'mono', 'text': '二行目'},
        {'t': 'mono', 'text': '三行目'},
      ]);
      final p = ScenePlayer(scene: s, cast: cast)..start();
      p.advance();
      p.advance(); // 二行目
      expect(p.text, '二行目');

      final save = p.toSave(slot: 1, playSec: 10);
      expect(save.lineIndex, 1);

      final q = ScenePlayer(scene: s, cast: cast)..restore(save);
      expect(q.text, '二行目',
          reason: '復帰で1行進んでしまうと、保存した行が読めないまま飛ぶ');
    });

    test('フラグ・好感度・サイクル・老化も戻る', () {
      final s = scene([
        {'t': 'flag', 'set': 'f1'},
        {'t': 'skip28y'},
        {'t': 'mono', 'text': 'あ'},
      ]);
      final p = ScenePlayer(scene: s, cast: cast)..start();
      final save = p.toSave(slot: 2, playSec: 0);

      final q = ScenePlayer(scene: s, cast: cast)..restore(save);
      expect(q.flags, contains('f1'));
      expect(q.cycle, 1);
      expect(q.aging, 1);
    });
  });
}
