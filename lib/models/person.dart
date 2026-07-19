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

  const Person({
    required this.face,
    this.kind = FaceKind.svg,
    required this.name,
    required this.hobby,
  });

  /// 旧コード互換: SVG顔のパスを取り出す（match_game系がまだ使用）。
  String get faceAsset => face;
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
