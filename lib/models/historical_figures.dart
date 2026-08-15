/// 📚 歴史上の人物カタログ。学習指導要領の「覚えるべき人」＋世界史の偉人。
///
/// 顔はアバターから生成するので写真の著作権問題はゼロ。
/// 名前・業績は歴史的事実でありパブリックドメイン。
/// 名刺の会社名・メール・電話は現代風にアレンジした創作（架空）。
///
/// 使いかた: [generateHistoricalPeople] で Person のリストにして
/// 名刺覚え／なまえコールの出演プールに混ぜる。
library;

import 'dart:math';
import 'avatar.dart';
import 'person.dart';

class HistoricalFigure {
  final String id;
  final String nameJa;
  final String nameEn;
  final String yomi;
  final String fieldJa; // 業績・肩書（日本語）
  final String fieldEn;
  final String hobbyJa; // 逸話（日本語）
  final String hobbyEn;
  final String schoolJa; // 出身・時代背景
  final String schoolEn;
  final String emoji;
  final Avatar avatar;

  const HistoricalFigure({
    required this.id,
    required this.nameJa,
    required this.nameEn,
    required this.yomi,
    required this.fieldJa,
    required this.fieldEn,
    required this.hobbyJa,
    required this.hobbyEn,
    required this.schoolJa,
    required this.schoolEn,
    required this.emoji,
    required this.avatar,
  });
}

