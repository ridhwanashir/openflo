# Archived Artifacts

This directory preserves the lineage of `rnr_app_category_v2.csv`. None of these files are part of the active production sync path.

## Contents

| Directory | Purpose |
|---|---|
| `migration-notebooks/` | Historical notebooks used to migrate legacy mapping data into earlier catalog schemas. |
| `legacy-catalogs/` | Superseded `mis_app_category` files and the manually maintained taxonomy snapshot. |
| `legacy-persona-queries/` | Persona SQL variants replaced by the catalog-driven weekly stored procedure. |
| `legacy-docs/` | Design and workflow documents that describe the superseded notebook-driven process. |
| `generated-formats/` | Historical conversion notebook for Avro/JSONL manual-load outputs. |

## Rules

- Do not use archived CSVs as production sources of truth.
- Do not run the migration notebooks expecting them to reproduce the current 11-column catalog schema.
- The active source of truth is the repository-root `rnr_app_category_v2.csv`.
- The active taxonomy table is derived by `dags/app_catalog_sync.py`; it is not loaded from `taxonomy_reference.csv`.
- The active downstream persona implementation is `stored_procedures/bq_sp_national_stg_nio_appsrtgout_usecase_weekly.sql`.
