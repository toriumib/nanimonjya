# 計測（Firebase Analytics）

> 📊 2026-08 のデータを読んだ所見と改善計画は [ANALYTICS_REVIEW.md](ANALYTICS_REVIEW.md)。
> **計測されていない機能の一覧と、これから追加するイベント定義もそちら。**
>
> 直近（2026-07-22〜08-18）の GA4 エクスポートを読んだ所見は下記「データ所見と改善案」。

---

## データ所見と改善案（2026-08-19）

### 数字の要約

| 指標 | 値 | 判定 |
|---|---|---|
| 新規ユーザー | 228人（Direct 82% / Organic Search 17% / Referral 0.4%） | 自然流入中心 |
| プラットフォーム | Android 227 / Web 25 | ほぼ Android |
| Day 1 リテンション | コホートの大半が 0%（良くて33%） | ⚠️ 悪い |
| **Day 7 リテンション** | **全コホート 0%** | 🔴 致命的 |
| **app_remove** | **64件（63人）＝新規の約28%が削除** | 🔴 致命的 |
| **app_exception** | **1699件（18人）** | 🔴 要修正 |
| ストーリーモード | story_start 1 / story_ending 1 | 実質1人＝デッド |
| 広告 | ad_shown 6095（15人＝1人あたり406回） | ⚠️ 多すぎ |

### ファネル（どこで消えるか）

```
first_open 203人
  → first_game_started 53人（26%）  ← 74%が一度もゲームを始めない
  → game_start 350回
  → game_end 124回（完走 35%）
```

- **起動→初回ゲーム 26%** が最大の穴。ホームから遊び方へ到達できていない。
- 読み物は open 232 に対し read_page 36 / read_finish 0。開くが読まれない。

### 改善案（優先度順）

1. **app_exception 1699件を直す** — 18人で1699件＝1人約94件。クラッシュ/例外が大量発生。`AppAnalytics.screen()` で Crashlytics に画面名を載せる対応は済んでいるので、Crashlytics のスタックを**画面別**に集計して多発画面を特定する。
2. **初回→初回ゲーム 26% を上げる** — 起動した74%が未プレイで消える。初回は1タップでゲーム開始できる導線に（チュートリアル・設定を前に挟まない）。
3. **Day 7 リテンション 0% を直す** — 1週間後に戻る理由が無い。通知（notify_prompt は9件しか出ていない）と復習キュー（spaced_review）を前面に出す。
4. **ストーリーモードは撤去か休眠** — 下記参照。
5. **広告1人406回は異常** — 少数ユーザーに広告が集中。インタースティシャル頻度とリワードの出し方を再点検。

### ストーリーモードは使われている？

**使われていません。** story_start=1 / story_ending=1 / story_progress=13（＝1人が途中まで）。Noah ストーリー（英語未翻訳）は事実上デッド。**撤去を推奨**（保守コストが浮く）。残すなら「よみもの」タブ内の1枚へ格下げ。

### 定義済みなのに未配線（計測の穴）

- `answer`（`answerLogged`）— 1問ごとの正誤・反応時間。**2026-08-19 に name_call_screen へ配線済み**（`_answer` 内）。
- `tap_action`（`tapAction`）— ボタン押下。未配線（任意）。

### イベントの足し方（継続的に足すとき）

1. 送信は必ず `lib/services/app_analytics.dart` にメソッドを1つ足し、画面から直接 `FirebaseAnalytics` を呼ばない（表記ゆれで集計不能になる）。
2. メソッドは `_log('イベント名', {'パラメータ': 値})` を呼ぶだけ。
3. 「開いた／使った／終えた」の**3点セット**で撃つ（開いた数だけでは使われたのか分からない）。
4. イベント名・パラメータ名は**後から変えない**（GA4 は名前で保存。変えると過去と繋がらない）。
5. 個人を特定できる値（名前・写真・名刺の中身）は絶対に送らない。
6. カスタムパラメータは Firebase コンソール → Analytics → カスタム定義 への登録が要る（登録前は内訳が出ない）。

「どのモードが使われているか・人気か」を後から数えられるようにするための決めごと。

送信は `lib/services/app_analytics.dart` に集約する。**画面やロジックから直接
`FirebaseAnalytics` を呼ばない**（イベント名の表記ゆれが起きて集計できなくなる）。

