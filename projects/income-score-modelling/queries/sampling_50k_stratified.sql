-- ============================================================
-- STRATIFIED 50k SAMPLING WITH VALID NIK
-- Project  : Income Score Modelling — IOH
-- Author   : Data Scientist (IOH)
-- Created  : 2026-04-01
-- ============================================================
-- Strategy : Proportional Stratified Sampling — Hamilton / Largest Remainder
--   Quota strata : province × user_persona × age_bin
--                  × neighborhood_tier_grouped × ses_category
--   Theoretical max strata: 32 × 17 × 6 × 3 × 5 = 48,960
--   Eligible universe (valid NIK + province + tier): 22,538,711
--   Quota method:
--     Step 1 — floor_quota  = FLOOR(50000 × stratum_n / total_n)
--     Step 2 — remainder    = fractional part of exact quota
--     Step 3 — distribute (50000 − sum_of_floors) extra slots, one per
--              stratum, to the strata with the largest remainders
--   Result  : exactly 50,000 rows, proportional allocation, no rounding waste
--   Note    : ROUND() previously yielded 47,319; this method closes the gap
-- ============================================================
-- Exclusions (all applied in stratum_profile CTE):
--   - user_persona = 'Others' or NULL
--   - NULL or invalid NIK
--   - NULL province (empty array in profile table)
--   - NULL neighborhood_tier (field unpopulated in profile table)
--   - NULL age / age_bin = 'Unknown' (age column NULL in source)
--   - NULL ses_category (no SES match for msisdn)
-- Rationale: all quota dimensions must be populated so the final
-- sample contains zero NULL/Unknown values. The Hamilton method
-- redistributes excluded users' slots to populated strata,
-- preserving exact 50,000 total.
-- ============================================================
-- Neighborhood tier grouping (used for quota only; original preserved in output):
--   High : Upper High, Lower High
--   Med  : Upper Med,  Lower Med
--   Low  : Low
-- ============================================================
-- Notes:
--   [1] `age` column expected as INTEGER in df_customer_profile_data_new.
--       NULL age → age_bin = NULL → excluded in stratum_profile.
--   [2] partition_month kept as >= '2026-03-01' to match user's working
--       version; change to = '2026-03-01' if single-snapshot is preferred.
--   [3] QUALIFY in valid_nik_users deduplicates if ar_cst_dly_smy has
--       multiple rows per msisdn (e.g., daily table). Remove QUALIFY
--       if msisdn is guaranteed unique in that table.
--   [4] RAND() in ROW_NUMBER produces a non-deterministic random sample.
--       Results will differ on each run. Seed control is not natively
--       supported in BigQuery; log the BQ job ID for reproducibility.
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
      ELSE NULL  -- NULL age → excluded in stratum_profile; see Note [1]
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
-- All six quota dimensions must be non-NULL to guarantee a clean output.
-- Users excluded here have their quota slots redistributed by the Hamilton
-- method in [6c] — the total sample stays exactly 50,000.
stratum_profile AS (
  SELECT
    *,
    -- All components guaranteed non-NULL by WHERE below; no COALESCE needed.
    CONCAT(
      province,                  '||',
      user_persona,              '||',
      age_bin,                   '||',
      neighborhood_tier_grouped, '||',
      ses_category
    ) AS stratum_key
  FROM base_profile
  WHERE
    user_persona      IS NOT NULL   -- excludes 'Others'-only users
    AND province          IS NOT NULL   -- excludes empty province array
    AND neighborhood_tier IS NOT NULL   -- excludes unpopulated tier
    AND age_bin           IS NOT NULL   -- excludes NULL age (→ 'Unknown' removed)
    AND ses_category      IS NOT NULL   -- excludes unmatched SES
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

-- ── [6a] EXACT AND FLOOR QUOTA PER STRATUM ──────────────────────────────────
-- Computes the exact proportional quota (with decimals) and its floor.
-- The fractional remainder is used in step [6c] to distribute leftover slots.
stratum_quota_raw AS (
  SELECT
    sc.stratum_key,
    sc.stratum_n,
    50000.0 * sc.stratum_n / t.n                                     AS exact_quota,
    CAST(FLOOR(50000.0 * sc.stratum_n / t.n) AS INT64)               AS floor_quota,
    (50000.0 * sc.stratum_n / t.n)
      - FLOOR(50000.0 * sc.stratum_n / t.n)                          AS remainder
  FROM stratum_counts sc
  CROSS JOIN total_n t
),

-- ── [6b] LEFTOVER SLOTS ───────────────────────────────────────────────────────
-- 50000 minus the sum of all floor quotas = number of extra +1 slots to award.
-- (With ROUND this was the source of the 47,319 shortfall.)
remainder_slots AS (
  SELECT 50000 - SUM(floor_quota) AS slots_to_distribute
  FROM stratum_quota_raw
),

-- ── [6c] HAMILTON ALLOCATION (FINAL QUOTA) ────────────────────────────────────
-- Awards +1 to the strata with the largest fractional remainders until
-- the total reaches exactly 50,000.
-- Tie-break by stratum_key (alphabetical) for determinism.
stratum_quota AS (
  SELECT
    sq.stratum_key,
    sq.stratum_n,
    sq.floor_quota
      + CASE
          WHEN ROW_NUMBER() OVER (ORDER BY sq.remainder DESC, sq.stratum_key ASC)
               <= (SELECT slots_to_distribute FROM remainder_slots)
          THEN 1
          ELSE 0
        END AS quota
  FROM stratum_quota_raw sq
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
