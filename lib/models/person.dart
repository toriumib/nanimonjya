import 'dart:math';

/// 顔画像の種類。描画方法を切り替えるために使う。
/// - svg   : バンドルされたオリジナルSVG（assets/images/faces/*.svg）
/// - asset : バンドルされたフリー素材の写真風イラスト（assets/images/char*.jpg）
/// - file  : ユーザーがアップロードした写真（端末のファイルパス、モバイル限定）
enum FaceKind { svg, asset, file }

/// 「人物」1人分。顔（画像）・名前・趣味を持つ。
/// なまえコールでは名前はプレイヤーがつけるので [name] は使わない場合もある。
class Person {
  final String face; // 画像パス（svg/画像アセット/ファイル）
  final FaceKind kind;
  final String name; // 表示名（例: 佐藤さん / Sato）
  final String hobby; // 趣味（上級レベルの属性クイズで使用）
  final String where; // どこで出会ったか（思い出しトレーニングの文脈。例: 会社の会議で）
  // 名刺の情報（思い出しトレーニング／カスタム名簿で使用。未設定は空文字）
  final String company; // 会社名
  final String title; // 肩書
  final String phone; // 電話番号
  final String email; // メールアドレス
  final String cardImage; // アップロードした実物の名刺画像パス（あれば）

  const Person({
    required this.face,
    this.kind = FaceKind.svg,
    required this.name,
    required this.hobby,
    this.where = '',
    this.company = '',
    this.title = '',
    this.phone = '',
    this.email = '',
    this.cardImage = '',
  });

  /// 旧コード互換: SVG顔のパスを取り出す（match_game系がまだ使用）。
  String get faceAsset => face;
}

/// 思い出しトレーニングでクイズにできる項目。
/// デフォルトは name+company、他はオプション。
enum RecallField { name, company, title, phone, email }

/// 指定した項目の値を取り出す（空なら出題対象外）。
String recallFieldValue(Person p, RecallField f) {
  switch (f) {
    case RecallField.name:
      return p.name;
    case RecallField.company:
      return p.company;
    case RecallField.title:
      return p.title;
    case RecallField.phone:
      return p.phone;
    case RecallField.email:
      return p.email;
  }
}

/// オリジナルSVG顔アセット一覧（12種のフラットデザイン顔）。ペアさがし用。
const List<String> kFaceAssets = [
  'assets/images/faces/face1.svg',
  'assets/images/faces/face2.svg',
  'assets/images/faces/face3.svg',
  'assets/images/faces/face4.svg',
  'assets/images/faces/face5.svg',
  'assets/images/faces/face6.svg',
  'assets/images/faces/face7.svg',
  'assets/images/faces/face8.svg',
  'assets/images/faces/face9.svg',
  'assets/images/faces/face10.svg',
  'assets/images/faces/face11.svg',
  'assets/images/faces/face12.svg',
];

/// フリー素材のキャラ画像一覧（12種）。なまえコール用。
const List<String> kCharImageAssets = [
  'assets/images/char1.jpg',
  'assets/images/char2.jpg',
  'assets/images/char3.jpg',
  'assets/images/char4.jpg',
  'assets/images/char5.jpg',
  'assets/images/char6.jpg',
  'assets/images/char7.jpg',
  'assets/images/char8.jpg',
  'assets/images/char9.jpg',
  'assets/images/char10.jpg',
  'assets/images/char11.jpg',
  'assets/images/char12.jpg',
];

/// 名前プール（日本でよくある姓。記憶術の読み物の例とも対応）。
const List<String> _namePoolJa = [
  '佐藤', '田中', '松本', '鈴木', '高橋', '渡辺',
  '伊藤', '山本', '中村', '小林', '加藤', '吉田',
  '山田', '佐々木', '山口', '斎藤', '井上', '木村',
];

const List<String> _namePoolEn = [
  'Sato', 'Tanaka', 'Matsumoto', 'Suzuki', 'Takahashi', 'Watanabe',
  'Ito', 'Yamamoto', 'Nakamura', 'Kobayashi', 'Kato', 'Yoshida',
  'Yamada', 'Sasaki', 'Yamaguchi', 'Saito', 'Inoue', 'Kimura',
];

