"""
DAG: app_catalog_sync
---------------------
Downloads rnr_app_category_v2.csv from GCS, parses
pipe-separated REPEATED STRING fields (including the `persona` column),
and does a full WRITE_TRUNCATE load into BigQuery.

The taxonomy table (`rnr_taxonomy_reference`) is **derived** from the app
catalog in-memory — no separate GCS download. Each DAG run appends a
date-partitioned snapshot (partition-level TRUNCATE for idempotency on
same-day re-runs).

GCS source:
  bucket : create_gcs_table
  blob   : app-category-mapping/rnr_app_category_v2.csv

Team editing workflow:
  Edit rnr_app_category_v2.csv → commit to GitLab
  → manually upload the committed CSV to GCS
  → trigger the DAG so it picks up the latest GCS version
  → Taxonomy is auto-derived from the catalog (no separate file to maintain)
"""

import csv
import io
import logging
from collections import defaultdict
from datetime import datetime, timedelta

from airflow import DAG
from airflow.models import Variable
from airflow.operators.python import PythonOperator
from teams import TeamsNotifier

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
BQ_PROJECT = "data-int-advana-prd-77c3"
BQ_DATASET = "core_analytics"
BQ_TABLE = "rnr_app_category_v2"
BQ_TABLE_REF = f"{BQ_PROJECT}.{BQ_DATASET}.{BQ_TABLE}"

ARRAY_FIELDS = {"sig_app_tags", "nio_aggr_app_tags", "persona", "els_norm_app_tags", "els_host"}

BQ_SCHEMA = [
    {"name": "app_name",               "type": "STRING", "mode": "NULLABLE"},
    {"name": "nio_aggr_app_tags",      "type": "STRING", "mode": "REPEATED"},
    {"name": "sig_app_tags",           "type": "STRING", "mode": "REPEATED"},
    {"name": "els_norm_app_tags",      "type": "STRING", "mode": "REPEATED"},
    {"name": "els_host",              "type": "STRING", "mode": "REPEATED"},
    {"name": "category",               "type": "STRING", "mode": "NULLABLE"},
    {"name": "subcategory",            "type": "STRING", "mode": "NULLABLE"},
    {"name": "secondary_category",     "type": "STRING", "mode": "NULLABLE"},
    {"name": "secondary_subcategory",  "type": "STRING", "mode": "NULLABLE"},
    {"name": "description",            "type": "STRING", "mode": "NULLABLE"},
    {"name": "persona",                "type": "STRING", "mode": "REPEATED"},
]

BQ_TAXONOMY_TABLE = "rnr_taxonomy_reference"
BQ_TAXONOMY_TABLE_REF = f"{BQ_PROJECT}.{BQ_DATASET}.{BQ_TAXONOMY_TABLE}"

TAXONOMY_EXAMPLES_COUNT = 5  # number of sample apps per subcategory

