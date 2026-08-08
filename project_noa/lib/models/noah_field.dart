/// SPEC 4.1 — キャラクターと、その「覚える項目」。
library;

/// 覚える項目。3択のクイズはこの単位で出す。
///
/// ⚠️ ここに項目を足すと、記憶率（4.3）の分母が変わる。
///    セーブ済みのデータは `memory` に `"hibino.hobby": true` の形で
///    入っているので、**既存の名前は変えないこと**。
enum NoahField {
  name,
  affiliation,
  hobby,
  commId,
  school;

  String get labelJa => switch (this) {
        NoahField.name => '名前',
        NoahField.affiliation => '所属',
        NoahField.hobby => '趣味',
        NoahField.commId => '通信ID',
        NoahField.school => '学生時代',
      };

  /// セーブに書くときのキー（`hibino.hobby` の後ろ半分）。
  ///
  /// ⚠️ `name` は enum の値そのもの（NoahField.name）と紛らわしいので
  ///    使わない。`Enum.name` を明示して文字列を取る。
  String get key => switch (this) {
        NoahField.name => 'name',
        NoahField.affiliation => 'affiliation',
        NoahField.hobby => 'hobby',
        NoahField.commId => 'commId',
        NoahField.school => 'school',
      };

  /// 文字列からの復元（シナリオJSONの `"field": "hobby"` を読むため）。
  static NoahField? fromKey(String k) {
    for (final f in NoahField.values) {
      if (f.key == k) return f;
    }
    return null;
  }
}

/// 登場人物1人ぶん。`assets/characters.json` が正データ。
class NoahCharacter {
  final String id;
  final String name;
  final String reading;
  final String affiliation;
  final String hobby;
  final String commId;
  final String school;

  /// 過去のやり直し（STORY 5.1「止まっている場所」）。
  final String regret;

  /// 何周目で出るか。0=所長（恋愛対象外）、1=1周目、2=2周目、3=脇。
  final int cast;
  final bool romance;

  /// 立ち絵が無いときの色と絵文字（プレースホルダに使う）。
  final int color;
  final String emoji;

  const NoahCharacter({
    required this.id,
    required this.name,
    required this.reading,
    required this.affiliation,
    required this.hobby,
    required this.commId,
    required this.school,
    required this.regret,
    required this.cast,
    required this.romance,
    required this.color,
    required this.emoji,
  });

  factory NoahCharacter.fromJson(Map<String, dynamic> j) {
    String s(String k) => (j[k] as String?) ?? '';
    return NoahCharacter(
      id: s('id'),
      name: s('name'),
      reading: s('reading'),
      affiliation: s('affiliation'),
      hobby: s('hobby'),
      commId: s('commId'),
      school: s('school'),
      regret: s('regret'),
      cast: (j['cast'] as num?)?.toInt() ?? 3,
      romance: (j['romance'] as bool?) ?? false,
      // JSON には "0xFFE8663C" の形の文字列で入っている
      color: int.tryParse(s('color')) ?? 0xFF888888,
      emoji: s('emoji').isEmpty ? '🙂' : s('emoji'),
    );
  }

  /// 項目の値を引く。3択の正解・誤答はここから作る。
  String valueOf(NoahField f) => switch (f) {
        NoahField.name => name,
        NoahField.affiliation => affiliation,
        NoahField.hobby => hobby,
        NoahField.commId => commId,
        NoahField.school => school,
      };

  /// 記憶率のキー（例: `hibino.hobby`）。
  String memoryKey(NoahField f) => '$id.${f.key}';
}

/// 全キャラクター。`CharacterRepository.load()` が作る。
class NoahCast {
  final List<NoahCharacter> all;
  const NoahCast(this.all);

  NoahCharacter? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// 恋愛対象（周回で解禁される8人）。
  List<NoahCharacter> get romanceable =>
      [for (final c in all) if (c.romance) c];

  /// 記憶率の分母。**出しうる (キャラ, 項目) の総数**（SPEC 4.3）。
  int get totalPairs => all.length * NoahField.values.length;
}
