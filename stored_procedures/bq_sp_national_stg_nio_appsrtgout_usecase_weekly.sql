-- =============================================================================
-- Stored Procedure: bq_sp_national_stg_nio_appsrtgout_usecase_weekly
-- =============================================================================
-- Weekly user persona pipeline.
--
-- Flow:
--   1. Build traffic/recency/frequency (TRF) per (msisdn, app) from SOR
--   2. Compute per-app deciles (traffic, recency, frequency)
--   3. Build persona→app mapping from rnr_app_category_v2.persona column (data-driven)
--   4. Aggregate per-app deciles at persona-category level → re-decile
--   5. Classify engagement groups at persona level
--   6. Identify muslim_fashion via intersection (ecommerce_addict High Engaged ∩ religious_content active)
--   7. Insert final rows into stg_nio_appsrtgout_usecase_weekly
--   8. Drop all temp tables
--
-- Changes from previous version:
--   • persona_app_map now reads from rnr_app_category_v2.persona (REPEATED STRING)
--     instead of hardcoded STRUCT array — fully data-driven
--   • religious_content is a real persona (no longer mapped to 'others')
--   • premium_fashion_shopper is labeled directly in CSV (no rename from fashion_shopper)
--   • muslim_fashion: hybrid approach — labeled in CSV + intersection as supplementary
-- =============================================================================

CREATE OR REPLACE PROCEDURE `appl-int-df-prd-wd2y.bq_df_dm3_prd_owned_sor.bq_sp_national_stg_nio_appsrtgout_usecase_weekly`(
  v_bq_project STRING,
  v_bq_src_dataset STRING,
  v_bq_tar_dataset STRING,
  v_date DATE
)
OPTIONS (strict_mode=false)
BEGIN

DECLARE weekly_suffix STRING;
DECLARE date_var_sql STRING;
DECLARE start_date_sql STRING;
DECLARE end_date_sql STRING;
DECLARE partition_column_name STRING;
DECLARE partition_column_value STRING;
DECLARE delete_partition_column_value STRING;
DECLARE timestamp_id STRING;

SET timestamp_id = FORMAT_TIMESTAMP("%Y%m%d%H%M%S", CURRENT_TIMESTAMP());
SET weekly_suffix = '_weekly';
SET date_var_sql = CONCAT('"',FORMAT_DATE("%Y-%m-%d", v_date), '"');
SET start_date_sql = '''DATE_SUB(DATE_SUB(DATE_TRUNC(''' || date_var_sql || ''', WEEK), INTERVAL 1 DAY), INTERVAL 1 MONTH)''';
SET end_date_sql = '''DATE_SUB(DATE_TRUNC(''' || date_var_sql || ''', WEEK), INTERVAL 1 DAY)''';
SET partition_column_name = 'partition_date';
SET partition_column_value = end_date_sql;
SET delete_partition_column_value = end_date_sql;


-- Add persona_score column if it does not yet exist (idempotent)
EXECUTE IMMEDIATE
  '''ALTER TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.stg_nio_appsrtgout_usecase''' || weekly_suffix || '''`
  ADD COLUMN IF NOT EXISTS persona_score FLOAT64''';

-- Delete existing partition data for idempotent re-runs
EXECUTE IMMEDIATE
  '''DELETE FROM `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.stg_nio_appsrtgout_usecase''' || weekly_suffix || '''`
  WHERE ''' || partition_column_name || ''' = ''' || delete_partition_column_value;


-- ═══════════════════════════════════════════════════════════════════════════
-- Step 1: Build traffic/recency/frequency per (msisdn, app)
-- ═══════════════════════════════════════════════════════════════════════════
EXECUTE IMMEDIATE
  '''CREATE OR REPLACE TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.traffic_recency_frequency''' || weekly_suffix || '''_''' || timestamp_id || '''` AS (
  SELECT
    DISTINCT msisdn,
    LOWER(application_name) AS application_name,
    ''' || delete_partition_column_value || ''' ''' || partition_column_name || ''',
    SUM(volume_total_bytes) AS traffic,
    DATE_DIFF(''' || partition_column_value || ''', MAX(dt_id), day) AS recency,
    COUNT(DISTINCT dt_id) AS frequency
  FROM `''' || v_bq_project || '''.''' || v_bq_src_dataset || '''.stg_nio_appsrtgout`
  WHERE dt_id BETWEEN ''' || start_date_sql || ''' AND ''' || end_date_sql || '''
    AND LOWER(application_name) IN (
      SELECT DISTINCT LOWER(sig_app_tag)
      FROM `data-int-advana-prd-77c3.core_analytics.rnr_app_category_v2`,
           UNNEST(sig_app_tags) AS sig_app_tag
    )
  GROUP BY 1, 2
  )''';


