# ナニモンジャ (Nanimonja)

名付け神経衰弱カードゲームのFlutterアプリ。Android (Google Play: `com.nanimonjya`) とWeb (Firebase Hosting: nanimonjya.web.app / Vercel) で配信。

## プロジェクト構成
- `lib/screens/` — 画面（top / player_selection / game = オフライン, online_game_lobby / online_game = オンライン, result, profile）
- `lib/services/` — `player_profile.dart`（コイン/実績/称号/きせかえ等のローカル保存, ChangeNotifier singleton）, `ad_ids.dart`（広告ID一元管理）, `reward_ad_helper.dart`, `sfx.dart`
- `lib/models/` — `achievement.dart`, `cosmetics.dart`（きせかえテーマ・称号・応援わんちゃんのカタログ）
- `lib/widgets/dog_squad.dart` — バトル画面の応援わんちゃん（累計コインで増える）
- `lib/l10n/` — arb + 自動生成。新規メタ機能の文言は `meta_strings.dart`（arb非依存の自己完結ヘルパー）
- `function/` — Cloud Functions（Gemini名前生成 `generateSimilarNames`, TTS `synthesizeSpeech`）
- オンライン対戦はFirestore `rooms/{roomId}` ドキュメントで状態同期

## ビルド・リリース
- **Android**: `scripts/bump_and_build.ps1`（versionCodeを自動+1してAABビルド）または `release.bat`。出力: `build/app/outputs/bundle/release/app-release.aab`
- 署名: `android/app/key.properties`（**gitignore対象・リポジトリに無い**。ローカルPCにのみ存在。keystoreは `key.jks`）→ クラウド環境ではリリース署名ビルド不可、コード変更とWebビルドのみ可能
- **Web**: `flutter build web --release` → Firebase Hosting (`firebase deploy --only hosting`) / Vercel (`vercel deploy --prod` in build/web)
- `web/app-ads.txt` はAdMob審査用。ビルドで build/web に自動コピーされる。消さないこと

## 重要な決まりごと
- versionCode はPlay Consoleで既に~57まで使用済み。必ずbumpスクリプトを使う
- AdMob本番ID: App `ca-app-pub-6744940157577324~9444754212`, Banner `/4880687935`, Rewarded `/9009716197`（`lib/services/ad_ids.dart`で管理。デバッグ時は自動でテストID）
- `dart:io` の `Platform` は使用禁止（Webでクラッシュ）。`kIsWeb`/`defaultTargetPlatform` を使う
- 広告関連は全て `kIsWeb` ガード必須（google_mobile_adsはWeb非対応）
- アプリ内表記は「ナニモンジャ」で統一（「ナンジャモンジャ」は商標配慮で使わない）
- リザルトBGMは魔王魂「シャイニングスター」(`assets/audio/shining_star.mp3`)。クレジット表記必須
- targetSdk 35 / NDK 27.0.12077973（16KBページサイズ対応）を維持
- 日本語Windows環境: PowerShellでのファイル読み書きは .NET の UTF8Encoding を明示（Get/Set-ContentはUTF-8を破壊する）

## オンライン対戦の設計メモ
- カード送りは `displayDelayCompleteTimestamp`（2秒の記憶タイム）後、全クライアントが `_advanceCardAfterDelay` を試行し、トランザクション内ガードで1回だけ実行される
- AI選択肢は命名時に事前生成して `characterChoices` マップ（画像URL→偽名リスト）に保存。表示時はそこから即時構築、無ければローカル生成にフォールバック
- `_choicesForCard` でどのカード用の選択肢かを追跡（毎スナップショットでのクリア禁止 — 無限再生成ループになる）
