# DS-IOH Application Mapping

End-to-end pipeline for maintaining the IOH app taxonomy catalog and generating weekly user persona segments in BigQuery.

---

## What This Does

1. **Source of truth** — `rnr_app_category_v2.csv` in GitLab defines the app catalog, persona mapping, and taxonomy
2. **Current sync path** — the latest CSV is uploaded to GCS manually, then the Airflow DAG reads that GCS object, loads it to BigQuery, and derives a taxonomy snapshot automatically
3. **Persona generation** — a weekly stored procedure reads the `persona` column from the BQ catalog and classifies IOH subscribers into 18 behavioral personas based on app usage

---

## Architecture

```
This repo (GitLab)
└── rnr_app_category_v2.csv     ← edit here to update app catalog + persona mapping
         │
         │  CURRENT: manual upload
         ▼
GCS: gs://create_gcs_table/app-category-mapping/rnr_app_category_v2.csv
         │
         │  Airflow DAG (manual trigger by default, Cloud Composer)
         │  dags/app_catalog_sync.py
         ▼
BigQuery: core_analytics.rnr_app_category_v2        (1,200+ app entries, incl. persona)
BigQuery: core_analytics.rnr_taxonomy_reference     (auto-derived, date-partitioned)
         │
         │  Weekly stored procedure (SP)
         │  bq_sp_national_stg_nio_appsrtgout_usecase_weekly
         ▼
BigQuery: stg_nio_appsrtgout_usecase_weekly
         (18 personas × all engagement groups)
```

**GCP Project:** `data-int-advana-prd-77c3` | **BQ Dataset:** `core_analytics`

---

## Quick Start

See [MAINTENANCE_GUIDE.md](MAINTENANCE_GUIDE.md) for full step-by-step instructions.

### Edit the app catalog
1. Open `rnr_app_category_v2.csv` on GitLab → click **Edit**
2. Use `|` (pipe) to separate multiple values in `sig_app_tags`, `nio_aggr_app_tags`, and `persona`
3. Commit the change
4. Upload the latest CSV to GCS:
   ```bash
   gcloud storage cp rnr_app_category_v2.csv gs://create_gcs_table/app-category-mapping/rnr_app_category_v2.csv
   ```
5. Trigger the `app_catalog_sync` DAG in Cloud Composer

### First-time deployment
1. Upload `dags/app_catalog_sync.py` to your Composer GCS bucket (`gs://<bucket>/dags/`)
2. Ensure the Composer service account can read `gs://create_gcs_table` and write to the target BigQuery tables
3. Optional: set Airflow Variable `schedule_interval` to `{"app_catalog_sync": "@daily"}` if scheduled runs are required

---

## Files

| File | Purpose |
|---|---|
| `rnr_app_category_v2.csv` | App catalog — 1,200+ apps with categories, match tags, and persona mapping |
| `taxonomy_reference.csv` | Historical taxonomy reference (no longer used by DAG — taxonomy is auto-derived) |
| `dags/app_catalog_sync.py` | Airflow DAG — syncs app catalog from GCS to BigQuery and derives taxonomy on each DAG run |
| `stored_procedures/bq_sp_...weekly.sql` | Weekly persona SP — reads persona from BQ catalog, classifies users |
| `user_persona_query_v2.sql` | Deprecated — replaced by the stored procedure |
| `MAINTENANCE_GUIDE.md` | Full operations and troubleshooting guide |
| `app_mapping_migration.ipynb` | Historical migration notebook |
| `csv_to_json.ipynb` | Converts CSV to Avro/JSONL for manual BQ loads |

---

## BigQuery Tables

| Table | Rows | Description |
|---|---|---|
| `rnr_app_category_v2` | ~1,200 | App catalog with REPEATED `sig_app_tags`, `nio_aggr_app_tags`, and `persona` |
| `rnr_taxonomy_reference` | ~73/partition | Auto-derived taxonomy, date-partitioned by `taxonomy_version` |
| `stg_nio_appsrtgout_usecase_weekly` | Weekly | All users × 18 personas × engagement groups (produced by SP) |

---

## User Personas (18 total)

| Persona | Based on |
|---|---|
| `active_in_social_media` | Social, messaging, short video apps |
| `beauty_enthusiast` | Beauty & personal care apps |
| `cashless_lifestyle` | E-wallet, payment, BNPL, mobile banking apps |
| `crypto_trader` | Crypto & digital asset apps |
| `ecommerce_addict` | Marketplace apps |
| `food_hunter` | Dining, food delivery & cooking apps |
| `gamers` | Mobile games & gaming platforms |
| `health_enthusiast` | Telemedicine, fitness & health wearable apps |
| `mom_and_baby` | Maternal & family apps |
| `movie_lovers` | Video streaming apps |
| `music_addict` | Music streaming apps |
| `muslim_fashion` | Labeled in CSV + inferred via ecommerce∩religious intersection |
| `news_reader` | News & media apps |
| `premium_fashion_shopper` | Fashion commerce apps (excl. muslim_fashion) |
| `religious_content` | Religious & spiritual content apps |
| `ride_hailing_loyalist` | Ride-hailing apps |
| `student_e-learning` | Education, LMS & reference apps |
| `travel_enthusiast` | Travel booking, navigation & transit apps |

---

## Setup

### Airflow Variables

| Variable | Value |
|---|---|
| `schedule_interval` | Optional JSON, e.g. `{"app_catalog_sync": "@daily"}`. If missing, the DAG is manual-trigger only. |

No GitLab PAT is required for the current DAG. Composer does not read GitLab directly.

### Automation status

Current operating mode is manual:

1. GitLab remains the source of truth for `rnr_app_category_v2.csv`
2. Someone uploads the latest committed CSV to GCS manually
3. Composer reads the GCS object and loads BigQuery

Known blockers before full automation:

| Automation path | Current blocker |
|---|---|
| GitLab runner uploads CSV to GCS | Runner / service account WIF access to GCS is not confirmed working |
| Composer DAG reads GitLab directly | Composer does not currently have GitLab repository access |

### GitLab remote

```bash
git remote add gitlab https://mygitlab-dev.ioh.co.id/cbo/b2b-data-monetization/data-scientist/ds-ioh-application-mapping.git
```
