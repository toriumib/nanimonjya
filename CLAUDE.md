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
- 命名ルール2種（ホームで切替）: **出たとき命名**（`nameAsYouGo`。**v2.4.0でこちらが既定**。1枚ずつ登場し初対面はその場命名=無得点、再登場で想起=得点）と **まとめて命名**（①全員に先に命名→②名簿封印→③想起）
- まとめて命名には `autoNames` オプション（🎲名前はおまかせ）。1人ずつ入力せず、おなまえガチャで重複しない名前を自動付与して本編へ
- 出現枚数: 基本1枚／`doubleCard`で2枚同時＝りょうどり（まとめて命名時のみ）。出たとき命名は常に1枚
- 登場人数は6/9/12から選択（デフォルト12）。名前を思い出せたら獲得・外すと没収 → 獲得枚数勝負
- 🎵 BGMは `services/bgm.dart` の `Bgm.instance` に一元化。**各画面が `setAsset(selectedBgm)` と素のファイル名を渡していたため、実アセットキー `assets/audio/<名前>` と一致せず全プラットフォームでBGMが無音だった**（v2.4.0で修正）。`kIsWeb` ガードも撤去しWebでも鳴る。`selectedResultBgm` もどこからも再生されていなかったので各リザルトで `Bgm.instance.playResult()` を呼ぶ
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

### 🛍 ショップ拡張アイテム（models/shop_items.dart、v2.3.0+106）
- **ほめボイス**（`kPraiseVoices`）: 正解・全問正解のときにTTSで褒めてくれる。元気な応援／やさしい先生／執事／熱血コーチ／禅僧。`Speech.praise(ja:, finale:)`で再生
- **お守り**（`kLuckyCharms`、1つだけ装備）: 🍀思い出しのお守り（ヒント強調）／🪙招福こばん（コイン+20%）／🧭絞りこみコンパス（選択肢4→3）／🛡️まちがえ守り（1ゲーム1回だけ誤答を正解あつかい）。効果は`CharmEffect` enumで分岐
- **名刺スキン**（`kCardSkins`）: ビジネス特訓の名刺の配色が変わる（ゴールド／ミッドナイト／サクラ／ミント）
- 保存は PlayerProfile の `unlockedVoices/Charms/Skins` と `selectedVoice/Charm/Skin`。購入は`_buyInto()`共通処理、`coinMultiplier`は覚醒+お守りの加算
- UIは character_shop_screen.dart の `_itemRow()`（買う／装備／試し聞きを1行で扱う共通行）

### 📚 よみものタブ（home_shell.dart、v2.3.0+106）
- 記憶術・研究の読み物を**下部タブに昇格**（なまえコール／ペアさがし／ビジネス特訓／**よみもの**／マイページの5タブ）
- `MemoryTipsScreen(embedded: true)` で表示。embedded時は戻る矢印を出さず、最終ページのボタンは「最初から読む↺」になる

### 記憶術Tips（l10n/memory_tips.dart）
- `kMemoryShortTips`（一般Tips）＋`kNameScienceTips`（**研究ベース・出典つき**。MemoryShortTip.source）。読み物`kMemoryTipPages`にも「研究が言う名前のコツ①②」を出典つきで追加
- 出典は名前記憶の代表研究（Roediger & Karpicke 2006, Morris/Fritz 2005, MacLeod 2010, Craik & Tulving 1975, McWeeny 1987ベイカー錯誤, Rogers 1977自己関連づけ, Morris/Jones/Hampson 1978, DeGutis 2024）。本文は断定回避のオリジナル要約
- **睡眠・意識の読み物（v2.3.0+106で追加）**: 「研究が言う名前のコツ③：覚えたら、眠る」（Staresina 2024 TiCS の徐波-スピンドル-リプル連携、Baranwal 2023 の睡眠衛生）／「おまけ①：記憶は残るのに、意識は消える」（Tononi 2024 Neuron、Mashour 2024 Neuron）／「おまけ②：2つの意識理論が正面から戦った」（**Cogitate Consortium 2025 Nature のIIT vs GNWT敵対的検証**）。出典は著者・年・誌名・巻号・doiまで明記
- 表示先: **よみものタブ**（メイン）＋ワンポイントticker（memory_tip_ticker）＋ビジネス特訓の待ち時間/おさらい（`_tipCard`）

