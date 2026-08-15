-- 📊 BigQuery（Firebase Analytics エクスポート）用のクエリ集
--
-- AdMobのレポートだけでは「どの枠が効いているか」が分からない。
-- AdMobは format（バナー／リワード…）単位までで、**アプリ内のどこか**は出ない。
-- アプリ側は `ad_load_requested` / `ad_shown` / `ad_skipped` /
-- `ad_reward_prompt` / `ad_reward_earned` に placement を載せているので、
-- ここを突き合わせると「どこに置いた動画が見られているか」まで分かる。
--
-- 使い方:
--   Firebase コンソール → BigQuery Export で作られる
--   `<project>.analytics_<propertyId>.events_*` を FROM に指定する。
--   下では `analytics_TABLE` としているので、実際のIDに置換すること。
--   （プロジェクトIDは nanimonjya。propertyId は BigQuery の
--     データセット名 analytics_XXXXXXXXX の数字部分）
--
-- ⚠️ 直近3日は events_intraday_* に入るので、当日ぶんも見たいときは
--    events_* を `events_*` と `events_intraday_*` の UNION にする。

-- 期間はまとめてここで変える
DECLARE start_date STRING DEFAULT FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 28 DAY));
DECLARE end_date   STRING DEFAULT FORMAT_DATE('%Y%m%d', CURRENT_DATE());


-- ============================================================
-- 1. 広告の空振り分析（いちばん見たいもの）
--    「読んだ回数」に対して「出せた回数」がどれだけあるか、置き場所ごとに。
--    2026-08のAdMob: リワードは446リクエスト→14表示（3.1%）だった。
--    その14回が**どこで**再生されたのかが、この表で分かる。
-- ============================================================
WITH ad AS (
  SELECT
    event_name,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'format')    AS format,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'placement') AS placement,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'reason')    AS reason
  FROM `analytics_TABLE.events_*`
  WHERE _TABLE_SUFFIX BETWEEN start_date AND end_date
    AND event_name IN ('ad_load_requested','ad_shown','ad_skipped',
                       'ad_reward_prompt','ad_reward_earned')
)
SELECT
  format,
  placement,
  COUNTIF(event_name = 'ad_load_requested') AS loads,
  COUNTIF(event_name = 'ad_shown')          AS shown,
  SAFE_DIVIDE(COUNTIF(event_name = 'ad_shown'),
              COUNTIF(event_name = 'ad_load_requested')) AS show_rate,
  COUNTIF(event_name = 'ad_reward_prompt')  AS reward_prompt,
  COUNTIF(event_name = 'ad_reward_earned')  AS reward_earned,
  SAFE_DIVIDE(COUNTIF(event_name = 'ad_reward_earned'),
              COUNTIF(event_name = 'ad_reward_prompt')) AS completion_rate,
  COUNTIF(event_name = 'ad_skipped')        AS skipped
FROM ad
GROUP BY format, placement
ORDER BY shown DESC;


-- ============================================================
-- 2. 「見なかった理由」の内訳
--    not_loaded が多い = 先読みが間に合っていない（＝先読みを戻す判断材料）
--    no_fill が多い    = 在庫が無い（＝アプリ側では直せない）
-- ============================================================
SELECT
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'format')    AS format,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'placement') AS placement,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'reason')    AS reason,
  COUNT(*) AS n
FROM `analytics_TABLE.events_*`
WHERE _TABLE_SUFFIX BETWEEN start_date AND end_date
  AND event_name = 'ad_skipped'
GROUP BY format, placement, reason
ORDER BY n DESC;


-- ============================================================
-- 3. 遊びの通過率（ここが本丸）
--    AdMobの数字から、インタースティシャル表示7回 ≒ 試合完了21回と読める。
--    バナー表示は646回（＝画面表示の回数）なので、
--    **画面は見られているのに試合が終わっていない**。どこで落ちているかを見る。
-- ============================================================
WITH ev AS (
  SELECT
    user_pseudo_id,
    event_name,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'firebase_screen') AS screen
  FROM `analytics_TABLE.events_*`
  WHERE _TABLE_SUFFIX BETWEEN start_date AND end_date
)
SELECT
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT IF(event_name = 'first_open', user_pseudo_id, NULL))    AS new_users,
  COUNT(DISTINCT IF(event_name = 'game_start', user_pseudo_id, NULL))    AS started_game,
  COUNT(DISTINCT IF(event_name = 'game_end',   user_pseudo_id, NULL))    AS finished_game,
  SAFE_DIVIDE(COUNT(DISTINCT IF(event_name = 'game_end', user_pseudo_id, NULL)),
              COUNT(DISTINCT user_pseudo_id)) AS finish_rate
FROM ev;


-- ============================================================
-- 4. 離脱している画面
--    「その画面を見た人のうち、そのセッションで最後の画面になった割合」。
--    高いほど、そこで閉じられている。
-- ============================================================
WITH s AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    event_timestamp,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'firebase_screen') AS screen
  FROM `analytics_TABLE.events_*`
  WHERE _TABLE_SUFFIX BETWEEN start_date AND end_date
    AND event_name = 'screen_view'
),
ranked AS (
  SELECT
    screen,
    ROW_NUMBER() OVER (PARTITION BY user_pseudo_id, session_id
                       ORDER BY event_timestamp DESC) AS rn_desc
  FROM s
  WHERE screen IS NOT NULL
)
SELECT
  screen,
  COUNT(*)                       AS views,
  COUNTIF(rn_desc = 1)           AS last_in_session,
  SAFE_DIVIDE(COUNTIF(rn_desc = 1), COUNT(*)) AS exit_rate
FROM ranked
GROUP BY screen
HAVING views >= 20
ORDER BY exit_rate DESC;


-- ============================================================
-- 5. 復習（間隔反復）が効いているか
--    まちがえた人を日をあけて出し直す仕組みを入れたので、
--    復習をやった人が翌日以降も戻ってきているかを見る。
-- ============================================================
WITH d AS (
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS day,
    MAX(IF(event_name = 'spaced_review_done', 1, 0)) AS did_review
  FROM `analytics_TABLE.events_*`
  WHERE _TABLE_SUFFIX BETWEEN start_date AND end_date
  GROUP BY user_pseudo_id, day
)
SELECT
  did_review,
  COUNT(DISTINCT user_pseudo_id) AS users,
  AVG(days_active)               AS avg_active_days
FROM (
  SELECT user_pseudo_id, MAX(did_review) AS did_review, COUNT(DISTINCT day) AS days_active
  FROM d GROUP BY user_pseudo_id
)
GROUP BY did_review;


-- ============================================================
-- 6. 課金（Play Console に商品を登録したあとで見る）
--    商品を登録するまでは queryProductDetails が空を返すので、
--    iap 系のイベントは出ない＝ここが空なのは想定どおり。
-- ============================================================
SELECT
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'item_id')  AS item_id,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'method')   AS method,
  COUNT(*)                       AS purchases,
  COUNT(DISTINCT user_pseudo_id) AS buyers
FROM `analytics_TABLE.events_*`
WHERE _TABLE_SUFFIX BETWEEN start_date AND end_date
  AND event_name = 'shop_purchase'
GROUP BY item_id, method
ORDER BY purchases DESC;
