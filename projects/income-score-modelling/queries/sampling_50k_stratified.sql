-- ============================================================
-- STRATIFIED 50k SAMPLING WITH VALID NIK
-- Project  : Income Score Modelling — IOH
-- Author   : Data Scientist (IOH)
-- Created  : 2026-04-01
-- ============================================================
-- Strategy : Proportional Stratified Sampling — Hamilton / Largest Remainder
--             Brand-split: 25,000 IM3 + 25,000 3ID = 50,000 total
--   Quota strata : brand × province × user_persona × age_bin
--                  × neighborhood_tier_grouped × ses_category
--   Theoretical max strata: 2 × 32 × 17 × 6 × 3 × 5 = 97,920
--   Quota method (applied independently per brand, target n=25,000 each):
--     Step 1 — floor_quota  = FLOOR(25000 × stratum_n / brand_total_n)
--     Step 2 — remainder    = fractional part of exact quota
--     Step 3 — distribute (25000 − sum_of_floors) extra slots per brand,
--              one per stratum, to the strata with the largest remainders
--   Result  : exactly 50,000 rows (25,000 IM3 + 25,000 3ID)
-- ============================================================
-- Brand identification (derived from msisdn prefix):
--   IM3 prefixes : 62814, 62815, 62816, 62855, 62856, 62857, 62858
--   3ID prefixes : 62895, 62896, 62897, 62898, 62899
-- NIK source tables (separate per brand):
--   IM3 : data-dtp-prd-aa1a.smy.ar_cst_dly_smy
--   3ID : data-dtptechm-prd-c7ca.dwh.h3i_ar_cst_dly_smy
-- ============================================================
-- Exclusions (all applied in stratum_profile CTE):
--   - user_persona = 'Others' or NULL
--   - NULL or invalid NIK
--   - NULL province (empty array in profile table)
--   - NULL neighborhood_tier (field unpopulated in profile table)
--   - NULL age (age column NULL in source)
--   - NULL ses_category (no SES match for msisdn)
-- Rationale: all quota dimensions must be populated so the final
-- sample contains zero NULL/Unknown values. The Hamilton method
-- redistributes excluded users' slots to populated strata,
-- preserving exactly 25,000 per brand (50,000 total).
-- ============================================================
-- Neighborhood tier grouping (used for quota only; original preserved in output):
--   High : Upper High, Lower High
--   Med  : Upper Med,  Lower Med
--   Low  : Low
-- ============================================================
-- Notes:
--   [1] `age` column expected as INTEGER in df_customer_profile_data_new.
--       NULL age → age_bin = NULL → excluded in stratum_profile.
--   [2] partition_month kept as >= '2026-03-01'; change to = for single-snapshot.
--   [3] QUALIFY deduplicates if source tables are daily partitioned.
--       Remove if msisdn is guaranteed unique.
--   [4] RAND() in ROW_NUMBER is non-deterministic. Log the BQ job ID.
--   [5] h3i_ar_cst_dly_smy schema assumed identical to ar_cst_dly_smy
--       (columns: dt_id, msisdn, nik). Adjust if schema differs.
--   [6] neighborhood_tier_0824 is expected to have exactly 1 row per
--       geohash_6 (no fan-out). Pre-check:
--       SELECT COUNT(*), COUNT(DISTINCT geohash_6) FROM
--       `data-int-advana-prd-77c3.core_analytics.neighborhood_tier_0824`
--       Both counts must match before running this query.
-- ============================================================

WITH