/// 趣味プール（属性クイズ用）。
const List<String> _hobbyPoolJa = [
  '釣り', 'ピアノ', 'キャンプ', 'ラーメン巡り', '将棋', 'ヨガ',
  'カメラ', '登山', 'ゲーム', '映画', 'ガーデニング', 'マラソン',
];

const List<String> _hobbyPoolEn = [
  'Fishing', 'Piano', 'Camping', 'Ramen tours', 'Shogi', 'Yoga',
  'Photography', 'Hiking', 'Gaming', 'Movies', 'Gardening', 'Running',
];

/// ゲーム1回分の人物リストを生成する（SVG顔。ペアさがし用）。
/// 顔・名前・趣味それぞれをシャッフルして組み合わせるので、毎回別人になる。
List<Person> generatePeople(int count, {required bool ja, Random? random}) {
  final rng = random ?? Random();
  assert(count <= kFaceAssets.length);
  final faces = [...kFaceAssets]..shuffle(rng);
  final namePool = ja ? _namePoolJa : _namePoolEn;
  final names = [...namePool]..shuffle(rng);
  final hobbyPool = ja ? _hobbyPoolJa : _hobbyPoolEn;
  final hobbies = [...hobbyPool]..shuffle(rng);
  return List.generate(count, (i) {
    return Person(
      face: faces[i],
      kind: FaceKind.svg,
      name: ja ? '${names[i]}さん' : names[i],
      hobby: hobbies[i % hobbies.length],
    );
  });
}

/// なまえコール用: フリー素材のキャラ画像で人物を生成する。
/// なまえコールは名前をプレイヤーがつけるので name はプレースホルダ。
List<Person> generateImagePeople(int count, {required bool ja, Random? random}) {
  final rng = random ?? Random();
  assert(count <= kCharImageAssets.length);
  final faces = [...kCharImageAssets]..shuffle(rng);
  return List.generate(count, (i) {
    return Person(
      face: faces[i],
      kind: FaceKind.asset,
      name: '',
      hobby: '',
    );
  });
}

/// 「どこで出会ったか」の文脈プール（思い出しトレーニング用）。
/// 実生活で「あの人だれだっけ」となる典型シーン。顔・名前・場所を結びつけて覚える。
const List<String> _metContextJa = [
  '会社の会議で',
  '取引先との打ち合わせで',
  '飲み会で',
  '子どもの保護者会で',
  'ジムで',
  'ご近所づきあいで',
  '同窓会で',
  '趣味のサークルで',
  'セミナーで',
  'カフェで',
  '引っ越しのあいさつで',
  '取引先の忘年会で',
];

const List<String> _metContextEn = [
  'at a work meeting',
  'at a client meeting',
  'at a drinking party',
  "at a kids' school event",
  'at the gym',
  'around the neighborhood',
  'at a class reunion',
  'at a hobby club',
  'at a seminar',
  'at a café',
  'at a housewarming',
  "at a client's year-end party",
];

