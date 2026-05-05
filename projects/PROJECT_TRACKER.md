# Project Tracker

> Central tracking system for all projects under management

---

## Overview

This tracker maintains visibility across all active projects, their status, documentation, and assigned agents.

<<<<<<< HEAD
**Last Updated**: 2026-04-23  
=======
**Last Updated**: 2026-03-19  
>>>>>>> 3c310d3 (feat: Add comprehensive project status documentation and update workflow for app mapping sessions)
**Total Active Projects**: 1

---

## Active Projects

### High Priority
*Projects requiring immediate attention*

| Project | Status | Agent | Last Updated | Next Milestone | Health |
|---------|--------|-------|--------------|----------------|--------|
<<<<<<< HEAD
| Income Score Modelling (IOH) | In Progress — Data Preparation | Master Orchestrator | 2026-04-23 | Receive partner data → hash reversal → BigQuery join | 🟡 |
=======
| Application Mapping | Active | `app-mapper`, `tag-curator`, `data-connector` | 2026-03-19 | BigQuery Upload (TBD) | 🟡 |

### Normal Priority
*Projects in steady state*

| Project | Status | Agent | Last Updated | Next Milestone | Health |
|---------|--------|-------|--------------|----------------|--------|
| *(none yet)* | — | — | — | — | — |

### Low Priority / Monitoring
*Projects in maintenance mode*

| Project | Status | Agent | Last Updated | Notes |
|---------|--------|-------|--------------|-------|
| [NAME] | [STATUS] | [AGENT] | [DATE] | [NOTES] |

---

## Project Status Definitions

| Status | Meaning |
|--------|---------|
| **Planning** | Requirements gathering, initial design |
| **Active** | Actively being worked on |
| **Review** | In QA or review phase |
| **Deployed** | Live in production |
| **Maintenance** | Ongoing support only |
| **On Hold** | Temporarily paused |
| **Completed** | Finished and archived |

---

## Health Indicators

| Indicator | Meaning |
|-----------|---------|
| 🟢 **Green** | On track, no issues |
| 🟡 **Yellow** | Minor issues, manageable |
| 🔴 **Red** | Significant blockers, needs attention |
| ⚪ **Gray** | Inactive or on hold |

---

## Completed Projects

| Project | Completion Date | Final Status | Agent | Archive Location |
|---------|-----------------|--------------|-------|------------------|
| [NAME] | [DATE] | [STATUS] | [AGENT] | [LOCATION] |

---

## Quick Stats

- **Total Active**: 1
- **High Priority**: 1
- **Normal Priority**: 0
- **Low Priority**: 0
- **Completed**: 0

---

## Upcoming Milestones

### This Week
| Project | Milestone | Date | Status |
|---------|-----------|------|--------|
| Application Mapping | BigQuery table upload | TBD | ⬜ Not Started |
| Application Mapping | LLM description quality review | TBD | ⬜ Not Started |

### This Month
| Project | Milestone | Date | Status |
|---------|-----------|------|--------|
| Application Mapping | BigQuery table populated | TBD | ⬜ Not Started |
| Application Mapping | Taxonomy v2.1 team sign-off | TBD | ⬜ Not Started |
| Application Mapping | Full production mapping table | TBD | ⬜ Not Started |

### Completed This Sprint
| Project | Milestone | Completed | Notes |
|---------|-----------|-----------|-------|
| Application Mapping | CSV baseline created | 2026-03-19 | `mis_app_category_v2.csv` — 1,199 rows × 8 cols |
| Application Mapping | Category taxonomy finalized | 2026-03-19 | v2.1 — 11 L1, 65 L2, snake_case |
| Application Mapping | Description coverage 100% | 2026-03-19 | 1,199/1,199, 0 empty |
| Application Mapping | BNPL subcategory created | 2026-03-19 | `bnpl_pay_later` — 7 apps |
| Application Mapping | Secondary labels applied | 2026-03-19 | 37 apps with dual-category coverage |
| Application Mapping | Notebook consolidated | 2026-03-19 | Inline corrections, no patch cells |

