# Project: Income Score Modelling using Telco Data (IOH)

> **Status**: 🟡 In Progress — Data Preparation Phase  
> **Owner**: Data Scientist  
> **Organization**: Indosat Ooredoo Hutchison (IOH)  
> **Initialized**: 2026-04-01  
> **Last Updated**: 2026-04-23

---

## Project Overview

### Objective
Build an **Income Scoring Model** for IOH's user base using telco behavioral data as primary features, labelled against external income data from a partner/provider (~50k records).

### Business Value
- Enable IOH to estimate subscriber income levels for product targeting, credit scoring partnerships, and personalized offers.
- Provide a statistically validated, reproducible ML pipeline grounded in external income data.

### Label Definition (Two Variants — TBD on final choice)

| Variant | Type | Description | Example |
|---------|------|-------------|---------|
| **Categorical Range** | Multi-class classification | Income grouped into brackets | `1`, `2`, `3` → `<1M`, `1–3M`, `>3M` IDR/month |
| **Exact Amount** | Regression | Continuous income figure | `2,500,000` IDR/month |

> The final label type will be decided once the partner data is received and inspected. Both variants will be assessed during EDA.

---

### High-Level Pipeline

```
[Partner Data]
    │
    │  hashed_msisdn + NIK + income_label (~50k rows)
    ▼
[Step 1: Hash Reversal]
    │  Reverse hashed MSISDN → raw MSISDN
    │  (using IOH internal hash lookup / reverse table in BigQuery)
    ▼
[Step 2: Join with IOH Telco Data — BigQuery]
    │  Match on MSISDN → pull subscriber behavioral features
    │  (ARPU, data usage, top-up patterns, roaming, device, etc.)
    ▼
[Step 3: Data Validation]
    │  Check match rate, null rates, schema consistency,
    │  label distribution, duplicate records
    ▼
[Step 4: Data Exploration (EDA)]
    │  Understand label distribution (both variants)
    │  Feature distributions, correlations, missingness
    │  Assess data quality and coverage bias
    ▼
[HOLD — Await EDA findings before proceeding to modelling]
    │
    ▼
[Step 5: Feature Engineering]        ← NOT YET STARTED
[Step 6: Modelling]                  ← NOT YET STARTED
[Step 7: Evaluation & Validation]    ← NOT YET STARTED
[Step 8: Deployment]                 ← NOT YET STARTED
```

---

## Current Phase

### Phase: Data Reception & Preparation
**Goal**: Receive the partner dataset, reverse hash identifiers, join with IOH telco data in BigQuery, validate, and explore the data. No modelling until data quality and label are confirmed.

**Key Activities**:
- [ ] Receive partner dataset (~50k rows: hashed MSISDN, NIK, income label)
- [ ] Reverse hashed MSISDN using IOH internal lookup (BigQuery)
- [ ] Join with IOH subscriber telco behavioral data (BigQuery)
- [ ] Run data validation checks (match rate, nulls, schema, duplicates, label distribution)
- [ ] Conduct EDA on joined dataset
- [ ] Assess both label variants (categorical range vs. exact amount)
- [ ] Document findings and decide label type + confirm feature candidates
- [ ] **Decision gate**: Proceed to modelling only after EDA sign-off

**Target Output**: Validated, joined dataset with EDA findings documented. Label type decision made.

---

## Data Sources

| Source | Type | Owner / Provider | Location | Status | Notes |
|--------|------|-----------------|----------|--------|-------|
| Partner Income Data | External labels | External Partner | File transfer (TBD) | Awaiting receipt | ~50k rows; hashed MSISDN + NIK + income label |
| IOH Hash Lookup Table | Internal identifier map | IOH Data Platform | GCP BigQuery | Available | Used to reverse hashed MSISDN |
| IOH Subscriber Telco Data | Internal behavioral features | IOH Data Platform | GCP BigQuery | Available | ARPU, data usage, top-up, roaming, device, etc. |

---

## Label Variants

### Option A: Categorical Range (Classification)
- Income grouped into discrete brackets (e.g., `<1M`, `1–3M`, `3–5M`, `>5M` IDR/month)
- Model type: Multi-class classifier (e.g., LightGBM, XGBoost)
- Evaluation: Accuracy, F1-macro, confusion matrix

