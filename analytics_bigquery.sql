-- 📊 BigQuery クエリ集（プロジェクト: nanimonjya）
--
-- ============================================================
-- ⚠️ まず読むこと: Analytics のエクスポートは**まだ繋がっていない**
-- ============================================================
--
-- 2026-08-16 時点で BigQuery にあるデータセットは次の4つ:
--
--   firebase_crashlytics   … クラッシュ（繋がっている）
--   firebase_performance   … 起動時間・画面描画（繋がっている）
--   firebase_messaging     … プッシュ通知（繋がっている）
--   firebase_sessions      … セッション（繋がっている）
--
-- **`analytics_<プロパティID>` が無い。** これが Google Analytics(GA4) の
-- エクスポートで、`events_*` テーブル＝アプリが送っている
-- `game_start` / `ad_shown` / `screen_view` などが入る唯一の置き場所。
-- 下の「セクションB」はこれが無いと動かない。
--
-- 繋ぎかた（Firebaseコンソールではなく **Googleアナリティクス側**の設定）:
--   1. analytics.google.com → 管理 → プロパティ →「BigQuery のリンク」
--   2. 「リンク」→ プロジェクト `nanimonjya` を選ぶ
--   3. データストリーム（Android アプリ / ウェブ）を選択
--   4. 「毎日」（無料）にチェック。すぐ見たいなら「ストリーミング」も
--      （こちらは従量課金。まずは「毎日」だけで十分）
--   5. 作成
--
-- ⚠️ **さかのぼれない。** リンクした翌日以降のデータしか入らないので、
--    過去ぶんは Google アナリティクスの画面で見るしかない。
--    早く繋ぐほど早く積み上がる、という性質のもの。
--
-- ⚠️ `com_kengo_marubatusokketu_ANDROID` というテーブルが混ざっている。
--    これは **別アプリ（com.kengo.marubatusokketu）** のCrashlytics。
--    同じプロジェクトに2アプリぶん入っているので、
--    クラッシュを見るときはアプリを絞ること（下のクエリはそうしてある）。
--
-- 使い方: `<PROPERTY_ID>` を実際の数字に置き換える（リンクすると
--        `nanimonjya.analytics_123456789` のような名前で現れる）。


-- ============================================================
-- セクションA: いま繋がっているデータで、今日から見られるもの
-- ============================================================

-- ------------------------------------------------------------
-- A-1. クラッシュしていないユーザーの割合（このアプリだけ）
--      ⚠️ 別アプリのテーブルが同居しているので必ず絞る。
-- ------------------------------------------------------------
SELECT
  DATE(event_timestamp)                         AS day,
  COUNT(DISTINCT installation_uuid)             AS users_with_crash,
  COUNT(*)                                      AS crashes,
  COUNTIF(is_fatal)                             AS fatal_crashes
FROM `nanimonjya.firebase_crashlytics.com_nanimonjya_ANDROID`
WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 28 DAY)
GROUP BY day
ORDER BY day DESC;


-- ------------------------------------------------------------
-- A-2. 落ちている場所トップ20
--      「どの画面で落ちたか」は custom_keys の `screen` に入れてある
--      （app_analytics.dart の screen() が Crashlytics にも書いている）。
--      これがあるおかげで、スタックだけでは分からない原因画面が追える。
-- ------------------------------------------------------------
SELECT
  issue_title,
  issue_subtitle,
  (SELECT value FROM UNNEST(custom_keys) WHERE key = 'screen') AS screen,
  COUNT(*)                          AS events,
  COUNT(DISTINCT installation_uuid) AS users,
  MAX(event_timestamp)              AS last_seen
FROM `nanimonjya.firebase_crashlytics.com_nanimonjya_ANDROID`
WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 28 DAY)
GROUP BY issue_title, issue_subtitle, screen
ORDER BY users DESC, events DESC
LIMIT 20;


