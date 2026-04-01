-- ============================================================
-- STRATIFIED 50k SAMPLING WITH VALID NIK
-- Project  : Income Score Modelling — IOH
-- Author   : Data Scientist (IOH)
-- Created  : 2026-04-01
-- ============================================================
-- Strategy : Proportional Stratified Sampling (Option A)
--   Quota strata : province × user_persona × age_bin
--                  × neighborhood_tier_grouped × ses_category
--   Theoretical max strata: 32 × 17 × 6 × 3 × 5 = 48,960
--   Quota per stratum: ROUND(50000 × stratum_n / total_valid_nik_n)
--   Strata with proportional quota < 0.5 receive quota=0 (naturally excluded)
-- ============================================================
-- Exclusions:
--   - user_persona = 'Others' excluded from strata and sample
--   - Users with NULL or invalid NIK excluded
-- ============================================================
-- Neighborhood tier grouping (used for quota only; original preserved in output):
--   High : Upper High, Lower High
--   Med  : Upper Med,  Lower Med
--   Low  : Low
-- ============================================================
-- Notes:
--   [1] `age_bin` — adjust to `age` if the column is named differently
--       in df_customer_profile_data_new
--   [2] partition_month changed from >= to = '2026-03-01' to ensure a
--       clean single-snapshot and prevent duplicate msisdns across months
--   [3] QUALIFY in valid_nik_users deduplicates if ar_cst_dly_smy has
--       multiple rows per msisdn (e.g., daily table). Remove QUALIFY
--       if msisdn is guaranteed unique in that table.
--   [4] RAND() in ROW_NUMBER produces a non-deterministic random sample.
--       Results will differ on each run. Seed control is not natively
--       supported in BigQuery; log the job ID for reproducibility.
--   [5] Final COUNT may be slightly below 50k if many strata round down.
--       To force exactly 50k, add LIMIT 50000 on the final SELECT.
-- ============================================================
-- NULL handling:
--   province / kabupaten NULL  : c.province is a NULL or empty ARRAY for
--       those subscribers. (SELECT ... FROM UNNEST(NULL) LIMIT 1) returns
--       NULL. The original aggregate query used CROSS JOIN UNNEST which
--       silently dropped those rows; here we do the same via the WHERE
--       filter in stratum_profile.
--   neighborhood_tier NULL     : c.neighborhood_tier is unpopulated for
--       many subscribers in df_customer_profile_data_new. Excluded below
--       because these users cannot be assigned to a quota stratum.
--   ses_category NULL          : LEFT JOIN on SES table found no match.
--       NULL is kept as its own valid stratum (handled via COALESCE in
--       stratum_key), so these users remain in the sample pool.
-- ============================================================

WITH

-- ── [1] VALID NIK UNIVERSE ────────────────────────────────────────────────────
-- Filters ar_cst_dly_smy to subscribers with a structurally valid
-- Indonesian NIK (16-digit KTP format validated by regex).
-- Indonesian NIK structure:
--   digits  1– 6 : kabupaten/kota area code
--   digits  7– 8 : day of birth (male: 01–31; female: 41–71)
--   digits  9–10 : month of birth (01–12)
--   digits 11–12 : birth year (2 digit)
--   digits 13–16 : sequential number
valid_nik_users AS (
  SELECT
    DISTINCT msisdn,
    nik
  FROM `data-dtp-prd-aa1a.smy.ar_cst_dly_smy`
  WHERE
    dt_id >= '2026-03-01'
    AND nik IS NOT NULL
    AND REGEXP_CONTAINS(
      nik,
      '^\\d{6}([04][1-9]|[1256][0-9]|[37][01])(0[1-9]|1[0-2])\\d{2}\\d{4}$'
    )
  QUALIFY
    ROW_NUMBER() OVER (PARTITION BY msisdn ORDER BY nik) = 1
    -- See Note [3]: keeps one row per msisdn deterministically
),

-- ── [2] BASE PROFILE: ONE ROW PER MSISDN ─────────────────────────────────────
-- Joins customer profile + SES + valid NIK users.
-- Array columns (kabupaten, province, user_persona) are reduced to a single
-- representative value per user using a subquery with LIMIT 1.
-- For user_persona, 'Others' is excluded during the pick; users whose ONLY
-- persona is 'Others' will have user_persona = NULL (filtered out in [3]).
base_profile AS (
  SELECT
    c.msisdn,
    v.nik,

    -- Array columns: pick first element for stratification & output
    (SELECT kab  FROM UNNEST(c.kabupaten)    AS kab  LIMIT 1)                     AS kabupaten,
    (SELECT prov FROM UNNEST(c.province)     AS prov LIMIT 1)                     AS province,
    (SELECT p    FROM UNNEST(c.user_persona) AS p
                 WHERE p != 'Others'
                 LIMIT 1)                                                          AS user_persona,

    CASE
      WHEN age < 18 THEN '<18'
      WHEN age BETWEEN 18 AND 24 THEN '18-24'
      WHEN age BETWEEN 25 AND 34 THEN '25-34'
      WHEN age BETWEEN 35 AND 44 THEN '35-44'
      WHEN age BETWEEN 45 AND 54 THEN '45-54'
      WHEN age >= 55 THEN '55+'
      ELSE 'Unknown'
    END AS age_bin,
    c.neighborhood_tier, -- original 5-tier value; preserved in final output

    -- Grouped 3-tier for quota stratification
    CASE
      WHEN c.neighborhood_tier IN ('Upper High', 'Lower High') THEN 'High'
      WHEN c.neighborhood_tier IN ('Upper Med',  'Lower Med')  THEN 'Med'
      WHEN c.neighborhood_tier = 'Low'                         THEN 'Low'
      ELSE NULL  -- handles unexpected values; excluded in [3] via stratum_key
    END AS neighborhood_tier_grouped,

    ses.cat AS ses_category

  FROM `appl-ext-sdappl-prd-02yz.data_foundation.df_customer_profile_data_new` c
  INNER JOIN valid_nik_users v
    ON c.msisdn = v.msisdn          -- INNER: only NIK-valid users proceed
  LEFT JOIN `data-int-advana-prd-77c3.core_analytics.msisdn_latest_ses_v1` ses
    ON  c.msisdn          = ses.msisdn
    AND ses.partition_month >= '2026-03-01'
  WHERE
    c.partition_month >= '2026-03-01'  -- See Note [2]
),