### 🛍 キャラクターショップ（character_shop_screen.dart / models/character_catalog.dart）
- 追加キャラ19種（`kExtraCharacters`、id: c14〜c32）をコインで購入できるショップ。画像は `assets/images/char14.webp`〜`char32.webp`（ユーザー提供の実写、価格帯120〜340コイン）
- ⚠️ **c13 は欠番**。一度 `kCharImageAssets` の無料枠へ昇格させたあと取り下げた。IDを使い回すと、以前 c13 を買った人の `unlockedCharacters` が別のキャラを指すので、二度と使わないこと。基本の顔は **15枚**（`NameCallGame.maxPeople` と必ずそろえる）
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
- 珍名アルバムは撤去のまま。**ランキング画面（`ranking_screen.dart`）はランクマッチの導線として復活**

### 🌐 オンライン4モード（services/online_match_service.dart）

`rooms` ドキュメント1つで4つの遊び方を扱う。`mode` の接頭辞が game を表す（`nc`=namecall / `race`=pairs / `rk`=rank / `tp`=turnpairs）。**盤面は共有seedから両端末が同じものを生成する**ので、Firestoreに載せるのは進行だけ。

| game | 方式 | Firestoreに書くもの | 勝敗 | 画面 |
|---|---|---|---|---|
| `namecall` | 同時レース | 進捗・最終結果 | 獲得枚数→タイム | `name_call_screen` |
| `pairs` | 同時レース | 進捗・最終結果 | 手数→タイム | `match_game_screen` |
| `rank` | ロックステップ早押し | `cardIndex` / `claims` | 先取した枚数 | `rank_match_screen` |
| `turnpairs` | ターン制 | `moves`（めくった順） | 獲得ペア数 | `turn_pairs_screen` |

- **フレンドマッチ＝1台で遊ぶときと同じルール**: 部屋に `people`（出てくる人数）を載せ、ホストの設定をゲストにも配る。ランダムマッチは**同じ人数の部屋どうし**だけをマッチさせる（`findRandomMatch` が `people` で絞る）。人数の正規化は `OnlineMatchService.resolvePeople`（rankは8固定・pairs系はペア数固定）
- **🏆 ランクマッチ**: 8人・苗字100（`kCommonSurnames`）から配布・4択・早い者勝ち。同じ問題を両者に同時に出し、正解したら `claimCard(index)` のトランザクションで先取を宣言する（**先にサーバーへ届いた方だけ true**）。誰も取れなければ8秒で `passCard`。勝敗は `RankingService`（`rankings/{uid}`、勝ち+25/負け-15）にも反映＝`OnlineResultScreen(ranked: true)` のときだけ。合言葉での身内対戦は用意しない（ポイント稼ぎ防止）
- **🔁 ターン制対戦**: 記憶術トレーニングの盤面を交互にめくる。部屋には `moves`（カード番号の並び）だけを積み、`models/turn_pairs.dart` の `replayTurnPairs()` で再生して「取れた札・手番・得点」を復元する。**得点や手番を端末ごとに持たない**ので通信が1回抜けても食い違わない。画面側は `_settled`（判定済み）と `_flipping`（表示中の1〜2枚）に分けて、そろわなかった2枚を見せる間をとる
- ⚠️ `OnlineMatchSession` のスナップショット反映は **claims → cardIndex の順**（逆にすると最後の1問の先取が得点に入らない）
- ⚠️ オンラインは購入キャラ・デッキ編集を混ぜない（両端末で顔ぶれが一致しなくなる）。必ず `kCharImageAssets` を渡す
- テストは `test/online_modes_test.dart`（game判別・人数の正規化・ターン制の再生）

### ⚔️ ベータ「なまえバトル」（name_battle_screen.dart / models/battle.dart）

神経衰弱で取った人が、そのまま戦うタワーディフェンス。**覚えたことが強さになる**のが狙い。

