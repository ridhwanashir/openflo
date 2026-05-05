# Master Agent Context

<<<<<<< HEAD
> Current state snapshot for the Master Orchestrator.  
> Updated: 2026-04-01
=======
> Current system state, active priorities, and working context.  
> **Last Updated**: 2026-03-19
>>>>>>> 3c310d3 (feat: Add comprehensive project status documentation and update workflow for app mapping sessions)

---

## Active Project

<<<<<<< HEAD
**Project**: Income Score Modelling using Telco Data  
**Organization**: Indosat Ooredoo Hutchison (IOH)  
**Owner Role**: Data Scientist  
**Current Phase**: Early Phase — Sampling Design  
**Overall Health**: 🟡 Yellow (open questions on sampling spec; awaiting owner input)
=======
**OpenFlo Initialized**: ✅ 2026-03-17  
**Active Project**: Application Mapping (IOH Telco Data)  
**Active Agents**: `app-mapper`, `tag-curator`, `data-connector`  
**Current Phase**: CSV Baseline Complete → BigQuery Upload
>>>>>>> 3c310d3 (feat: Add comprehensive project status documentation and update workflow for app mapping sessions)

---

## Current Priorities

<<<<<<< HEAD
1. **Clarify sampling specification** — Matching key, stratification approach, n=50k target, geographic scope
2. **Data governance check** — Privacy/DPO approval for external data handoff
3. **Align with external provider** — Understand data format, delivery timeline, and coverage constraints

---

## Owner Working Style (Key Notes)
- Prefers careful, detailed approach over speed
- Always expects alternative approaches + pros/cons before decisions
- Detailed documentation and audit trail required
- Proactive flagging of risks and blockers expected
=======
1. Upload `mis_app_category_v2.csv` to BigQuery (project/dataset/table names needed from data team)
2. Update `data-connector.md` with actual BQ project/dataset/table identifiers
3. Review taxonomy with team — v2.1 is finalized but should be signed off
4. Begin description quality review pass with LLM for downstream consumption

---

## Owner Working Patterns

- Prefers structured, actionable output over open-ended discussions
- Uses both BigQuery (production) and CSV (development/iteration)
- End goal: feed enriched mapping data to an agentic LLM
- Wants categories and descriptions to be LLM-optimized
- Prefers inline corrections over separate patch/correction cells in notebooks

---

## Completed Milestones

| Milestone | Date | Notes |
|-----------|------|-------|
| OpenFlo framework initialized | 2026-03-17 | Agents, memory, project folder set up |
| CSV baseline created | 2026-03-19 | `mis_app_category_v2.csv` — 1,199 rows × 8 cols |
| Taxonomy v2.1 finalized | 2026-03-19 | 11 L1 categories, 65 L2 subcategories, snake_case |
| Description coverage | 2026-03-19 | 1,199/1,199 (100%) filled |
| Category reclassifications | 2026-03-19 | 18 apps corrected via CATEGORY_FIXES |
| Secondary labels | 2026-03-19 | 37 apps with dual-category coverage |
>>>>>>> 3c310d3 (feat: Add comprehensive project status documentation and update workflow for app mapping sessions)

---

## System State

<<<<<<< HEAD
| Component | Status |
|-----------|--------|
| Master Agent | ✅ Configured |
| Project doc | ✅ Created (`projects/income-score-modelling/PROJECT.md`) |
| Project Tracker | ✅ Updated |
| Memory System | ✅ Initialized |
| Data Sampling Agent | ✅ Created |
| Sampling Workflow | ✅ Created |
=======
- BigQuery project/dataset/table names pending from data team → blocks production upload
>>>>>>> 3c310d3 (feat: Add comprehensive project status documentation and update workflow for app mapping sessions)

---

## Pending Owner Inputs

<<<<<<< HEAD
- [ ] Matching key for tax data linkage (phone, NIK, etc.)
- [ ] DPO/governance constraints on shared fields
- [ ] Stratification criteria (demographics, usage tier, region)
- [ ] Timeline expectations for validation data return
- [ ] Geographic scope of study
=======
- Project is DS-IOH (Data Science — Indosat Ooredoo Hutchison)
- Indonesia-specific app context is important (local apps have high priority)
- The `sig_app_tags` column is critical for the agentic LLM to construct BigQuery filter queries
- Notebook: `app_mapping_migration.ipynb` — run top-to-bottom to regenerate CSV
- Output schema: `app_name | source_app_names_old | sig_app_tags | category | subcategory | description | secondary_category | secondary_subcategory`
>>>>>>> 3c310d3 (feat: Add comprehensive project status documentation and update workflow for app mapping sessions)