-- ═══════════════════════════════════════════════════════════════════════════
-- Step 2: Compute per-app deciles (traffic, recency, frequency)
-- ═══════════════════════════════════════════════════════════════════════════
EXECUTE IMMEDIATE
  '''CREATE OR REPLACE TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.traffic_decile_tb''' || weekly_suffix || '''_''' || timestamp_id || '''` AS (
  SELECT application_name, t_unique,
    NTILE(10) OVER(PARTITION BY application_name ORDER BY t_unique ASC) traffic_decile
  FROM (
    SELECT DISTINCT application_name, (traffic) AS t_unique
    FROM `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.traffic_recency_frequency''' || weekly_suffix || '''_''' || timestamp_id || '''`
  ))''';

EXECUTE IMMEDIATE
  '''CREATE OR REPLACE TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.recency_decile_tb''' || weekly_suffix || '''_''' || timestamp_id || '''` AS (
  SELECT application_name, r_unique,
    NTILE(10) OVER(PARTITION BY application_name ORDER BY r_unique DESC) recency_decile
  FROM (
    SELECT DISTINCT application_name, (recency) AS r_unique
    FROM `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.traffic_recency_frequency''' || weekly_suffix || '''_''' || timestamp_id || '''`
  ))''';

EXECUTE IMMEDIATE
  '''CREATE OR REPLACE TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.frequency_decile_tb''' || weekly_suffix || '''_''' || timestamp_id || '''` AS (
  SELECT application_name, f_unique,
    NTILE(10) OVER(PARTITION BY application_name ORDER BY f_unique ASC) frequency_decile
  FROM (
    SELECT DISTINCT application_name, (frequency) AS f_unique
    FROM `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.traffic_recency_frequency''' || weekly_suffix || '''_''' || timestamp_id || '''`
  ))''';

EXECUTE IMMEDIATE
  '''CREATE OR REPLACE TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.final_table''' || weekly_suffix || '''_''' || timestamp_id || '''` AS (
  SELECT E.*, F.frequency_decile
  FROM (
    SELECT C.*, D.recency_decile
    FROM (
      SELECT A.*, B.traffic_decile
      FROM `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.traffic_recency_frequency''' || weekly_suffix || '''_''' || timestamp_id || '''` A
      LEFT JOIN `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.traffic_decile_tb''' || weekly_suffix || '''_''' || timestamp_id || '''` B
        ON A.traffic = B.t_unique AND A.application_name = B.application_name
    ) C
    LEFT JOIN `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.recency_decile_tb''' || weekly_suffix || '''_''' || timestamp_id || '''` D
      ON C.recency = D.r_unique AND C.application_name = D.application_name
  ) E
  LEFT JOIN `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.frequency_decile_tb''' || weekly_suffix || '''_''' || timestamp_id || '''` F
    ON E.frequency = F.f_unique AND E.application_name = F.application_name
  )''';


-- ═══════════════════════════════════════════════════════════════════════════
-- Step 3: Build app → persona mapping from rnr_app_category_v2.persona
--         (DATA-DRIVEN — no hardcoded STRUCT)
-- ═══════════════════════════════════════════════════════════════════════════
EXECUTE IMMEDIATE
  '''CREATE OR REPLACE TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.persona_app_map''' || weekly_suffix || '''_''' || timestamp_id || '''` AS
  SELECT DISTINCT
    LOWER(r.app_name) AS app_name,
    p AS persona_name
  FROM `data-int-advana-prd-77c3.core_analytics.rnr_app_category_v2` r,
       UNNEST(r.persona) AS p
  WHERE ARRAY_LENGTH(r.persona) > 0''';


-- ═══════════════════════════════════════════════════════════════════════════
-- Step 4: Aggregate per-app decile ranks at persona-category level
-- ═══════════════════════════════════════════════════════════════════════════
EXECUTE IMMEDIATE
  '''CREATE OR REPLACE TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.category_scores''' || weekly_suffix || '''_''' || timestamp_id || '''` AS
  SELECT
    ft.msisdn,
    pam.persona_name           AS persona_category,
    MAX(ft.traffic_decile)   + AVG(ft.traffic_decile)   AS cat_traffic_score,
    MAX(ft.recency_decile)                               AS cat_recency_score,
    MAX(ft.frequency_decile) + AVG(ft.frequency_decile) AS cat_frequency_score
  FROM `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.final_table''' || weekly_suffix || '''_''' || timestamp_id || '''` ft
  JOIN `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.persona_app_map''' || weekly_suffix || '''_''' || timestamp_id || '''` pam
    ON LOWER(ft.application_name) = pam.app_name
  GROUP BY ft.msisdn, pam.persona_name''';


