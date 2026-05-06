-- ============================================================
-- SAMPLE TABLE — HASHED MSISDN FOR EXTERNAL HANDOFF
-- Project  : Income Score Modelling — IOH
-- Source   : data-int-advana-prd-77c3.core_analytics.rnr_income_prediction_sample_final
-- Target   : data-int-advana-prd-77c3.core_analytics.rnr_income_prediction_sample_external
-- Purpose  : Pseudonymise msisdn before submitting to external validation
--            provider. NIK is retained as the matching key.
-- Created  : 2026-04-01
-- ============================================================
-- Hashing approach: salted SHA-256, output as lowercase hex string.
--
--   hash_msisdn = TO_HEX(SHA256(CONCAT(msisdn_string, '||', SALT)))
--
-- Why salted?
--   Indonesian mobile numbers are ~12–13 digits — an enumerable space.
--   An unsalted SHA-256 can be reversed by a rainbow table in minutes.
--   A project-specific salt makes pre-computation infeasible.
--
-- Salt management:
--   Replace SALT_PLACEHOLDER below with a secret string stored in your
--   team's secret manager (e.g., GCP Secret Manager).
--   Do NOT commit the actual salt value to version control.
--   The same salt must be used consistently if you need to re-identify
--   or join on hash_msisdn in future queries.
--
-- Alternative (unsalted) — use only if downstream system requires it:
--   TO_HEX(SHA256(CAST(msisdn AS STRING)))
-- ============================================================
-- Output columns:
--   hash_msisdn             — salted SHA-256 hex of msisdn (64 chars)
--   nik                     — national ID; matching key for provider
--   kabupaten               — district (reference)
--   province                — province
--   user_persona            — behavioral segment
--   age_bin                 — age group bin
--   neighborhood_tier       — original 5-tier value
--   neighborhood_tier_grouped — grouped 3-tier (High / Med / Low)
--   ses_category            — socioeconomic segment
-- NOTE: msisdn is intentionally excluded from the output.
-- ============================================================

CREATE OR REPLACE TABLE
  `data-int-advana-prd-77c3.core_analytics.rnr_income_prediction_sample_external`
AS

WITH

-- ── Salt definition ───────────────────────────────────────────────────────────
-- Replace 'SALT_PLACEHOLDER' with your actual project salt before running.
-- Retrieve from GCP Secret Manager or equivalent; do not hardcode in prod.
salt AS (
  SELECT 'SALT_PLACEHOLDER' AS value
)

SELECT
  -- Hashed msisdn: salted SHA-256 → lowercase hex string (64 characters)
  TO_HEX(
    SHA256(CONCAT(CAST(s.msisdn AS STRING), '||', salt.value))
  )                                    AS hash_msisdn,

  s.nik,
  s.kabupaten,
  s.province,
  s.user_persona,
  s.age_bin,
  s.neighborhood_tier,
  s.neighborhood_tier_grouped,
  s.ses_category

FROM `data-int-advana-prd-77c3.core_analytics.rnr_income_prediction_sample_final` s
CROSS JOIN salt
;
