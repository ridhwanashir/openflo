# Workflow Guide

> How to create, manage, and use workflows in OpenFlo

---

## What is a Workflow?

A **workflow** is a repeatable process that defines:
- **What** needs to be done
- **How** it should be done
- **Who** does it
- **In what order** steps occur
- **What** the output should be

---

## When to Create a Workflow

Create a workflow when you notice:
- ✅ Same process happening repeatedly
- ✅ Multi-step task that needs consistency
- ✅ Process with clear handoffs between agents
- ✅ Task that benefits from standardization

---

## Workflow Structure

Every workflow should include:

```markdown
# Workflow: [NAME]

## Purpose
[What this workflow accomplishes]

## Trigger
[When this workflow runs]

## Participants
- [Agent/Role 1]
- [Agent/Role 2]

## Steps

### Step 1: [Name]
**Who**: [Agent/Role]
**What**: [Description]
**Output**: [Expected output]
**Next**: [What triggers next step]

### Step 2: [Name]
**Who**: [Agent/Role]
**What**: [Description]
**Output**: [Expected output]
**Next**: [What triggers next step]

## Success Criteria
- [Criterion 1]
- [Criterion 2]

## Common Variations
- [Variation 1 and when to use it]
- [Variation 2 and when to use it]

## Troubleshooting
- [Common issue 1 and solution]
- [Common issue 2 and solution]
```

---

## Using Workflows

### 1. Create a New Workflow

```
Create workflow for [PROCESS_NAME]

Steps:
1. [Step 1]
2. [Step 2]
3. [Step 3]

Triggers: [when this runs]
Participants: [who is involved]
Outputs: [what it produces]
```

### 2. Run an Existing Workflow

```
Run workflow [WORKFLOW_NAME]

Context: [relevant information]
```

### 3. Customize a Template

```
Customize workflow [TEMPLATE_NAME] for [SPECIFIC_USE]

Changes:
- [Change 1]
- [Change 2]
```

---

## Available Templates

See `/workflows/templates/` for ready-to-use templates:

- `feature-development.md` - Software feature from idea to deployment
- `content-creation.md` - Content from brief to publication
- `bug-fix.md` - Bug from report to resolution
- `onboarding.md` - New team member onboarding
- `client-delivery.md` - Client project from kickoff to delivery
- `incident-response.md` - Production incident handling

---

## Best Practices

### DO:
- ✅ Keep workflows focused (5-10 steps max)
- ✅ Define clear handoffs between steps
- ✅ Include expected outputs for each step
- ✅ Document variations and edge cases
- ✅ Review and update workflows regularly

### DON'T:
- ❌ Make workflows too complex
- ❌ Skip defining success criteria
- ❌ Forget to document who does what
- ❌ Leave steps ambiguous
- ❌ Create workflows for one-off tasks

---

## Workflow Examples

### Simple Workflow (3 steps)
```
Workflow: Blog Post Creation

1. Research topic → @researcher
2. Write draft → @writer
3. Edit and publish → @editor
```

### Complex Workflow (7 steps)
```
Workflow: Feature Development

1. Receive request → Master Agent
2. Clarify requirements → Master Agent
3. Create PRD → @prd-writer
4. Technical design → @tech-lead
5. Break into tickets → @ticket-writer
6. Development → Developers
7. Review and deploy → @code-reviewer
```

---

## Measuring Workflow Effectiveness

Track these metrics:
- **Completion rate**: % of workflows completed successfully
- **Time to complete**: Average duration
- **Quality score**: Error/rework rate
- **Satisfaction**: User feedback

---

**Next**: Check `workflows/templates/` for ready-to-use workflow templates.