-- ═══════════════════════════════════════════════════════════════════════════
-- Step 5: Re-decile the category-level scores
-- ═══════════════════════════════════════════════════════════════════════════
EXECUTE IMMEDIATE
  '''CREATE OR REPLACE TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.category_deciles''' || weekly_suffix || '''_''' || timestamp_id || '''` AS
  SELECT
    msisdn,
    persona_category,
    NTILE(10) OVER(PARTITION BY persona_category ORDER BY cat_traffic_score   ASC)  AS cat_traffic_decile,
    NTILE(10) OVER(PARTITION BY persona_category ORDER BY cat_recency_score   DESC) AS cat_recency_decile,
    NTILE(10) OVER(PARTITION BY persona_category ORDER BY cat_frequency_score ASC)  AS cat_frequency_decile
  FROM `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.category_scores''' || weekly_suffix || '''_''' || timestamp_id || '''`''';


-- ═══════════════════════════════════════════════════════════════════════════
-- Step 6: Classify engagement groups + compute persona_score
-- ═══════════════════════════════════════════════════════════════════════════
EXECUTE IMMEDIATE
  '''CREATE OR REPLACE TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.category_engagement''' || weekly_suffix || '''_''' || timestamp_id || '''` AS
  SELECT
    msisdn,
    persona_category,
    CASE
      WHEN cat_recency_decile <= 5                                                                       THEN 'Non Active User'
      WHEN cat_recency_decile > 5 AND cat_traffic_decile IN(1,2,3)   AND cat_frequency_decile IN(1,2,3)  THEN 'Low Engaged User'
      WHEN cat_recency_decile > 5 AND cat_traffic_decile IN(8,9,10)  AND cat_frequency_decile IN(8,9,10) THEN 'High Engaged User'
      WHEN cat_recency_decile > 5 AND cat_traffic_decile IN(8,9,10)  AND cat_frequency_decile IN(1,2,3)  THEN 'Impulsive User'
      WHEN cat_recency_decile > 5 AND cat_traffic_decile IN(1,2,3)   AND cat_frequency_decile IN(8,9,10) THEN 'Non Effective User'
      ELSE 'Normal User'
    END AS cat_engagement_group,
    CAST(cat_traffic_decile + cat_recency_decile + cat_frequency_decile AS FLOAT64) AS persona_score
  FROM `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.category_deciles''' || weekly_suffix || '''_''' || timestamp_id || '''`''';


-- ═══════════════════════════════════════════════════════════════════════════
-- Step 7: Identify muslim_fashion via intersection
--         (ecommerce_addict High Engaged ∩ religious_content active)
--         This supplements the CSV-labeled muslim_fashion apps.
-- ═══════════════════════════════════════════════════════════════════════════
EXECUTE IMMEDIATE
  '''CREATE OR REPLACE TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.muslim_fashion_users''' || weekly_suffix || '''_''' || timestamp_id || '''` AS
  SELECT f.msisdn
  FROM (
    SELECT msisdn
    FROM `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.category_engagement''' || weekly_suffix || '''_''' || timestamp_id || '''`
    WHERE persona_category = 'ecommerce_addict' AND cat_engagement_group = 'High Engaged User'
  ) f
  INNER JOIN (
    SELECT msisdn
    FROM `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.category_engagement''' || weekly_suffix || '''_''' || timestamp_id || '''`
    WHERE persona_category = 'religious_content' AND cat_engagement_group != 'Non Active User'
  ) r ON f.msisdn = r.msisdn''';


