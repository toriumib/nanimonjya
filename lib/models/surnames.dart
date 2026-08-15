/// 🏷 おまかせ命名につかう名前プール。日英それぞれ上位100。
library;
/// 造語のガチャ名だと「実在しそうな名前を覚える」練習にならないため、
/// 実際によくある苗字から選ぶようにする。CPU対戦のように
/// アプリ側が名前を決める場面で使う。
///
/// 順位は一般に公開されている姓の多さの目安にもとづく並びで、
/// 厳密な統計値ではない（ゲーム内の名前プールとしての用途）。
const List<String> kCommonSurnames = [
  '佐藤', '鈴木', '高橋', '田中', '伊藤', '渡辺', '山本', '中村', '小林', '加藤',
  '吉田', '山田', '佐々木', '山口', '松本', '井上', '木村', '林', '斎藤', '清水',
  '山崎', '森', '池田', '橋本', '阿部', '石川', '山下', '中島', '石井', '小川',
  '前田', '岡田', '長谷川', '藤田', '後藤', '近藤', '村上', '遠藤', '青木', '坂本',
  '斉藤', '福田', '太田', '西村', '藤井', '金子', '岡本', '藤原', '中野', '三浦',
  '原田', '中川', '松田', '竹内', '小野', '田村', '中山', '和田', '石田', '森田',
  '上田', '原', '柴田', '酒井', '工藤', '横山', '宮崎', '宮本', '内田', '高木',
  '安藤', '島田', '谷口', '大野', '高田', '丸山', '今井', '河野', '藤本', '村田',
  '武田', '上野', '杉山', '增田', '小島', '平野', '大塚', '千葉', '久保', '松井',
  '岩崎', '桜井', '木下', '野口', '松尾', '菊地', '野村', '新井', '渡部', '佐野',
];

/// 🇺🇸 英語版のおまかせ命名につかう名前（US SSA 実在の上位100）。
///
/// 日本語のときは苗字＋さん、英語のときはファーストネームで呼ぶ。
/// 「人の名前を覚える」練習として、現実の頻出名を載せる。
const List<String> kCommonEnglishNames = [
  'James', 'Mary', 'Robert', 'Patricia', 'John', 'Jennifer',
  'Michael', 'Linda', 'David', 'Elizabeth', 'William', 'Barbara',
  'Richard', 'Susan', 'Joseph', 'Jessica', 'Thomas', 'Sarah',
  'Christopher', 'Karen', 'Charles', 'Lisa', 'Daniel', 'Nancy',
  'Matthew', 'Betty', 'Anthony', 'Margaret', 'Mark', 'Sandra',
  'Donald', 'Ashley', 'Steven', 'Dorothy', 'Andrew', 'Kimberly',
  'Paul', 'Emily', 'Joshua', 'Donna', 'Kenneth', 'Michelle',
  'Kevin', 'Carol', 'Brian', 'Amanda', 'George', 'Melissa',
  'Timothy', 'Deborah', 'Ronald', 'Stephanie', 'Edward', 'Rebecca',
  'Jason', 'Sharon', 'Jeffrey', 'Laura', 'Ryan', 'Cynthia',
  'Jacob', 'Kathleen', 'Gary', 'Amy', 'Nicholas', 'Angela',
  'Eric', 'Shirley', 'Jonathan', 'Brenda', 'Stephen', 'Emma',
  'Larry', 'Anna', 'Justin', 'Pamela', 'Scott', 'Nicole',
  'Brandon', 'Samantha', 'Benjamin', 'Katherine', 'Samuel', 'Christine',
  'Raymond', 'Helen', 'Gregory', 'Debra', 'Frank', 'Rachel',
  'Alexander', 'Carolyn', 'Patrick', 'Janet', 'Jack', 'Maria',
  'Dennis', 'Catherine', 'Jerry', 'Heather', 'Tyler', 'Diane',
];

/// ロケールに応じた名前プールを返す。
List<String> commonNamePool(bool ja) =>
    ja ? kCommonSurnames : kCommonEnglishNames;

/// 名前を表示用に整える（日本語なら「佐藤さん」、英語ならそのまま）。
String formatNameForLocale(String name, bool ja) =>
    ja ? '$nameさん' : name;

/// 苗字に敬称をつけた表示名（「佐藤さん」）。
/// 英語ロケールでは Mr./Ms. を使わず苗字のみにする（性別を仮定しないため）。
String surnameWithHonorific(String surname, bool ja) =>
    ja ? '$surnameさん' : surname;
