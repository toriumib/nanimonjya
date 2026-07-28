import 'package:characters/characters.dart'; // 絵文字・全角を1文字として数えるため
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// 📇 名刺画像から文字を読み取って、フォームの各項目を推測する。
///
/// ML Kit の文字認識は**端末内で完結**するので、名刺の中身が外部へ送られることは
/// ない（実在の個人情報を扱う機能なので、これは重要な性質）。
///
/// 注意: 完璧な解析は狙わない。名刺のレイアウトは千差万別なので、
/// **入力を空欄から始めなくて済む**ところまでを目標にし、
/// 最後は必ず人が直せるようフォームに流し込む。
class CardOcrResult {
  final String name;
  final String company;
  final String title;
  final String phone;
  final String email;

  /// 認識できた生テキスト（どこにも当てはめられなかった行の確認用）。
  final List<String> lines;

  const CardOcrResult({
    this.name = '',
    this.company = '',
    this.title = '',
    this.phone = '',
    this.email = '',
    this.lines = const [],
  });

  bool get isEmpty =>
      name.isEmpty &&
      company.isEmpty &&
      title.isEmpty &&
      phone.isEmpty &&
      email.isEmpty;
}

class CardOcrService {
  CardOcrService._();
  static final CardOcrService instance = CardOcrService._();

  /// 日本語名刺が主対象なので japanese スクリプトを使う
  /// （ラテン文字も同時に拾えるため、英語表記の会社名やメールも読める）。
  TextRecognizer? _recognizer;

  /// この端末でOCRが使えるか（Webは非対応）。
  static bool get available => !kIsWeb;

  Future<CardOcrResult> scan(String imagePath) async {
    if (!available) return const CardOcrResult();
    _recognizer ??= TextRecognizer(script: TextRecognitionScript.japanese);
    try {
      final input = InputImage.fromFilePath(imagePath);
      final result = await _recognizer!.processImage(input);
      final lines = <String>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          final t = line.text.trim();
          if (t.isNotEmpty) lines.add(t);
        }
      }
      return _extract(lines);
    } catch (e) {
      debugPrint('card OCR failed: $e');
      return const CardOcrResult();
    }
  }

  /// 認識した行から各項目を推測する。
  ///
  /// 使っている手がかり:
  /// - メール: @ を含む行
  /// - 電話: 数字とハイフンが主体で、桁数が電話番号らしい行
  /// - 会社: 法人格（株式会社・有限会社・Inc. など）を含む行
  /// - 肩書: 役職語（部長・課長・代表・Manager など）を含む行
  /// - 氏名: 残った行のうち、短くて記号を含まないもの
  @visibleForTesting
  CardOcrResult extractForTest(List<String> lines) => _extract(lines);

  CardOcrResult _extract(List<String> lines) {
    String email = '';
    String phone = '';
    String company = '';
    String title = '';
    String name = '';

    // 氏名候補の判定から外すため、使った行を記録する
    final used = <int>{};

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      // --- メール ---
      if (email.isEmpty) {
        final m = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+').firstMatch(line);
        if (m != null) {
          email = m.group(0)!;
          used.add(i);
          continue;
        }
      }
      // --- 電話（FAXは除く） ---
      if (phone.isEmpty && !RegExp(r'fax|ＦＡＸ', caseSensitive: false).hasMatch(line)) {
        final digits = line.replaceAll(RegExp(r'[^0-9]'), '');
        // 日本の電話番号はおおむね10〜11桁。国際表記も拾えるよう幅を持たせる
        if (digits.length >= 9 &&
            digits.length <= 13 &&
            RegExp(r'^[0-9+\-()\s.ｰ―−‐上下TELtel電話：:]+$').hasMatch(line)) {
          phone = RegExp(r'[0-9+][0-9+\-()\s.]*').firstMatch(line)?.group(0)?.trim() ?? '';
          if (phone.isNotEmpty) {
            used.add(i);
            continue;
          }
        }
      }
      // --- 会社名（法人格を含む行） ---
      if (company.isEmpty &&
          RegExp(r'株式会社|有限会社|合同会社|一般社団|財団|\bInc\.?\b|\bCorp\.?\b|\bLtd\.?\b|\bLLC\b|\bCo\.,?',
                  caseSensitive: false)
              .hasMatch(line)) {
        company = line;
        used.add(i);
        continue;
      }
      // --- 肩書（役職語を含む行） ---
      if (title.isEmpty &&
          RegExp(r'代表|取締役|社長|部長|課長|係長|主任|マネージャー|リーダー|エンジニア|ディレクター|プロデューサー|顧問|\bCEO\b|\bCTO\b|\bCOO\b|\bManager\b|\bDirector\b|\bEngineer\b|\bPresident\b',
                  caseSensitive: false)
              .hasMatch(line)) {
        title = line;
        used.add(i);
        continue;
      }
    }

    // --- 氏名: 残りの行から「短くて記号のない行」を選ぶ ---
    // 名刺は氏名がいちばん大きく書かれるが、行の高さ情報まで見ると複雑になるので、
    // ここでは「短い・記号なし・数字なし」という単純な条件で拾う。
    for (var i = 0; i < lines.length; i++) {
      if (used.contains(i)) continue;
      final line = lines[i].replaceAll(RegExp(r'\s+'), ' ').trim();
      if (line.isEmpty) continue;
      if (RegExp(r'[0-9@#/｜|]').hasMatch(line)) continue;
      if (line.characters.length > 12) continue;
      // 住所っぽい行は除く
      if (RegExp(r'都|道|府|県|市|区|町|村|丁目|番地|〒').hasMatch(line)) continue;
      name = line;
      break;
    }

    return CardOcrResult(
      name: name,
      company: company,
      title: title,
      phone: phone,
      email: email,
      lines: lines,
    );
  }

  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
