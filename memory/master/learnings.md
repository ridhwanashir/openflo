# Master Agent Learnings

> Accumulated patterns, insights, and lessons from this project.  
> Updated as the project progresses.

---

## Project Context Learnings

<<<<<<< HEAD
### IOH Data Context
- IOH = Indosat Ooredoo Hutchison, Indonesian telco operator
- External validation source = government tax authority data (SPT/DJP or similar)
- Income ground truth from tax data only captures **formal income earners** — this is a known scope limitation to document explicitly in model cards

### Methodology Notes
- Telco-to-income modelling is a form of **proxy labelling** — model quality is bounded by quality and coverage of the validation ground truth
- Tax data match rate is typically 30–60% for telco populations — oversample accordingly
- Key telco signals for income proxy: ARPU, data bundle tier, international roaming usage, device segment, top-up frequency and amount, subscriber tenure

---

## Process Learnings

*(Will be populated as project progresses)*

---

## Reusable Patterns

*(Will be added as patterns are identified)*
=======
### 2026-03-19 — Notebook Editing

**Observation**: `replace_string_in_file` consistently fails on `.ipynb` files  
**Context**: Attempted to apply 22 string replacements to DESC_FINANCE dict inside `app_mapping_migration.ipynb`  
**Learning**: `.ipynb` stores cell source as JSON-encoded arrays. The tool operates on rendered Python source but the raw file is JSON, causing string mismatch failures at both Python-source and JSON-escaped levels  
**Action Taken**: Always use `edit_notebook_file` with `editType="edit"` for `.ipynb` cells. For large dicts with many corrections, replace the entire cell at once.

### 2026-03-19 — Column Reorder Cell Risk

**Observation**: A column-reorder cell before SAVE can silently drop columns if not kept in sync  
**Context**: Cell 43 selected only 6 columns, dropping `source_app_names_old` and `sig_app_tags`. Went unnoticed because the SAVE cell just prints `list(output.columns)` which showed reduced count  
**Learning**: Column selection cells before a save are a silent failure risk when schema changes. If a reorder cell exists, update it every time new columns are added to the schema  
**Action Taken**: Updated cell 43 to include all 8 canonical columns in the correct order.

### 2026-03-18 — Inline Fixes vs Patch Cells

**Observation**: Separate PATCH/CORRECTIONS cells are harder to maintain than inline edits  
**Context**: Had 3 post-hoc cells patching descriptions after DESC_* dicts were loaded, plus a unicode fix cell and a CORRECTIONS dict loop  
**Learning**: Apply all corrections at the source. Post-hoc corrections create execution-order dependencies and make it unclear what the "true" value of a field is  
**Action Taken**: All 22 corrections, 3 patches, and unicode fix folded directly into `DESC_FINANCE`.

---

## Early Hypotheses — Status

| Hypothesis | Status | Notes |
|------------|--------|-------|
| Tag vocabulary (~20 tags) covers 90%+ of real cases | *Not yet tested* | Tags not yet applied in bulk |
| ~60% exact matches, ~25% high-confidence | *Not yet tested* | BQ mapping not yet run |
| Indonesian apps = 20–40% of table | ✅ Validated | Finance/commerce/communication heavy with local apps |
| 2–3 sentence descriptions sufficient for LLM | *In progress* | Single or 2-sentence descriptions used; LLM quality review pending |
| L2 assignable for 80%+ of entries | ✅ Exceeded | 100% of 1,199 apps have valid L2 |
>>>>>>> 3c310d3 (feat: Add comprehensive project status documentation and update workflow for app mapping sessions)
