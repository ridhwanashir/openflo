# Workflow: App Mapping Session

> Standard workflow for a mapping session — adding, correcting, or reviewing app entries in `mis_app_category_v2.csv`.

---

## Purpose

Produce a clean, complete, and reproducible mapping of IOH telco applications to the v2.1 taxonomy. Every session should end with the notebook re-run top-to-bottom and the CSV committed.

---

## Trigger

- New apps identified in the Signature Apps Library
- Incorrect category/subcategory discovered for an existing app
- Description quality issue flagged by LLM quality review
- Scheduled taxonomy review

---

## Participants

- **App Mapper** (`app-mapper`): Assigns category, subcategory, description
- **Tag Curator** (`tag-curator`): Validates taxonomy compliance, flags violations
- **Data Connector** (`data-connector`): Saves output to CSV/BigQuery
- **Master Orchestrator**: Reviews and approves taxonomy changes

---

## Steps

### Step 1: Identify Changes Needed
**Who**: Master Agent or `app-mapper`  
**What**:
- Pull new app names from the Signature Apps Library CSV
- Review flagged entries (empty descriptions, wrong categories, stale mappings)
- List apps needing: new entry / category correction / description fix / secondary label

**Output**: Prioritized list of apps to process

**Next**: Categorize scope (minor fix → inline edit; bulk addition → new section in DESC_* dict)

---

### Step 2: Apply Category Changes (if any)
**Who**: `app-mapper`  
**What**:
- For **reclassifications**: add entry to `CATEGORY_FIXES` in cell 40 of `app_mapping_migration.ipynb`
- Entry format: `("App Name", "old_cat", "old_sub", "new_cat", "new_sub")`
- For **new subcategory**: confirm with Master Agent first (D-011 precedent), then add to taxonomy and `taxonomy_reference.csv`

**Output**: Updated `CATEGORY_FIXES` list in cell 40

**Next**: Apply description changes

---

### Step 3: Apply Description Changes
**Who**: `app-mapper`  
**What**:
- Find the app in the appropriate `DESC_*` dict (cell 26–35 in notebook)
- Edit the dict value **inline** — never create a separate PATCH cell
- Description format: `"[App Name] is a [subcategory] app by [vendor]. It [primary function]."`
- For new apps: add to the correct `DESC_*` dict section under its L1 category

**Key constraints**:
- Descriptions ≤ 2 sentences
- No promotional language, regulatory claims, or deprecated corporate history
- Use ASCII apostrophe U+0027 in dict keys; encode U+2019 explicitly if needed

**Output**: Updated `DESC_*` dict entry

**Next**: Apply secondary labels (if needed)

---

### Step 4: Apply Secondary Labels (if any)
**Who**: `app-mapper`  
**What**:
- Add entry to `SECONDARY_LABELS` dict in cell 41
- Only for apps genuinely serving two distinct L1 audiences
- Entry format: `"App Name": ("secondary_l1", "secondary_l2")`

**Output**: Updated `SECONDARY_LABELS` dict (if applicable)

**Next**: Run notebook and validate

---

### Step 5: Re-run Notebook & Validate
**Who**: `data-connector` / Copilot  
**What**:
- Run the FULL notebook top-to-bottom (or from cell 21 `#VSC-8efedce1` if only DESC/CATEGORY/SECONDARY changes)
- Check validation cell 24 output: all spot-checks must pass ✅
- Check merge cell 36 output: `Descriptions filled: 1199/1199 (100.0%)`
- Check CATEGORY_FIXES cell 40: `N / N applied`
- Check SECONDARY_LABELS cell 41: `37 / 37 applied` (or updated count)
- Check save cell 44: 8 columns confirmed

**Output**: Passing validation report in notebook terminal

**Next**: Review output CSV

---

### Step 6: Review Output CSV
**Who**: `tag-curator`  
**What**:
- Spot-check changed entries in `mis_app_category_v2.csv`
- Confirm all modified apps have correct category/subcategory/description
- Verify 0 empty descriptions and 0 label violations
- Run: `python3 -c "import pandas as pd; df=pd.read_csv('mis_app_category_v2.csv'); print(df.columns.tolist(), df.shape)"`

**Output**: Verified CSV

**Next**: Commit + optionally upload to BigQuery

---

### Step 7: Commit Changes
**Who**: Master Agent / owner  
**What**:
- `git add app_mapping_migration.ipynb mis_app_category_v2.csv taxonomy_reference.csv`
- `git commit -m "feat(mapping): [brief description of changes]"`
- Push to remote if ready for team review

**Output**: Committed changeset

---

## Success Criteria

- [ ] Validation report shows all checks passed
- [ ] 0 empty descriptions after re-run
- [ ] All new categories are valid snake_case L1/L2 values
- [ ] CSV has 8 columns: `app_name | source_app_names_old | sig_app_tags | category | subcategory | description | secondary_category | secondary_subcategory`
- [ ] Changes are committed to git

---

## Common Variations

**Minor description fix** (1 app): Edit inline in DESC_* dict → re-run from cell 36 → save  
**Bulk new apps** (10+): Add to DESC_* dict section → re-run from cell 21 → full validation  
**New subcategory**: Get Master Agent approval → update taxonomy → add entries → full re-run  
**Secondary label correction**: Edit SECONDARY_LABELS → re-run from cell 41 → save  

---

## Troubleshooting

| Problem | Solution |
|---------|---------|
| App description empty after merge | Check app name spelling in DESC_* dict — must match `app_name` column exactly |
| CATEGORY_FIXES: `not found: [app]` | App name in CATEGORY_FIXES doesn't match `output["app_name"]` exactly |
| Validation assertion fails on columns | Cell 43 may be selecting wrong columns — update to include all 8 |
| `sig_app_tags` column missing from CSV | Cell 43 dropped it — update column selection list in that cell |
| `to_safe()` changes a label | Label in DESC_* dict uses non-snake_case; fix the source label to pre-normalised snake_case |
| `.ipynb` edit with `replace_string_in_file` fails | Use `edit_notebook_file` with `editType="edit"` instead |
