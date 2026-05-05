WITH app_category AS (
  -- Map every app to its persona category
  SELECT application_name, category FROM UNNEST([
    -- active_in_social_media
    STRUCT('facebook'            AS application_name, 'active_in_social_media' AS category),
    STRUCT('tiktok',              'active_in_social_media'),
    STRUCT('instagram',           'active_in_social_media'),
    STRUCT('whatsapp',            'active_in_social_media'),
    STRUCT('facebook_messenger',  'active_in_social_media'),
    -- beauty_enthusiast
    STRUCT('femaledaily',         'beauty_enthusiast'),
    STRUCT('beautynesia_id',      'beauty_enthusiast'),
    STRUCT('sephora',             'beauty_enthusiast'),
    STRUCT('beautycircle',        'beauty_enthusiast'),
    STRUCT('pixieset',            'beauty_enthusiast'),
    STRUCT('oriflame',            'beauty_enthusiast'),
    STRUCT('sociolla',            'beauty_enthusiast'),
    STRUCT('soco',                'beauty_enthusiast'),
    STRUCT('watsonsid',           'beauty_enthusiast'),
    STRUCT('guardian',            'beauty_enthusiast'),
    -- ecommerce_addict
    STRUCT('shopee',              'ecommerce_addict'),
    STRUCT('lazada',              'ecommerce_addict'),
    STRUCT('tokopedia',           'ecommerce_addict'),
    STRUCT('olx',                 'ecommerce_addict'),
    -- food_hunter
    STRUCT('pergikuliner',        'food_hunter'),
    STRUCT('mcdonalds',           'food_hunter'),
    STRUCT('kopikenangan',        'food_hunter'),
    STRUCT('forecoffee',          'food_hunter'),
    STRUCT('dominos',             'food_hunter'),
    STRUCT('kfcku',               'food_hunter'),
    STRUCT('zomato',              'food_hunter'),
    STRUCT('dominospizza',        'food_hunter'),
    STRUCT('maxx_coffe',          'food_hunter'),
    STRUCT('kfc',                 'food_hunter'),
    STRUCT('hangry',              'food_hunter'),
    -- gamers
    STRUCT('rayjump',             'gamers'),
    STRUCT('helixjump',           'gamers'),
    STRUCT('subwaysurfers',       'gamers'),
    STRUCT('8ballpool',           'gamers'),
    STRUCT('mobilelegends',       'gamers'),
    STRUCT('freefire',            'gamers'),
    STRUCT('roblox',              'gamers'),
    STRUCT('pubg',                'gamers'),
    STRUCT('garena',              'gamers'),
    STRUCT('clashofclans',        'gamers'),
    STRUCT('clashroyale',         'gamers'),
    STRUCT('brawlstars',          'gamers'),
    STRUCT('lordsmobile',         'gamers'),
    STRUCT('mobilelegends',       'gamers'),
    STRUCT('stumbleguys',         'gamers'),
    STRUCT('ludoking',            'gamers'),
    STRUCT('fifamobilesoccer',    'gamers'),
    STRUCT('pokemonunite',        'gamers'),
    STRUCT('lilithgames',         'gamers'),
    -- health_enthusiast
    STRUCT('halodoc',             'health_enthusiast'),
    STRUCT('hellosehat',          'health_enthusiast'),
    STRUCT('k24klikapotekonline', 'health_enthusiast'),
    STRUCT('alomedika',           'health_enthusiast'),
    STRUCT('fitaja',              'health_enthusiast'),
    STRUCT('alodokter',           'health_enthusiast'),
    -- mom_and_baby
    STRUCT('babybus',             'mom_and_baby'),
    STRUCT('orami',               'mom_and_baby'),
    STRUCT('tentang_anak',        'mom_and_baby'),
    STRUCT('teman_bumil',         'mom_and_baby'),
    STRUCT('hallobumil',          'mom_and_baby'),
    STRUCT('the_asian_parent',    'mom_and_baby'),
    STRUCT('healthparenting',     'mom_and_baby'),
    STRUCT('pregnancy_tracker',   'mom_and_baby'),
    STRUCT('bukubumil',           'mom_and_baby'),
    STRUCT('babycentre',          'mom_and_baby'),
    -- movie_lovers
    STRUCT('netflix',             'movie_lovers'),
    STRUCT('vidio',               'movie_lovers'),
    STRUCT('wetv',                'movie_lovers'),
    STRUCT('disneyplus',          'movie_lovers'),
    STRUCT('viu',                 'movie_lovers'),
    STRUCT('hotstar',             'movie_lovers'),
    STRUCT('amazon_prime',        'movie_lovers'),
    STRUCT('genflix',             'movie_lovers'),
    STRUCT('iflix',               'movie_lovers'),
    STRUCT('catchplay',           'movie_lovers'),
    -- music_addict
    STRUCT('spotify',             'music_addict'),
    STRUCT('youtubemusic',        'music_addict'),
    STRUCT('soundcloud',          'music_addict'),
    STRUCT('jooxmusic',           'music_addict'),
    STRUCT('smule',               'music_addict'),
    STRUCT('musixmatch',          'music_addict'),
    -- muslim_fashion
    STRUCT('elbina_hijab',        'muslim_fashion'),
    STRUCT('zoya',                'muslim_fashion'),
    STRUCT('elzatta',             'muslim_fashion'),
    STRUCT('house_of_amee',       'muslim_fashion'),
    STRUCT('tuneeca',             'muslim_fashion'),
    STRUCT('jilbrave',            'muslim_fashion'),
    -- student_e-learning
    STRUCT('ruang_guru',          'student_e-learning'),
    STRUCT('brainly',             'student_e-learning'),
    STRUCT('googleclassroom',     'student_e-learning'),
    STRUCT('zenius',              'student_e-learning'),
    STRUCT('quipper',             'student_e-learning'),
    STRUCT('kelas_pintar',        'student_e-learning'),
    STRUCT('rumah_belajar',       'student_e-learning'),
    STRUCT('cakap',               'student_e-learning'),
    STRUCT('gauthmath',           'student_e-learning'),
    -- travel_enthusiast
    STRUCT('traveloka',           'travel_enthusiast'),
    STRUCT('tiket',               'travel_enthusiast'),
    STRUCT('agoda',               'travel_enthusiast'),
    STRUCT('booking',             'travel_enthusiast'),
    STRUCT('airbnb',              'travel_enthusiast'),
    STRUCT('trivago',             'travel_enthusiast'),
    STRUCT('pegipegi',            'travel_enthusiast'),
    STRUCT('expedia',             'travel_enthusiast'),
    STRUCT('kaiaccess',           'travel_enthusiast')
  ])
),