const List<HistoricalFigure> kHistoricalFigures = [
  // ── 世界史の偉人 ──
  HistoricalFigure(
    id: 'hg_galileo',
    nameJa: 'ガリレオ・ガリレイ',
    nameEn: 'Galileo Galilei',
    yomi: 'がりれお・がりれい',
    fieldJa: '天文学者・物理学者／地動説',
    fieldEn: 'Astronomer & Physicist · Heliocentrism',
    hobbyJa: '「それでも地球は動く」と言ったと伝えられる',
    hobbyEn: 'Reputedly said "And yet it moves" about the Earth',
    schoolJa: 'イタリア・ピサ生まれ',
    schoolEn: 'Born in Pisa, Italy',
    emoji: '🔭',
    avatar: Avatar(
      skin: 0, faceShape: 2, hair: 1, hairColor: 5, eyes: 1, eyebrows: 1,
      nose: 2, mouth: 3, glasses: 0, mole: 0, beard: 5,
      gender: 1, age: 65, height: 170),
  ),
  HistoricalFigure(
    id: 'hg_newton',
    nameJa: 'ニュートン',
    nameEn: 'Isaac Newton',
    yomi: 'にゅーとん',
    fieldJa: '物理学者・万有引力の発見',
    fieldEn: 'Physicist · Universal Gravitation',
    hobbyJa: '錬金術にも熱中し、聖書の研究に没頭した',
    hobbyEn: 'Deeply devoted to alchemy and biblical studies',
    schoolJa: 'イギリス生まれ・ケンブリッジ大学',
    schoolEn: 'Born in England · Cambridge University',
    emoji: '🍎',
    avatar: Avatar(
      skin: 0, faceShape: 2, hair: 1, hairColor: 5, eyes: 1, eyebrows: 2,
      nose: 1, mouth: 2, glasses: 0, mole: 0, beard: 0,
      gender: 1, age: 50, height: 173),
  ),
  HistoricalFigure(
    id: 'hg_curie',
    nameJa: 'キュリー夫人',
    nameEn: 'Marie Curie',
    yomi: 'きゅりーふじん',
    fieldJa: '物理学者・化学者／放射線研究',
    fieldEn: 'Physicist & Chemist · Radioactivity',
    hobbyJa: 'ノーベル賞を2回受賞（物理学賞と化学賞）',
    hobbyEn: 'Only person to win Nobel Prizes in two sciences',
    schoolJa: 'ポーランド生まれ・パリ大学',
    schoolEn: 'Born in Poland · University of Paris',
    emoji: '☢️',
    avatar: Avatar(
      skin: 0, faceShape: 0, hair: 4, hairColor: 4, eyes: 2, eyebrows: 0,
      nose: 0, mouth: 1, glasses: 0, mole: 1, beard: 0,
      gender: 2, age: 45, height: 160),
  ),
  HistoricalFigure(
    id: 'hg_darwin',
    nameJa: 'ダーウィン',
    nameEn: 'Charles Darwin',
    yomi: 'だーうぃん',
    fieldJa: '自然科学者・進化論',
    fieldEn: 'Naturalist · Theory of Evolution',
    hobbyJa: 'ビーグル号で5年間世界を航海し標本を集めた',
    hobbyEn: 'Sailed the world for 5 years on HMS Beagle',
    schoolJa: 'イギリス生まれ・ケンブリッジ大学',
    schoolEn: 'Born in England · Cambridge University',
    emoji: '🐢',
    avatar: Avatar(
      skin: 0, faceShape: 2, hair: 1, hairColor: 5, eyes: 3, eyebrows: 1,
      nose: 2, mouth: 3, glasses: 0, mole: 0, beard: 5,
      gender: 1, age: 55, height: 183),
  ),
  HistoricalFigure(
    id: 'hg_edison',
    nameJa: 'エジソン',
    nameEn: 'Thomas Edison',
    yomi: 'えじそん',
    fieldJa: '発明家・電球と蓄音機',
    fieldEn: 'Inventor · Light Bulb & Phonograph',
    hobbyJa: '「天才は1%のひらめきと99%の努力」で有名',
    hobbyEn: '"Genius is 1% inspiration, 99% perspiration"',
    schoolJa: 'アメリカ生まれ・独学（学校には数ヶ月しか通わず）',
    schoolEn: 'Born in USA · Largely self-taught',
    emoji: '💡',
    avatar: Avatar(
      skin: 0, faceShape: 3, hair: 6, hairColor: 5, eyes: 0, eyebrows: 2,
      nose: 1, mouth: 0, glasses: 0, mole: 0, beard: 0,
      gender: 1, age: 55, height: 178),
  ),
  HistoricalFigure(
    id: 'hg_tesla',
    nameJa: 'テスラ',
    nameEn: 'Nikola Tesla',
    yomi: 'てすら',
    fieldJa: '発明家・交流電流システム',
    fieldEn: 'Inventor · AC Electrical System',
    hobbyJa: 'ハトをこよなく愛し、3で割り切れる数にこだわった',
    hobbyEn: 'Loved pigeons, obsessed with numbers divisible by 3',
    schoolJa: 'オーストリア帝国生まれ・グラーツ工科大学',
    schoolEn: 'Born in Austrian Empire · Graz University of Tech',
    emoji: '⚡',
    avatar: Avatar(
      skin: 0, faceShape: 3, hair: 6, hairColor: 0, eyes: 3, eyebrows: 1,
      nose: 2, mouth: 0, glasses: 0, mole: 0, beard: 2,
      gender: 1, age: 42, height: 188),
  ),
  HistoricalFigure(
    id: 'hg_beethoven',
    nameJa: 'ベートーヴェン',
    nameEn: 'Ludwig van Beethoven',
    yomi: 'べーとーゔぇん',
    fieldJa: '作曲家・「運命」「第九」',
    fieldEn: 'Composer · Symphony No.5 & No.9',
    hobbyJa: '耳が聞こえなくなっても作曲を続けた',
    hobbyEn: 'Continued composing even after losing his hearing',
    schoolJa: 'ドイツ生まれ・ボンで学びウィーンで活躍',
    schoolEn: 'Born in Germany · Studied in Bonn, worked in Vienna',
    emoji: '🎵',
    avatar: Avatar(
      skin: 0, faceShape: 2, hair: 6, hairColor: 3, eyes: 1, eyebrows: 1,
      nose: 1, mouth: 2, glasses: 0, mole: 0, beard: 0,
      gender: 1, age: 50, height: 168),
  ),
  // ── 日本の偉人（学習指導要領より）──
  HistoricalFigure(
    id: 'hg_nobunaga',
    nameJa: '織田 信長',
    nameEn: 'Oda Nobunaga',
    yomi: 'おだ のぶなが',
    fieldJa: '戦国武将・天下統一を目指した',
    fieldEn: 'Warlord · Sought to unify Japan',
    hobbyJa: '鉄砲をいち早く取り入れ、経済を活性化した',
    hobbyEn: 'Adopted firearms early, promoted free trade',
    schoolJa: '尾張（現在の愛知県）生まれ',
    schoolEn: 'Born in Owari (present-day Aichi Prefecture)',
    emoji: '⚔️',
    avatar: Avatar(
      skin: 0, faceShape: 2, hair: 6, hairColor: 0, eyes: 3, eyebrows: 2,
      nose: 2, mouth: 0, glasses: 0, mole: 0, beard: 1,
      gender: 1, age: 38, height: 170),
  ),
  HistoricalFigure(
    id: 'hg_ieyasu',
    nameJa: '徳川 家康',
    nameEn: 'Tokugawa Ieyasu',
    yomi: 'とくがわ いえやす',
    fieldJa: '江戸幕府初代将軍',
    fieldEn: 'First Shogun of the Tokugawa Shogunate',
    hobbyJa: '「鳴かぬなら鳴くまで待とうホトトギス」のたとえで有名',
    hobbyEn: 'Known for patience: waited 260 years for lasting peace',
    schoolJa: '三河（現在の愛知県東部）生まれ',
    schoolEn: 'Born in Mikawa (present-day eastern Aichi)',
    emoji: '🏯',
    avatar: Avatar(
      skin: 0, faceShape: 2, hair: 0, hairColor: 0, eyes: 1, eyebrows: 1,
      nose: 0, mouth: 1, glasses: 0, mole: 2, beard: 3,
      gender: 1, age: 55, height: 165),
  ),
  HistoricalFigure(
    id: 'hg_yukichi',
    nameJa: '福沢 諭吉',
    nameEn: 'Fukuzawa Yukichi',
    yomi: 'ふくざわ ゆきち',
    fieldJa: '教育者・慶應義塾大学創設者',
    fieldEn: 'Educator · Founder of Keio University',
    hobbyJa: '『学問のすゝめ』を著し「天は人の上に人をつくらず」',
    hobbyEn: 'Wrote "Encouragement of Learning": all are created equal',
    schoolJa: '豊前中津藩（現在の大分県）生まれ',
    schoolEn: 'Born in Buzen-Nakatsu (present-day Oita Prefecture)',
    emoji: '📖',
    avatar: Avatar(
      skin: 0, faceShape: 3, hair: 5, hairColor: 0, eyes: 0, eyebrows: 2,
      nose: 1, mouth: 2, glasses: 1, mole: 0, beard: 0,
      gender: 1, age: 55, height: 173),
  ),
  HistoricalFigure(
    id: 'hg_hideyo',
    nameJa: '野口 英世',
    nameEn: 'Noguchi Hideyo',
    yomi: 'のぐち ひでよ',
    fieldJa: '細菌学者・黄熱病の研究',
    fieldEn: 'Bacteriologist · Yellow Fever Research',
    hobbyJa: '左手のやけどを乗り越え世界で活躍、千円札の肖像に',
    hobbyEn: 'Overcame a childhood burn, became face of ¥1000 note',
    schoolJa: '福島県生まれ・独学で医師免許を取得',
    schoolEn: 'Born in Fukushima · Self-taught, became a doctor',
    emoji: '🔬',
    avatar: Avatar(
      skin: 1, faceShape: 1, hair: 2, hairColor: 0, eyes: 2, eyebrows: 0,
      nose: 1, mouth: 1, glasses: 2, mole: 0, beard: 0,
      gender: 1, age: 40, height: 162),
  ),
  HistoricalFigure(
    id: 'hg_ryoma',
    nameJa: '坂本 龍馬',
    nameEn: 'Sakamoto Ryoma',
    yomi: 'さかもと りょうま',
    fieldJa: '幕末の志士・薩長同盟を仲介',
    fieldEn: 'Samurai · Brokered the Satsuma-Choshu Alliance',
    hobbyJa: '日本初の商社「亀山社中」を作った',
    hobbyEn: 'Founded Japan\'s first trading company',
    schoolJa: '土佐（現在の高知県）生まれ・千葉道場で剣術を学ぶ',
    schoolEn: 'Born in Tosa (Kochi) · Trained in swordsmanship',
    emoji: '🌊',
    avatar: Avatar(
      skin: 0, faceShape: 3, hair: 5, hairColor: 0, eyes: 4, eyebrows: 0,
      nose: 2, mouth: 0, glasses: 0, mole: 3, beard: 0,
      gender: 1, age: 31, height: 175),
  ),
  HistoricalFigure(
    id: 'hg_shoin',
    nameJa: '吉田 松陰',
    nameEn: 'Yoshida Shoin',
    yomi: 'よしだ しょういん',
    fieldJa: '思想家・教育者／松下村塾',
    fieldEn: 'Thinker & Educator · Shokasonjuku School',
    hobbyJa: 'わずか2年余りの講義で維新の志士を多数輩出',
    hobbyEn: 'In just 2 years, taught many future Meiji leaders',
    schoolJa: '長州（現在の山口県）生まれ',
    schoolEn: 'Born in Choshu (present-day Yamaguchi)',
    emoji: '🏫',
    avatar: Avatar(
      skin: 0, faceShape: 1, hair: 5, hairColor: 0, eyes: 3, eyebrows: 2,
      nose: 0, mouth: 2, glasses: 0, mole: 0, beard: 0,
      gender: 1, age: 28, height: 165),
  ),
  // ── さらに世界の偉人 ──
  HistoricalFigure(
    id: 'hg_nightingale',
    nameJa: 'ナイチンゲール',
    nameEn: 'Florence Nightingale',
    yomi: 'ないちんげーる',
    fieldJa: '看護師・統計学者／近代看護の母',
    fieldEn: 'Nurse & Statistician · Founder of Modern Nursing',
    hobbyJa: '「クリミアの天使」と呼ばれ、統計グラフの発明者でもある',
    hobbyEn: '"The Lady with the Lamp", also invented statistical graphs',
    schoolJa: 'イギリス生まれ・富裕層の家庭に育つ',
    schoolEn: 'Born in England to a wealthy family',
    emoji: '🏥',
    avatar: Avatar(
      skin: 0, faceShape: 0, hair: 4, hairColor: 3, eyes: 2, eyebrows: 0,
      nose: 0, mouth: 1, glasses: 0, mole: 1, beard: 0,
      gender: 2, age: 38, height: 165),
  ),
  HistoricalFigure(
    id: 'hg_davinci',
    nameJa: 'ダ・ヴィンチ',
    nameEn: 'Leonardo da Vinci',
    yomi: 'だ・う゛ぃんち',
    fieldJa: '芸術家・科学者・発明家',
    fieldEn: 'Artist · Scientist · Inventor',
    hobbyJa: '「モナリザ」を描き、飛行機の設計図も残した',
    hobbyEn: 'Painted the Mona Lisa, designed early flying machines',
    schoolJa: 'イタリア・フィレンツェ生まれ',
    schoolEn: 'Born in Florence, Italy',
    emoji: '🎨',
    avatar: Avatar(
      skin: 0, faceShape: 2, hair: 1, hairColor: 5, eyes: 1, eyebrows: 1,
      nose: 2, mouth: 3, glasses: 0, mole: 0, beard: 5,
      gender: 1, age: 60, height: 175),
  ),
];

/// すべての歴史上の人物を Person のリストとして取得。
/// [ja] で名前・所属・趣味の表示言語を切り替える。
List<Person> generateHistoricalPeople({required bool ja, Random? random}) {
  final rng = random ?? Random();
  return [
    for (final h in kHistoricalFigures)
      Person(
        face: h.avatar.encode(),
        kind: FaceKind.avatar,
        name: ja ? '${h.nameJa}さん' : h.nameEn,
        hobby: ja ? h.hobbyJa : h.hobbyEn,
        where: ja ? h.schoolJa : h.schoolEn,
        company: ja ? h.fieldJa : h.fieldEn,
        title: '',
        phone: '',
        email: '',
      ),
  ]..shuffle(rng);
}

/// 歴史人物のIDリストを取得。
List<String> get kHistoricalFigureIds =>
    [for (final h in kHistoricalFigures) h.id];
