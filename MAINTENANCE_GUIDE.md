# App Catalog Maintenance Guide

> **Who this is for:** Anyone on the DS-IOH team who needs to update the app taxonomy, deploy the sync pipeline, or troubleshoot BigQuery table issues.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [The CSV — Source of Truth](#2-the-csv--source-of-truth)
3. [How to Update the App Catalog](#3-how-to-update-the-app-catalog)
4. [One-Time Setup: Deploy the Airflow DAG](#4-one-time-setup-deploy-the-airflow-dag)
5. [One-Time Setup: Set Airflow Variables](#5-one-time-setup-set-airflow-variables)
6. [Running the DAG (Manual Trigger)](#6-running-the-dag-manual-trigger)
7. [How the DAG Works (Step by Step)](#7-how-the-dag-works-step-by-step)
8. [BigQuery Table Reference](#8-bigquery-table-reference)
9. [Troubleshooting](#9-troubleshooting)
10. [Cheat Sheet](#10-cheat-sheet)

---

## 1. Architecture Overview

```
You / Team
   │
   │  Edit rnr_app_category_v2.csv
   ▼
GitLab Repo  ←──── single source of truth
   │
   │  Airflow DAG downloads it via GitLab API (using PAT)
   ▼
Cloud Composer (Airflow)
   │
   │  Parses CSV → full replace (WRITE_TRUNCATE)
   ▼
BigQuery: data-int-advana-prd-77c3.core_analytics.rnr_app_category_v2
   │
   │  user_persona_query_v2.sql reads this table
   ▼
rnr_user_persona_small_segment_temp_3
```

**Key principle:** The CSV is always the complete list. Every DAG run wipes the BQ table and reloads from scratch. No manual BQ edits — any change made directly in BQ will be overwritten on the next run.

---

## 2. The CSV — Source of Truth

**File:** `rnr_app_category_v2.csv`  
**Location in repo:** repo root

### Column Reference

| Column | Type | Notes |
|---|---|---|
| `app_name` | Single value | Display name of the app |
| `source_app_names_old` | **Pipe-separated** (`\|`) | Alternative/legacy app identifiers |
| `sig_app_tags` | **Pipe-separated** (`\|`) | Tags used to match user activity |
| `category` | Single value | Primary category |
| `subcategory` | Single value | Primary subcategory |
| `secondary_category` | Single value | Optional second category |
| `secondary_subcategory` | Single value | Optional second subcategory |
| `description` | Single value | Free text description |

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

## 3. How to Update the App Catalog

You have two options. Both result in the same thing — a committed change to `rnr_app_category_v2.csv` in GitLab.

### Option A — Edit directly on GitLab (no local setup needed)

1. Go to your company GitLab repo
2. Open `rnr_app_category_v2.csv`
3. Click the **Edit** (pencil) button
4. Make your changes in the web editor
5. Scroll down → write a commit message → click **Commit changes**
6. That's it. The DAG will pick up the new version on its next run (or trigger it manually — see [Section 6](#6-running-the-dag-manual-trigger))

### Option B — Edit locally and push

```bash
# 1. Pull latest
git pull upstream main

# 2. Edit the file in Excel / any editor
#    Save as CSV (UTF-8, comma-separated)

# 3. Verify no bracket format crept in (should return 0 matches)
grep -c '\[' rnr_app_category_v2.csv

# 4. Commit and push
git add rnr_app_category_v2.csv
git commit -m "Update app catalog: <describe what changed>"
git push upstream main
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

## 5. One-Time Setup: Set Airflow Variables

The DAG needs two Airflow Variables to run. These are set once and stored securely in Composer.

### How to set them

Go to: **Cloud Composer → [your environment] → Open Airflow UI → Admin → Variables**

Click **+** and add:

| Key | Value |
|---|---|
| `GITLAB_PAT` | Your GitLab Personal Access Token (see below) |
| `GITLAB_RAW_URL` | The raw file URL (see below) |

### How to get your GitLab PAT

1. Go to GitLab → top-right avatar → **Edit profile**
2. Left sidebar → **Access Tokens**
3. Click **Add new token**
4. Name it something like `composer-app-catalog-read`
5. Expiry: set a date (e.g. 1 year)
6. Scopes: check only **`read_repository`**
7. Click **Create personal access token**
8. **Copy the token now** — you won't see it again

### How to get the raw file URL

In GitLab, open `rnr_app_category_v2.csv` → click **Open raw** → copy the URL from your browser.

It will look like:  
`https://gitlab.com/<group>/<project>/-/raw/main/rnr_app_category_v2.csv`

---

## 6. Running the DAG (Manual Trigger)

After editing the CSV and committing to GitLab:

1. Go to **Cloud Composer → [your environment] → Open Airflow UI**
2. Find `app_catalog_sync` in the DAG list
3. Click the **▶ Trigger DAG** button (the play icon on the right)
4. Optionally click the DAG name → **Graph View** to watch task progress in real time

The DAG runs `@daily` by default so it also runs automatically every day — useful if your team makes frequent edits.

### Expected run time

Under 1 minute for 1,200 rows. If it takes longer than 3 minutes, something is wrong — check the logs.

---

## 7. How the DAG Works (Step by Step)

**File:** `dags/app_catalog_sync.py`

```
[sync_catalog] ──► [validate]
```

### Task 1: `sync_catalog`

1. Reads `GITLAB_PAT` and `GITLAB_RAW_URL` from Airflow Variables
2. Downloads the CSV from GitLab using the PAT for authentication
3. Parses every row:
   - `sig_app_tags` and `source_app_names_old` → split on `|` → Python list
   - Empty strings → `None`
4. Loads all rows to BigQuery using **WRITE_TRUNCATE** (full replace)
   - Target: `data-int-advana-prd-77c3.core_analytics.rnr_app_category_v2`
   - `sig_app_tags` and `source_app_names_old` are loaded as `REPEATED STRING`

### Task 2: `validate`

1. Checks that at least **1,199 rows** were loaded
2. Spot-checks that the `BCA` row has exactly **3 sig_app_tags** (`Klikbca`, `BCAS_MOBILE2`, `MYBCA`)
3. If either check fails, the task fails with a clear error message

> If validation fails, the BQ table has already been truncated and reloaded with the new (potentially wrong) data. Fix the CSV, commit it, and re-trigger the DAG.

---

## 8. BigQuery Table Reference

**Table:** `data-int-advana-prd-77c3.core_analytics.rnr_app_category_v2`

### Schema

| Field | BQ Type | Mode |
|---|---|---|
| `app_name` | STRING | NULLABLE |
| `source_app_names_old` | STRING | **REPEATED** |
| `sig_app_tags` | STRING | **REPEATED** |
| `category` | STRING | NULLABLE |
| `subcategory` | STRING | NULLABLE |
| `secondary_category` | STRING | NULLABLE |
| `secondary_subcategory` | STRING | NULLABLE |
| `description` | STRING | NULLABLE |

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

## 9. Troubleshooting

### DAG fails at `sync_catalog` — HTTP 401

Your GitLab PAT is invalid or expired. Generate a new one (see [Section 5](#5-one-time-setup-set-airflow-variables)) and update the `GITLAB_PAT` Airflow Variable.

### DAG fails at `sync_catalog` — HTTP 404

The `GITLAB_RAW_URL` is wrong. Verify by pasting the URL into your browser while logged into GitLab — it should show the raw CSV text. Update the variable.

### DAG fails at `validate` — row count < 1199

The CSV was uploaded with fewer rows than expected. Check:
- Was the CSV accidentally truncated when saving from Excel?
- Were rows deleted unintentionally?

Fix the CSV, commit, and re-trigger.

### BQ table looks wrong after a run

The table is fully replaced each run. Check the CSV in GitLab — if the CSV is correct, re-trigger the DAG.

### The persona query returns wrong results

1. Check that the BQ table was loaded by the DAG (not manually edited)
2. Verify `sig_app_tags` is `REPEATED STRING` in the BQ schema (not a plain string with pipes in it)
3. The query uses `UNNEST(r.sig_app_tags)` — this only works correctly if the field is `REPEATED`

### DAG is not visible in Airflow UI

The DAG file hasn't been uploaded to the Composer GCS bucket yet, or Airflow hasn't scanned it yet (wait 1–2 minutes after upload).

---

## 10. Cheat Sheet

```
EDIT CATALOG
  → Edit rnr_app_category_v2.csv on GitLab
  → Use | to separate multi-values (no brackets, no commas)
  → Commit the change

SYNC TO BQ
  → Airflow UI → app_catalog_sync → Trigger DAG ▶
  → Wait ~1 min → both tasks should turn green

CHECK BQ
  SELECT COUNT(*) FROM `data-int-advana-prd-77c3.core_analytics.rnr_app_category_v2`
  -- Should return >= 1199

CHANGE PAT (when it expires)
  → GitLab → Profile → Access Tokens → new token (read_repository)
  → Airflow UI → Admin → Variables → update GITLAB_PAT

DEPLOY UPDATED DAG
  → gcloud storage cp dags/app_catalog_sync.py gs://<bucket>/dags/
```