---

## Notes & Observations

- `mis_app_category_v2.csv` is the authoritative baseline. Re-generate by running `app_mapping_migration.ipynb` top-to-bottom.
- `taxonomy_reference.csv` is auto-generated from the notebook (cell 42) and reflects the current L1/L2 distribution.
- BigQuery upload is blocked on receiving project/dataset/table identifiers from the data team.

---

**Maintained by**: Master Agent  
**Update Frequency**: Real-time as changes occur  
**Review Frequency**: Weekly summary, monthly deep review

---

## Active Projects

### High Priority
*Projects requiring immediate attention*

| Project | Status | Agent | Last Updated | Next Milestone | Health |
|---------|--------|-------|--------------|----------------|--------|
| Application Mapping | Active | `app-mapper`, `tag-curator`, `data-connector` | 2026-03-17 | Schema Finalization (2026-03-24) | 🟡 |
>>>>>>> 3c310d3 (feat: Add comprehensive project status documentation and update workflow for app mapping sessions)

### Normal Priority
*Projects in steady state*

| Project | Status | Agent | Last Updated | Next Milestone | Health |
|---------|--------|-------|--------------|----------------|--------|
| — | — | — | — | — | — |

### Low Priority / Monitoring
*Projects in maintenance mode*

| Project | Status | Agent | Last Updated | Notes |
|---------|--------|-------|--------------|-------|
| [NAME] | [STATUS] | [AGENT] | [DATE] | [NOTES] |

---

## Project Status Definitions

| Status | Meaning |
|--------|---------|
| **Planning** | Requirements gathering, initial design |
| **Active** | Actively being worked on |
| **Review** | In QA or review phase |
| **Deployed** | Live in production |
| **Maintenance** | Ongoing support only |
| **On Hold** | Temporarily paused |
| **Completed** | Finished and archived |

---

## Health Indicators

| Indicator | Meaning |
|-----------|---------|
| 🟢 **Green** | On track, no issues |
| 🟡 **Yellow** | Minor issues, manageable |
| 🔴 **Red** | Significant blockers, needs attention |
| ⚪ **Gray** | Inactive or on hold |

---

## Completed Projects

| Project | Completion Date | Final Status | Agent | Archive Location |
|---------|-----------------|--------------|-------|------------------|
| [NAME] | [DATE] | [STATUS] | [AGENT] | [LOCATION] |

---

## Quick Stats

- **Total Active**: 1
- **High Priority**: 1
- **Normal Priority**: 0
- **Low Priority**: 0
- **Completed**: 0

---

## Upcoming Milestones

### This Week
| Project | Milestone | Date | Status |
|---------|-----------|------|--------|
| Income Score Modelling (IOH) | Awaiting partner data receipt | TBD | ⬜ Pending |

### This Month
| Project | Milestone | Date | Status |
|---------|-----------|------|--------|
| Income Score Modelling (IOH) | Hash reversal + BigQuery join | TBD | ⬜ Blocked on data receipt |
| Income Score Modelling (IOH) | Data validation | TBD | ⬜ Blocked on join |
| Income Score Modelling (IOH) | EDA + label type decision | TBD | ⬜ Blocked on validation |

### Next Quarter
| Project | Milestone | Date | Status |
|---------|-----------|------|--------|
| Income Score Modelling (IOH) | Feature engineering | TBD | ⬜ Blocked on EDA sign-off |
| Income Score Modelling (IOH) | Baseline model training | TBD | ⬜ Not started |
| Income Score Modelling (IOH) | Model evaluation & registration | TBD | ⬜ Not started |

---

## Notes & Observations

*[Track patterns, insights, and important observations]*

---

**Maintained by**: Master Agent  
**Update Frequency**: Real-time as changes occur  
**Review Frequency**: Weekly summary, monthly deep review
