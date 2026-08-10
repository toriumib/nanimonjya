/// 🤖 AIクローン — 自分の顔・声・話し方を登録して、AIの自分が名刺を渡す。
///
/// 流れ:
/// 1. 自撮り or 写真選択 → FaceKind.file で保存
/// 2. アバター自動提案（肌の色・髪型・メガネを選ぶだけでOK）
/// 3. 声の録音（10秒）→ 録音ファイルを保持
/// 4. TTSで名乗る自己紹介を設定
/// 5. CustomRosterEntry として名簿に追加
///
/// 相手は RecallTraining でこのAIに出会い、名刺をもらう。
/// 「自分そっくりのAIが自己紹介してくれる」体験。
library;

import 'dart:convert';
import 'avatar.dart';

class AiClonePersona {
  /// 話し方のタイプ。
  final String style;   // 'genki' | 'shinshi' | 'sensei' | 'cool' | 'natural'
  /// よく使う口癖（3語まで）。
  final List<String> catchphrases;
  /// 自己紹介の一言（自由入力）。
  final String greeting;
  /// 録音した音声ファイルのパス（なければTTSで代用）。
  final String? voicePath;
  /// ベースのアバター。
  final Avatar avatar;

  const AiClonePersona({
    required this.style,
    this.catchphrases = const [],
    required this.greeting,
    this.voicePath,
    required this.avatar,
  });

  Map<String, dynamic> toJson() => {
    'style': style,
    'catchphrases': catchphrases,
    'greeting': greeting,
    'voicePath': voicePath,
    'avatar': avatar.encode(),
  };

  factory AiClonePersona.fromJson(Map<String, dynamic> json) => AiClonePersona(
    style: json['style'] as String? ?? 'natural',
    catchphrases: (json['catchphrases'] as List<dynamic>?)
        ?.cast<String>() ?? const [],
    greeting: json['greeting'] as String? ?? '',
    voicePath: json['voicePath'] as String?,
    avatar: Avatar.decode(json['avatar'] as String? ?? '{}'),
  );
}

/// 話し方の選択肢。
const Map<String, Map<String, String>> kAiStyles = {
  'natural': {'ja': 'ふつう', 'en': 'Natural'},
  'genki':   {'ja': '元気いっぱい', 'en': 'Energetic'},
  'shinshi': {'ja': '物腰やわらか', 'en': 'Gentle'},
  'sensei':  {'ja': 'おだやか先生', 'en': 'Wise'},
  'cool':    {'ja': 'クール', 'en': 'Cool'},
};

/// 口癖の候補。
const Map<String, List<String>> kCatchphraseOptions = {
  'natural': ['なるほど', 'たしかに', 'そうそう', 'I see', 'Right?', 'Exactly'],
  'genki':   ['やったー！', 'いいね！', 'さいこー！', 'Awesome!', "Let's go!", 'Woohoo!'],
  'shinshi': ['おや', 'なるほど', '失礼します', 'Indeed', 'I see', 'Pardon me'],
  'sensei':  ['ふむ', 'なるほど', 'そうですね', 'Hmm', 'Indeed', 'I agree'],
  'cool':    ['ふーん', 'まあね', 'いいね', 'Cool', 'Sure', 'Nice'],
};

/// TTSで読む自己紹介テキストを生成。
String buildAiIntroduction({
  required String name,
  required String style,
  required String greeting,
  required bool ja,
}) {
  final base = ja
      ? 'こんにちは、$name です。'
      : 'Hi, I\'m $name.';
  if (greeting.isNotEmpty) return '$base $greeting';
  return base;
}

/// AIクローンの「話し方」に応じたTTS向けピッチ・レート調整。
({double pitch, double rate}) voiceParams(String style) => switch (style) {
  'genki'   => (pitch: 1.2, rate: 0.52),
  'shinshi' => (pitch: 0.85, rate: 0.42),
  'sensei'  => (pitch: 0.95, rate: 0.40),
  'cool'    => (pitch: 0.8, rate: 0.45),
  _         => (pitch: 1.0, rate: 0.48),
};