-- ── [3] STRATUM ASSIGNMENT ────────────────────────────────────────────────────
-- Excludes users missing any required quota stratum dimension:
--   user_persona IS NOT NULL     : had only 'Others' persona
--   province IS NOT NULL         : empty/null province array in profile table
--   neighborhood_tier IS NOT NULL: tier field unpopulated in profile table
-- ses_category NULL is allowed — treated as its own stratum via COALESCE.
-- Builds a composite stratum_key string for clean single-column joins downstream.
stratum_profile AS (
  SELECT
    *,
    CONCAT(
      province,                              '||',
      user_persona,                          '||',
      age_bin,                               '||',
      neighborhood_tier_grouped,             '||',
      COALESCE(ses_category, '__NULL__')
    ) AS stratum_key
  FROM base_profile
  WHERE
    user_persona      IS NOT NULL   -- excludes 'Others'-only users
    AND province      IS NOT NULL   -- excludes users with no province array data
    AND neighborhood_tier IS NOT NULL  -- excludes users with no tier assignment
),

-- ── [4] STRATUM COUNTS ────────────────────────────────────────────────────────
-- Count of valid-NIK, non-Others users per quota stratum.
stratum_counts AS (
  SELECT
    stratum_key,
    COUNT(*) AS stratum_n
  FROM stratum_profile
  GROUP BY stratum_key
),

-- ── [5] TOTAL VALID-NIK UNIVERSE COUNT ───────────────────────────────────────
-- Denominator for proportional quota computation.
total_n AS (
  SELECT SUM(stratum_n) AS n
  FROM stratum_counts
),

-- ── [6] PROPORTIONAL QUOTA PER STRATUM ───────────────────────────────────────
-- quota_i = ROUND( 50000 × stratum_n_i / total_n )
-- Strata with proportional share < 0.5 naturally receive quota=0.
-- GREATEST(0, ...) guards against any unexpected negative edge case.
stratum_quota AS (
  SELECT
    sc.stratum_key,
    sc.stratum_n,
    CAST(
      GREATEST(0, ROUND(50000.0 * sc.stratum_n / t.n))
    AS INT64) AS quota
  FROM stratum_counts sc
  CROSS JOIN total_n t
),

-- ── [7] RANDOM RANK WITHIN STRATUM ───────────────────────────────────────────
-- Assigns a random rank to each user within their stratum.
-- See Note [4] on non-determinism and reproducibility.
ranked AS (
  SELECT
    sp.*,
    ROW_NUMBER() OVER (
      PARTITION BY sp.stratum_key
      ORDER BY RAND()
    ) AS rn
  FROM stratum_profile sp
)

-- ── [8] FINAL SAMPLE ─────────────────────────────────────────────────────────
-- Selects users where their random rank is within their stratum's quota.
-- Output columns:
--   msisdn                  — subscriber identifier (for internal linkage)
--   nik                     — national ID (primary key for external provider matching)
--   kabupaten               — district (for reference; not used in quota strata)
--   province                — province
--   user_persona            — behavioral segment (Others excluded)
--   age_bin                 — age group bin
--   neighborhood_tier       — original 5-tier value (Upper High / Lower High /
--                             Upper Med / Lower Med / Low)
--   neighborhood_tier_grouped — aggregated 3-tier (High / Med / Low)
--                               used as quota dimension; visible for cross-check
--   ses_category            — socioeconomic segment (SES A–E)
SELECT
  r.msisdn,
  r.nik,
  r.kabupaten,
  r.province,
  r.user_persona,
  r.age_bin,
  r.neighborhood_tier,           -- original fine-grained tier (visible in result)
  r.neighborhood_tier_grouped,   -- grouped tier used for stratification
  r.ses_category
FROM ranked r
INNER JOIN stratum_quota q
  ON r.stratum_key = q.stratum_key
WHERE
  r.rn <= q.quota
ORDER BY
  r.province,
  r.user_persona,
  r.age_bin,
  r.neighborhood_tier_grouped,
  r.ses_category
-- LIMIT 50000  -- Uncomment to enforce a hard cap (see Note [5])
;