-- ═══════════════════════════════════════════════════════════════════════════
-- Step 8: Insert final rows into output table
-- ═══════════════════════════════════════════════════════════════════════════
EXECUTE IMMEDIATE
  '''INSERT INTO `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.stg_nio_appsrtgout_usecase''' || weekly_suffix || '''` (
    msisdn,
    application_name,
    traffic,
    traffic_decile,
    recency,
    recency_decile,
    frequency,
    frequency_decile,
    engagement_group,
    user_persona,
    persona_score,
    ''' || partition_column_name || ''',
    job_id,
    insert_timestamp
  )
  SELECT
    base.msisdn,
    base.application_name,
    base.traffic,
    base.traffic_decile,
    base.recency,
    base.recency_decile,
    base.frequency,
    base.frequency_decile,
    base.engagement_group,
    -- Persona assignment:
    --   • No persona mapping or inactive → 'others'
    --   • ecommerce_addict users who also engage religious_content → supplementary 'muslim_fashion'
    --   • All other personas pass through as-is from the CSV-driven mapping
    CASE
      WHEN pam.persona_name IS NULL
        OR ce.cat_engagement_group IS NULL
        OR ce.cat_engagement_group = 'Non Active User'
        THEN 'others'
      WHEN pam.persona_name = 'ecommerce_addict' AND mfu.msisdn IS NOT NULL
        THEN 'muslim_fashion'
      ELSE pam.persona_name
    END AS user_persona,
    COALESCE(ce.persona_score, 0) AS persona_score,
    base.''' || partition_column_name || ''',
    base.job_id,
    base.insert_timestamp
  FROM (
    SELECT
      msisdn,
      application_name,
      ''' || partition_column_name || ''',
      traffic,
      traffic_decile,
      recency,
      recency_decile,
      frequency,
      frequency_decile,
      CASE
        WHEN recency_decile <= 5 THEN 'Non Active User'
        WHEN recency_decile > 5 AND traffic_decile IN(1,2,3) AND frequency_decile IN(1,2,3) THEN 'Low Engaged User'
        WHEN recency_decile > 5 AND traffic_decile IN(8,9,10) AND frequency_decile IN(8,9,10) THEN 'High Engaged User'
        WHEN recency_decile > 5 AND traffic_decile IN(8,9,10) AND frequency_decile IN(1,2,3) THEN 'Impulsive User'
        WHEN recency_decile > 5 AND traffic_decile IN(1,2,3) AND frequency_decile IN(8,9,10) THEN 'Non Effective User'
        ELSE 'Normal User'
      END AS engagement_group,
      job_id,
      insert_timestamp
    FROM (
      SELECT
        msisdn,
        application_name,
        ''' || partition_column_name || ''',
        traffic,
        traffic_decile,
        recency,
        recency_decile,
        frequency,
        frequency_decile,
        "bq_sp_national_stg_nio_appsrtgout_usecase''' || weekly_suffix || '''" AS job_id,
        TIMESTAMP_TRUNC(CURRENT_TIMESTAMP, second) AS insert_timestamp
      FROM `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.final_table''' || weekly_suffix || '''_''' || timestamp_id || '''`
    )
  ) base
  LEFT JOIN `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.persona_app_map''' || weekly_suffix || '''_''' || timestamp_id || '''` pam
    ON LOWER(base.application_name) = pam.app_name
  LEFT JOIN `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.category_engagement''' || weekly_suffix || '''_''' || timestamp_id || '''` ce
    ON base.msisdn = ce.msisdn AND pam.persona_name = ce.persona_category
  LEFT JOIN `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.muslim_fashion_users''' || weekly_suffix || '''_''' || timestamp_id || '''` mfu
    ON base.msisdn = mfu.msisdn AND pam.persona_name = 'ecommerce_addict'
  ''';


-- ═══════════════════════════════════════════════════════════════════════════
-- Cleanup: drop all temp tables
-- ═══════════════════════════════════════════════════════════════════════════
EXECUTE IMMEDIATE '''DROP TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.traffic_recency_frequency''' || weekly_suffix || '''_''' || timestamp_id || '''`''';
EXECUTE IMMEDIATE '''DROP TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.traffic_decile_tb''' || weekly_suffix || '''_''' || timestamp_id || '''`''';
EXECUTE IMMEDIATE '''DROP TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.recency_decile_tb''' || weekly_suffix || '''_''' || timestamp_id || '''`''';
EXECUTE IMMEDIATE '''DROP TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.frequency_decile_tb''' || weekly_suffix || '''_''' || timestamp_id || '''`''';
EXECUTE IMMEDIATE '''DROP TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.final_table''' || weekly_suffix || '''_''' || timestamp_id || '''`''';
EXECUTE IMMEDIATE '''DROP TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.persona_app_map''' || weekly_suffix || '''_''' || timestamp_id || '''`''';
EXECUTE IMMEDIATE '''DROP TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.category_scores''' || weekly_suffix || '''_''' || timestamp_id || '''`''';
EXECUTE IMMEDIATE '''DROP TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.category_deciles''' || weekly_suffix || '''_''' || timestamp_id || '''`''';
EXECUTE IMMEDIATE '''DROP TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.category_engagement''' || weekly_suffix || '''_''' || timestamp_id || '''`''';
EXECUTE IMMEDIATE '''DROP TABLE `''' || v_bq_project || '''.''' || v_bq_tar_dataset || '''.muslim_fashion_users''' || weekly_suffix || '''_''' || timestamp_id || '''`''';

END
