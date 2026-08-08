# 計測（Firebase Analytics）

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
