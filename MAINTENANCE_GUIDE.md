# App Catalog Maintenance Guide

> **Who this is for:** Anyone on the DS-IOH team who needs to update the app taxonomy, deploy the sync pipeline, or troubleshoot BigQuery table issues.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [The CSVs — Source of Truth](#2-the-csvs--source-of-truth)
3. [How to Update the App Catalog](#3-how-to-update-the-app-catalog)
4. [One-Time Setup: Deploy the Airflow DAG](#4-one-time-setup-deploy-the-airflow-dag)
5. [GCS Handoff And Automation Status](#5-gcs-handoff-and-automation-status)
6. [Running the DAG (Manual Trigger)](#6-running-the-dag-manual-trigger)
7. [How the DAG Works (Step by Step)](#7-how-the-dag-works-step-by-step)
8. [BigQuery Tables Reference](#8-bigquery-tables-reference)
9. [What is stg_nio_appsrtgout_usecase_weekly?](#9-what-is-stg_nio_appsrtgout_usecase_weekly)
10. [Troubleshooting](#10-troubleshooting)
11. [Cheat Sheet](#11-cheat-sheet)

---

## 1. Architecture Overview

```
You / Team
   │
   │  Edit rnr_app_category_v2.csv
   ▼
GitLab Repo  ←──── source of truth for the app catalog CSV
   │
   │  CURRENT: manually upload the latest committed CSV
   ▼
GCS: gs://create_gcs_table/app-category-mapping/rnr_app_category_v2.csv
   │
   │  Cloud Composer DAG reads the GCS object
   ▼
Cloud Composer (Airflow)
   │
   │  Parses CSV → full replace app catalog → derive taxonomy snapshot
   ▼
BigQuery: data-int-advana-prd-77c3.core_analytics.rnr_app_category_v2
BigQuery: data-int-advana-prd-77c3.core_analytics.rnr_taxonomy_reference
   │
   │  weekly stored procedure reads these tables
   ▼
BigQuery: stg_nio_appsrtgout_usecase_weekly
(18 personas × all engagement groups)
```

**Key principle:** The CSV is always the complete list. Every DAG run wipes the BQ table and reloads from scratch. No manual BQ edits — any change made directly in BQ will be overwritten on the next run.

**Current operating mode:** GitLab is the human source of truth, but it is not automatically connected to GCS or Composer yet. Upload the latest committed CSV to GCS manually, then trigger the DAG.

**Known automation blockers:**

| Path | Current blocker |
|---|---|
| GitLab runner → GCS | Runner / service account WIF access to GCS is not confirmed working |
| Composer DAG → GitLab repo | Composer does not currently have GitLab repository access |

---

## 2. The CSVs — Source of Truth

There is one active CSV file that the DAG syncs to BigQuery.

---

### File 1: `rnr_app_category_v2.csv`

**BigQuery target:** `core_analytics.rnr_app_category_v2`

### Column Reference

| Column | Type | Notes |
|---|---|---|
| `app_name` | Single value | Display name of the app |
| `nio_aggr_app_tags` | **Pipe-separated** (`\|`) | Alternative/legacy app identifiers (maps to NIO aggregated app tags) |
| `sig_app_tags` | **Pipe-separated** (`\|`) | Tags used to match user activity |
| `category` | Single value | Primary category |
| `subcategory` | Single value | Primary subcategory |
| `secondary_category` | Single value | Optional second category |
| `secondary_subcategory` | Single value | Optional second subcategory |
| `description` | Single value | Free text description |
| `persona` | **Pipe-separated** (`\|`) | Assigned persona(s) for user segmentation (e.g. `cashless_lifestyle`, `ecommerce_addict\|cashless_lifestyle`) |

### Multi-value field format

Use `|` (pipe) to separate multiple values. **No spaces around the pipe.**

```
# Correct
BCA,Klikbca|BCAS_MOBILE2|MYBCA,...

# Wrong — do NOT use brackets or commas for multi-value
BCA,"[Klikbca,BCAS_MOBILE2,MYBCA]",...
```

If an app has only one value, just write the value with no pipe:

```
1cak,1cak,...
```

If a field is empty, leave it blank (no placeholder text):

```
SomeApp,,tag1|tag2,Category,,,,
```

---

### File 2: `taxonomy_reference.csv` (historical artifact)

**BigQuery target:** none directly

> **Note:** The taxonomy table is now **auto-derived** from the app catalog by the DAG on each run. You no longer need to manually maintain `taxonomy_reference.csv`. The CSV is kept in the repo as a historical reference only.

The taxonomy table in BigQuery is partitioned by `taxonomy_version` (DATE), with one snapshot per DAG run. Each run samples up to 5 example apps per subcategory from the catalog.

| Column | Type | Notes |
|---|---|---|
| `category` | Single value | Top-level category (e.g. `finance`, `entertainment`) |
| `subcategory` | Single value | Subcategory (e.g. `mobile_banking`, `mobile_games`) |
| `include_examples` | Pipe-separated | Up to 5 example app names from the catalog |
| `app_count` | Integer | Number of apps in this subcategory (auto-computed) |
| `taxonomy_version` | DATE | DAG execution date (partition key) |

> **Important:** If you add a new `category`/`subcategory` combination to `rnr_app_category_v2.csv`, the taxonomy is updated on the next DAG run after the latest CSV has been uploaded to GCS. A GitLab commit alone does not update BigQuery. No manual edit to `taxonomy_reference.csv` is needed.

---

## 3. How to Update the App Catalog

You have two options. Both result in the same thing — a committed change to `rnr_app_category_v2.csv` in GitLab. After committing, the current production handoff still requires a manual GCS upload.

### Option A — Edit directly on GitLab (no local setup needed)

1. Go to your company GitLab repo
2. Open `rnr_app_category_v2.csv`
3. Click the **Edit** (pencil) button
4. Make your changes in the web editor
5. Scroll down → write a commit message → click **Commit changes**
6. Download or pull the latest committed CSV, then upload it to GCS:
   ```bash
   gcloud storage cp rnr_app_category_v2.csv gs://create_gcs_table/app-category-mapping/rnr_app_category_v2.csv
   ```
7. Trigger the DAG manually — see [Section 6](#6-running-the-dag-manual-trigger)

### Option B — Edit locally and push

```bash
# 1. Pull latest
git pull gitlab master

# 2. Edit the file in Excel / any editor
#    Save as CSV (UTF-8, comma-separated)

# 3. Verify no bracket format crept in (should return 0 matches)
grep -c '\[' rnr_app_category_v2.csv

# 4. Commit and push
git add rnr_app_category_v2.csv
git commit -m "Update app catalog: <describe what changed>"
git push gitlab master

# 5. Upload the latest committed CSV to GCS
gcloud storage cp rnr_app_category_v2.csv gs://create_gcs_table/app-category-mapping/rnr_app_category_v2.csv
```

> **Warning:** If you open the CSV in Excel and save it, Excel may alter the formatting. Check that pipe-separated values are still intact and the file is still comma-delimited before pushing.

---

## 4. One-Time Setup: Deploy the Airflow DAG

This only needs to be done once (or when the DAG file changes).

### Upload the DAG file to Cloud Composer

Cloud Composer stores DAGs in a GCS bucket. Find yours in the Composer environment details page — it looks like:  
`gs://<composer-env-bucket>/dags/`

```bash
# Upload the DAG
gcloud storage cp dags/app_catalog_sync.py gs://<your-composer-bucket>/dags/app_catalog_sync.py
```

Or drag-and-drop the file into the bucket via the GCP Console:  
**Cloud Storage → [your composer bucket] → dags/ folder → Upload file**

The Airflow scheduler picks up new DAG files within ~1–2 minutes automatically.

---

## 5. GCS Handoff And Automation Status

The DAG reads `rnr_app_category_v2.csv` from GCS — **no GitLab Airflow Variables needed**.
The current working handoff is manual upload to GCS.

### GCS source path

```
gs://create_gcs_table/app-category-mapping/rnr_app_category_v2.csv
```

The Composer Service Account already has read access to this bucket.

### Manual upload

After a CSV change is committed to GitLab, upload the exact committed CSV:

```bash
gcloud storage cp rnr_app_category_v2.csv gs://create_gcs_table/app-category-mapping/rnr_app_category_v2.csv
```

### GitLab CI upload status

`.gitlab-ci.yml` contains a manual `upload-csv-to-gcs` job for future automation testing, but do not treat it as the production path yet.

| Requirement | Current status |
|---|---|
| GitLab OIDC / WIF provider | Configured in `.gitlab-ci.yml` |
| GitLab runner service account | `gitlab-ci-de@appl-int-df-prd-wd2y.iam.gserviceaccount.com` |
| Target GCS project | `data-int-advana-prd-77c3` |
| GCS object write access | Not confirmed working |

Once WIF and bucket permissions are fixed, the manual CI job can be promoted back to an automatic upload job.

---

## 6. Running the DAG (Manual Trigger)

After editing the CSV, committing to GitLab, and uploading the latest CSV to GCS:

1. Go to **Cloud Composer → [your environment] → Open Airflow UI**
2. Find `app_catalog_sync` in the DAG list
3. Click the **▶ Trigger DAG** button (the play icon on the right)
4. Optionally click the DAG name → **Graph View** to watch task progress in real time

You will see three tasks run in sequence:
```
[sync_catalog] → [sync_taxonomy] → [validate]
```
`sync_catalog` downloads and loads the app catalog. `sync_taxonomy` derives the taxonomy from the loaded catalog rows. `validate` runs checks after both.

### Choosing a sync schedule

The DAG is currently **manual-trigger by default**. It only becomes scheduled if the Airflow Variable `schedule_interval` includes an entry for `app_catalog_sync`.

| Option | Setting | Best for |
|---|---|---|
| **A — Manual** (current) | missing key or `null` | Full control while GCS upload is manual |
| **B — Daily** | `@daily` | Frequent catalog updates after upload automation is reliable |
| **C — Weekly** | `@weekly` | Stable catalog, infrequent changes |
| **D — On push** | manual DAG trigger from CI | Future option after GitLab runner WIF is fixed |

On-push sync requires two pieces that are not currently in place: GitLab runner write access to GCS and a reliable way to trigger Composer after upload.

### Expected run time

Under 1 minute for ~1,200 app rows + 73 taxonomy rows. If it takes longer than 3 minutes, something is wrong — check the logs.

---

## 7. How the DAG Works (Step by Step)

**File:** `dags/app_catalog_sync.py`

```
[sync_catalog] → [sync_taxonomy] → [validate]
```

### Task 1: `sync_catalog`

1. Downloads `rnr_app_category_v2.csv` from GCS (`gs://create_gcs_table/app-category-mapping/rnr_app_category_v2.csv`)
2. Parses every row:
   - `sig_app_tags`, `nio_aggr_app_tags`, and `persona` → split on `|` → Python list
   - Empty strings → `None`
4. Loads all rows to BigQuery with **WRITE_TRUNCATE** (full replace)
   - Target: `data-int-advana-prd-77c3.core_analytics.rnr_app_category_v2`
   - `sig_app_tags`, `nio_aggr_app_tags`, and `persona` loaded as `REPEATED STRING`
5. Pushes parsed rows to XCom for `sync_taxonomy` to consume

### Task 2: `sync_taxonomy`

1. Pulls parsed catalog rows from XCom (no GitLab download — derived from the catalog)
2. Aggregates per `(category, subcategory)` in CSV order:
   - Counts apps per subcategory
   - Samples up to 5 example app names per subcategory
3. Sets `taxonomy_version` to the DAG execution date
4. Loads to `core_analytics.rnr_taxonomy_reference` with **partition-level TRUNCATE**
   - Destination: `rnr_taxonomy_reference$YYYYMMDD` (overwrites only that day’s partition)
   - Historical partitions are preserved

`sync_catalog` → `sync_taxonomy` run **sequentially** — taxonomy depends on catalog rows.

### Task 3: `validate`

Runs after **both** sync tasks complete. Performs three checks:

#### Check 1: App catalog row count floor
Asserts `loaded_rows >= 1199` (the baseline count when this DAG was written).  
**Why:** Catches catastrophic failures — empty file upload, half-truncated CSV, encoding corruption.

#### Check 2: Taxonomy row count floor
Asserts `taxonomy_rows >= 70` (current taxonomy has ~73 subcategories).  
**Why:** Catches an empty or corrupted catalog that yields too few subcategories.

#### Check 3: BCA spot-check
Queries BQ and asserts `ARRAY_LENGTH(sig_app_tags) = 3` for the `BCA` row.  
**Why BCA?** It's a stable, well-known entry with exactly 3 known tags (`Klikbca`, `BCAS_MOBILE2`, `MYBCA`). This specifically catches **silent REPEATED field parsing failures** — a load that succeeds but has all multi-value fields collapsed into a single-element array (which `ARRAY_LENGTH` would return as 1, not 3).

---

### Choosing a different validation approach

| Option | What it checks | Trade-off |
|---|---|---|
| **A — Current** | Row count floor + taxonomy floor + BCA spot-check | Balanced. Catches most real failures without being fragile. |
| **B — Strict row count** | `loaded_rows == 1199` (exact) | Fails if you intentionally add/remove any app — update the constant every time. |
| **C — Schema check** | Query `INFORMATION_SCHEMA` to verify REPEATED mode | Catches schema drift, but overkill for a simple full-replace pipeline. |
| **D — No validation** | None — trust the BQ load job's `job.errors` | Fastest, but silent failures go undetected until the persona query breaks. |

To switch, edit the `validate` function in `dags/app_catalog_sync.py`.

> If validation fails, the BQ table has already been truncated and reloaded with the potentially wrong data. Fix the CSV, commit it, and re-trigger the DAG.

---

## 8. BigQuery Tables Reference

### App Catalog

**Table:** `data-int-advana-prd-77c3.core_analytics.rnr_app_category_v2`

| Field | BQ Type | Mode |
|---|---|---|
| `app_name` | STRING | NULLABLE |
| `nio_aggr_app_tags` | STRING | **REPEATED** |
| `sig_app_tags` | STRING | **REPEATED** |
| `category` | STRING | NULLABLE |
| `subcategory` | STRING | NULLABLE |
| `secondary_category` | STRING | NULLABLE |
| `secondary_subcategory` | STRING | NULLABLE |
| `description` | STRING | NULLABLE |
| `persona` | STRING | **REPEATED** |

### Taxonomy Reference

**Table:** `data-int-advana-prd-77c3.core_analytics.rnr_taxonomy_reference`  
**Partitioned by:** `taxonomy_version` (DATE, daily)

| Field | BQ Type | Mode |
|---|---|---|
| `category` | STRING | NULLABLE |
| `subcategory` | STRING | NULLABLE |
| `include_examples` | STRING | NULLABLE |
| `app_count` | INTEGER | NULLABLE |
| `taxonomy_version` | DATE | NULLABLE |

### Querying REPEATED fields

REPEATED STRING fields behave like arrays. Use `UNNEST` to expand them:

```sql
-- Count apps per category
SELECT category, COUNT(*) AS app_count
FROM `data-int-advana-prd-77c3.core_analytics.rnr_app_category_v2`
GROUP BY category
ORDER BY app_count DESC;

-- Find which apps have a specific sig_app_tag
SELECT app_name
FROM `data-int-advana-prd-77c3.core_analytics.rnr_app_category_v2`
WHERE 'BCAS_MOBILE2' IN UNNEST(sig_app_tags);

-- Expand all tags (one row per tag)
SELECT app_name, tag
FROM `data-int-advana-prd-77c3.core_analytics.rnr_app_category_v2`,
UNNEST(sig_app_tags) AS tag;
```

---

## 9. What is `stg_nio_appsrtgout_usecase_weekly`?

This is the **output table** produced by the weekly stored procedure `bq_sp_national_stg_nio_appsrtgout_usecase_weekly`. It is not maintained by the DAG — it is regenerated by the SP.

> **Note:** `user_persona_query_v2.sql` is deprecated. Use the stored procedure instead.

### What it contains

One row per `(msisdn, application_name, user_persona)` style result from the app-usage pipeline. A subscriber can appear in multiple personas and engagement groups.

| Column | Description |
|---|---|
| `msisdn` | Hashed subscriber identifier |
| `application_name` | App tag from the usage source after catalog filtering |
| `traffic`, `recency`, `frequency` | Per-app usage features for the weekly lookback window |
| `traffic_decile`, `recency_decile`, `frequency_decile` | Per-app deciles, then used for persona-level scoring |
| `engagement_group` | Per-app engagement group |
| `user_persona` | Assigned persona (e.g. `gamers`, `cashless_lifestyle`) |
| `persona_score` | Sum of persona-level traffic, recency, and frequency deciles |
| `partition_date`, `job_id`, `insert_timestamp` | Load metadata |

### The 18 personas

| Persona | Driven by |
|---|---|
| `active_in_social_media` | `communication`: social_network, short_video_live, instant_messaging |
| `beauty_enthusiast` | `lifestyle`: beauty_personal_care |
| `cashless_lifestyle` | `finance`: e_wallet, payment_gateway, bnpl_pay_later |
| `crypto_trader` | `finance`: crypto_digital_assets |
| `ecommerce_addict` | `commerce`: marketplace |
| `food_hunter` | `lifestyle`: dining_fnb, food_delivery |
| `gamers` | `entertainment`: mobile_games, gaming_platform |
| `health_enthusiast` | `health_wellness`: healthcare_telemedicine, fitness_sport |
| `mom_and_baby` | `health_wellness`: maternal_family |
| `movie_lovers` | `entertainment`: video_streaming |
| `music_addict` | `entertainment`: music_streaming |
| `muslim_fashion` | CSV-labeled apps + behavioral intersection (ecommerce ∩ religious) |
| `news_reader` | `information_education`: news_media |
| `premium_fashion_shopper` | `commerce`: fashion, excluding muslim_fashion apps |
| `religious_content` | `information_education`: religious_spiritual |
| `ride_hailing_loyalist` | `transportation`: ride_hailing |
| `student_e-learning` | `information_education`: general_education, campus_lms |
| `travel_enthusiast` | `transportation`: travel_booking |

### How to regenerate it

The stored procedure runs weekly on schedule. To run manually:

```sql
CALL `appl-int-df-prd-wd2y.bq_df_dm3_prd_owned_sor.bq_sp_national_stg_nio_appsrtgout_usecase_weekly`(
  '<bq_project>',
  '<source_dataset>',
  '<target_dataset>',
  DATE '<run_date>'
);
```

The version-controlled SP source is at `stored_procedures/bq_sp_national_stg_nio_appsrtgout_usecase_weekly.sql`.

**Important:** The SP reads `persona` as a `REPEATED STRING` field from the BQ catalog. This only works correctly if the BQ table was loaded by the DAG.

### How persona assignment works

```
The stored procedure reads persona labels directly from the BQ catalog:
  → rnr_app_category_v2.persona (REPEATED STRING) maps each app to persona(s)
  → No hardcoded CASE logic for persona assignment

For each app in the catalog:
  → each sig_app_tag is UNNEST-ed into one row
  → tag is LOWER/TRIM normalized to match raw app usage data
  → app’s persona(s) come from the persona column (data-driven)

For each subscriber (msisdn):
  → JOIN their weekly app usage against the tag-to-persona mapping
  → aggregate RTF (Recency, Traffic, Frequency) per persona
  → compute deciles within each persona group
  → classify into engagement groups
  → output all engagement groups (not just High Engaged)

Special: muslim_fashion has a supplementary intersection check
  → users in both ecommerce and religious apps get muslim_fashion
  → this is in addition to CSV-labeled muslim_fashion apps
```

---

## 10. Troubleshooting

### DAG fails at `sync_taxonomy` — empty taxonomy

The taxonomy is derived from the app catalog. If the catalog has no valid `category`/`subcategory` values, the taxonomy will be empty. Check the CSV.

### taxonomy_reference.csv has a new subcategory but persona query doesn't use it

The persona mapping now lives in the `persona` column of `rnr_app_category_v2.csv`. Adding a new subcategory without assigning a persona value means those apps will fall into `others` in the SP output. To assign a persona, update the `persona` column for the relevant app rows.

### DAG fails at `sync_catalog` — GCS 403 / permission denied

The Composer Service Account lacks read access to `gs://create_gcs_table`. Ask your
platform team to grant `roles/storage.objectViewer` on the bucket.

### DAG fails at `sync_catalog` — GCS 404 / blob not found

The CSV has not been uploaded to GCS yet. Either:
- Trigger the GitLab CI `upload-csv-to-gcs` job manually, or
- Upload manually: `gcloud storage cp rnr_app_category_v2.csv gs://create_gcs_table/app-category-mapping/rnr_app_category_v2.csv`

### DAG fails at `validate` — row count < 1199

The CSV was uploaded with fewer rows than expected. Check:
- Was the CSV accidentally truncated when saving from Excel?
- Were rows deleted unintentionally?

Fix the CSV, commit, and re-trigger.

### BQ table looks wrong after a run

The table is fully replaced each run. Check the CSV in GitLab — if the CSV is correct, re-trigger the DAG.

### The persona query returns wrong results

1. Check that the BQ table was loaded by the DAG (not manually edited)
2. Verify `sig_app_tags` and `persona` are `REPEATED STRING` in the BQ schema (not plain strings with pipes)
3. The SP uses `UNNEST(r.persona)` — this only works correctly if the field is `REPEATED`
4. Check that `persona` values in the CSV match what the SP expects

### DAG is not visible in Airflow UI

The DAG file hasn't been uploaded to the Composer GCS bucket yet, or Airflow hasn't scanned it yet (wait 1–2 minutes after upload).

---

## 11. Cheat Sheet

```
EDIT APP CATALOG
  → Edit rnr_app_category_v2.csv on GitLab
  → Use | to separate multi-values (no brackets, no commas)
  → persona column: assign persona(s) per app, pipe-separated if multiple
  → Commit the change

TAXONOMY
  → Auto-derived from app catalog on each DAG run
  → No manual editing needed
  → Historical snapshots preserved via date partitioning

SYNC TO BQ
  → Airflow UI → app_catalog_sync → Trigger DAG ▶
  → Wait ~1 min → all three tasks should turn green
  → Task flow: sync_catalog → sync_taxonomy → validate

CHECK BQ
  SELECT COUNT(*) FROM `data-int-advana-prd-77c3.core_analytics.rnr_app_category_v2`
  -- Should return >= 1199
  SELECT taxonomy_version, COUNT(*) FROM `data-int-advana-prd-77c3.core_analytics.rnr_taxonomy_reference` GROUP BY 1 ORDER BY 1 DESC
  -- Should return >= 70 rows per partition

PERSONA PIPELINE
  → SP runs weekly: bq_sp_national_stg_nio_appsrtgout_usecase_weekly
  → Reads persona from rnr_app_category_v2.persona (data-driven, no hardcoded mapping)
  → Output: stg_nio_appsrtgout_usecase_weekly

FORCE GCS UPLOAD (if CI didn't run)
  → gcloud storage cp rnr_app_category_v2.csv gs://create_gcs_table/app-category-mapping/rnr_app_category_v2.csv

DEPLOY UPDATED DAG
  → gcloud storage cp dags/app_catalog_sync.py gs://<bucket>/dags/
```
