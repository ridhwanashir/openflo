# Project: Income Score Modelling using Telco Data (IOH)

> **Status**: 🟡 Planning — Early Phase (Sampling in Progress)  
> **Owner**: Data Scientist  
> **Organization**: Indosat Ooredoo Hutchison (IOH)  
> **Initialized**: 2026-04-01  
> **Last Updated**: 2026-04-01

---

## Project Overview

### Objective
Build an **Income Scoring Model** for IOH's user base using telco behavioral data as primary features, validated against external ground-truth income data from government tax records (SPT/DJP).

### Business Value
- Enable IOH to estimate subscriber income levels for product targeting, credit scoring partnerships, and personalized offers.
- Provide a statistically validated, reproducible ML pipeline grounded in external income data.

### High-Level Approach
1. **Sampling**: Extract a representative sample (~50,000 users) from the IOH user base that matches the coverage of the external validation dataset.
2. **Data Preparation**: Clean and join telco behavioral features with validated income labels.
3. **Feature Engineering**: Construct income-predictive features from telco signals (ARPU, data usage, roaming, top-up patterns, etc.).
4. **Modelling**: Train and tune an income scoring model.
5. **Validation**: Evaluate model performance against government tax income labels.
6. **Deployment**: Register model and scoring pipeline for production inference.

---

## Current Phase

### Phase: Sampling Design
**Goal**: Generate a 50,000-record sample from the IOH user base that can be submitted to (or matched with) the external validation data provider (government tax authority).

**Key Activities**:
- [ ] Define sampling universe (eligible subscribers)
- [ ] Determine sampling strategy (random, stratified, quota-based)
- [ ] Align sample scope with external provider's coverage constraints
- [ ] Document data fields required in the sample request
- [ ] Obtain internal data governance/privacy approval for external data handoff
- [ ] Deliver sample file to external data provider

**Target Output**: A clean, approved 50k subscriber sample list ready for external validation data matching.

---

## Data Sources

| Source | Type | Owner / Provider | Status | Notes |
|--------|------|-----------------|--------|-------|
| IOH User Base | Internal telco data | IOH Data Platform | Available | Full subscriber base; needs sampling |
| Government Tax Data | External validation labels | Tax Authority / DJP (via provider) | Pending | Provides income ground-truth for matched users |

---

## Constraints & Risks

| # | Risk / Constraint | Severity | Mitigation |
|---|------------------|----------|------------|
| 1 | Privacy & data governance — sharing subscriber identifiers externally | High | Anonymise/pseudonymise IDs; get DPO approval |
| 2 | Low match rate between IOH sample and tax data | Medium | Oversample; align on matching key (NIK/phone) |
| 3 | Tax data coverage bias (formal income earners only) | High | Document scope clearly; consider model applicability limits |
| 4 | Small labelled dataset relative to full user base | Medium | Use semi-supervised or calibration techniques |
| 5 | Data freshness — telco features and tax data period mismatch | Medium | Align observation windows carefully |

---

## Milestones

| Milestone | Target Date | Status | Notes |
|-----------|------------|--------|-------|
| Sampling strategy defined | TBD | ⬜ Not started | Pending detail from owner |
| Sample file delivered to provider | TBD | ⬜ Not started | — |
| Validation data received from provider | TBD | ⬜ Not started | — |
| EDA completed | TBD | ⬜ Not started | — |
| Feature engineering completed | TBD | ⬜ Not started | — |
| Baseline model trained | TBD | ⬜ Not started | — |
| Model validated against tax labels | TBD | ⬜ Not started | — |
| Model registered for production | TBD | ⬜ Not started | — |

---

## Active Agents

| Agent | Purpose | Status |
|-------|---------|--------|
| Master Orchestrator | Project coordination & task delegation | Active |
| Data Sampling Agent | Design & execute the 50k sampling strategy | Active |

---

## Decisions Log

| Date | Decision | Rationale | Alternatives Considered |
|------|----------|-----------|------------------------|
| 2026-04-01 | Start with 50k stratified sample | Manageable for external provider; sufficient for initial model | Census (too large), pure random (risk of coverage gaps) |

---

## Open Questions

> Questions that need owner input before proceeding.

1. What is the matching key between IOH subscribers and the tax authority data? (phone number, NIK, etc.)
2. Are there regulatory/DPO constraints on the data fields that can be included in the sample?
3. What is the timeline expectation for receiving the validated data back from the provider?
4. Should the 50k be a random sample, or stratified by any demographic or usage dimension?
5. What is the intended geographic scope — nationwide or specific regions?

---

## Notes & Context

- **IOH** = Indosat Ooredoo Hutchison (Indonesian telco operator)
- **External validation provider** = Government tax data authority (e.g., Direktorat Jenderal Pajak / DJP or similar)
- **Income scoring** will likely capture formal + informal income signals; be explicit about model limitations given tax data only covers formal income
- Owner prefers careful, detailed approach — always present alternatives and trade-offs before major decisions
