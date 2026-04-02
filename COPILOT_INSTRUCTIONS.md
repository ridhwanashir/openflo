# GitHub Copilot Instructions for OpenFlo

> **How to use OpenFlo with GitHub Copilot effectively.**

---

## 🎯 Copilot + OpenFlo = Superpowers

GitHub Copilot is the interface. OpenFlo is the system. Together they create a powerful AI agent orchestration platform.

---

## 🚀 Getting Started

### Command: Initialize OpenFlo

**Purpose**: Set up the entire system for your project

**Usage:**
```
Initialize OpenFlo for my project.

Project Name: [NAME]
Project Type: [software/business/creative/consulting]
Description: [1-2 sentences]
My Role: [your role]
```

**What Happens:**
1. Copilot reads `agents/MASTER_AGENT.md` template
2. Customizes it with your project details
3. Creates `projects/[name]/PROJECT.md`
4. Sets up memory folders
5. Confirms initialization

---

## 🤖 Agent Commands

### Create a New Agent

```
Create a specialized agent for [PURPOSE].

Agent Name: [NAME]
Responsibilities:
- [Task 1]
- [Task 2]
- [Task 3]

Key Skills: [skill 1, skill 2]
```

**Example:**
```
Create a specialized agent for code review.

Agent Name: Code Reviewer
Responsibilities:
- Review pull requests for quality
- Check for security issues
- Suggest performance improvements
- Verify test coverage

Key Skills: Code analysis, security best practices, performance optimization
```

---

### List All Agents

```
List all agents
```

**Output:**
```
Active Agents:
✓ Master Orchestrator (master)
✓ Code Reviewer (code-reviewer) - Active
✓ PRD Writer (prd-writer) - Active
✓ Test Generator (test-generator) - Active

Inactive Agents:
- None
```

---

### Use an Agent

```
@[agent-id] [task description]
```

**Examples:**
```
@code-reviewer Review this function for security issues
```
```
@prd-writer Create a PRD for user authentication feature
```
```
@test-generator Generate unit tests for this component
```

---

## 📋 Project Commands

### Show Project Status

```
Show project status
```

**Output:**
```
Project: SaaS Dashboard

Active:
- User authentication (In Progress)
- Dashboard UI (To Do)
- API integration (To Do)

Completed:
- Project setup ✓
- Database schema ✓

Blockers:
- None

Next Milestone: MVP Launch (2 weeks)
```

---

### Create New Project

```
Create new project [NAME]

Type: [software/business/creative/consulting]
Description: [brief description]
```

---

### Update Project Status

```
Update project [NAME] status

Completed: [what was done]
In Progress: [what's being worked on]
Blockers: [any issues]
```

---

## 🔄 Workflow Commands

### Create Workflow

```
Create workflow for [PROCESS_NAME]

Steps:
1. [Step 1]
2. [Step 2]
3. [Step 3]

Triggers: [when this workflow runs]
Outputs: [what it produces]
```

**Example:**
```
Create workflow for feature development

Steps:
1. Receive feature request
2. Create PRD document
3. Break into technical tickets
4. Estimate effort
5. Assign to developer

Triggers: New feature request
Outputs: PRD + Jira tickets
```

---

### List Workflows

```
Show available workflows
```

---

### Run Workflow

```
Run workflow [WORKFLOW_NAME]

Context: [any relevant info]
```

---

## 🧠 Memory Commands

### Store Information

```
Remember: [information to store]
```

```
Store in memory: [information]
Category: [category]
```

**Examples:**
```
Remember: We use PostgreSQL for primary database and Redis for caching
```
```
Store in memory: Client prefers Slack over email for urgent communication
Category: client-preferences
```

---

### Retrieve Information

```
What do we know about [TOPIC]?
```

```
Recall: [TOPIC]
```

**Examples:**
```
What do we know about the authentication system?
```
```
Recall: client communication preferences
```

---

### Search Memory

```
Search memory for [KEYWORD]
```

---

## 📝 Documentation Commands

### Update Documentation

```
Update documentation for [TOPIC]
```

```
Document [DECISION/FEATURE/PROCESS]
```

**Examples:**
```
Update documentation for the API endpoints
```
```
Document why we chose React over Vue
```

---

### Create Documentation

