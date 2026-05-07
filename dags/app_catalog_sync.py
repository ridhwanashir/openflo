"""
DAG: app_catalog_sync
---------------------
Downloads rnr_app_category_v2.csv and taxonomy_reference.csv from the private
GitLab repo, parses pipe-separated REPEATED STRING fields, and does a full
WRITE_TRUNCATE load into BigQuery for both tables.

Required Airflow Variables (set via Composer UI or `airflow variables set`):
  GITLAB_PAT              — GitLab Personal Access Token with `read_repository` scope
  GITLAB_RAW_URL          — raw URL to rnr_app_category_v2.csv in the repo
  GITLAB_TAXONOMY_RAW_URL — raw URL to taxonomy_reference.csv in the repo

Team editing workflow:
  Edit rnr_app_category_v2.csv or taxonomy_reference.csv on GitLab
  → DAG picks up the latest committed version on next run
"""

import csv
import io
import logging
from datetime import datetime, timedelta

import requests
from airflow import DAG
from airflow.models import Variable
from airflow.operators.python import PythonOperator

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
BQ_PROJECT = "data-int-advana-prd-77c3"
BQ_DATASET = "core_analytics"
BQ_TABLE = "rnr_app_category_v2"
BQ_TABLE_REF = f"{BQ_PROJECT}.{BQ_DATASET}.{BQ_TABLE}"

ARRAY_FIELDS = {"sig_app_tags", "source_app_names_old"}

BQ_SCHEMA = [
    {"name": "app_name",               "type": "STRING", "mode": "NULLABLE"},
    {"name": "source_app_names_old",   "type": "STRING", "mode": "REPEATED"},
    {"name": "sig_app_tags",           "type": "STRING", "mode": "REPEATED"},
    {"name": "category",               "type": "STRING", "mode": "NULLABLE"},
    {"name": "subcategory",            "type": "STRING", "mode": "NULLABLE"},
    {"name": "secondary_category",     "type": "STRING", "mode": "NULLABLE"},
    {"name": "secondary_subcategory",  "type": "STRING", "mode": "NULLABLE"},
    {"name": "description",            "type": "STRING", "mode": "NULLABLE"},
    {"name": "review_status",          "type": "STRING", "mode": "NULLABLE"},
]

BQ_TAXONOMY_TABLE = "rnr_taxonomy_reference"
BQ_TAXONOMY_TABLE_REF = f"{BQ_PROJECT}.{BQ_DATASET}.{BQ_TAXONOMY_TABLE}"

BQ_TAXONOMY_SCHEMA = [
    {"name": "category",         "type": "STRING",  "mode": "NULLABLE"},
    {"name": "subcategory",      "type": "STRING",  "mode": "NULLABLE"},
    {"name": "definition",       "type": "STRING",  "mode": "NULLABLE"},
    {"name": "include_examples", "type": "STRING",  "mode": "NULLABLE"},
    {"name": "exclude_examples", "type": "STRING",  "mode": "NULLABLE"},
    {"name": "app_count",        "type": "INTEGER", "mode": "NULLABLE"},
    {"name": "taxonomy_version", "type": "STRING",  "mode": "NULLABLE"},
]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _parse_array_field(value: str) -> list:
    """
    Accepts either:
      - pipe-separated  : "val1|val2|val3"   (current format)
      - bracket-wrapped : "[val1,val2,val3]"  (legacy format, defensive)
    Returns a list of non-empty stripped strings.
    """
    if not value or not value.strip():
        return []
    v = value.strip()
    if v.startswith("[") and v.endswith("]"):
        inner = v[1:-1]
        parts = [p.strip().strip("'\"") for p in inner.split(",")]
        return [p for p in parts if p]
    return [p.strip() for p in v.split("|") if p.strip()]


# ---------------------------------------------------------------------------
# Task 1 + 2 + 3: download → parse → load  (single callable, avoids XCom
#                 size limits for ~1,200 rows × 8 columns)
# ---------------------------------------------------------------------------
def sync_catalog(**context):
    from google.cloud import bigquery

    # --- Download ---
    pat = Variable.get("GITLAB_PAT")
    raw_url = Variable.get("GITLAB_RAW_URL")

    resp = requests.get(
        raw_url,
        headers={"PRIVATE-TOKEN": pat},
        timeout=30,
    )
    resp.raise_for_status()
    logging.info("Downloaded app catalog: %d bytes from GitLab", len(resp.content))

    # --- Parse ---
    reader = csv.DictReader(io.StringIO(resp.text))
    rows = []
    for row in reader:
        for field in ARRAY_FIELDS:
            row[field] = _parse_array_field(row.get(field, ""))
        # Normalise empty strings → None for NULLABLE fields
        for key in list(row.keys()):
            if key not in ARRAY_FIELDS and row[key] == "":
                row[key] = None
        rows.append(row)
    logging.info("Parsed %d rows", len(rows))

    # --- Load ---
    client = bigquery.Client(project=BQ_PROJECT)
    schema = [bigquery.SchemaField(**f) for f in BQ_SCHEMA]
    job_config = bigquery.LoadJobConfig(
        schema=schema,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
    )
    job = client.load_table_from_json(rows, BQ_TABLE_REF, job_config=job_config)
    job.result()

    loaded = job.output_rows
    logging.info("Loaded %d rows to %s", loaded, BQ_TABLE_REF)
    # Push row count for the validate task
    context["ti"].xcom_push(key="loaded_rows", value=loaded)