-- ── [1a] VALID NIK — IM3 ─────────────────────────────────────────────────────
-- Source : data-dtp-prd-aa1a.smy.ar_cst_dly_smy
-- Filters to IM3 msisdn prefixes with structurally valid NIK.
-- Indonesian NIK: 6-digit area | 2-digit day (F: +40) | 2-digit month |
--                 2-digit year | 4-digit sequential number
valid_nik_im3 AS (
  SELECT DISTINCT
    msisdn,
    nik,
    'IM3' AS brand
  FROM `data-dtp-prd-aa1a.smy.ar_cst_dly_smy`
  WHERE
    dt_id >= '2026-03-01'
    AND nik IS NOT NULL
    AND REGEXP_CONTAINS(
      nik,
      '^\\d{6}([04][1-9]|[1256][0-9]|[37][01])(0[1-9]|1[0-2])\\d{2}\\d{4}$'
    )
    AND (
      STARTS_WITH(CAST(msisdn AS STRING), '62814') OR
      STARTS_WITH(CAST(msisdn AS STRING), '62815') OR
      STARTS_WITH(CAST(msisdn AS STRING), '62816') OR
      STARTS_WITH(CAST(msisdn AS STRING), '62855') OR
      STARTS_WITH(CAST(msisdn AS STRING), '62856') OR
      STARTS_WITH(CAST(msisdn AS STRING), '62857') OR
      STARTS_WITH(CAST(msisdn AS STRING), '62858')
    )
  QUALIFY
    ROW_NUMBER() OVER (PARTITION BY msisdn ORDER BY nik) = 1  -- see Note [3]
),

-- ── [1b] VALID NIK — 3ID ─────────────────────────────────────────────────────
-- Source : data-dtptechm-prd-c7ca.dwh.h3i_ar_cst_dly_smy
-- See Note [5] regarding schema assumption.
valid_nik_3id AS (
  SELECT DISTINCT
    msisdn,
    nik,
    '3ID' AS brand
  FROM `data-dtptechm-prd-c7ca.dwh.h3i_ar_cst_dly_smy`
  WHERE
    dt_id >= '2026-03-01'
    AND nik IS NOT NULL
    AND REGEXP_CONTAINS(
      nik,
      '^\\d{6}([04][1-9]|[1256][0-9]|[37][01])(0[1-9]|1[0-2])\\d{2}\\d{4}$'
    )
    AND (
      STARTS_WITH(CAST(msisdn AS STRING), '62895') OR
      STARTS_WITH(CAST(msisdn AS STRING), '62896') OR
      STARTS_WITH(CAST(msisdn AS STRING), '62897') OR
      STARTS_WITH(CAST(msisdn AS STRING), '62898') OR
      STARTS_WITH(CAST(msisdn AS STRING), '62899')
    )
  QUALIFY
    ROW_NUMBER() OVER (PARTITION BY msisdn ORDER BY nik) = 1  -- see Note [3]
),

