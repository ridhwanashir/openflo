# Memory System Structure

> How the OpenFlo memory system works

---

## Overview

The memory system ensures your AI agents learn and improve over time. Information persists across sessions, enabling continuous learning.

---

## Memory Architecture

```
memory/
├── master/                    # Master agent memory
│   ├── context.md            # Current state, preferences
│   ├── decisions.md          # Key decisions & rationale
│   ├── learnings.md          # Patterns & insights learned
│   └── interactions.md       # Important conversations
│
└── specialized/              # Per-agent memory
    └── [agent-id]/
        ├── context.md        # Agent-specific state
        ├── decisions.md      # Domain decisions
        └── knowledge.md      # Accumulated domain knowledge
```

---

## What Gets Stored

### Master Agent Memory

**Context** (`context.md`):
- Current state of all projects
- Active tasks and priorities
- Recent interactions
- System preferences
- Owner's working patterns

**Decisions** (`decisions.md`):
- Why agents were created
- Major architecture decisions
- Priority settings
- Agent assignments

**Learnings** (`learnings.md`):
- What approaches work well
- Common request patterns
- Effective configurations
- Process improvements

**Interactions** (`interactions.md`):
- Key conversations
- Feedback received
- Important context

### Specialized Agent Memory

**Context** (`context.md`):
- Current state within domain
- Active items
- Recent activities
- Current priorities

**Decisions** (`decisions.md`):
- Domain-specific choices
- Trade-offs and rationale
- Escalated items

**Knowledge** (`knowledge.md`):
- Domain-specific information
- Technical details
- Patterns and best practices
- Common issues and solutions

---

## When to Store Information

### Immediately Store:
- ✅ Important decisions made
- ✅ New information learned
- ✅ Owner preferences or feedback
- ✅ Significant context changes

### Periodically Store:
- ✅ Daily activity summary
- ✅ Weekly patterns
- ✅ Monthly learnings

---

## How to Use Memory in Copilot

### Store Information
```
Remember: [information to store]
```

```
Store in memory: [information]
Category: [category]
```

### Retrieve Information
```
What do we know about [TOPIC]?
```

```
Recall: [TOPIC]
```

### Search Memory
```
Search memory for [KEYWORD]
```

---

## Memory Entry Format

When writing to memory, use this format:

```markdown
### [Entry Title]
**Timestamp**: [ISO date/time]
**Category**: [Category]
**Content**: [The actual information]
**Impact**: [Why this matters]
**Related**: [Links to related info]
```

---

## Memory Maintenance

### Weekly:
- Review and consolidate recent entries
- Identify emerging patterns
- Clean up duplicates

### Monthly:
- Archive old entries
- Create learning summaries
- Review and update knowledge base

### Quarterly:
- Major memory review
- Archive completed project memory
- Update memory structure as needed

---

## Privacy & Security

### What NOT to Store:
- ❌ Passwords or API keys
- ❌ Private personal information
- ❌ Sensitive business data
- ❌ Temporary working notes

### What to Reference Instead:
- 🔒 Location of sensitive info (not the info itself)
- 🔒 Who to ask for access
- 🔒 Relevant policies or procedures
- 🔒 Security considerations

---

**Status**: Ready to use  
**Version**: 1.0