-- ------------------------------------------------------------
-- A-3. 起動の遅さ（アプリを開いてから使えるまで）
--      ここが遅いと、遊ぶ前に閉じられる。広告や記事を増やす前に見る値。
-- ------------------------------------------------------------
SELECT
  event_name,
  APPROX_QUANTILES(event_duration_us / 1000, 100)[OFFSET(50)] AS p50_ms,
  APPROX_QUANTILES(event_duration_us / 1000, 100)[OFFSET(90)] AS p90_ms,
  COUNT(*) AS samples
FROM `nanimonjya.firebase_performance.*`
WHERE event_type = 'DURATION_TRACE'
  AND event_name IN ('_app_start', '_app_start_cold', '_app_start_warm')
GROUP BY event_name
ORDER BY samples DESC;


-- ------------------------------------------------------------
-- A-4. カクついている画面（描画が遅いフレームの割合）
--      顔の画像を増やした影響がここに出る。
-- ------------------------------------------------------------
SELECT
  event_name AS screen,
  SUM(slow_frames)   AS slow_frames,
  SUM(frozen_frames) AS frozen_frames,
  COUNT(*)           AS sessions
FROM `nanimonjya.firebase_performance.*`
WHERE event_type = 'SCREEN_TRACE'
GROUP BY screen
HAVING sessions >= 20
ORDER BY frozen_frames DESC, slow_frames DESC
LIMIT 20;


-- ============================================================
-- セクションB: GA4 のリンクを作ったあとに使うもの
--   ⚠️ `analytics_<PROPERTY_ID>` が出来るまでは動かない（テーブルが無い）
-- ============================================================

-- ------------------------------------------------------------
-- B-1. 広告の空振り（いちばん見たいもの）
--      AdMobは format 単位までしか出ないので、**アプリ内のどこか**が分からない。
--      アプリ側は placement を載せているので、ここで初めて突き合わせられる。
--      2026-08のAdMob: リワード446リクエスト→14表示。その14回がどこか、を出す。
-- ------------------------------------------------------------
WITH ad AS (
  SELECT
    event_name,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'format')    AS format,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'placement') AS placement
  FROM `nanimonjya.analytics_<PROPERTY_ID>.events_*`
  WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 28 DAY))
                          AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
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
              COUNTIF(event_name = 'ad_reward_prompt')) AS completion_rate
FROM ad
GROUP BY format, placement
ORDER BY shown DESC;


-- ------------------------------------------------------------
-- B-2. 「なぜ出せなかったか」の内訳
--      not_loaded が多い → 先読みを戻す判断材料
--      no_fill が多い   → 在庫の問題でアプリ側では直せない
--      expired が多い   → 期限切れ（全画面広告のTTLを入れた効果がここに出る）
-- ------------------------------------------------------------
SELECT
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'format')    AS format,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'placement') AS placement,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'reason')    AS reason,
  COUNT(*) AS n
FROM `nanimonjya.analytics_<PROPERTY_ID>.events_*`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 28 DAY))
                        AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND event_name = 'ad_skipped'
GROUP BY format, placement, reason
ORDER BY n DESC;


-- ------------------------------------------------------------
-- B-3. 遊びの通過率（ここが本丸）
--      AdMobの数字からは「画面は見られているのに試合が終わっていない」と読めた。
--      どこで落ちているかはこれで分かる。
-- ------------------------------------------------------------
SELECT
  COUNT(DISTINCT user_pseudo_id)                                          AS users,
  COUNT(DISTINCT IF(event_name='first_open',  user_pseudo_id, NULL))      AS new_users,
  COUNT(DISTINCT IF(event_name='mode_pick',   user_pseudo_id, NULL))      AS picked_mode,
  COUNT(DISTINCT IF(event_name='game_start',  user_pseudo_id, NULL))      AS started,
  COUNT(DISTINCT IF(event_name='game_end',    user_pseudo_id, NULL))      AS finished,
  SAFE_DIVIDE(COUNT(DISTINCT IF(event_name='game_end',   user_pseudo_id, NULL)),
              COUNT(DISTINCT IF(event_name='game_start', user_pseudo_id, NULL))) AS finish_rate