// ---- 架空の名刺データ生成（存在しない会社名・肩書・連絡先） ----
// 会社名は2つの造語パーツ＋業種語尾を組み合わせて作る（実在企業を避けるための造語）。
// (ja, romaji) を対にしてメールのドメインにも使う。
const List<List<String>> _coStemA = [
  ['アオ', 'ao'], ['ソラ', 'sora'], ['ミラ', 'mira'], ['ハル', 'haru'],
  ['ユメ', 'yume'], ['ネオ', 'neo'], ['リオ', 'rio'], ['ノヴァ', 'nova'],
  ['セラ', 'sera'], ['コト', 'koto'], ['ナギ', 'nagi'], ['ルミ', 'lumi'],
];
const List<List<String>> _coStemB = [
  ['テック', 'tech'], ['リンク', 'link'], ['ワークス', 'works'], ['バース', 'verse'],
  ['ステラ', 'stella'], ['ライズ', 'rise'], ['ゲート', 'gate'], ['ルクス', 'lux'],
  ['フォート', 'fort'], ['ミント', 'mint'], ['コア', 'core'], ['ノミ', 'nomi'],
];
const List<String> _coSuffixJa = [
  '株式会社', '工業', 'システムズ', '商事', 'ホールディングス', 'デザイン', '物産',
];
const List<String> _coSuffixEn = [
  'Inc.', 'Industries', 'Systems', 'Trading', 'Holdings', 'Design', 'Corp.',
];
const List<List<String>> _titles = [
  ['営業部 主任', 'Sales, Lead'],
  ['マーケティング部 課長', 'Marketing Manager'],
  ['開発部 エンジニア', 'Software Engineer'],
  ['総務部 部長', 'General Affairs Director'],
  ['企画部 リーダー', 'Planning Lead'],
  ['カスタマーサクセス 担当', 'Customer Success'],
  ['人事部 主任', 'HR, Lead'],
  ['経営企画室 室長', 'Head of Strategy'],
  ['広報部 担当', 'Public Relations'],
  ['財務部 課長', 'Finance Manager'],
  ['デザイナー', 'Designer'],
  ['代表取締役', 'CEO'],
];

/// 架空の携帯電話番号（表示専用のダミー。実在番号を意図しない）。
String _fakePhone(Random rng) {
  final head = ['090', '080', '070'][rng.nextInt(3)];
  final mid = (1000 + rng.nextInt(9000)).toString();
  final tail = (1000 + rng.nextInt(9000)).toString();
  return '$head-$mid-$tail';
}

/// 思い出しトレーニング用: 実写の人物に「名前・会社・肩書・連絡先・出会った場所」を割り当てて生成する。
/// 会社名/連絡先はすべて架空。実際に人と出会う→時間をおいて思い出す、を再現する。
List<Person> generateRecallPeople(int count, {required bool ja, Random? random}) {
  final rng = random ?? Random();
  assert(count <= kCharImageAssets.length);
  final faces = [...kCharImageAssets]..shuffle(rng);
  // 苗字はランダム（毎回シャッフルして別人に）
  final idxs = List.generate(_namePoolJa.length, (i) => i)..shuffle(rng);
  final hobbies = [...(ja ? _hobbyPoolJa : _hobbyPoolEn)]..shuffle(rng);
  final contexts = [...(ja ? _metContextJa : _metContextEn)]..shuffle(rng);
  final titles = [..._titles]..shuffle(rng);
  return List.generate(count, (i) {
    final ni = idxs[i % idxs.length];
    final surnameJa = _namePoolJa[ni];
    final surnameEn = _namePoolEn[ni];
    // 架空の会社名（造語A＋造語B＋業種語尾）
    final a = _coStemA[rng.nextInt(_coStemA.length)];
    final b = _coStemB[rng.nextInt(_coStemB.length)];
    final sufIdx = rng.nextInt(_coSuffixJa.length);
    final company = ja
        ? '${a[0]}${b[0]}${_coSuffixJa[sufIdx]}'
        : '${a[1][0].toUpperCase()}${a[1].substring(1)}${b[1]} ${_coSuffixEn[sufIdx]}';
    final domain = '${a[1]}${b[1]}.co.jp'; // 架空ドメイン
    final email = '${surnameEn.toLowerCase()}@$domain';
    final title = titles[i % titles.length];
    return Person(
      face: faces[i],
      kind: FaceKind.asset,
      name: ja ? '$surnameJaさん' : surnameEn,
      hobby: hobbies[i % hobbies.length],
      where: contexts[i % contexts.length],
      company: company,
      title: ja ? title[0] : title[1],
      phone: _fakePhone(rng),
      email: email,
    );
  });
}

/// 趣味クイズ用: 正解以外の選択肢を作る。
List<String> hobbyChoices(Person answer, {required bool ja, int total = 3, Random? random}) {
  final rng = random ?? Random();
  final pool = (ja ? _hobbyPoolJa : _hobbyPoolEn)
      .where((h) => h != answer.hobby)
      .toList()
    ..shuffle(rng);
  final choices = [answer.hobby, ...pool.take(total - 1)]..shuffle(rng);
  return choices;
}
