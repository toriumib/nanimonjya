-- ============================================================
-- ペタネーム Firebase Analytics → BigQuery SQL分析集
-- プロジェクト: nanimonjya
-- 使い方: Firebase ConsoleでBigQuery連携をONにした後、このSQLを実行
-- ============================================================

-- [1] クラッシュ分析: 全app_exceptionイベント（直近30日）
SELECT
  PARSE_TIMESTAMP('%Y%m%d%H%M%S', CONCAT(event_date, event_timestamp)) AS time_jst,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'screen') AS screen,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'message') AS error_message,
  device.operating_system, device.mobile_brand_name, device.mobile_model_name
FROM `nanimonjya.analytics_*.events_*`
WHERE event_name = 'app_exception'
  AND _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
ORDER BY time_jst DESC
LIMIT 100;

-- [2] ファネル分析（全期間）
SELECT
  (SELECT COUNT(DISTINCT user_pseudo_id) FROM `nanimonjya.analytics_*.events_*` WHERE event_name = 'first_open') AS first_open_users,
  (SELECT COUNT(DISTINCT user_pseudo_id) FROM `nanimonjya.analytics_*.events_*` WHERE event_name = 'game_start') AS game_start_users,
  (SELECT COUNT(DISTINCT user_pseudo_id) FROM `nanimonjya.analytics_*.events_*` WHERE event_name = 'game_end') AS game_end_users,
  (SELECT COUNT(DISTINCT user_pseudo_id) FROM `nanimonjya.analytics_*.events_*` WHERE event_name = 'cpu_match_end') AS cpu_match_users,
  (SELECT COUNT(DISTINCT user_pseudo_id) FROM `nanimonjya.analytics_*.events_*` WHERE event_name = 'app_remove') AS uninstall_users;

-- [3] 日別DAU + ゲーム開始数
SELECT
  event_date,
  COUNT(DISTINCT user_pseudo_id) AS dau,
  COUNTIF(event_name = 'game_start') AS game_starts,
  COUNTIF(event_name = 'game_end') AS game_ends,
  COUNTIF(event_name = 'app_exception') AS crashes,
  COUNTIF(event_name = 'app_remove') AS uninstalls
FROM `nanimonjya.analytics_*.events_*`
WHERE event_name IN ('game_start', 'game_end', 'app_exception', 'app_remove', 'screen_view')
GROUP BY event_date
ORDER BY event_date DESC;

-- [4] 国別ユーザー数＋エンゲージ時間
SELECT
  geo.country,
  COUNT(DISTINCT user_pseudo_id) AS users,
  AVG(
    (SELECT value.double_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec')
  ) / 1000 AS avg_engagement_sec,
  COUNTIF(event_name = 'game_start') AS game_starts,
  COUNTIF(event_name = 'app_remove') AS uninstalls
FROM `nanimonjya.analytics_*.events_*`
GROUP BY geo.country
ORDER BY users DESC;

-- [5] ゲーム離脱率（game_start→game_exitのパターン別）
SELECT
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'reason') AS exit_reason,
  COUNT(*) AS count
FROM `nanimonjya.analytics_*.events_*`
WHERE event_name = 'game_exit'
GROUP BY exit_reason
ORDER BY count DESC;

-- [6] なまえコール途中離脱ポイント
SELECT
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'phase') AS phase,
  COUNT(*) AS count
FROM `nanimonjya.analytics_*.events_*`
WHERE event_name = 'namecall_progress'
GROUP BY phase
ORDER BY count DESC;

-- [7] ユーザー維持率（Day 1, Day 7）
WITH first_visit AS (
  SELECT user_pseudo_id, MIN(event_date) AS first_date
  FROM `nanimonjya.analytics_*.events_*`
  WHERE event_name = 'first_open'
  GROUP BY user_pseudo_id
)
SELECT
  f.first_date,
  COUNT(DISTINCT f.user_pseudo_id) AS new_users,
  COUNT(DISTINCT CASE WHEN DATE_DIFF(PARSE_DATE('%Y%m%d', e.event_date), PARSE_DATE('%Y%m%d', f.first_date), DAY) = 1 THEN e.user_pseudo_id END) AS day1_ret,
  COUNT(DISTINCT CASE WHEN DATE_DIFF(PARSE_DATE('%Y%m%d', e.event_date), PARSE_DATE('%Y%m%d', f.first_date), DAY) = 7 THEN e.user_pseudo_id END) AS day7_ret
FROM first_visit f
LEFT JOIN `nanimonjya.analytics_*.events_*` e
  ON f.user_pseudo_id = e.user_pseudo_id
GROUP BY f.first_date
ORDER BY f.first_date DESC;
