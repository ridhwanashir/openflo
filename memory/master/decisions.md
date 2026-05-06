# Master Agent Decisions Log

> Records key decisions, rationale, and alternatives considered.  
> Maintained for audit trail and reproducibility.

---

## Decision Log

### [2026-04-01] OpenFlo System Initialized

**Decision**: Initialize OpenFlo for Income Score Modelling project with a Data Scientist workflow configuration.  
**Rationale**: Project is in early phase; establishing structured tracking, agent system, and documentation baseline before data work begins ensures reproducibility and reduces rework.  
**Alternatives Considered**:
- *Ad hoc notes only*: Faster to start, but loses traceability and makes handoffs harder.
- *Lightweight README only*: Insufficient for multi-phase ML project with external dependencies.

### 2026-03-18 — Taxonomy v2 Design

| # | Decision | Rationale |
|---|----------|-----------|
| D-009 | L2 subcategory principle = **service type** | Role-based or ownership-based distinctions go in description, not subcategory |
| D-010 | 11 L1 categories in snake_case | `to_safe()` enforces no ampersands/spaces; eliminates encoding issues in BQ/LLM |
| D-011 | Add `bnpl_pay_later` subcategory under finance | BNPL apps (Kredivo, Atome, Akulaku) are distinct from e_wallet and payment_gateway |
| D-012 | Add secondary category/subcategory columns | Super-apps (Gojek, Grab, Shopee) span two L1 domains; single label is insufficient |
| D-013 | Output schema: 8 columns | `app_name | source_app_names_old | sig_app_tags | category | subcategory | description | secondary_category | secondary_subcategory` |

### 2026-03-19 — Notebook Structure

| # | Decision | Rationale |
|---|----------|-----------|
| D-014 | Inline all corrections into source DESC_* dicts | Eliminates post-hoc PATCH/CORRECTIONS cells; notebook is cleaner and reproducible |
| D-015 | Remove separate CORRECTIONS, PATCH, unicode-fix cells | All fixes live in DESC_FINANCE directly; notebook runs top-to-bottom with no side effects |
| D-016 | Use `to_safe()` normaliser on all taxonomy labels | Single authoritative function ensures snake_case consistency across all columns |
| D-017 | Column reorder cell before save | Enforces canonical column order: base cols → enriched cols → secondary cols |

---

### [2026-04-01] Target Sample Size Set to 50,000

<<<<<<< HEAD
**Decision**: Target 50k records from IOH user base for external validation matching.  
**Rationale**: Balances statistical representativeness with practical constraints on external provider data handling.  
**Alternatives Considered**:
- *Full population*: Maximum signal but impractical for external matching and DPO risk is higher.
- *10k–20k*: Faster and lower risk, but may reduce model performance and generalizability.
- *100k+*: Better coverage but increases data governance complexity and external provider burden.

**Status**: Size confirmed; stratification strategy TBD (awaiting owner input).

---

### [2026-04-01] Data Sampling Agent Created

**Decision**: Create a dedicated Data Sampling Agent to own the 50k sampling workflow.  
**Rationale**: Sampling is the critical first phase with its own methodology, governance steps, and dependencies. Dedicated agent keeps responsibilities clean.  
**Alternatives Considered**:
- *Handle sampling in Master Agent*: Simpler setup but mixes orchestration with domain execution.
=======
| # | Question | Options | By |
|---|----------|---------|-----|
| P-001 | BigQuery table location (project/dataset/table) | *(team to provide)* | Data team |
| P-002 | LLM model to use for quality review pass | GPT-4o, Claude 3.5, Gemini Pro | *(pending team decision)* |
| P-003 | Refresh frequency for stale mappings | 30d / 60d / 90d | *(pending SLA definition)* |
| P-004 | Should description length cap be 2 or 3 sentences? | Current: 2 sentences per `app-mapper` rules | Review after LLM quality pass |
>>>>>>> 3c310d3 (feat: Add comprehensive project status documentation and update workflow for app mapping sessions)