# ---------------------------------------------------------------------------
# Task 2: sync_taxonomy
# ---------------------------------------------------------------------------
def sync_taxonomy(**context):
    from google.cloud import bigquery

    pat = Variable.get("GITLAB_PAT")
    raw_url = Variable.get("GITLAB_TAXONOMY_RAW_URL")

    resp = requests.get(
        raw_url,
        headers={"PRIVATE-TOKEN": pat},
        timeout=30,
    )
    resp.raise_for_status()
    logging.info("Downloaded taxonomy: %d bytes from GitLab", len(resp.content))

    reader = csv.DictReader(io.StringIO(resp.text))
    rows = []
    for row in reader:
        if row.get("app_count"):
            try:
                row["app_count"] = int(row["app_count"])
            except ValueError:
                row["app_count"] = None
        for key in list(row.keys()):
            if row[key] == "":
                row[key] = None
        rows.append(row)
    logging.info("Parsed %d taxonomy rows", len(rows))

    client = bigquery.Client(project=BQ_PROJECT)
    schema = [bigquery.SchemaField(**f) for f in BQ_TAXONOMY_SCHEMA]
    job_config = bigquery.LoadJobConfig(
        schema=schema,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
    )
    job = client.load_table_from_json(rows, BQ_TAXONOMY_TABLE_REF, job_config=job_config)
    job.result()
    logging.info("Loaded %d taxonomy rows to %s", job.output_rows, BQ_TAXONOMY_TABLE_REF)
    context["ti"].xcom_push(key="taxonomy_rows", value=job.output_rows)


# ---------------------------------------------------------------------------
# Task 3: validate
# ---------------------------------------------------------------------------
def validate(**context):
    from google.cloud import bigquery

    loaded_rows = context["ti"].xcom_pull(key="loaded_rows", task_ids="sync_catalog")
    taxonomy_rows = context["ti"].xcom_pull(key="taxonomy_rows", task_ids="sync_taxonomy")

    # --- App catalog floor check ---
    # 1,199 is the baseline row count when this DAG was written.
    # Catches catastrophic failures: empty file, half-truncated upload, etc.
    assert loaded_rows >= 1199, (
        f"Row count check failed: expected >= 1199, got {loaded_rows}"
    )

    # --- Taxonomy floor check ---
    assert taxonomy_rows >= 70, (
        f"Taxonomy row count check failed: expected >= 70, got {taxonomy_rows}"
    )

    client = bigquery.Client(project=BQ_PROJECT)

    # --- Spot-check: BCA must have exactly 3 sig_app_tags ---
    # BCA is a stable, well-known entry (tags: Klikbca, BCAS_MOBILE2, MYBCA).
    # This catches silent REPEATED field parsing failures — a file that loads
    # successfully but has all multi-value fields collapsed into a single string.
    query = f"""
        SELECT ARRAY_LENGTH(sig_app_tags) AS tag_count
        FROM `{BQ_TABLE_REF}`
        WHERE app_name = 'BCA'
        LIMIT 1
    """
    result = list(client.query(query).result())
    assert len(result) == 1, "Validation failed: BCA row not found in BQ"
    assert result[0].tag_count == 3, (
        f"Validation failed: BCA expected 3 sig_app_tags, got {result[0].tag_count}"
    )

    logging.info(
        "Validation passed — %d app rows, %d taxonomy rows, BCA has %d sig_app_tags",
        loaded_rows,
        taxonomy_rows,
        result[0].tag_count,
    )


# ---------------------------------------------------------------------------
# DAG definition
# ---------------------------------------------------------------------------
default_args = {
    "owner": "ds-ioh",
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
    "email_on_failure": False,
}

with DAG(
    dag_id="app_catalog_sync",
    description="Full-replace sync of rnr_app_category_v2 and rnr_taxonomy_reference from GitLab to BigQuery",
    schedule_interval="@daily",
    start_date=datetime(2026, 5, 6),
    catchup=False,
    default_args=default_args,
    tags=["app-mapping", "catalog"],
) as dag:

    t_sync = PythonOperator(
        task_id="sync_catalog",
        python_callable=sync_catalog,
    )

    t_taxonomy = PythonOperator(
        task_id="sync_taxonomy",
        python_callable=sync_taxonomy,
    )

    t_validate = PythonOperator(
        task_id="validate",
        python_callable=validate,
    )

    [t_sync, t_taxonomy] >> t_validate
