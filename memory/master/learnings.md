# Master Agent Learnings

> Accumulated patterns, insights, and lessons from this project.  
> Updated as the project progresses.

---

## Project Context Learnings

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
