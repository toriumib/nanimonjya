import 'dart:convert';
import 'dart:math';

/// 🧑‍🎨 顔メモ用のアバター。
///
/// 新しく入った人の顔を覚えたいとき、**その人の写真を勝手に撮るわけにはいかない**。
/// かといって名前だけのメモでは顔と結びつかない。
/// そこで「メガネ・ほくろ・髪型」のような**特徴を選んで顔を組み立てる**。
///
/// 組み立てる作業そのものが記憶に効く。顔を見て「四角メガネ・左ほおにほくろ」と
/// 言葉にすること自体が特徴の言語化（タグ付け）で、
/// あとから思い出す手がかりになる（`featuresJa` がその手がかりを返す）。
///
/// 端末内にJSON文字列として保存する。外部へは送らない。
class Avatar {
  // ── 見た目のパーツ（すべて 0 起点のインデックス）──
  final int skin; // 肌の色
  final int faceShape; // 輪郭
  final int hair; // 髪型
  final int hairColor; // 髪の色
  final int eyes; // 目
  final int eyebrows; // まゆ
  final int nose; // 鼻
  final int mouth; // 口
  final int glasses; // メガネ（0=なし）
  final int mole; // ほくろの位置（0=なし）
  final int beard; // ひげ（0=なし）

  // ── 覚える手がかりになる属性（絵には出ないが、思い出す助けになる）──
  final int gender; // 0=指定なし 1=男性 2=女性 3=その他
  final int age; // 目安の年齢
  final int height; // 目安の身長(cm)

  /// 📊 別の顔と、いくつの項目が違うか（計測用）。
  ///
  /// `const Avatar()`（既定の顔）と比べると、
  /// **エディタで実際にいじった数**が分かる。0なら開いて何もせず出ている。
  int diffCount(Avatar other) {
    var n = 0;
    if (skin != other.skin) n++;
    if (faceShape != other.faceShape) n++;
    if (hair != other.hair) n++;
    if (hairColor != other.hairColor) n++;
    if (eyes != other.eyes) n++;
    if (eyebrows != other.eyebrows) n++;
    if (nose != other.nose) n++;
    if (mouth != other.mouth) n++;
    if (glasses != other.glasses) n++;
    if (mole != other.mole) n++;
    if (beard != other.beard) n++;
    if (gender != other.gender) n++;
    if (age != other.age) n++;
    if (height != other.height) n++;
    return n;
  }

  const Avatar({
    this.skin = 1,
    this.faceShape = 0,
    this.hair = 1,
    this.hairColor = 0,
    this.eyes = 0,
    this.eyebrows = 0,
    this.nose = 0,
    this.mouth = 0,
    this.glasses = 0,
    this.mole = 0,
    this.beard = 0,
    this.gender = 0,
    this.age = 30,
    this.height = 165,
  });

  // ── パーツの数（エディタのページ送りと、値の丸めに使う）──
  static const int skinCount = 5;
  static const int faceShapeCount = 4;
  static const int hairCount = 14;
  static const int hairColorCount = 6;
  static const int eyesCount = 6;
  static const int eyebrowsCount = 4;
  static const int noseCount = 3;
  static const int mouthCount = 5;
  static const int glassesCount = 5;
  static const int moleCount = 5;
  static const int beardCount = 4;
  static const int genderCount = 4;

  static const int minAge = 15;
  static const int maxAge = 80;
  static const int minHeight = 130;
  static const int maxHeight = 200;

  Avatar copyWith({
    int? skin,
    int? faceShape,
    int? hair,
    int? hairColor,
    int? eyes,
    int? eyebrows,
    int? nose,
    int? mouth,
    int? glasses,
    int? mole,
    int? beard,
    int? gender,
    int? age,
    int? height,
  }) =>
      Avatar(
        skin: skin ?? this.skin,
        faceShape: faceShape ?? this.faceShape,
        hair: hair ?? this.hair,
        hairColor: hairColor ?? this.hairColor,
        eyes: eyes ?? this.eyes,
        eyebrows: eyebrows ?? this.eyebrows,
        nose: nose ?? this.nose,
        mouth: mouth ?? this.mouth,
        glasses: glasses ?? this.glasses,
        mole: mole ?? this.mole,
        beard: beard ?? this.beard,
        gender: gender ?? this.gender,
        age: age ?? this.age,
        height: height ?? this.height,
      );

  Map<String, dynamic> toJson() => {
        'sk': skin,
        'fs': faceShape,
        'ha': hair,
        'hc': hairColor,
        'ey': eyes,
        'eb': eyebrows,
        'no': nose,
        'mo': mouth,
        'gl': glasses,
        'ml': mole,
        'be': beard,
        'ge': gender,
        'ag': age,
        'he': height,
      };