⚠️ 個人を特定できる値（入力した名前・写真・名刺の中身）は絶対に送らない。
送るのはカタログ上のIDと数量だけ。

---

## モード人気を見るための3点セット

| 見たいこと | イベント | 備考 |
|---|---|---|
| どのタブが開かれたか | `feature_open`（param: `feature`） | 下タブ6つの切り替え |
| **どの遊び方が選ばれたか** | `mode_pick`（param: `mode`） | ホームのボタン単位。人気の順位はここで見る |
| どの画面が見られたか | `screen_view` | 全画面。`AppAnalytics.screen()` |

### なぜ `mode_pick` が必要だったか
`feature_open` が数えるのは「下タブを切り替えた回数」だけで、
なまえがおタブの中にある **みんなで／ひとりで／オンライン／ランク** が
まったく区別できなかった。モードの人気を知るには、押された瞬間を
ボタン単位で撃つ必要がある。

`game_start` とは別イベントにしてある。押したあと設定シートで
やめた人も `mode_pick` には残るので、**「興味は持たれたが始められていない」**
モードを見つけられる（`mode_pick` は多いのに `game_start` が少ない＝
設定シートで止まっている）。

### `mode` に入る値（固定）
`local`（みんなで1台）/ `cpu` / `online_friend` / `rank` /
`face_memo` / `profile` / `tutorial` / `support`

---

## 画面（screen_view）

`main.dart` に `FirebaseAnalyticsObserver` は入っているが、
`MaterialPageRoute` に `settings` を付けていないので**ルート名では取れない**。
そのため各画面の `initState` で `AppAnalytics.screen('<名前>')` を呼んでいる。

新しい画面を足すときは、この1行を忘れないこと。

主な画面名: `top` / `shop` / `profile` / `tutorial` / `story_noah` /
`memory_tips` / `recall_training` / `training_hub` / `custom_roster` /
`avatar_editor` / `line_match` / `report` / `ranking` / `online_lobby` ほか

---

## ゲームの中身

| イベント | 何が分かるか |
|---|---|
| `game_start` / `game_end` | モード別のプレイ数・スコア |
| `namecall_progress` | 完走ファネルの通過点（`naming_done` → `recall_first` → `recall_half`） |
| `game_exit` | どこで抜けたか（`completed` / `quit` / `backgrounded`）＋進捗% |
| `cpu_match_end` / `online_match_end` / `solo_training_end` | 勝敗・正答率・反応速度 |
| `spaced_review_done` | 日をまたいだ復習の定着 |

### ものがたりモード
| イベント | 何が分かるか |
|---|---|
| `story_progress`（param: `phase`） | 五幕のどこまで進んだか。章が変わったときだけ撃つ |
| `story_ending`（`ending` / `correct` / `total`） | 4つの結末の分布と、覚えられた数 |

`phase` は `_Phase` の名前をそのまま使う（`prologue` / `meet` / `recall` /
`date` / `climax` / `finalTest` / `ending` など）。

---

## 収益まわり

| イベント | 何が分かるか |
|---|---|
| `ad_reward_prompt` / `ad_reward_earned`（param: `placement`） | 広告の視聴率（分母／分子） |
| `ad_offered_for_item` | **何が欲しくて**動画を見たのか |
| `shop_item_tap` / `shop_purchase` / `shop_short_of_coins` | 欲しがられているが売れていない＝高すぎる商品 |

---

## GA4 での見かた

1. Firebase コンソール → Analytics → イベント
2. モード人気: `mode_pick` を開き、`mode` パラメータで内訳を見る
3. 完走率: 「探索」→「目標到達プロセスデータ探索」に
   `game_start` → `namecall_progress`(phase別) → `game_end` を順に置く
4. どこで離脱するか: `screen_view` の画面名別の滞在と、`game_exit` の `reason`

⚠️ カスタムパラメータ（`mode` / `feature` / `phase` など）を GA4 の
レポートで内訳として使うには、**カスタムディメンションへの登録**が要る。
Firebase コンソール → Analytics → カスタム定義 で、使いたい
パラメータ名を登録しておくこと。登録前のデータは内訳が出ない。
