/// 📖 船内百科 — 用語集（SPEC 3.6）と、船内の謎（STORY 7章）。
///
/// 謎は3周目に全解禁（記憶率60%以上）。
/// **解いても得しない。解くと誰かを少し好きになるだけ。**
/// なので、報酬ではなく読み物として置く。
library;

/// 船内の謎ひとつ。
class ShipMystery {
  final String id;

  /// 問い。解禁前でもこれは見せる（気になるから探す）。
  final String question;

  /// 答え。解禁されるまで伏せる。
  final String answer;

  /// 本編で気づいたときに立つフラグ。
  /// 立っていれば、周回の解禁を待たずにその1件だけ開く。
  final String? flag;

  const ShipMystery({
    required this.id,
    required this.question,
    required this.answer,
    this.flag,
  });
}

/// STORY 7章の6つ。
const List<ShipMystery> kMysteries = [
  ShipMystery(
    id: 'flower',
    question: '観測室の花に、毎朝水をやっているのは誰か',
    answer: '清掃ロボット。アップロードされた元・園芸係の意思を引き継いでいる。'
        '手順書には無い作業を、三百年つづけている。',
  ),
  ShipMystery(
    id: 'haiku',
    question: 'カラオケの掲示板に、匿名の俳句を貼っているのは誰か',
    answer: '岩尾玄助。句はぜんぶ、故郷の山への恋。'
        'この船に山は無い。だから詠むのだと、本人は言わない。',
    flag: 'mystery_haiku_guessed',
  ),
  ShipMystery(
    id: 'soy',
    question: '食堂の醤油が、三百三十年変わらないのはなぜか',
    answer: '篠原恭平が継ぎ足している。'
        'そして水原紗耶香も、祖母のぬか床を同じように継ぎ足している。'
        '二人は、お互いのことを知らない。',
    flag: 'mystery_nukadoko_told',
  ),
  ShipMystery(
    id: 'tomorrow',
    question: 'テニスコートの壁の「また明日」は、誰が刻んだのか',
    answer: '冷凍睡眠の前夜、全員が順番に刻んだ。'
        '三百三十年後に会うのに「また明日」はないだろう、と誰かが言った。'
        'それでも全員が、それがいいと言った。',
    flag: 'mystery_tomorrow_seen',
  ),
  ShipMystery(
    id: 'pinflag',
    question: '十八番ホールのピンフラッグが、発射後も残っているのはなぜか',
    answer: '発射の朝、土倉源三が立て直した。'
        '「帰ってくる目印に」と言って。誰も、帰る予定は無いのに。',
  ),
  ShipMystery(
    id: 'tags',
    question: '冷凍ポッドの番号札を、毎晩ひとつだけ磨いているのは誰か',
    answer: '記録官——あなた自身。無意識の習慣だった。'
        '名前を覚えていられなくなっても、手のほうが順番を覚えていた。',
  ),
];

/// 用語集（SPEC 3.6 / STORY 9章）。
class GlossaryEntry {
  final String term;
  final String body;
  const GlossaryEntry(this.term, this.body);
}

const List<GlossaryEntry> kGlossary = [
  GlossaryEntry('ASC',
      'アルデヒド安定化冷凍保存。シナプスの形を化学的に固定してからガラス化する。'
      '【研究段階】ヒトの蘇生は実現していない。'),
  GlossaryEntry('MELiSSA',
      'ESAの閉鎖生態系プロジェクト。水と窒素を循環させて外から足さない。'
      '【研究段階】完全な循環はまだ達成されていない。'),
  GlossaryEntry('DFD',
      '直接核融合推進。推力と発電を同時にまかなう構想。'
      '【研究段階】実機は存在しない。'),
  GlossaryEntry('磁気セイル',
      '超伝導ループで恒星風を受けて減速する。'
      '【研究段階】理論研究の段階。'),
  GlossaryEntry('ターミネータ',
      '潮汐ロックした星の、昼と夜の境目。永遠の夕暮れの帯。'
      'LHS 1140 b では、ここだけが人の住める温度になる。'),
  GlossaryEntry('コネクトーム',
      '神経のつながりの地図。ショウジョウバエの全脳は完成している（2024）。'
      '【研究段階】ヒトはまだ遠い。'),
  GlossaryEntry('クロス・コンタミネーション',
      '長期の冷凍保存で、誰の記憶かの区別がにじむ現象。'
      '【創作】本作の設定であり、科学的な裏づけを主張しない。'),
  GlossaryEntry('呼名',
      '名前を声に出して呼ぶこと。記録官の仕事。'
      '読み返すより思い出すほうが残る、という考えにもとづく。'),
  GlossaryEntry('さよならの手紙',
      '乗れなかった側が、乗る側へ渡すために書いた手紙。'
      '定員が五百になった日、全員が破って招待状に書き換えた。'),
  GlossaryEntry('名刺160枚',
      '備蓄庫の最後の紙で刷った。十六人×十枚。'
      '土倉源三のぶんは、はじめから一枚も無い。'),
  GlossaryEntry('ノア・ドーム',
      '横浜市戸塚区大池町。旧・大池カントリークラブの地下三キロ。'
      '十八番ホールのグリーンの真下が発射サイロ。'),
  GlossaryEntry('東京層群',
      '関東平野の深部にある堅固な泥岩・砂岩の互層。'
      '【観測】大深度の構造物を支える層として実在する。'),
  GlossaryEntry('覚醒期',
      '二十八年眠って二年起きる、その「二年」のこと。全十一回。'),
  GlossaryEntry('台帳',
      '記録官が持つ三冊の帳面。'
      '生まれた者、死んだ者、まだどちらでもない者。'),
  GlossaryEntry('ベルの不等式',
      '【観測】破れが実験で確認されている（2022年ノーベル物理学賞）。'
      '⚠️ これが否定したのは「局所実在論」であって、決定論そのものではない。'
      '決まっているかどうかは、まだ決着していない。'),
];

/// その謎を開いてよいか。
///
/// 周回で全解禁されるか、本編で自分で気づいたか、のどちらか。
bool isMysteryOpen(
  ShipMystery m, {
  required bool allUnlocked,
  required Set<String> flags,
}) {
  if (allUnlocked) return true;
  final f = m.flag;
  return f != null && flags.contains(f);
}
