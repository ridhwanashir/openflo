# Project Status - DS-IOH-Application-Mapping

Reviewed on: 2026-07-09
Mapping confidence: High  
Related IOH folders: `/Users/mac/Documents/IOH - IDA/Projects/SDA Small Segment Analysis`, `/Users/mac/Documents/IOH - IDA/Projects/SDA - Smart Digital Advertisement`

## Current State

This repo is the SDA application taxonomy/mapping workspace. The active production artifact is `rnr_app_category_v2.csv`; GitLab remains the human source of truth, but the current runtime handoff is manual upload to GCS followed by a manual Cloud Composer DAG run.

Current runtime flow:

1. Edit and commit `rnr_app_category_v2.csv` in GitLab.
2. Manually upload the committed CSV to `gs://create_gcs_table/app-category-mapping/rnr_app_category_v2.csv`.
3. Trigger Composer DAG `app_catalog_sync`.
4. DAG loads `data-int-advana-prd-77c3.core_analytics.rnr_app_category_v2`.
5. DAG derives `data-int-advana-prd-77c3.core_analytics.rnr_taxonomy_reference` from the app catalog on each DAG run.
6. Weekly stored procedure reads the catalog `persona` field and writes `stg_nio_appsrtgout_usecase_weekly`.

Known automation blockers:

- GitLab runner / service account WIF access to GCS is not confirmed working.
- Composer does not currently have access to read the GitLab repo directly.
- Until one of those paths is fixed, a GitLab commit alone does not update BigQuery.

## Key Repo Assets

- `Signature Apps Library 20250828(Tracker v4 20240910).csv`
- `mis_app_category*.csv`
- `rnr_app_category_v2.csv`
- `taxonomy_reference.csv` (historical reference only; active taxonomy table is DAG-derived)
- `app_mapping_migration*.ipynb`
- `csv_to_json.ipynb`
- `output/`
- `stored_procedures/bq_sp_national_stg_nio_appsrtgout_usecase_weekly.sql`
- `user_persona_query*.sql` (deprecated / historical query variants)
- `workflows/app-mapping-*.md`
- `agents/specialized/app-mapper.md`

## Related Local Assets

- `SDA Small Segment Analysis/Signature Apps Library 20250828(Tracker v4 20240910).csv`
- `SDA Small Segment Analysis/mis_app_category.csv`
- `Application Mapping Flow.png`
- `Mas Elson Flow - App Store Play Store.png`
- `User Persona Flow Diagram.png`
- SDA New Segment Review flow assets

## Updates To Carry Forward

- Keep README and maintenance guide aligned to the current manual GCS handoff.
- Promote the GitLab CI upload job from manual to automatic only after WIF and bucket write access are verified.
- If Composer should read GitLab directly instead, provision GitLab repo access and deliberately revert the DAG source path from GCS to GitLab.
- Review the 4 app rows with missing `sig_app_tags`: Adidas Running, Amazon Alexa, Weverse Shop, eFootball.
- Decide whether the 470 rows with blank `persona` are intentionally excluded from persona segmentation.

## Open Questions

- Who owns fixing GitLab runner WIF access to `gs://create_gcs_table`?
- Should the DAG remain manual-trigger while GCS upload is manual, or should it be scheduled after upload discipline is stable?
- Should deprecated `user_persona_query_v2.sql` and `user_persona_query_v2_old.sql` be archived after the stored procedure is confirmed in production?