- 流れ: 📖名簿 → 🃏神経衰弱 → ⚔️バトル。1人（CPU戦・6人・10回めくり／取り逃した人が敵になる）と、**1台で2人**（8人・交互めくり・だいたい4人ずつ）
- カードの作りは3種類（`BattleCardStyle`）。2人プレイのボタンから選ぶ
  🃏顔札×名札（顔と名前を結びつけていないと取れない）／🂡1枚に顔と名前（トランプ式）／😀顔だけ
- **戦場は縦**。手前(下)が自分、奥(上)が相手。2人プレイは相手側の陣をまるごと180度回して、スマホの両端がそれぞれの持ち場になる
- 能力は**顔ごとに固定**（`kUnitCatalog`）。近距離4種／遠距離2種／タワー狙い1種
- 戦闘は `models/battle.dart` の純粋ロジック（**乱数なし**）。テストは `test/battle_test.dart`

**⚠️ 数値をいじる前に読むこと**（どれも実際に壊れて直した）
- **⚡の回復は取った人数で決まる**（`BattleState.rateFor`）。ここを両者同じにすると、4人取っても2人取っても引き分けになり、**神経衰弱をがんばる意味が消える**
- **近距離の射程 > `bodySize`** を必ず保つ。逆転すると、味方の後ろで足を止めたまま攻撃が届かず列が固まる
- **遠距離は撃ちながら進む**。足を止めると最大射程でにらみ合ったまま90秒たち、しかも列の先頭に弓がいるとうしろの味方まで止まって誰もタワーに届かない
- 終盤30秒は⚡2倍（`rushSeconds`）。にらみ合いのまま終わらせないため

## ビルド・リリース
手順の詳細は `DEPLOY.md`、スマホから作業するときは `MOBILE.md` を見る。
- **Android**: `scripts/bump_and_build.ps1`（versionCode自動+1してAABビルド）。出力: `build/app/outputs/bundle/release/app-release.aab`
- 署名: `android/app/key.properties` と `key.jks` は**どちらもgitignore対象・ローカルPCのみ**。
  ⚠️ 以前 `key.jks` がコミットされていたので履歴から削除した（`.gitignore` に `*.jks`）。
  **二度とリポジトリに入れないこと**。クラウド環境に鍵が無い＝スマホからAABは出せない、で正しい
- **Web**: `flutter build web --release` → **`build/web` の中で** `npx vercel --prod`
  （リポジトリのルートから叩くとファイル数上限15,000に引っかかる）
- `web/app-ads.txt` はAdMob審査用。ビルドで build/web に自動コピーされる。消さないこと

## 重要な決まりごと
- versionCode は必ずbumpスクリプトを使う（Play Consoleで重複拒否）
- AdMob本番ID（**AdMobコンソールの実際の枠**。`lib/services/ad_ids.dart`で管理。デバッグ時は自動でテストID）
  - バナー `/4880687935` / インタースティシャル `/8670804845`
  - **リワード `/9009716197`** / **リワードインタースティシャル `/2619409531`**
  - ⚠️ 以前このファイルは Rewarded を `/2619409531` と書いていたが**間違い**。
    それはリワードインタースティシャルの枠で、実際にコードもその誤りを写して
    いた（形式違いのIDを `RewardedAd.load` に渡していて本番で配信されない）
  - 未実装だが作成済みの枠: アプリ起動 `/9282156275` / ネイティブ `/9170475636`
- `dart:io` の `Platform` は使用禁止（Webでクラッシュ）。`kIsWeb`/`defaultTargetPlatform` を使う
- 広告関連は全て `kIsWeb` ガード必須（google_mobile_adsはWeb非対応）
- 医療・認知機能への効果は断定表現禁止。「〜と言われている」「〜が期待される」等のヘッジ表現＋免責を守る（`meta_strings.dart` の `cognitiveDisclaimer` 参照）
- 記憶術コンテンツ（`memory_tips.dart`）は完全オリジナル文章。外部記事のコピー禁止
- targetSdk 36（Android 16。2026-08-31までにPlayが必須化した対象APIレベル要件に対応、v2.3.0+103で35→36に引き上げ） / compileSdk 36 / NDK 27.0.12077973（16KBページサイズ対応）を維持
- 日本語Windows環境: PowerShellでのファイル読み書きは .NET の UTF8Encoding を明示（Get/Set-ContentはUTF-8を破壊する）
- フォント: ロゴ=Mochiy Pop One、本文=Zen Maru Gothic（google_fonts経由）

