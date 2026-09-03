-- =============================================================================
-- User Persona Query v2 (App-Level RTF / "Old Logic")
-- -----------------------------------------------------------------------------
-- RTF deciles are computed PER APPLICATION, not per persona category.
-- A user qualifies for a persona if they are classified as "High Engaged User"
-- on at least one app that belongs to that persona's app list.
--
-- This is intentionally kept comparable to v2 so the two result sets can be
-- joined/counted side-by-side to understand the population difference.
--
-- Persona app mapping: same taxonomy-driven approach as user_persona_query_v2.sql
-- =============================================================================

CREATE OR REPLACE TABLE `data-int-advana-prd-77c3.core_analytics.rnr_user_persona_small_segment_temp_3_old` AS

WITH

-- ---------------------------------------------------------------------------
-- Step 0: Build app → persona mapping (identical to v2)
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

        -- muslim_fashion: app_name-based, no secondary category needed
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
-- Step 1: Aggregate RTF per (msisdn, application_name)
-- Each app is treated independently — no persona rollup yet
-- ---------------------------------------------------------------------------
app_rtf AS (
  SELECT
    u.msisdn,
    LOWER(TRIM(u.application_name)) AS application_name,
    SUM(u.traffic)                  AS app_traffic,
    MIN(u.recency)                  AS app_recency,    -- most recent session for this app
    SUM(u.frequency)                AS app_frequency   -- total days active on this app
  FROM `appl-int-df-prd-wd2y.bq_df_dm3_prd_owned_summary.stg_nio_appsrtgout_usecase_weekly` u
  INNER JOIN app_persona ap
    ON LOWER(TRIM(u.application_name)) = ap.application_name
  WHERE u.partition_date = DATE_SUB(DATE_TRUNC(CURRENT_DATE(), WEEK), INTERVAL 1 DAY)
  GROUP BY 1, 2
),

-- ---------------------------------------------------------------------------
-- Step 2: Compute deciles at the APPLICATION level
-- Users are ranked against all others who used the same app
-- ---------------------------------------------------------------------------
app_deciles AS (
  SELECT
    msisdn,
    application_name,
    app_traffic,
    app_recency,
    app_frequency,
    NTILE(10) OVER (PARTITION BY application_name ORDER BY app_traffic   ASC)  AS traffic_decile,
    NTILE(10) OVER (PARTITION BY application_name ORDER BY app_recency   DESC) AS recency_decile,  -- lower days_ago = more recent = higher decile
    NTILE(10) OVER (PARTITION BY application_name ORDER BY app_frequency ASC)  AS frequency_decile
  FROM app_rtf
),

-- ---------------------------------------------------------------------------
-- Step 3: Classify each (msisdn, app) into an engagement group
-- ---------------------------------------------------------------------------
app_engagement AS (
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
  FROM app_deciles
),

-- ---------------------------------------------------------------------------
-- Step 4: Keep only high-engaged (msisdn, app) pairs, then join to persona
-- If a user is High Engaged on ANY app in a persona → they qualify
-- ---------------------------------------------------------------------------
high_engaged_apps AS (
  SELECT
    ae.msisdn,
    ap.persona,
    ae.application_name,
    ae.app_traffic,
    ae.app_recency,
    ae.app_frequency,
    ae.traffic_decile,
    ae.recency_decile,
    ae.frequency_decile
  FROM app_engagement ae
  INNER JOIN app_persona ap
    ON ae.application_name = ap.application_name
  WHERE ae.engagement_group = 'High Engaged User'
)

-- ---------------------------------------------------------------------------
-- Final output: one row per (msisdn, persona)
-- Aggregated to show the strongest-performing app driving the persona
-- and the count of qualifying apps per persona for the user
-- ---------------------------------------------------------------------------
SELECT
  msisdn,
  persona                                              AS user_persona,
  'High Engaged User'                                  AS engagement_group,
  COUNT(DISTINCT application_name)                     AS qualifying_app_count,    -- how many apps drove this persona
  MAX(app_traffic)                                     AS max_app_traffic,
  MIN(app_recency)                                     AS min_app_recency,
  MAX(app_frequency)                                   AS max_app_frequency,
  MAX(traffic_decile)                                  AS best_traffic_decile,
  MAX(recency_decile)                                  AS best_recency_decile,
  MAX(frequency_decile)                                AS best_frequency_decile
FROM high_engaged_apps
GROUP BY msisdn, persona
ORDER BY msisdn, user_persona