  /// 値が範囲外でも落ちないように必ず丸める。
  /// （パーツを増やしたあとに古い保存を読む／逆にパーツを減らす場合に備える）
  factory Avatar.fromJson(Map<String, dynamic> j) {
    int v(String k, int fallback, int count) {
      final n = (j[k] as num?)?.toInt() ?? fallback;
      return n < 0 ? 0 : (n >= count ? count - 1 : n);
    }

    return Avatar(
      skin: v('sk', 1, skinCount),
      faceShape: v('fs', 0, faceShapeCount),
      hair: v('ha', 1, hairCount),
      hairColor: v('hc', 0, hairColorCount),
      eyes: v('ey', 0, eyesCount),
      eyebrows: v('eb', 0, eyebrowsCount),
      nose: v('no', 0, noseCount),
      mouth: v('mo', 0, mouthCount),
      glasses: v('gl', 0, glassesCount),
      mole: v('ml', 0, moleCount),
      beard: v('be', 0, beardCount),
      gender: v('ge', 0, genderCount),
      age: ((j['ag'] as num?)?.toInt() ?? 30).clamp(minAge, maxAge),
      height: ((j['he'] as num?)?.toInt() ?? 165).clamp(minHeight, maxHeight),
    );
  }

  /// 保存用の1行文字列。CustomEntry や Person.face にそのまま入れられる。
  String encode() => jsonEncode(toJson());

  /// [encode] した文字列から戻す。壊れていたら既定のアバターにする
  /// （名簿が丸ごと読めなくなるより、顔が既定に戻るほうがまし）。
  static Avatar decode(String s) {
    if (s.isEmpty) return const Avatar();
    try {
      return Avatar.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return const Avatar();
    }
  }

  /// 文字列がアバターとして読めるか（Person.face が画像パスかアバターかの判別）。
  static bool looksLikeAvatar(String s) =>
      s.startsWith('{') && s.contains('"fs"');

  /// でたらめな顔を1つ作る。「まず作ってみる」の出発点に使う。
  factory Avatar.random([Random? random]) {
    final r = random ?? Random();
    return Avatar(
      skin: r.nextInt(skinCount),
      faceShape: r.nextInt(faceShapeCount),
      hair: r.nextInt(hairCount),
      hairColor: r.nextInt(hairColorCount),
      eyes: r.nextInt(eyesCount),
      eyebrows: r.nextInt(eyebrowsCount),
      nose: r.nextInt(noseCount),
      mouth: r.nextInt(mouthCount),
      glasses: r.nextInt(glassesCount),
      mole: r.nextInt(moleCount),
      beard: r.nextInt(beardCount),
      gender: r.nextInt(genderCount),
      age: minAge + r.nextInt(maxAge - minAge),
      height: minHeight + r.nextInt(maxHeight - minHeight),
    );
  }

  /// 🏷 覚える手がかりになる「特徴」を短い言葉で返す。
  ///
  /// 顔を見たときに言葉で言えるものだけを挙げる。
  /// 「四角メガネ・左ほおにほくろ」のように言語化しておくと、
  /// あとで思い出すときの取っかかりになる。
  /// 目立つものが無ければ空を返す（無理に特徴をひねり出さない）。
  List<String> featuresJa() => [
        if (glasses > 0) kGlassesJa[glasses],
        if (mole > 0) '${kMoleJa[mole]}にほくろ',
        if (beard > 0) kBeardJa[beard],
        if (hair != 1) kHairJa[hair],
      ];
}

// ── 日本語のラベル（エディタの表示と、特徴の言語化に使う）──

const List<String> kSkinJa = ['color1', 'color2', 'color3', 'color4', 'color5'];
const List<String> kFaceShapeJa = ['たまご型', 'まる型', '四角い', '細おもて'];
const List<String> kHairJa = [
  'ぼうず',
  'ふつう', // 既定。特徴には出さない
  'ショート',
  'ロング',
  'ポニーテール',
  'ウェーブ',
  'オールバック',
  'つむじが立った髪',
  'ツインテール',
  'おだんご',
  'マッシュ',
  'パーマ',
  'サイド分け',
  'ぱっつん',
];
const List<String> kHairColorJa = ['黒', 'こげ茶', '茶', '金', '赤茶', '白髪まじり'];
const List<String> kEyesJa = ['ふつう', 'たれ目', 'つり目', '細い目', 'まるい目', 'ぱっちり'];
const List<String> kEyebrowsJa = ['ふつう', '太い', '細い', 'への字'];
const List<String> kNoseJa = ['ふつう', '小さい', '高い'];
const List<String> kMouthJa = ['ふつう', 'にっこり', 'への字', '小さい', '大きい'];
const List<String> kGlassesJa = ['なし', '丸メガネ', '四角メガネ', '細いメガネ', 'サングラス'];
const List<String> kMoleJa = ['なし', '左ほお', '右ほお', '口もと', '目の下'];
const List<String> kBeardJa = ['なし', '口ひげ', 'あごひげ', '無精ひげ'];
const List<String> kGenderJa = ['指定なし', '男性', '女性', 'その他'];