### Option B: Exact Amount (Regression)
- Continuous income value in IDR/month
- Model type: Regressor (e.g., LightGBM, XGBoost, or quantile regression)
- Evaluation: MAE, RMSE, MAPE; consider log-transform for skewed distribution

> **Decision pending**: Finalize after inspecting partner data label format in EDA phase.

---

## Constraints & Risks

| # | Risk / Constraint | Severity | Mitigation |
|---|------------------|----------|------------|
| 1 | Privacy & data governance — sharing subscriber identifiers externally | High | Hashed IDs used for exchange; reverse hash stays internal |
| 2 | Low match rate between partner data and IOH subscriber base | Medium | Validate match rate early; flag if <70% |
| 3 | Income label quality from partner (self-reported or estimated?) | High | Inspect and document label source and methodology |
| 4 | Coverage bias — partner data may skew toward formal income earners | High | Document scope clearly; consider model applicability limits |
| 5 | Small labelled dataset (~50k) relative to full user base | Medium | Use calibration and sampling-aware techniques |
| 6 | Data freshness — telco features and income label period mismatch | Medium | Align observation windows carefully during join |
| 7 | NIK matching reliability across datasets | Medium | Validate NIK format consistency before joining |

---

## Milestones

| Milestone | Target Date | Status | Notes |
|-----------|------------|--------|-------|
| Sampling strategy defined | 2026-04-01 | ✅ Done | Stratified 50k sample; delivered to partner |
| Sample file delivered to partner | TBD | ✅ Done | Hashed MSISDN + NIK submitted |
| Partner income data received | TBD | ⬜ Not started | Awaiting partner delivery |
| Hash reversal completed (BigQuery) | TBD | ⬜ Not started | — |
| Telco data join completed (BigQuery) | TBD | ⬜ Not started | — |
| Data validation completed | TBD | ⬜ Not started | — |
| EDA completed | TBD | ⬜ Not started | — |
| Label type decision made | TBD | ⬜ Not started | Categorical vs. exact — post EDA |
| Feature engineering completed | TBD | ⬜ Not started | Blocked on EDA |
| Baseline model trained | TBD | ⬜ Not started | Blocked on feature eng. |
| Model evaluated & validated | TBD | ⬜ Not started | — |
| Model registered for production | TBD | ⬜ Not started | — |

---

## Active Agents

| Agent | Purpose | Status |
|-------|---------|--------|
| Master Orchestrator | Project coordination & task delegation | Active |
| Data Sampling Agent | Design & execute the 50k sampling strategy | Completed |

---

## Decisions Log

| Date | Decision | Rationale | Alternatives Considered |
|------|----------|-----------|------------------------|
| 2026-04-01 | Start with 50k stratified sample | Manageable for external provider; sufficient for initial model | Census (too large), pure random (risk of coverage gaps) |
| 2026-04-23 | Two label variants in scope (categorical range + exact amount) | Partner data label format unknown until received; both approaches kept open | Single-label approach too early without seeing data |
| 2026-04-23 | Hold modelling until EDA sign-off | Data quality, match rate, and label format must be validated before committing to a modelling approach | Risk of building on bad labels without validation |
| 2026-04-23 | Use GCP BigQuery for hash reversal and telco data join | All IOH internal data lives in BigQuery; consistent infrastructure | — |

---

## Open Questions

| # | Question | Raised | Owner | Status |
|---|----------|--------|-------|--------|
| 1 | What is the exact label format in the partner data? (brackets vs. raw number) | 2026-04-23 | DS | Open — pending data receipt |
| 2 | What is the expected match rate between partner NIK/MSISDN and IOH subscriber base? | 2026-04-23 | DS | Open |
| 3 | What time period does the partner income data cover? | 2026-04-23 | DS | Open |
| 4 | Which telco behavioral features are available and at what granularity? | 2026-04-23 | DS | Open — to confirm during join step |
| 5 | Is the income label self-reported, tax-derived, or estimated by partner? | 2026-04-23 | DS | Open |

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
