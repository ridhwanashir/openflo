# Project Status - DS-IOH SDA App Catalog & Taxonomy

Reviewed on: 2026-09-03
Repository target name: `DS-IOH-SDA-App-Catalog-Taxonomy`

## Purpose

This repository creates and maintains the `rnr_app_category_v2` application catalog and its derived taxonomy for the IOH SDA platform. Persona segmentation is a downstream consumer of the catalog, not the repository's primary ownership boundary.

## Active Runtime Flow

1. Edit and commit `rnr_app_category_v2.csv`.
2. Manually upload the committed CSV to `gs://create_gcs_table/app-category-mapping/rnr_app_category_v2.csv`.
3. Trigger Composer DAG `app_catalog_sync`.
4. The DAG fully replaces `data-int-advana-prd-77c3.core_analytics.rnr_app_category_v2`.
5. The DAG derives a dated snapshot in `data-int-advana-prd-77c3.core_analytics.rnr_taxonomy_reference`.
6. Downstream stored procedures and dashboards consume the catalog.

GitLab-to-GCS upload and Composer triggering remain manual. WIF bucket-write access is not yet confirmed, and Composer does not read the GitLab repository directly.

## Current Catalog Snapshot

| Metric | Value |
|---|---:|
| App rows | 1,199 |
| L1 categories | 11 |
| Category/subcategory pairs | 73 |
| Persona labels | 18 |
| Duplicate app names | 0 |
| Blank descriptions | 0 |
| Rows without `sig_app_tags` | 4 |
| Rows without `persona` | 470 |
| Rows populated in `els_norm_app_tags` | 0 |
| Rows populated in `els_host` | 0 |

Apps still missing `sig_app_tags`: Adidas Running, Amazon Alexa, Weverse Shop, and eFootball.

## Active Assets

- `rnr_app_category_v2.csv`: catalog source of truth.
- `dags/app_catalog_sync.py`: GCS-to-BigQuery catalog load and taxonomy derivation.
- `stored_procedures/bq_sp_national_stg_nio_appsrtgout_usecase_weekly.sql`: downstream weekly persona classification.
- `.gitlab-ci.yml`: manual WIF/upload test jobs for future automation.
- `data/reference/signature_apps_library_20250828.csv`: source reference for matching and audits.
- `README.md`, `MAINTENANCE_GUIDE.md`, and `docs/team-overview.md`: active documentation.

Historical notebooks, catalogs, manual-load formats, persona queries, and superseded workflow documentation are retained under `archive/`. Income-score modelling assets and generic OpenFlo scaffolding were removed from this repository because they already live in the separate `DS-IOH-Model-Income-Score` repository.

## Open Work

- Populate or remove the placeholder ELS fields after the enrichment design is confirmed.
- Resolve the four missing `sig_app_tags` entries.
- Confirm whether the 470 blank persona rows are intentionally excluded.
- Verify GitLab Runner WIF and GCS object-write permission before automating uploads.
- Decide whether Composer should remain manual-triggered after upload automation is available.
- Verify the deployed Composer DAG, current GCS object, and BigQuery table against this repository revision.

## Related Project

`DS-IOH-SDA-Application-Mapping-Automation` is a separate planned automation pipeline for discovering and approving new unmapped apps. It is not yet the production source of truth.
