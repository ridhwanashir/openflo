-- ============================================================
-- SAMPLE DISTRIBUTION PROFILE — PER COLUMN
-- Project  : Income Score Modelling — IOH
-- Source   : data-int-advana-prd-77c3.core_analytics.rnr_income_prediction_sample_final
-- Purpose  : QC check — distribution of each stratification dimension
--            independently; verify proportional allocation held.
-- Created  : 2026-04-01
-- ============================================================
-- Output schema:
--   dimension     — column name being profiled
--   value         — unique value within that column
--   n             — COUNT(DISTINCT msisdn) for this value
--   pct           — share of total sample (n / 50000 × 100), 2 decimal places
-- Ordered by: dimension, n DESC
-- ============================================================

WITH

total AS (
  SELECT COUNT(DISTINCT msisdn) AS total_n
  FROM `data-int-advana-prd-77c3.core_analytics.rnr_income_prediction_sample_final`
),

dist_province AS (
  SELECT
    'province'            AS dimension,
    CAST(province AS STRING) AS value,
    COUNT(DISTINCT msisdn)   AS n
  FROM `data-int-advana-prd-77c3.core_analytics.rnr_income_prediction_sample_final`
  GROUP BY province
),

dist_user_persona AS (
  SELECT
    'user_persona'           AS dimension,
    CAST(user_persona AS STRING) AS value,
    COUNT(DISTINCT msisdn)       AS n
  FROM `data-int-advana-prd-77c3.core_analytics.rnr_income_prediction_sample_final`
  GROUP BY user_persona
),

dist_age_bin AS (
  SELECT
    'age_bin'              AS dimension,
    CAST(age_bin AS STRING)   AS value,
    COUNT(DISTINCT msisdn)    AS n
  FROM `data-int-advana-prd-77c3.core_analytics.rnr_income_prediction_sample_final`
  GROUP BY age_bin
),

dist_neighborhood_tier AS (
  SELECT
    'neighborhood_tier'             AS dimension,
    CAST(neighborhood_tier AS STRING) AS value,
    COUNT(DISTINCT msisdn)            AS n
  FROM `data-int-advana-prd-77c3.core_analytics.rnr_income_prediction_sample_final`
  GROUP BY neighborhood_tier
),

dist_neighborhood_tier_grouped AS (
  SELECT
    'neighborhood_tier_grouped'             AS dimension,
    CAST(neighborhood_tier_grouped AS STRING) AS value,
    COUNT(DISTINCT msisdn)                    AS n
  FROM `data-int-advana-prd-77c3.core_analytics.rnr_income_prediction_sample_final`
  GROUP BY neighborhood_tier_grouped
),

dist_ses_category AS (
  SELECT
    'ses_category'              AS dimension,
    COALESCE(CAST(ses_category AS STRING), '(null)') AS value,
    COUNT(DISTINCT msisdn)      AS n
  FROM `data-int-advana-prd-77c3.core_analytics.rnr_income_prediction_sample_final`
  GROUP BY ses_category
),

# dist brand
dist_brand AS (
  SELECT
    'brand' AS dimension,
    CAST(brand AS STRING) AS value,
    COUNT(DISTINCT msisdn) AS n
  FROM `data-int-advana-prd-77c3.core_analytics.rnr_income_prediction_sample_final`
  GROUP BY brand
),

all_dims AS (
  SELECT * FROM dist_province
  UNION ALL
  SELECT * FROM dist_user_persona
  UNION ALL
  SELECT * FROM dist_age_bin
  UNION ALL
  SELECT * FROM dist_neighborhood_tier
  UNION ALL
  SELECT * FROM dist_neighborhood_tier_grouped
  UNION ALL
  SELECT * FROM dist_ses_category
    UNION ALL
    SELECT * FROM dist_brand
)

SELECT
  d.dimension,
  d.value,
  d.n,
  ROUND(100.0 * d.n / t.total_n, 2) AS pct
FROM all_dims d
CROSS JOIN total t
ORDER BY
  d.dimension,
  d.n DESC
;