## コード修正からリリースまでの手順

コードを変更したら、必ずこの順で進める。**次のステップに進む前に問題があれば必ず直してからにすること。**
**すべてのステップを連続で実行し、途中で止めない。**

### 1. 静的チェック

```bash
flutter analyze
```

エラー/警告があれば修正する。info のみならOK。

### 2. テスト

```bash
flutter test
```

全261テスト通過が必須。1件でも落ちたら修正。

### 3. WebビルドとVercelデプロイ

```bash
flutter build web --release
cd build/web && npx vercel --prod
```

`build/web/.vercel/project.json` がビルドで消えた場合は `DEPLOY.md` の手順で復元する。

### 4. AABビルド（Android）

```bash
powershell.exe -ExecutionPolicy Bypass -File scripts/bump_and_build.ps1
```

出力: `build/app/outputs/bundle/release/app-release.aab`
versionCode が自動で +1 される。Google Play Console にアップロードするときはこの AAB を使う。
AAB はエミュレータに直接インストールできない。エミュレータで確認する場合は `flutter build apk --release` で APK をビルドし `adb install` する。

### 5. エミュレータ確認（任意）

```bash
# APK ビルド
flutter build apk --release

# エミュレータ起動（起動済みなら不要）
emulator -avd Pixel_6a_API_35 -no-boot-anim &

# インストール
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-release.apk

# 起動
adb -s emulator-5554 shell monkey -p com.nanimonjya -c android.intent.category.LAUNCHER 1

# スクリーンショット
adb -s emulator-5554 exec-out screencap -p > emu_home.png
```

### 6. Google Play リリースノート作成

`RELEASE_NOTES_vX.X.X.md` に日英両方で書く。
- 「**サマリ**:」の後に行うことの全体的な要約を一文で
- 「**変更点**:」に行ったことの箇条書き（日本語）
- 「**Changes**:」に英語の箇条書き

### 7. コミット＆プッシュ

```bash
git add -A
git commit -m "〜を直す / 〜を追加"
git push
```

コミットメッセージは日本語・一文で「何を直したか」を書く。
**コミット前に `git status` で意図しないファイルが入っていないか確認する。**
AAB や APK のビルド成果物は `.gitignore` されているはずだが、万が一ステージングに入っていたら `git reset` で外す。

### 8. Google Play Console へのアップロード

1. https://play.google.com/console を開く
2. アプリ「ペタネーム」(com.nanimonjya) を選択
3. 左メニュー「リリース」→「本番環境」
4. 「新しいリリースを作成」
5. AAB をアップロード（`build/app/outputs/bundle/release/app-release.aab`）
6. リリースノート（ja / en）を貼り付け
7. 「リリースを審査に送信」

### 9. Vercel 本番確認

デプロイ後に表示される Production URL（`https://web-sigma-drab-72.vercel.app`）をブラウザで開き、ホーム画面が正しく表示されることを確認する。

### 一発実行（ステップ1〜7）

```bash
flutter analyze && \
flutter test && \
flutter build web --release && \
cd build/web && npx vercel --prod && \
cd ../.. && \
powershell.exe -ExecutionPolicy Bypass -File scripts/bump_and_build.ps1 && \
git add -A && \
git commit -m "〜を直す" && \
git push
```

⚠️ 途中でエラーが出たら、そこで止めて修正。最後まで通ったら Google Play Console へアップロード。

---

## 残タスク（要ユーザー対応）
- デプロイ済みの旧Cloud Functions（generateSimilarNames/synthesizeSpeech/startGameOnPlayerCount）の削除: `firebase login` 後に `firebase deploy --only functions --force`（ローカルの `function/index.js` は空にしてある）
- App Check強制化はFirebaseコンソール作業（v2.1.0が行き渡ってから）
- `firestore.rules` はデプロイ済みのまま変更していない（新オンラインは既存ルールの範囲内で動作する設計）。`funnyNames`/`rankings` のルールは残っているが実害なし