// ── English labels ──
const List<String> kSkinEn = ['Fair', 'Light', 'Tan', 'Brown', 'Dark'];
const List<String> kFaceShapeEn = ['Oval', 'Round', 'Square', 'Slim'];
const List<String> kHairEn = [
  'Bald', 'Short', 'Short crop', 'Long', 'Ponytail', 'Wavy',
  'Slicked back', 'Spiky', 'Twin tails', 'Bun', 'Mushroom cut', 'Perm',
  'Side part', 'Blunt bangs',
];
const List<String> kHairColorEn = ['Black', 'Dark brown', 'Brown', 'Blonde', 'Auburn', 'Greying'];
const List<String> kEyesEn = ['Normal', 'Droopy', 'Upturned', 'Narrow', 'Round', 'Wide'];
const List<String> kEyebrowsEn = ['Normal', 'Thick', 'Thin', 'Angled'];
const List<String> kNoseEn = ['Normal', 'Small', 'Tall'];
const List<String> kMouthEn = ['Normal', 'Smiling', 'Frowning', 'Small', 'Large'];
const List<String> kGlassesEn = ['None', 'Round glasses', 'Square glasses', 'Thin glasses', 'Sunglasses'];
const List<String> kMoleEn = ['None', 'Left cheek', 'Right cheek', 'Near mouth', 'Under eye'];
const List<String> kBeardEn = ['None', 'Mustache', 'Goatee', 'Stubble'];
const List<String> kGenderEn = ['Unspecified', 'Male', 'Female', 'Other'];

/// Locale-aware label getters.
String skinLabel(int i, bool ja) => (ja ? kSkinJa : kSkinEn)[i.clamp(0, kSkinJa.length - 1)];
String faceShapeLabel(int i, bool ja) => (ja ? kFaceShapeJa : kFaceShapeEn)[i.clamp(0, kFaceShapeJa.length - 1)];
String hairLabel(int i, bool ja) => (ja ? kHairJa : kHairEn)[i.clamp(0, kHairJa.length - 1)];
String hairColorLabel(int i, bool ja) => (ja ? kHairColorJa : kHairColorEn)[i.clamp(0, kHairColorJa.length - 1)];
String eyesLabel(int i, bool ja) => (ja ? kEyesJa : kEyesEn)[i.clamp(0, kEyesJa.length - 1)];
String eyebrowsLabel(int i, bool ja) => (ja ? kEyebrowsJa : kEyebrowsEn)[i.clamp(0, kEyebrowsJa.length - 1)];
String noseLabel(int i, bool ja) => (ja ? kNoseJa : kNoseEn)[i.clamp(0, kNoseJa.length - 1)];
String mouthLabel(int i, bool ja) => (ja ? kMouthJa : kMouthEn)[i.clamp(0, kMouthJa.length - 1)];
String glassesLabel(int i, bool ja) => (ja ? kGlassesJa : kGlassesEn)[i.clamp(0, kGlassesJa.length - 1)];
String moleLabel(int i, bool ja) => (ja ? kMoleJa : kMoleEn)[i.clamp(0, kMoleJa.length - 1)];
String beardLabel(int i, bool ja) => (ja ? kBeardJa : kBeardEn)[i.clamp(0, kBeardJa.length - 1)];
String genderLabel(int i, bool ja) => (ja ? kGenderJa : kGenderEn)[i.clamp(0, kGenderJa.length - 1)];

/// 特徴を日本語または英語でリストにする。
List<String> features(Avatar a, bool ja) {
  final out = <String>[];
  if (a.glasses > 0) out.add(glassesLabel(a.glasses, ja));
  if (a.mole > 0) out.add(moleLabel(a.mole, ja));
  if (a.hair > 0) out.add(hairLabel(a.hair, ja));
  if (a.beard > 0) out.add(beardLabel(a.beard, ja));
  return out;
}