BQ_TAXONOMY_SCHEMA = [
    {"name": "category",         "type": "STRING",  "mode": "NULLABLE"},
    {"name": "subcategory",      "type": "STRING",  "mode": "NULLABLE"},
    {"name": "include_examples", "type": "STRING",  "mode": "NULLABLE"},
    {"name": "app_count",        "type": "INTEGER", "mode": "NULLABLE"},
    {"name": "taxonomy_version", "type": "DATE",    "mode": "NULLABLE"},
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
# Task 1: sync_catalog — download → parse → load app catalog to BQ
# ---------------------------------------------------------------------------
GCS_BUCKET = "create_gcs_table"
GCS_BLOB   = "app-category-mapping/rnr_app_category_v2.csv"


def sync_catalog(**context):
    from google.cloud import bigquery, storage

    # --- Download from GCS ---
    gcs_client = storage.Client()
    blob = gcs_client.bucket(GCS_BUCKET).blob(GCS_BLOB)
    content = blob.download_as_text()
    logging.info("Downloaded app catalog: %d bytes from GCS gs://%s/%s",
                 len(content), GCS_BUCKET, GCS_BLOB)

    # --- Parse ---
    reader = csv.DictReader(io.StringIO(content))
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
    schema = [
        bigquery.SchemaField(f["name"], f["type"], mode=f.get("mode", "NULLABLE"))
        for f in BQ_SCHEMA
    ]
    job_config = bigquery.LoadJobConfig(
        schema=schema,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
    )
    job = client.load_table_from_json(rows, BQ_TABLE_REF, job_config=job_config)
    job.result()

    loaded = job.output_rows
    logging.info("Loaded %d rows to %s", loaded, BQ_TABLE_REF)

    # Push for downstream tasks
    context["ti"].xcom_push(key="loaded_rows", value=loaded)
    context["ti"].xcom_push(key="catalog_rows", value=rows)


# ---------------------------------------------------------------------------
# Task 2: sync_taxonomy — derive from catalog rows, load as date partition
# ---------------------------------------------------------------------------
def sync_taxonomy(**context):
    from google.cloud import bigquery

    catalog_rows = context["ti"].xcom_pull(key="catalog_rows", task_ids="sync_catalog")

    # --- Aggregate per (category, subcategory) in CSV order ---
    buckets = defaultdict(lambda: {"count": 0, "examples": []})
    for row in catalog_rows:
        cat = row.get("category")
        sub = row.get("subcategory")
        if not cat or not sub:
            continue
        key = (cat, sub)
        buckets[key]["count"] += 1
        if len(buckets[key]["examples"]) < TAXONOMY_EXAMPLES_COUNT:
            buckets[key]["examples"].append(row["app_name"])

    # --- Build taxonomy rows ---
    snapshot_date = context["data_interval_start"].date().isoformat()
    taxonomy_rows = []
    for (cat, sub), info in sorted(buckets.items()):
        taxonomy_rows.append({
            "category": cat,
            "subcategory": sub,
            "include_examples": "|".join(info["examples"]),
            "app_count": info["count"],
            "taxonomy_version": snapshot_date,
        })
    logging.info("Derived %d taxonomy rows for partition %s", len(taxonomy_rows), snapshot_date)

    # --- Load with partition-level TRUNCATE ---
    # Writing to table$YYYYMMDD overwrites only that day's partition,
    # preserving historical partitions (idempotent on same-day re-runs).
    client = bigquery.Client(project=BQ_PROJECT)
    schema = [
        bigquery.SchemaField(f["name"], f["type"], mode=f.get("mode", "NULLABLE"))
        for f in BQ_TAXONOMY_SCHEMA
    ]
    partition_suffix = snapshot_date.replace("-", "")
    partitioned_dest = f"{BQ_TAXONOMY_TABLE_REF}${partition_suffix}"

    job_config = bigquery.LoadJobConfig(
        schema=schema,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
        time_partitioning=bigquery.TimePartitioning(
            type_=bigquery.TimePartitioningType.DAY,
            field="taxonomy_version",
        ),
    )
    job = client.load_table_from_json(taxonomy_rows, partitioned_dest, job_config=job_config)
    job.result()

    logging.info("Loaded %d taxonomy rows to %s", job.output_rows, partitioned_dest)
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
    "retries": 0,
    "retry_delay": timedelta(minutes=5),
}

# None = manual-trigger only; to re-enable scheduled runs, add
# "app_catalog_sync": "@daily" to the `schedule_interval` Airflow Variable.
_schedule_intervals = Variable.get("schedule_interval", deserialize_json=True, default_var={})
schedule_interval = _schedule_intervals.get("app_catalog_sync", None)

with DAG(
    dag_id="app_catalog_sync",
    description="Sync app catalog from GitLab to BigQuery; derive taxonomy snapshot automatically",
    schedule_interval=schedule_interval,  # None = manual trigger; set via Variable to schedule
    start_date=datetime(2026, 5, 6),
    catchup=False,
    default_args=default_args,
    on_failure_callback=TeamsNotifier(),
    tags=["app-mapping", "catalog"],
) as dag:

    t_sync = PythonOperator(
        task_id="sync_catalog",
        python_callable=sync_catalog,
        provide_context=True,
    )

    t_taxonomy = PythonOperator(
        task_id="sync_taxonomy",
        python_callable=sync_taxonomy,
        provide_context=True,
    )

    t_validate = PythonOperator(
        task_id="validate",
        python_callable=validate,
        provide_context=True,
    )

    # Sequential: taxonomy depends on catalog rows via XCom
    t_sync >> t_taxonomy >> t_validate
