-- =============================================================================
-- User Persona Query v2
-- -----------------------------------------------------------------------------
-- Changes from v1:
--   • Replaces the hardcoded ~100-app STRUCT list with a dynamic JOIN against
--     the taxonomy catalog: data-int-advana-prd-77c3.core_analytics.rnr_app_category_v2
--   • sig_app_tags is pipe-split and LOWER/TRIM-normalised for case-safe matching
--   • Adds 4 new personas driven by taxonomy subcategories:
--       cashless_lifestyle, crypto_trader, ride_hailing_loyalist, premium_fashion_shopper
--   • muslim_fashion is retained via an app_name hardcoded list (no dedicated
--     subcategory in the current taxonomy)
--   • RTF aggregation, decile computation, and engagement group logic unchanged
-- =============================================================================

CREATE OR REPLACE TABLE `data-int-advana-prd-77c3.core_analytics.rnr_user_persona_small_segment_temp_3` AS

WITH

-- ---------------------------------------------------------------------------
-- Step 0: Build app → persona mapping from the taxonomy catalog
--
-- sig_app_tags can hold multiple pipe-separated identifiers, e.g. "bca|klikbca|mybca".
-- Each tag is exploded into one row and lower-trimmed so it binds safely to
-- application_name values in the SOR table (which are already lowercase).
--
-- Persona assignment priority (CASE is evaluated top-to-bottom):
--   1. muslim_fashion  → hardcoded app_name list (checked BEFORE commerce.fashion)
--   2. Taxonomy-driven → (category, subcategory) CASE mapping
--   3. premium_fashion_shopper → commerce.fashion, excluding muslim_fashion apps
-- ---------------------------------------------------------------------------
app_persona AS (
  SELECT DISTINCT
    LOWER(TRIM(tag)) AS application_name,
    persona
  FROM (
    SELECT
      r.app_name,
      r.category,
      r.subcategory,
      r.secondary_category,
      r.secondary_subcategory,
      tag,
      CASE
        -- ── Existing personas ──────────────────────────────────────────────

        WHEN (
            (r.category = 'communication'           AND r.subcategory           IN ('social_network', 'short_video_live', 'instant_messaging'))
          OR (r.secondary_category = 'communication' AND r.secondary_subcategory IN ('social_network', 'short_video_live', 'instant_messaging'))
          )
          THEN 'active_in_social_media'

        WHEN (
            (r.category = 'lifestyle'           AND r.subcategory           = 'beauty_personal_care')
          OR (r.secondary_category = 'lifestyle' AND r.secondary_subcategory = 'beauty_personal_care')
          )
          THEN 'beauty_enthusiast'

        WHEN (
            (r.category = 'commerce'           AND r.subcategory           = 'marketplace')
          OR (r.secondary_category = 'commerce' AND r.secondary_subcategory = 'marketplace')
          )
          THEN 'ecommerce_addict'

        WHEN (
            (r.category = 'lifestyle'           AND r.subcategory           IN ('dining_fnb', 'food_delivery'))
          OR (r.secondary_category = 'lifestyle' AND r.secondary_subcategory IN ('dining_fnb', 'food_delivery'))
          )
          THEN 'food_hunter'

        WHEN (
            (r.category = 'entertainment'           AND r.subcategory           IN ('mobile_games', 'gaming_platform'))
          OR (r.secondary_category = 'entertainment' AND r.secondary_subcategory IN ('mobile_games', 'gaming_platform'))
          )
          THEN 'gamers'

        WHEN (
            (r.category = 'health_wellness'           AND r.subcategory           IN ('healthcare_telemedicine', 'fitness_sport'))
          OR (r.secondary_category = 'health_wellness' AND r.secondary_subcategory IN ('healthcare_telemedicine', 'fitness_sport'))
          )
          THEN 'health_enthusiast'

        WHEN (
            (r.category = 'health_wellness'           AND r.subcategory           = 'maternal_family')
          OR (r.secondary_category = 'health_wellness' AND r.secondary_subcategory = 'maternal_family')
          )
          THEN 'mom_and_baby'

        WHEN (
            (r.category = 'entertainment'           AND r.subcategory           = 'video_streaming')
          OR (r.secondary_category = 'entertainment' AND r.secondary_subcategory = 'video_streaming')
          )
          THEN 'movie_lovers'

        WHEN (
            (r.category = 'entertainment'           AND r.subcategory           = 'music_streaming')
          OR (r.secondary_category = 'entertainment' AND r.secondary_subcategory = 'music_streaming')
          )
          THEN 'music_addict'

        -- muslim_fashion: app_name-based, no secondary category needed.
        -- Evaluated BEFORE commerce.fashion to take precedence over premium_fashion_shopper.
        WHEN LOWER(r.app_name) IN (
            'elbina hijab', 'zoya', 'elzatta', 'house of amee', 'tuneeca', 'jilbrave', 'zizara'
          )
          THEN 'muslim_fashion'

        WHEN (
            (r.category = 'information_education'           AND r.subcategory           IN ('general_education', 'campus_lms'))
          OR (r.secondary_category = 'information_education' AND r.secondary_subcategory IN ('general_education', 'campus_lms'))
          )
          THEN 'student_e-learning'

        WHEN (
            (r.category = 'transportation'           AND r.subcategory           = 'travel_booking')
          OR (r.secondary_category = 'transportation' AND r.secondary_subcategory = 'travel_booking')
          )
          THEN 'travel_enthusiast'

        -- ── New personas ───────────────────────────────────────────────────

        WHEN (
            (r.category = 'finance'           AND r.subcategory           IN ('e_wallet', 'payment_gateway', 'bnpl_pay_later'))
          OR (r.secondary_category = 'finance' AND r.secondary_subcategory IN ('e_wallet', 'payment_gateway', 'bnpl_pay_later'))
          )
          THEN 'cashless_lifestyle'

        WHEN (
            (r.category = 'finance'           AND r.subcategory           = 'crypto_digital_assets')
          OR (r.secondary_category = 'finance' AND r.secondary_subcategory = 'crypto_digital_assets')
          )
          THEN 'crypto_trader'

        WHEN (
            (r.category = 'transportation'           AND r.subcategory           = 'ride_hailing')
          OR (r.secondary_category = 'transportation' AND r.secondary_subcategory = 'ride_hailing')
          )
          THEN 'ride_hailing_loyalist'

        -- premium_fashion_shopper: primary OR secondary commerce.fashion, excluding muslim_fashion brands
        WHEN (
            (r.category = 'commerce'           AND r.subcategory           = 'fashion')
          OR (r.secondary_category = 'commerce' AND r.secondary_subcategory = 'fashion')
          )
          AND LOWER(r.app_name) NOT IN (
            'elbina hijab', 'zoya', 'elzatta', 'house of amee', 'tuneeca', 'jilbrave', 'zizara'
          )
          THEN 'premium_fashion_shopper'

        ELSE NULL
      END AS persona
    FROM `data-int-advana-prd-77c3.core_analytics.rnr_app_category_v2` r,
    UNNEST(SPLIT(r.sig_app_tags, '|')) AS tag
    WHERE r.sig_app_tags IS NOT NULL
  )
  WHERE persona IS NOT NULL
),