-- ── [1c] VALID NIK — COMBINED ────────────────────────────────────────────────
-- UNION ALL is safe: msisdn prefix ranges are disjoint between brands,
-- so no subscriber can appear in both CTEs above.
valid_nik_users AS (
  SELECT msisdn, nik, brand FROM valid_nik_im3
  UNION ALL
  SELECT msisdn, nik, brand FROM valid_nik_3id
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
    v.brand,                                                                          -- IM3 or 3ID

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
    -- neighborhood_tier: prefer direct profile column (populated for IM3);
    -- fall back to geohash-6 spatial lookup (covers 3ID where profile column is NULL).
    COALESCE(c.neighborhood_tier, nt.neighborhood_tier) AS neighborhood_tier,

    -- Grouped 3-tier for quota stratification
    CASE
      WHEN COALESCE(c.neighborhood_tier, nt.neighborhood_tier)
               IN ('Upper High', 'Lower High') THEN 'High'
      WHEN COALESCE(c.neighborhood_tier, nt.neighborhood_tier)
               IN ('Upper Med',  'Lower Med')  THEN 'Med'
      WHEN COALESCE(c.neighborhood_tier, nt.neighborhood_tier)
               = 'Low'                         THEN 'Low'
      ELSE NULL  -- handles unexpected values; excluded in [3]
    END AS neighborhood_tier_grouped,

    ses.cat AS ses_category

  FROM `appl-ext-sdappl-prd-02yz.data_foundation.df_customer_profile_data_new` c
  INNER JOIN valid_nik_users v
    ON c.msisdn = v.msisdn          -- INNER: only NIK-valid users proceed
  LEFT JOIN `data-int-advana-prd-77c3.core_analytics.msisdn_latest_ses_v1` ses
    ON  c.msisdn          = ses.msisdn
    AND ses.partition_month >= '2026-03-01'
  LEFT JOIN `data-int-advana-prd-77c3.core_analytics.neighborhood_tier_0824` nt
    ON LEFT(c.geohash, 6) = nt.geohash_6
    -- Fallback tier for 3ID: c.neighborhood_tier is NULL for 3ID subscribers;
    -- geohash-6 truncation from the profile geohash field maps to the tier table.
    -- Assumes 1 row per geohash_6 in tier table (verify with pre-check below).
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
    -- brand is first so each stratum is inherently brand-scoped.
    CONCAT(
      brand,                     '||',
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
-- Count per quota stratum. brand is carried separately for the per-brand
-- denominator join in [6a] (already encoded in stratum_key but a separate
-- column avoids parsing it back out).
stratum_counts AS (
  SELECT
    stratum_key,
    brand,
    COUNT(*) AS stratum_n
  FROM stratum_profile
  GROUP BY stratum_key, brand
),

-- ── [5] PER-BRAND UNIVERSE COUNT ─────────────────────────────────────────────
-- Denominator for proportional quota; computed independently per brand
-- so each brand targets exactly 25,000 rows.
brand_total_n AS (
  SELECT
    brand,
    SUM(stratum_n) AS n
  FROM stratum_counts
  GROUP BY brand
),

-- ── [6a] EXACT AND FLOOR QUOTA PER STRATUM ──────────────────────────────────
-- Per-brand proportional quota targeting 25,000 each.
-- The fractional remainder is used in [6c] to distribute leftover slots.
stratum_quota_raw AS (
  SELECT
    sc.stratum_key,
    sc.brand,
    sc.stratum_n,
    25000.0 * sc.stratum_n / bt.n                                     AS exact_quota,
    CAST(FLOOR(25000.0 * sc.stratum_n / bt.n) AS INT64)               AS floor_quota,
    (25000.0 * sc.stratum_n / bt.n)
      - FLOOR(25000.0 * sc.stratum_n / bt.n)                          AS remainder
  FROM stratum_counts sc
  JOIN brand_total_n bt ON sc.brand = bt.brand
),

-- ── [6b] LEFTOVER SLOTS PER BRAND ────────────────────────────────────────────
-- Per brand: 25,000 minus sum of floor quotas = extra +1 slots to distribute.
remainder_slots AS (
  SELECT
    brand,
    25000 - SUM(floor_quota) AS slots_to_distribute
  FROM stratum_quota_raw
  GROUP BY brand
),

-- ── [6c] HAMILTON ALLOCATION (FINAL QUOTA) ────────────────────────────────────
-- Awards +1 to strata with the largest fractional remainders, independently
-- per brand, until each brand total reaches exactly 25,000.
-- Tie-break by stratum_key (alphabetical) for determinism.
stratum_quota AS (
  SELECT
    sq.stratum_key,
    sq.brand,
    sq.stratum_n,
    sq.floor_quota
      + CASE
          WHEN ROW_NUMBER() OVER (
                 PARTITION BY sq.brand
                 ORDER BY sq.remainder DESC, sq.stratum_key ASC
               ) <= (
                 SELECT rs.slots_to_distribute
                 FROM remainder_slots rs
                 WHERE rs.brand = sq.brand
               )
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
--   brand                   — IM3 or 3ID (exactly 25,000 each)
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
  r.brand,
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
  r.brand,
  r.province,
  r.user_persona,
  r.age_bin,
  r.neighborhood_tier_grouped,
  r.ses_category
-- LIMIT 50000  -- Uncomment to enforce a hard cap (see Note [5])
;
