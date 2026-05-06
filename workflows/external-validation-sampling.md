# Workflow: External Validation Sampling

> **Workflow ID**: `external-validation-sampling`  
> **Project**: Income Score Modelling — IOH  
> **Owner Agent**: Data Sampling Agent  
> **Version**: 1.0  
> **Created**: 2026-04-01

---

## Purpose
Define the end-to-end process for generating, approving, and submitting a subscriber sample from the IOH user base to the external validation data provider (government tax authority), in order to obtain income ground-truth labels for model training and validation.

## Trigger
Initiated when: Owner confirms readiness to begin sampling phase and provides required inputs (matching key, DPO scope, stratification criteria).

## Participants
- **Data Scientist (Owner)**: Approves strategy, signs off on governance
- **Master Orchestrator**: Tracks milestones, flags blockers
- **Data Sampling Agent**: Executes all technical sampling steps
- **DPO / Data Governance**: Reviews and approves external data handoff (external participant)
- **External Data Provider**: Receives sample, returns matched income labels (external participant)

---

## Steps

### Step 1: Requirements Gathering
**Who**: Data Sampling Agent + Owner  
**What**: Collect all inputs needed to design the sample:
- Matching key (NIK / phone number / other)
- Allowed fields for external sharing
- Stratification requirements (region, usage segment, etc.)
- Provider format/schema requirements
- Timeline and target n (default: 50,000 matched records)  

**Output**: Completed requirements checklist in `projects/income-score-modelling/PROJECT.md`  
**Next**: Proceed to Step 2 once all required inputs are received

---

### Step 2: Sampling Strategy Design
**Who**: Data Sampling Agent  
**What**: Propose 3 alternative sampling approaches:
- Option A: Pure random sampling
- Option B: Stratified sampling (by usage tier / region / demographic proxy)
- Option C: Quota-based sampling (aligned with external provider's known coverage)

Present each with: description, pros/cons, expected match rate, implementation complexity, recommended oversampling multiplier.  

**Output**: Sampling Strategy Options document  
**Next**: Owner reviews and selects strategy → Step 3

---

### Step 3: Strategy Approval
**Who**: Owner (Data Scientist)  
**What**: Review options, ask clarifying questions, select and approve a strategy  
**Output**: Approved sampling strategy decision recorded in `memory/master/decisions.md`  
**Next**: Step 4

---

### Step 4: Sampling Universe Definition
**Who**: Data Sampling Agent  
**What**:
- Define eligible subscriber population (active, minimum tenure, data availability)
- Document all exclusion criteria
- Estimate universe size
- Compute required raw sample size (target n × oversampling factor)  

**Output**: Universe specification document  
**Next**: Step 5

---

### Step 5: Sample Extraction
**Who**: Data Sampling Agent  
**What**:
- Write and review sampling query (SQL / pySpark / etc.)
- Execute extraction on IOH data platform
- Validate raw extract (row count, field completeness, no duplicates)  

**Output**: Raw sample file  
**Next**: Step 6

---

### Step 6: Sample QC & Validation
**Who**: Data Sampling Agent  
**What**:
- Check distribution against expected strata
- Report missing rates per field
- Flag outliers or anomalies
- Compare sample demographics against full IOH user base  

**Output**: QC Report  
**Next**: Step 7 (if QC passes); loop back to Step 5 if issues found

---

### Step 7: Governance & Privacy Review
**Who**: Data Sampling Agent (prepares) + DPO (approves)  
**What**:
- Apply pseudonymisation / anonymisation as required
- Prepare data handoff checklist
- Submit for DPO review and approval  

**Output**: DPO-approved sample; signed data handoff checklist  
**Next**: Step 8

---

### Step 8: External Submission
**Who**: Data Scientist (Owner)  
**What**:
- Deliver sample file to external data provider in required format
- Record submission date, provider contact, expected return date
- Store submission record in `projects/income-score-modelling/PROJECT.md`  

**Output**: Submitted sample; confirmation from provider  
**Next**: Wait for validation data return → triggers EDA & Modelling workflow

---

## Success Criteria
- [ ] Sample size: ~50,000 matched records (after provider return and linkage)
- [ ] Sample representativeness: distributions align with approved strata
- [ ] QC: 0 duplicate subscriber IDs, <5% missing rate on key fields
- [ ] Governance: DPO-approved data handoff checklist completed
- [ ] Documentation: All steps and decisions recorded in project files

---

## Risk Flags
| Risk | Mitigation |
|------|------------|
| Low match rate (<40%) → fewer than 50k labels returned | Oversample by 2–2.5x in raw submission |
| DPO rejects field sharing scope | Reduce to minimum identifier fields; consult owner |
| External provider format mismatch | Confirm schema in Step 1; validate before submission |
| Telco data quality issues in sample | QC in Step 6; flag and document any imputation used |
