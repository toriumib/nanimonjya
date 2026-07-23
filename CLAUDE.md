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

## ゲームルール（v2.1.0）

### メインモード「なまえコール」（name_call_screen.dart / models/name_call.dart）
- 命名ルール2種（ホームで切替）: **まとめて命名**（①全員に先に命名→②名簿封印→③想起）と **出たとき命名**（`nameAsYouGo`。1枚ずつ登場し初対面はその場命名=無得点、再登場で想起=得点。従来ナンジャモンジャ式）
- 出現枚数: 基本1枚／`doubleCard`で2枚同時＝りょうどり（まとめて命名時のみ）。出たとき命名は常に1枚
- 登場人数は6/9/12から選択（デフォルト12）。名前を思い出せたら獲得・外すと没収 → 獲得枚数勝負
- 顔はフリー素材のキャラ画像（char*.jpg、`generateImagePeople`）。描画は`widgets/face_view.dart`のFaceViewでsvg/画像/アップロードファイルを統一処理
- 回答方式: ひとり/オンライン=自分の名簿からの4択＋10秒制限。**オフラインみんなで=審判方式**（顔を見て一斉に名前を呼び、早かった人のP1..PNボタンをタップ→カードごとに獲得。`_isReferee`）
- ひとり／1台で2〜4人／オンライン同時レース対応。終了時に名簿公開
- UIは下部タブ（home_shell.dart）: なまえコール／ペアさがし／とっくん／マイページ

### おぼえる（自分の写真）（custom_roster_screen.dart / study_screen.dart / services/custom_roster_service.dart）
- image_picker で顔写真＋名前を登録。写真はアプリのドキュメントディレクトリ配下 custom_faces/ にコピーし、メタデータをSharedPreferencesにJSON保存（モバイル限定、kIsWebガード）
- 登録した名簿で: フラッシュカード学習／確認テスト（4択）／なまえコール対戦（オフライン審判方式）
- 想定用途: 職場・学校で新しく出会う人の顔と名前を覚える

### とっくんの主役「思い出しトレーニング」（recall_training_screen.dart）
- 実生活の「この人だれだっけ？」を再現する想起特訓。とっくんタブ（training_hub_screen.dart）の先頭カード
- フロー: ①**であう**（実写char*.jpgの顔＋体を1人ずつ、名前・出会った場所[Person.where]・趣味とともに記銘）→ ②**時間がたつ**（間をおく画面。すぐ答えさせない）→ ③**思い出す**（顔を見て名前を4択想起、出会った場所がヒント）→ 結果＋おさらい
- `models/person.dart` の `generateRecallPeople(count, ja)` で実写＋名前＋出会った場所（`_metContextJa/En`）を生成。顔は必ず実写（FaceKind.asset）で「リアルな顔と体」を出す
- 記録は `recordSoloTraining`、コインは思い出せた人数×8（＋全問正解ボーナス20）

### サブモード「ペアさがし」（match_game_screen.dart）
- おぼえタイム（人物プロフィール表示・記銘）→ カード裏返し → 顔と名前のペア当て（想起）
- 一人特訓: レベル1/2/3 = 4/6/8ペア。Lv3は趣味ボーナスクイズ付き。手数・タイムでスコア化
- 記憶術トレーニング: おぼえタイムにタグ付けガイドを表示する特訓モード
- CPU対戦: 交互めくり・ペア成立で連続手番・獲得ペア数勝負。難易度4段階（easy/normal/hard/oni、oniはレート1500で解禁）
- みんなで対戦（ローカル）: 1台を回して2〜4人の交互手番（`MatchGameScreen(humanPlayers: N)`）
- オンライン対戦（v2.1.0で復活）: **同時レース方式**。同じseedを配布して両者が同一盤面を同時に解き、手数（同数ならタイム）で勝敗。Firestore `rooms` を再利用し、書き込みは進捗と最終結果のみ（ターン同期なし）。旧Functionsトリガーは `readyPlayerIds`/`imageUrls` が無いので発火しない。ロビーはランダムマッチ＋合言葉6文字
- 珍名アルバム・旧ランキング画面は撤去のまま

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
- デプロイ済みの旧Cloud Functions（generateSimilarNames/synthesizeSpeech/startGameOnPlayerCount）の削除: `firebase login` 後に `firebase deploy --only functions --force`（ローカルの `function/index.js` は空にしてある）
- App Check強制化はFirebaseコンソール作業（v2.1.0が行き渡ってから）
- `firestore.rules` はデプロイ済みのまま変更していない（新オンラインは既存ルールの範囲内で動作する設計）。`funnyNames`/`rankings` のルールは残っているが実害なし