-- ---------------------------------------------------------------------------
-- Step 1: Aggregate RTF per (msisdn, persona) from the weekly SOR table
-- Join uses LOWER(TRIM(...)) on the source side to match the normalised tags
-- ---------------------------------------------------------------------------
category_rtf AS (
  SELECT
    u.msisdn,
    ap.persona                 AS category,
    SUM(u.traffic)             AS category_traffic,
    MIN(u.recency)             AS category_recency,    -- most recent interaction with any app in the persona
    SUM(u.frequency)           AS category_frequency   -- total app-days across all apps in the persona
  FROM `appl-int-df-prd-wd2y.bq_df_dm3_prd_owned_summary.stg_nio_appsrtgout_usecase_weekly` u
  INNER JOIN app_persona ap
    ON LOWER(TRIM(u.application_name)) = ap.application_name
  WHERE u.partition_date = DATE_SUB(DATE_TRUNC(CURRENT_DATE(), WEEK), INTERVAL 1 DAY)
  GROUP BY 1, 2
),

-- ---------------------------------------------------------------------------
-- Step 2: Compute deciles at the persona level
-- Users are ranked against others who touched the same persona's apps
-- ---------------------------------------------------------------------------
category_deciles AS (
  SELECT
    msisdn,
    category,
    category_traffic,
    category_recency,
    category_frequency,
    NTILE(10) OVER (PARTITION BY category ORDER BY category_traffic   ASC)  AS traffic_decile,
    NTILE(10) OVER (PARTITION BY category ORDER BY category_recency   DESC) AS recency_decile,   -- lower days_ago = more recent = higher decile
    NTILE(10) OVER (PARTITION BY category ORDER BY category_frequency ASC)  AS frequency_decile
  FROM category_rtf
),

-- ---------------------------------------------------------------------------
-- Step 3: Classify each (msisdn, persona) into an engagement group
-- ---------------------------------------------------------------------------
category_engagement AS (
  SELECT
    *,
    CASE
      WHEN recency_decile <= 5
        THEN 'Non Active User'
      WHEN recency_decile > 5 AND traffic_decile BETWEEN 1  AND 3  AND frequency_decile BETWEEN 1  AND 3
        THEN 'Low Engaged User'
      WHEN recency_decile > 5 AND traffic_decile BETWEEN 8  AND 10 AND frequency_decile BETWEEN 8  AND 10
        THEN 'High Engaged User'
      WHEN recency_decile > 5 AND traffic_decile BETWEEN 8  AND 10 AND frequency_decile BETWEEN 1  AND 3
        THEN 'Impulsive User'
      WHEN recency_decile > 5 AND traffic_decile BETWEEN 1  AND 3  AND frequency_decile BETWEEN 8  AND 10
        THEN 'Non Effective User'
      ELSE 'Normal User'
    END AS engagement_group
  FROM category_deciles
)

-- ---------------------------------------------------------------------------
-- Final output: High Engaged Users only
-- One row per (msisdn, persona) — a user can hold multiple personas
-- ---------------------------------------------------------------------------
SELECT
  msisdn,
  category          AS user_persona,
  engagement_group,
  category_traffic,
  category_recency,
  category_frequency,
  traffic_decile,
  recency_decile,
  frequency_decile
FROM category_engagement
WHERE engagement_group = 'High Engaged User'
ORDER BY msisdn, user_persona