FROM `nanimonjya.analytics_<PROPERTY_ID>.events_*`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 28 DAY))
                        AND FORMAT_DATE('%Y%m%d', CURRENT_DATE());


-- ------------------------------------------------------------
-- B-4. 途中でやめた理由の切り分け
--      gameExit(=アプリ内で離脱) と gameBackground(=アプリごと外へ) を
--      分けて撃っているので、「飽きた」と「落ちた」を区別できる。
--      特定の枚数に中断が集中していたら、それは設計の問題。
-- ------------------------------------------------------------
SELECT
  event_name,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key='mode')         AS mode,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key='reason')       AS reason,
  (SELECT value.int_value    FROM UNNEST(event_params) WHERE key='progress_pct') AS progress_pct,
  COUNT(*) AS n
FROM `nanimonjya.analytics_<PROPERTY_ID>.events_*`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 28 DAY))
                        AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND event_name IN ('game_exit','game_background')
GROUP BY event_name, mode, reason, progress_pct
ORDER BY n DESC
LIMIT 30;


-- ------------------------------------------------------------
-- B-5. どのモードが選ばれているか（1人プレイの入口を足した効果もここで見る）
-- ------------------------------------------------------------
SELECT
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key='mode') AS mode,
  COUNT(*)                       AS picks,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM `nanimonjya.analytics_<PROPERTY_ID>.events_*`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 28 DAY))
                        AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND event_name = 'mode_pick'
GROUP BY mode
ORDER BY picks DESC;


-- ------------------------------------------------------------
-- B-6. 離脱している画面
-- ------------------------------------------------------------
WITH s AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key='ga_session_id')      AS session_id,
    event_timestamp,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key='firebase_screen') AS screen
  FROM `nanimonjya.analytics_<PROPERTY_ID>.events_*`
  WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 28 DAY))
                          AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
    AND event_name = 'screen_view'
),
ranked AS (
  SELECT screen,
         ROW_NUMBER() OVER (PARTITION BY user_pseudo_id, session_id
                            ORDER BY event_timestamp DESC) AS rn_desc
  FROM s WHERE screen IS NOT NULL
)
SELECT screen,
       COUNT(*)             AS views,
       COUNTIF(rn_desc = 1) AS last_in_session,
       SAFE_DIVIDE(COUNTIF(rn_desc = 1), COUNT(*)) AS exit_rate
FROM ranked
GROUP BY screen
HAVING views >= 20
ORDER BY exit_rate DESC;


-- ------------------------------------------------------------
-- B-7. 復習（間隔反復）が定着に効いているか
--      復習をやった人が翌日以降も戻ってきているかを見る。
-- ------------------------------------------------------------
WITH d AS (
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS day,
    MAX(IF(event_name = 'spaced_review_done', 1, 0)) AS did_review
  FROM `nanimonjya.analytics_<PROPERTY_ID>.events_*`
  WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 28 DAY))
                          AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  GROUP BY user_pseudo_id, day
)
SELECT did_review,
       COUNT(DISTINCT user_pseudo_id) AS users,
       AVG(days_active)               AS avg_active_days
FROM (
  SELECT user_pseudo_id, MAX(did_review) AS did_review, COUNT(DISTINCT day) AS days_active
  FROM d GROUP BY user_pseudo_id
)
GROUP BY did_review;


-- ------------------------------------------------------------
-- B-8. 課金（Play Console に商品を登録したあとで見る）
--      商品を登録するまで queryProductDetails が空を返すので、
--      ここが空なのは想定どおり。
-- ------------------------------------------------------------
SELECT
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key='item_id') AS item_id,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key='method')  AS method,
  COUNT(*)                       AS purchases,
  COUNT(DISTINCT user_pseudo_id) AS buyers
FROM `nanimonjya.analytics_<PROPERTY_ID>.events_*`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 28 DAY))
                        AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND event_name = 'shop_purchase'
GROUP BY item_id, method
ORDER BY purchases DESC;
