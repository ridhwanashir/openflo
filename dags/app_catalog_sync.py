"""
DAG: app_catalog_sync
---------------------
Downloads rnr_app_category_v2.csv from the private GitHub repo,
parses pipe-separated REPEATED STRING fields, and does a full
WRITE_TRUNCATE load into BigQuery.

Required Airflow Variables (set via Composer UI or `airflow variables set`):
  GITLAB_PAT      — GitLab Personal Access Token with `read_repository` scope
  GITLAB_RAW_URL  — e.g. https://gitlab.com/<group>/<project>/-/raw/main/rnr_app_category_v2.csv

Team editing workflow:
  Edit rnr_app_category_v2.csv on GitLab (web editor or local push)
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
    logging.info("Downloaded %d bytes from GitHub", len(resp.content))

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
# Task 2: validate
# ---------------------------------------------------------------------------
def validate(**context):
    from google.cloud import bigquery

    loaded_rows = context["ti"].xcom_pull(key="loaded_rows", task_ids="sync_catalog")

    assert loaded_rows >= 1199, (
        f"Row count check failed: expected >= 1199, got {loaded_rows}"
    )

    client = bigquery.Client(project=BQ_PROJECT)

    # Spot-check: BCA must have exactly 3 sig_app_tags
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
        "Validation passed — %d rows loaded, BCA has %d sig_app_tags",
        loaded_rows,
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
    description="Full-replace sync of rnr_app_category_v2 from GitHub to BigQuery",
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

    t_validate = PythonOperator(
        task_id="validate",
        python_callable=validate,
    )

    t_sync >> t_validate
