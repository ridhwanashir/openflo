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

---

### [2026-04-01] Target Sample Size Set to 50,000

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
