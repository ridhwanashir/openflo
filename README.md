# DS-IOH Application Mapping

End-to-end pipeline for maintaining the IOH app taxonomy catalog and generating weekly user persona segments in BigQuery.

---

## What This Does

1. **Source of truth** — two CSVs in this repo define the app taxonomy
2. **Automated sync** — an Airflow DAG runs daily, pulls both CSVs from this repo, and does a full-replace load into BigQuery
3. **Persona generation** — a SQL query reads the BQ catalog and classifies IOH subscribers into 18 behavioral personas based on weekly app usage

---

## Architecture

```
This repo (GitLab)
├── rnr_app_category_v2.csv     ← edit here to update app catalog
└── taxonomy_reference.csv      ← edit here to update taxonomy
         │
         │  Airflow DAG (daily, Cloud Composer)
         │  dags/app_catalog_sync.py
         ▼
BigQuery: core_analytics.rnr_app_category_v2        (1,200+ app entries)
BigQuery: core_analytics.rnr_taxonomy_reference     (65 category/subcategory rows)
         │
         │  Run user_persona_query_v2.sql on demand
         ▼
BigQuery: core_analytics.rnr_user_persona_small_segment_temp_3
         (18 personas × High Engaged Users only)
```

**GCP Project:** `data-int-advana-prd-77c3` | **BQ Dataset:** `core_analytics`

---

## Quick Start

See [MAINTENANCE_GUIDE.md](MAINTENANCE_GUIDE.md) for full step-by-step instructions.

### Edit the app catalog
1. Open `rnr_app_category_v2.csv` on GitLab → click **Edit**
2. Use `|` (pipe) to separate multiple values in `sig_app_tags` and `source_app_names_old`
3. Commit → trigger the `app_catalog_sync` DAG in Cloud Composer

### First-time deployment
1. Upload `dags/app_catalog_sync.py` to your Composer GCS bucket (`gs://<bucket>/dags/`)
2. Set three Airflow Variables: `GITLAB_PAT`, `GITLAB_RAW_URL`, `GITLAB_TAXONOMY_RAW_URL`

---

## Files

| File | Purpose |
|---|---|
| `rnr_app_category_v2.csv` | App catalog — 1,200+ apps with categories and match tags |
| `taxonomy_reference.csv` | Valid category/subcategory hierarchy with app counts |
| `dags/app_catalog_sync.py` | Airflow DAG — syncs both CSVs to BigQuery daily |
| `user_persona_query_v2.sql` | Generates weekly user persona segments |
| `MAINTENANCE_GUIDE.md` | Full operations and troubleshooting guide |
| `app_mapping_migration.ipynb` | Historical migration notebook |
| `csv_to_json.ipynb` | Converts CSV to Avro/JSONL for manual BQ loads |

---

## BigQuery Tables

| Table | Rows | Description |
|---|---|---|
| `rnr_app_category_v2` | ~1,200 | App catalog with REPEATED `sig_app_tags` and `source_app_names_old` |
| `rnr_taxonomy_reference` | 73 | Category/subcategory reference with definitions and boundary rules |
| `rnr_user_persona_small_segment_temp_3` | Weekly | High Engaged Users × 18 personas |

---

## User Personas (16 total)

| Persona | Based on |
|---|---|
| `active_in_social_media` | Social, messaging, short video apps |
| `beauty_enthusiast` | Beauty & personal care apps |
| `cashless_lifestyle` | E-wallet, payment, BNPL apps |
| `crypto_trader` | Crypto & digital asset apps |
| `ecommerce_addict` | Marketplace apps |
| `food_hunter` | Dining & food delivery apps |
| `gamers` | Mobile games & gaming platforms |
| `health_enthusiast` | Telemedicine & fitness apps |
| `mom_and_baby` | Maternal & family apps |
| `movie_lovers` | Video streaming apps |
| `music_addict` | Music streaming apps |
| `muslim_fashion` | Hardcoded list of hijab/modest fashion brands |
| `premium_fashion_shopper` | Fashion commerce apps (excl. muslim_fashion) |
| `ride_hailing_loyalist` | Ride-hailing apps |
| `student_e-learning` | Education & LMS apps |
| `travel_enthusiast` | Travel booking apps |

---

## Setup

### Airflow Variables required

| Variable | Value |
|---|---|
| `GITLAB_PAT` | GitLab PAT with `read_repository` scope |
| `GITLAB_RAW_URL` | Raw URL to `rnr_app_category_v2.csv` |
| `GITLAB_TAXONOMY_RAW_URL` | Raw URL to `taxonomy_reference.csv` |

### GitLab remote

```bash
git remote add upstream https://mygitlab-dev.ioh.co.id/cbo/b2b-data-monetization/data-scientist/ds-ioh-application-mapping.git
```
