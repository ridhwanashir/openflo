# Master Agent Context

> Current state snapshot for the Master Orchestrator.  
> Updated: 2026-04-01

---

## Active Project

**Project**: Income Score Modelling using Telco Data  
**Organization**: Indosat Ooredoo Hutchison (IOH)  
**Owner Role**: Data Scientist  
**Current Phase**: Early Phase — Sampling Design  
**Overall Health**: 🟡 Yellow (open questions on sampling spec; awaiting owner input)

---

## Current Priorities

1. **Clarify sampling specification** — Matching key, stratification approach, n=50k target, geographic scope
2. **Data governance check** — Privacy/DPO approval for external data handoff
3. **Align with external provider** — Understand data format, delivery timeline, and coverage constraints

---

## Owner Working Style (Key Notes)
- Prefers careful, detailed approach over speed
- Always expects alternative approaches + pros/cons before decisions
- Detailed documentation and audit trail required
- Proactive flagging of risks and blockers expected

---

## System State

| Component | Status |
|-----------|--------|
| Master Agent | ✅ Configured |
| Project doc | ✅ Created (`projects/income-score-modelling/PROJECT.md`) |
| Project Tracker | ✅ Updated |
| Memory System | ✅ Initialized |
| Data Sampling Agent | ✅ Created |
| Sampling Workflow | ✅ Created |

---

## Pending Owner Inputs

- [ ] Matching key for tax data linkage (phone, NIK, etc.)
- [ ] DPO/governance constraints on shared fields
- [ ] Stratification criteria (demographics, usage tier, region)
- [ ] Timeline expectations for validation data return
- [ ] Geographic scope of study
