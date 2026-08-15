import 'dart:math';

import 'surnames.dart';

/// 顔画像の種類。描画方法を切り替えるために使う。
/// - svg   : バンドルされたオリジナルSVG（assets/images/faces/*.svg）
/// - asset : バンドルされたフリー素材の写真風イラスト（assets/images/char*.jpg）
/// - file  : ユーザーがアップロードした写真（端末のファイルパス、モバイル限定）
/// 顔の描き方。
/// [avatar] のときは [Person.face] に画像パスではなく
/// アバターのJSON文字列（`Avatar.encode()`）が入る。
enum FaceKind { svg, asset, file, avatar }

/// 「人物」1人分。顔（画像）・名前・趣味を持つ。
/// なまえがおでは名前はプレイヤーがつけるので [name] は使わない場合もある。
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

/// フリー素材のキャラ画像一覧（12種）。なまえがお用。
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
  // 追加した実写3枚（12→15）。デッキ編集で選んだ数ぶんだけ登場する。
  'assets/images/25808650_m.jpg',
  'assets/images/26948510_s.jpg',
  'assets/images/4353720_s.jpg',
  // 🚫 char13.webp（旧c13）は取り下げた。**c13は欠番**にしてあり、
  //    ショップのカタログ（kExtraCharacters）にも戻さないこと。
  //    IDを使い回すと、以前 c13 を買った人の unlockedCharacters が
  //    別のキャラを指してしまう。
];

/// 🌍 英語版で出てくる顔（16枚）。
///
/// 日本語版の顔ぶれのまま英語の名前（Smith / Johnson…）を付けると、
/// 顔と名前が結びつきにくい。名前を覚える練習なのに、
/// **顔と名前がちぐはぐだと、そこに引っかかって記憶の邪魔になる**。
/// 表示言語が英語のときはこちらのプールを使う。
///
/// 素材は StyleGAN2 が生成した実在しない人の顔（Karras et al.）。
/// 実在の人物ではないので肖像権の問題が起きない。
///
/// ⚠️ **枚数は [kCharImageAssets] 以上を保つこと。**
///    なまえコールは最大 `NameCallGame.maxPeople` 人ぶんの顔を要求するので、
///    足りないと `assert(count <= pool.length)` で落ちる。
const List<String> kCharImageAssetsEn = [
  'assets/images/en/en1.webp',
  'assets/images/en/en2.webp',
  'assets/images/en/en3.webp',
  'assets/images/en/en4.webp',
  'assets/images/en/en5.webp',
  'assets/images/en/en6.webp',
  'assets/images/en/en7.webp',
  'assets/images/en/en8.webp',
  'assets/images/en/en9.webp',
  'assets/images/en/en10.webp',
  'assets/images/en/en11.webp',
  'assets/images/en/en12.webp',
  'assets/images/en/en13.webp',
  'assets/images/en/en14.webp',
  'assets/images/en/en15.webp',
  'assets/images/en/en16.webp',
];

/// 表示言語に合った基本の顔プールを返す。
///
/// ⚠️ **オンライン対戦では使わないこと。** 相手と表示言語が違うと
///    顔ぶれが食い違い、同じ盤面にならない。オンラインは今までどおり
///    [kCharImageAssets] を直接渡す（`rank_match` / `turn_pairs` /
///    `match_game` のオンライン分岐）。
List<String> charImageAssetsFor(bool ja) =>
    ja ? kCharImageAssets : kCharImageAssetsEn;

/// 名前プール（日本でよくある姓。記憶術の読み物の例とも対応）。
const List<String> _namePoolJa = [
  '佐藤', '田中', '松本', '鈴木', '高橋', '渡辺',
  '伊藤', '山本', '中村', '小林', '加藤', '吉田',
  '山田', '佐々木', '山口', '斎藤', '井上', '木村',
];

