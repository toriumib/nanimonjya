# ペタネーム (PetaName)

顔と名前の記憶トレーニングアプリ（顔カード×名前カードの神経衰弱）。
Android (Google Play: `com.nanimonjya` ※内部IDは互換維持、表示名は「ペタネーム」) とWeb (Vercel / Firebase Hosting) で配信。

**v2.0.0で全面ピボット**: 旧「名づけ神経衰弱」ルール・旧名称は全廃。他ボードゲームを想起させる名称・文言・イラストは使わないこと。

## プロジェクト構成
- `lib/screens/` — top / player_selection（モード選択）/ match_game（ゲーム本体）/ match_result（CPU対戦結果）/ training_report（特訓レポート）/ memory_tips（記憶術読み物）/ cognitive_info / tutorial / profile
- `lib/models/` — `person.dart`（顔SVG×名前×趣味の人物生成、毎回ランダム組合せ）, `cpu_rank.dart`（段位）, `achievement.dart`, `cosmetics.dart`
- `lib/services/` — `player_profile.dart`（コイン/実績/段位レーティング等のローカル保存, ChangeNotifier singleton）, `ad_ids.dart`, `app_analytics.dart`, `daily_reminder.dart`（19時通知）
- `lib/l10n/` — arb + 自動生成。メタ機能の文言は `meta_strings.dart`、記憶術コンテンツは `memory_tips.dart`
- `assets/images/faces/` — 自前生成のオリジナル顔SVG12種（外部イラストは使用禁止）

## ゲームルール（v2.0.0）
- おぼえタイム（人物プロフィール表示・記銘）→ カード裏返し → 顔と名前のペア当て（想起）
- 一人特訓: レベル1/2/3 = 4/6/8ペア。Lv3は趣味ボーナスクイズ付き。手数・タイムでスコア化
- 記憶術トレーニング: おぼえタイムにタグ付けガイドを表示する特訓モード
- CPU対戦: 交互めくり・ペア成立で連続手番・獲得ペア数勝負。難易度4段階（easy/normal/hard/oni、oniはレート1500で解禁）
- オンライン対戦・ランキング・珍名アルバムは撤去済み（旧コードは削除）。再実装時は新ルールで

## ビルド・リリース
- **Android**: `scripts/bump_and_build.ps1`（versionCode自動+1してAABビルド）。出力: `build/app/outputs/bundle/release/app-release.aab`
- 署名: `android/app/key.properties`（gitignore対象・ローカルPCのみ。keystoreは `key.jks`）
- **Web**: `flutter build web --release` → Vercel (`vercel deploy --prod` in build/web) / Firebase Hosting
- `web/app-ads.txt` はAdMob審査用。ビルドで build/web に自動コピーされる。消さないこと

## 重要な決まりごと
- versionCode は必ずbumpスクリプトを使う（Play Consoleで重複拒否）
- AdMob本番ID: App `ca-app-pub-6744940157577324~1059924160`, Banner `/4880687935`, Rewarded `/9009716197`（`lib/services/ad_ids.dart`で管理。デバッグ時は自動でテストID）
- `dart:io` の `Platform` は使用禁止（Webでクラッシュ）。`kIsWeb`/`defaultTargetPlatform` を使う
- 広告関連は全て `kIsWeb` ガード必須（google_mobile_adsはWeb非対応）
- 医療・認知機能への効果は断定表現禁止。「〜と言われている」「〜が期待される」等のヘッジ表現＋免責を守る（`meta_strings.dart` の `cognitiveDisclaimer` 参照）
- 記憶術コンテンツ（`memory_tips.dart`）は完全オリジナル文章。外部記事のコピー禁止
- targetSdk 35 / NDK 27.0.12077973（16KBページサイズ対応）を維持
- 日本語Windows環境: PowerShellでのファイル読み書きは .NET の UTF8Encoding を明示（Get/Set-ContentはUTF-8を破壊する）
- フォント: ロゴ=Mochiy Pop One、本文=Zen Maru Gothic（google_fonts経由）

## 残タスク（要ユーザー対応）
- ランチャーアイコン・ストアのフィーチャーグラフィック（`store_assets/*.png`）が旧ブランドのまま → 新デザインへの差し替えが必要
- Firestoreの旧 `rooms`/`rankings` コレクションとCloud Functions（Gemini名前生成/TTS）は新ルールでは未使用 → 課金抑止のため無効化を検討
