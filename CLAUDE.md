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

### 「ビジネス特訓」＝旧とっくん（tabTraining / recallTitle）
- v2.2.0でタブ名・画面タイトルを「ビジネス特訓」に改名（旧「とっくん」）。他モード（なまえコール／ペアさがし／おぼえる）の名称・UIは変更なし
- 実体は下記の「思い出しトレーニング」＋一人特訓（ペアさがしベース）＋記憶術トレーニングをまとめた training_hub_screen.dart

### 思い出しトレーニング（recall_training_screen.dart、ビジネス特訓の主役）
- 実生活の「この人だれだっけ？」を再現する想起特訓。とっくんタブ（training_hub_screen.dart）の先頭カード
- フロー: ①**であう**（実写char*.jpgの顔＋体を1人ずつ。**名刺を差し出す演出＋ふきだし「私は○○と申します。」＋TTS音声**で自己紹介。出会った場所[Person.where]・趣味も記銘）→ ②**時間がたつ**（間をおく画面。研究ベースTipsを出典つきで表示）→ ③**思い出す**（顔を見て名前を4択想起、出会った場所がヒント）→ 結果＋おさらい
- `models/person.dart` の `generateRecallPeople(count, ja)` で実写＋名前＋出会った場所（`_metContextJa/En`）を生成。顔は必ず実写（FaceKind.asset）で「リアルな顔と体」を出す
- **名刺**: であうフェーズは名刺を差し出す演出。会社名・氏名・肩書・電話・メール（すべて架空、`generateRecallPeople`が生成。会社名は造語パーツ2つ＋業種語尾、メールは架空ドメイン、電話はダミー）を表示。アップロードした実物名刺画像があればそれを表示
- **音声**: `services/speech.dart`（flutter_tts）。`introduce(bareName, company, title)`で「{会社}の{名前}と申します。{肩書}をしております。」をja-JP/en-US読み上げ。敬称なし苗字。入場時自動＋🔊再生。AndroidManifestに`TTS_SERVICE`のqueries追加済み
- **クイズ項目**: `RecallField`(name/company/title/phone/email)。デフォルト{name, company}、hubのチップでオプション追加。recall_trainingは項目別クイズに一般化（(person,field)ごとに4択、値が空の項目は出題しない）
- **実物名刺＋顔写真アップロード**: `custom_roster_service`のCustomEntryに company/title/phone/email/cardImagePath 追加（JSONは旧v1後方互換）。custom_roster_screenの登録フォームで顔写真＋各項目＋名刺画像を入力。「🧠 名刺で思い出しクイズ」で`RecallTrainingScreen(people: 名簿, fields: 存在する項目)`を起動。ビジネス実用向け
- 記録は `recordSoloTraining`、コインは正解数×8（＋全問正解ボーナス20）

### 記憶術Tips（l10n/memory_tips.dart）
- `kMemoryShortTips`（一般Tips）＋`kNameScienceTips`（**研究ベース・出典つき**。MemoryShortTip.source）。読み物`kMemoryTipPages`にも「研究が言う名前のコツ①②」を出典つきで追加
- 出典は名前記憶の代表研究（Roediger & Karpicke 2006, Morris/Fritz 2005, MacLeod 2010, Craik & Tulving 1975, McWeeny 1987ベイカー錯誤, Rogers 1977自己関連づけ, Morris/Jones/Hampson 1978, DeGutis 2024）。本文は断定回避のオリジナル要約
- 表示先: ワンポイントticker（memory_tip_ticker）＋思い出しトレーニングの待ち時間/おさらい（`_tipCard`）

### 🛍 キャラクターショップ（character_shop_screen.dart / models/character_catalog.dart）
- 追加キャラ20種（`kExtraCharacters`、id: c13〜c32）をコインで購入できるショップ。画像は `assets/images/char13.webp`〜`char32.webp`（ユーザー提供の実写、価格帯120〜340コイン）
- 購入状態は `PlayerProfile.unlockedCharacters`（Set\<String\>、SharedPreferences永続化）、購入APIは `PlayerProfile.unlockCharacter(id, cost)`
- 購入したキャラは「なまえコール」（オフライン/ひとりのみ。オンライン対戦は両者の顔一致が必要なため基本12人のまま）と「思い出しトレーニング」の出演プールに追加（`generateImagePeople`/`generateRecallPeople` の `charAssets` 引数、`unlockedExtraAssets()`で解決）
- ショップ画面には: コイン残高／🎁動画でコイン+60（RewardAdHelper）／⭐アプリ評価（in_app_review, `services/review_prompt.dart`と共通ロジック）／購入グリッド／基本12人の一覧
- マイページ（profile_screen.dart）に常設の「🛍 キャラクターショップ」ボタンあり
- **試合・特訓の結果画面**（match_result / local_result / online_result / recall_training の各result）に `widgets/store_cta.dart` の `StoreCtaCard`（「新しいキャラを仲間にしよう→ショップへ」誘導）を配置
- レビュー依頼: `services/review_prompt.dart` の `maybeAskReview()`（1回きり、`reviewPrompted`でゲート）。勝利・全問正解などの好タイミングで呼ぶ。match_result側は従来通り閾値3ゲームで直接呼び出し

### 💰 収益導線（広告・課金の再点検、v2.3.0）
- **インタースティシャル広告を有効化**（`services/interstitial_ad_helper.dart`。3プレイに1回、リザルト画面で表示）。main.dartで先読みを開始し、match_result/local_result/online_result/recall_trainingの各`initState`/終了処理で`InterstitialAdHelper.instance.onGameFinished()`を呼ぶ。以前はコード実装のみで呼び出しが無く完全に無効化されていた（なぜなぜ分析の結論: 収益ポイントがユーザーの感情が一番盛り上がる「結果が出た直後」に配置されていなかったことが根本原因）
- **「動画でコイン2倍」ボタン**（`widgets/double_coins_button.dart`）を全リザルト画面の獲得コイン表示直後に設置。獲得コインが0の結果では非表示。リワード広告の視聴率が最も高い定番配置
- 無料コインギフト（top_screen.dart）のクールダウンを30分→15分に短縮（`PlayerProfile.giftCooldownMinutes`）。ショップの動画報酬は50→60コインに増額済み

### 🌌 覚醒（プレステージ）システム（v2.3.0、無限リプレイ性）
- 段位（cpuRating）は鬼段位到達後も伸ばせるが、目標が尽きる問題への対策。`PlayerProfile.canAwaken`（鬼段位帯=`kCpuRanks.last.minRating`以上 かつ `cpuOniWins >= 3`）で解放
- `PlayerProfile.awaken()`: レーティングを1000にリセットし`awakenings`を+1。`coinMultiplier`（1.0 + awakenings*0.05、上限なし）が`_addCoins`と`claimMission`の全コイン獲得に自動適用される永続ボーナス
- UI: profile_screen.dartの「🌌 覚醒」カード（統計カードの直後）。確認ダイアログを挟んで実行、1回きりでなく何度でも繰り返せる
- `models/cpu_rank.dart`に`rankLabelWithAwakenings()`ヘルパーあり（段位表示に覚醒回数バッジを付けたい場合に使用。現状はプロフィール画面のみ表示、結果画面の段位表示には未適用）
- テストは `test/player_profile_test.dart`（SharedPreferences.setMockInitialValuesでモック。シングルトンのload()は初回のみ実行される点に注意し、setUpでフィールドを直接リセットしている）

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