/// 英語版の姓。**日本語版のローマ字読み（Sato / Tanaka…）ではない。**
/// 顔ぶれを欧米系にしたので、名前もそろえないと顔と名前が結びつかず、
/// 「名前を覚える」練習の邪魔になる。件数は [_namePoolJa] と同じにする
/// （`generateRecallPeople` が同じ添字で日英を引くため）。
const List<String> _namePoolEn = [
  'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia',
  'Miller', 'Davis', 'Rodriguez', 'Martinez', 'Wilson', 'Anderson',
  'Taylor', 'Thomas', 'Moore', 'Jackson', 'Martin', 'Lee',
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

/// ゲーム1回分の人物リストを生成する（ペアさがし・記憶術トレーニング用）。
/// 顔・名前・趣味それぞれをシャッフルして組み合わせるので、毎回別人になる。
///
/// [charAssets] を渡すとフリー素材の実写顔を使う（既定）。
/// 渡さなければ自前生成のSVG顔になる。
///
/// ⚠️ オンライン対戦では**両者に同じ顔ぶれ**が出る必要がある。
/// 購入済みキャラを混ぜたプールを渡すと端末ごとに盤面が変わってしまうので、
/// オンラインでは誰でも持っている [kCharImageAssets] をそのまま渡すこと。
List<Person> generatePeople(
  int count, {
  required bool ja,
  Random? random,
  List<String>? charAssets,
}) {
  final rng = random ?? Random();
  final useReal = charAssets == null || charAssets.length >= count;
  // 🌍 プールを渡されなかったときは、表示言語に合った顔を使う
  final pool = useReal ? (charAssets ?? charImageAssetsFor(ja)) : kFaceAssets;
  assert(count <= pool.length);
  final faces = [...pool]..shuffle(rng);
  final namePool = ja ? _namePoolJa : _namePoolEn;
  final names = [...namePool]..shuffle(rng);
  final hobbyPool = ja ? _hobbyPoolJa : _hobbyPoolEn;
  final hobbies = [...hobbyPool]..shuffle(rng);
  return List.generate(count, (i) {
    return Person(
      face: faces[i],
      kind: useReal ? FaceKind.asset : FaceKind.svg,
      name: ja ? '${names[i]}さん' : names[i],
      hobby: hobbies[i % hobbies.length],
    );
  });
}

/// 🎴 出演プールに入れられる「顔」1つぶん。
///
/// バンドルのキャラ画像だけでなく、顔メモで登録した写真や似顔絵も
/// 同じ土俵で扱えるようにするための入れもの。
///
/// [deckKey] はキャラデッキのON/OFFを覚えておくための一意なキー。
/// 画像アセットはパスがそのまま一意になるが、**顔メモの似顔絵は
/// 画像パスを持たない**（空文字）ので、パスをキーに使うと全員が
/// 同じキーに潰れてしまう。登録IDをもとにした `custom:<id>` を使う。
class FaceRef {
  final String deckKey;
  final FaceKind kind;

  /// 画像パス、またはアバターのJSON（[FaceKind.avatar] のとき）。
  final String face;

  const FaceRef({
    required this.deckKey,
    required this.kind,
    required this.face,
  });

  /// バンドルのキャラ画像から作る（いちばん多い使いかた）。
  factory FaceRef.asset(String path) =>
      FaceRef(deckKey: path, kind: FaceKind.asset, face: path);
}

/// なまえがお用: フリー素材のキャラ画像で人物を生成する。
/// なまえがおは名前をプレイヤーがつけるので name はプレースホルダ。
List<Person> generateImagePeople(int count,
    {required bool ja, Random? random, List<String>? charAssets}) {
  final rng = random ?? Random();
  final pool = (charAssets == null || charAssets.length < count)
      ? charImageAssetsFor(ja) // 🌍 英語版は欧米系の顔ぶれ
      : charAssets;
  assert(count <= pool.length);
  final faces = [...pool]..shuffle(rng);
  return List.generate(count, (i) {
    return Person(
      face: faces[i],
      kind: FaceKind.asset,
      name: '',
      hobby: '',
    );
  });
}

/// なまえがお用: 顔メモで登録した人も混ぜて生成する。
///
/// [generateImagePeople] との違いは、写真・似顔絵といった
/// **画像アセット以外の顔**も出演できること。
/// 顔メモに登録した人を、ふだんの対戦にもそのまま出せるようにする。
///
/// 足りないときはバンドルのキャラ画像で埋める（プールが少ないせいで
/// ゲームが始まらない、という事故を避ける）。
List<Person> generatePeopleFromFaces(int count,
    {required List<FaceRef> faces, Random? random}) {
  final rng = random ?? Random();
  final pool = [...faces];
  if (pool.length < count) {
    final have = pool.map((f) => f.deckKey).toSet();
    for (final a in kCharImageAssets) {
      if (pool.length >= count) break;
      if (have.contains(a)) continue;
      pool.add(FaceRef.asset(a));
    }
  }
  pool.shuffle(rng);
  final n = min(count, pool.length);
  return List.generate(
    n,
    (i) => Person(
      face: pool[i].face,
      kind: pool[i].kind,
      name: '',
      hobby: '',
    ),
  );
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
List<Person> generateRecallPeople(int count,
    {required bool ja, Random? random, List<String>? charAssets}) {
  final rng = random ?? Random();
  final pool = (charAssets == null || charAssets.length < count)
      ? charImageAssetsFor(ja) // 🌍 英語版は欧米系の顔ぶれ
      : charAssets;
  assert(count <= pool.length);
  final faces = [...pool]..shuffle(rng);
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

/// 🎯 思い出しクイズの選択肢を4つに満たすための「実在しない人」の値を作る。
///
/// 出題できる人数が少ないと選択肢が正解＋1個などになってしまい、
/// **覚えていなくても当たる**＝テストとして成立しなくなる。
/// 実際に起きていたのは次の2つ:
///   - 復習キュー（期限が来た人だけ）で残りが1〜2人のとき
///   - 顔メモに2人しか登録していない状態での確認テスト
///
/// [like] には正解の文字列を渡す。名前は敬称の有無を正解にそろえるため
/// （「佐藤さん」の中に「田中」が混じると、それだけで答えが割れてしまう）。
List<String> recallDistractors(
  RecallField field, {
  required bool ja,
  required int count,
  String like = '',
  Set<String> exclude = const <String>{},
  Random? random,
}) {
  if (count <= 0) return const [];
  final rng = random ?? Random();
  final out = <String>[];
  final seen = {...exclude};

  if (field == RecallField.name) {
    // 名前は実在しそうな苗字プールから借りる（造語だと練習にならない）
    final honorific = ja && like.endsWith('さん') ? 'さん' : '';
    final pool = [...commonNamePool(ja)]..shuffle(rng);
    for (final s in pool) {
      final v = '$s$honorific';
      if (seen.contains(v)) continue;
      seen.add(v);
      out.add(v);
      if (out.length >= count) break;
    }
    return out;
  }

  // 会社名・肩書・連絡先は、架空の人物を生成してその項目だけを借りる
  for (var attempt = 0; attempt < 8 && out.length < count; attempt++) {
    final filler = generateRecallPeople(
      min(count + 2, charImageAssetsFor(ja).length),
      ja: ja,
      random: rng,
    );
    for (final p in filler) {
      final v = recallFieldValue(p, field).trim();
      if (v.isEmpty || seen.contains(v)) continue;
      seen.add(v);
      out.add(v);
      if (out.length >= count) break;
    }
  }
  return out;
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