-- Step 1: aggregate RTF per (msisdn, category) from the weekly SOR table
category_rtf AS (
  SELECT
    u.msisdn,
    c.category,
    SUM(u.traffic)   AS category_traffic,
    MIN(u.recency)   AS category_recency,    -- most recent touch of any app in the category
    SUM(u.frequency) AS category_frequency   -- total app-days across all apps in the category
  FROM `appl-int-df-prd-wd2y.bq_df_dm3_prd_owned_summary.stg_nio_appsrtgout_usecase_weekly` u
  INNER JOIN app_category c ON u.application_name = c.application_name
  WHERE u.partition_date = DATE_SUB(DATE_TRUNC(CURRENT_DATE(), WEEK), INTERVAL 1 DAY)
  GROUP BY 1, 2
),

-- Step 2: compute deciles at the CATEGORY level (users compared within the same category)
category_deciles AS (
  SELECT
    msisdn,
    category,
    category_traffic,
    category_recency,
    category_frequency,
    NTILE(10) OVER (PARTITION BY category ORDER BY category_traffic ASC)  AS traffic_decile,
    NTILE(10) OVER (PARTITION BY category ORDER BY category_recency DESC) AS recency_decile,  -- DESC: lower days = more recent = higher decile
    NTILE(10) OVER (PARTITION BY category ORDER BY category_frequency ASC) AS frequency_decile
  FROM category_rtf
),

-- Step 3: apply engagement group classification (same logic as the existing SP)
category_engagement AS (
  SELECT
    *,
    CASE
      WHEN recency_decile <= 5
        THEN 'Non Active User'
      WHEN recency_decile > 5 AND traffic_decile   BETWEEN 1 AND 3 AND frequency_decile BETWEEN 1 AND 3
        THEN 'Low Engaged User'
      WHEN recency_decile > 5 AND traffic_decile   BETWEEN 8 AND 10 AND frequency_decile BETWEEN 8 AND 10
        THEN 'High Engaged User'
      WHEN recency_decile > 5 AND traffic_decile   BETWEEN 8 AND 10 AND frequency_decile BETWEEN 1 AND 3
        THEN 'Impulsive User'
      WHEN recency_decile > 5 AND traffic_decile   BETWEEN 1 AND 3 AND frequency_decile BETWEEN 8 AND 10
        THEN 'Non Effective User'
      ELSE 'Normal User'
    END AS engagement_group
  FROM category_deciles
)

-- Final: only High Engaged Users get the persona
SELECT
  msisdn,
  category         AS user_persona,
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