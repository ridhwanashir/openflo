# Project Status - DS-IOH-Application-Mapping

Reviewed on: 2026-05-04  
Mapping confidence: High  
Related IOH folders: `/Users/mac/Documents/IOH - IDA/Projects/SDA Small Segment Analysis`, `/Users/mac/Documents/IOH - IDA/Projects/SDA - Smart Digital Advertisement`

## Current State

This repo is the SDA application taxonomy/mapping workspace. It contains app library references, app category CSVs, migration notebooks, JSON/Avro/JSONL outputs, user persona SQL, app mapping workflows, and OpenFlo project memory. It is directly connected to SDA small segment analysis and application mapping flow assets in IOH.

## Key Repo Assets

- `Signature Apps Library 20250828(Tracker v4 20240910).csv`
- `mis_app_category*.csv`
- `rnr_app_category_v2.csv`
- `taxonomy_reference.csv`
- `app_mapping_migration*.ipynb`
- `csv_to_json.ipynb`
- `output/`
- `user_persona_query*.sql`
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

- Record app library version/date and expected migration output format.
- Document the pipeline from app library CSV to `rnr_app_category_v2` and generated output files.
- Link user persona SQL back to SDA small segment analysis.
- Confirm whether modified OpenFlo memory/project files are current working notes.

## Open Questions

- Which taxonomy file is the current source of truth?
- Should generated Avro/JSONL outputs be tracked or regenerated?
- Are `user_persona_query_v2.sql` and `user_persona_query_v2_old.sql` both needed?