```
Create documentation for [TOPIC]

Include:
- [Section 1]
- [Section 2]
- [Section 3]
```

---

## 🎯 Task-Specific Patterns

### Software Development

```
Create PRD for [FEATURE]
```

```
Break [FEATURE] into technical tickets
```

```
Review this code: [paste code]
```

```
Generate tests for [COMPONENT]
```

---

### Content Creation

```
Create content calendar for [CAMPAIGN]
```

```
Write a [TYPE] about [TOPIC]
Tone: [professional/casual/funny]
Length: [word count]
```

```
Optimize this content for SEO
```

---

### Business Operations

```
Generate weekly report
```

```
Analyze [DATA] and create summary
```

```
Create process documentation for [PROCESS]
```

---

## 🔧 System Commands

### Check System Status

```
OpenFlo status
```

**Output:**
```
System Status:
✓ Master Agent: Active
✓ Memory System: Connected
✓ Documentation: Up to date
✓ Active Agents: 5
✓ Projects: 2

Last updated: [timestamp]
```

---

### Reset/Clear

```
Clear context
```

```
Reset to defaults
```

---

### Export/Backup

```
Export project [NAME]
```

```
Backup all agents
```

---

## 💡 Advanced Patterns

### Chaining Agents

```
Step 1: @researcher Research [TOPIC]
Step 2: @writer Create summary from research
Step 3: @editor Review and polish
```

---

### Conditional Workflows

```
If [CONDITION]:
  Run workflow A
Else:
  Run workflow B
```

**Example:**
```
If this is a bug fix:
  Run bug-fix-workflow
Else:
  Run feature-dev-workflow
```

---

### Batch Processing

```
For each [ITEM] in [LIST]:
  @[AGENT] [TASK]
```

**Example:**
```
For each page in website:
  @seo-analyzer Check SEO optimization
```

---

## 🎨 Customization Commands

### Set Preferences

```
Set preference [KEY] to [VALUE]
```

**Examples:**
```
Set preference communication_style to concise
```
```
Set preference default_agent to prd-writer
```

---

### Create Template

```
Create template for [TYPE]

Fields:
- [Field 1]
- [Field 2]
- [Field 3]
```

---

### Modify Agent

```
Update agent [AGENT_NAME]

Add:
- [New capability]

Remove:
- [Old capability]

Change:
- [Existing capability]
```

---

## 🐛 Debug Commands

### Check Agent Config

```
Show agent [AGENT_NAME] configuration
```

### View Memory

```
Show memory for [AGENT/TOPIC]
```

### Trace Decision

```
Why did you [ACTION]?
```

### Validate Setup

```
Validate OpenFlo setup
```

---

## 📊 Report Commands

### Generate Reports

```
Generate [TYPE] report

Period: [daily/weekly/monthly]
Format: [summary/detailed]
```

**Examples:**
```
Generate weekly progress report
```
```
Generate project health report
```
```
Generate agent activity report
```

---

## 🎓 Learning Commands

### Teach the System

```
Learn: [PATTERN/INSIGHT]

Context: [where this applies]
Importance: [high/medium/low]
```

**Example:**
```
Learn: Always include error handling in API routes

Context: Backend development
Importance: high
```

---

### Review Learning

```
What have we learned?
```

```
Show patterns from past tasks
```

---

## 📝 Best Practices

### DO:
- ✅ Be specific in your requests
- ✅ Use @mentions for direct agent assignment
- ✅ Provide context for complex tasks
- ✅ Review and correct agent outputs
- ✅ Update documentation regularly

### DON'T:
- ❌ Give vague instructions
- ❌ Expect mind-reading (provide context)
- ❌ Skip reviewing agent work
- ❌ Forget to update project status
- ❌ Create too many agents (consolidate instead)

---

## 🔗 Quick Reference Card

| You Say | Copilot Does |
|---------|--------------|
| `Initialize OpenFlo` | Sets up system |
| `Create agent for X` | Creates specialized agent |
| `@agent [task]` | Assigns task to agent |
| `Show project status` | Reports on projects |
| `Remember: X` | Stores in memory |
| `Create workflow for X` | Creates workflow template |
| `Generate report` | Creates status report |

---

**Start here:** `Initialize OpenFlo for my project`
