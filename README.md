# DS-IOH SDA App Catalog & Taxonomy

Source repository for creating and maintaining the IOH SDA application catalog (`rnr_app_category_v2`) and its derived taxonomy in BigQuery.

The weekly user-persona pipeline consumes this catalog, but persona generation is a downstream use case rather than the repository's primary responsibility.

---

## Repository Scope

1. **Catalog source of truth** — `rnr_app_category_v2.csv` defines canonical apps, matching tags, categories, descriptions, and optional persona labels.
2. **Derived taxonomy** — the Airflow DAG derives a dated taxonomy snapshot from the catalog. The taxonomy is not maintained as a separate production CSV.
3. **BigQuery synchronization** — the latest committed catalog is uploaded to GCS manually, then loaded into BigQuery by the Composer DAG.
4. **Downstream persona usage** — a weekly stored procedure reads the `persona` column and classifies IOH subscribers into 18 behavioral personas based on app usage.

### Current catalog snapshot

| Metric | Value |
|---|---:|
| App rows | 1,199 |
| L1 categories | 11 |
| Category/subcategory pairs | 73 |
| Persona labels | 18 |
| Rows without `sig_app_tags` | 4 |
| Rows without `persona` | 470 |

The schema includes repeated `els_norm_app_tags` and `els_host` fields. They are currently placeholders: all catalog rows are blank until the ELS normalization/enrichment process is implemented.

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

> **Note:** The `gs://create_gcs_table` bucket also lives in project `data-int-advana-prd-77c3` (same project as the BigQuery dataset).

---

## Quick Start

See [MAINTENANCE_GUIDE.md](MAINTENANCE_GUIDE.md) for full step-by-step instructions.

### Edit the app catalog
> **Access:** Editing the CSV on GitLab requires VPN access.
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
| `rnr_app_category_v2.csv` | Production catalog SSOT — 1,199 apps with categories, matching fields, descriptions, and persona mapping |
| `dags/app_catalog_sync.py` | Airflow DAG — syncs app catalog from GCS to BigQuery and derives taxonomy on each DAG run |
| `stored_procedures/bq_sp_...weekly.sql` | Weekly persona SP — reads persona from BQ catalog, classifies users |
| `archive/` | Historical migration inputs, notebooks, generated formats, and superseded persona queries |
| `data/reference/signature_apps_library_20250828.csv` | Reference library used during historical tag matching and catalog audits |
| `docs/team-overview.md` | Team-facing architecture and downstream-consumer overview |
| `MAINTENANCE_GUIDE.md` | Full operations and troubleshooting guide |

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
git remote add gitlab https://mygitlab-dev.ioh.co.id/cbo/b2b-data-monetization/data-scientist/ds-ioh-sda-app-catalog-taxonomy.git
```

> **Access:** The GitLab instance (`mygitlab-dev.ioh.co.id`) requires VPN access.

---

## Related / Upcoming Work

A separate repo, `DS-IOH-SDA-Application-Mapping-Automation`, is developing an automation pipeline (`sda_app_mapping_automation`, weekly) to auto-discover new unmapped apps from traffic data, research them via Cloud Run (Tavily search + Gemini classification), and route proposals through a Teams approval step before they land in this repo's `rnr_app_category_v2.csv` / SSOT table. **This automation is not yet in production** — this repo remains the source of truth and the current manual workflow (GitLab → GCS → DAG) is still required until that automation ships.
