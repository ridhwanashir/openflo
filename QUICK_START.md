# OpenFlo Quick Start Guide

> **Get your AI Agent system running in 5 minutes.**

---

## ⚡ Instant Setup (Copilot Chat)

### Step 1: Initialize Your System

**In GitHub Copilot Chat, type:**

```
Initialize OpenFlo for my project.

Project Name: [YOUR_PROJECT_NAME]
Project Type: [software/business/creative/consulting/other]
Brief Description: [1-2 sentences about what this project does]

My role: [Product Manager/Developer/Founder/Consultant/etc]
My preferred working style: [detailed/high-level/async/collaborative]
```

**Example:**
```
Initialize OpenFlo for my project.

Project Name: SaaS Dashboard
Project Type: software
Brief Description: A B2B analytics dashboard for e-commerce companies

My role: Product Manager
My preferred working style: High-level direction, let AI handle details
```

**What Copilot Will Do:**
- ✅ Configure Master Agent with your details
- ✅ Set up project tracking
- ✅ Create initial folder structure
- ✅ Generate starter documentation

---

### Step 2: Create Your First Agent

**In Copilot Chat, type:**

```
Create a specialized agent for [TASK_TYPE].

Agent Name: [NAME]
Responsibilities:
1. [Task 1]
2. [Task 2]
3. [Task 3]

Key skills needed: [skills]
```

**Example:**
```
Create a specialized agent for writing user stories.

Agent Name: User Story Writer
Responsibilities:
1. Convert feature ideas into detailed user stories
2. Write acceptance criteria
3. Estimate story points
4. Create Jira tickets

Key skills needed: Agile methodology, technical writing, estimation
```

**What Copilot Will Do:**
- ✅ Create agent config file in `agents/specialized/`
- ✅ Set up agent memory folder
- ✅ Register agent in system
- ✅ Provide usage instructions

---

### Step 3: Use Your Agent

**Option A: Direct Assignment**
```
@user-story-writer Create user stories for our new checkout flow feature
```

**Option B: Through Master Agent**
```
I need user stories for the checkout flow feature
```
*(Master Agent will delegate to @user-story-writer)*

---

## 🎯 Common First Tasks

### For Software Projects

```
Create a PRD writer agent
```
```
Create a code review agent
```
```
Create a documentation manager agent
```

### For Content/Business

```
Create a content strategist agent
```
```
Create a social media manager agent
```
```
Create a report generator agent
```

### For Consulting

```
Create a client onboarding agent
```
```
Create a deliverable tracker agent
```
```
Create a meeting notes agent
```

---

## 📝 Daily Workflow Examples

### Morning Standup
```
Show me project status across all active projects
```

### Starting New Feature
```
I want to build [FEATURE]. Create the PRD and break it into tickets.
```

### Code Review
```
@code-reviewer Review this PR: [link or paste code]
```

### Documentation
```
Update documentation for the authentication system we just built
```

### Research
```
Research [TOPIC] and create a summary report
```

---

## 🔧 Customization Quick Wins

### 1. Set Your Preferences

**Edit `agents/MASTER_AGENT.md`:**

```markdown
## Owner Preferences

**Name**: [Your Name]
**Communication Style**: [direct/detailed/casual]
**Working Hours**: [timezone/availability]
**Decision Making**: [autonomous/ask-first/delegate]
```

### 2. Add Common Prompts

**Create `documentation/prompts/MY_COMMON_TASKS.md`:**

```markdown
# My Common Tasks

## Daily Standup Report
"Generate a daily standup report with: yesterday's completed tasks, 
today's planned tasks, and any blockers."

## Feature Request Processing
"When I describe a feature: 1) Ask clarifying questions, 
2) Create PRD, 3) Break into tickets, 4) Estimate effort"

## Code Review Checklist
"Review code for: 1) Security issues, 2) Performance, 
3) Best practices, 4) Test coverage"
```

### 3. Create Reusable Workflows

**Copy and customize from `workflows/templates/`:**

```bash
cp workflows/templates/feature-development.md workflows/my-feature-workflow.md
```

---

## 🐛 Troubleshooting

### "Agent not found"

**Solution:** Check if agent is registered
```
List all agents
```

### "Workflow not working"

**Solution:** Verify workflow file exists
```
Show me available workflows
```

### "Memory not persisting"

**Solution:** Ensure memory folder exists
```
Initialize memory system for [agent-name]
```

---

## 📚 Next Steps

1. **Read the full guide**: [agents/MASTER_AGENT.md](agents/MASTER_AGENT.md)
2. **Explore templates**: Check `agents/templates/` and `workflows/templates/`
3. **Join the community**: Share your customizations
4. **Contribute**: Improve templates for everyone

---

## 💡 Pro Tips

### Tip 1: Use @mentions for speed
```
@writer instead of "delegate to content writer agent"
```

### Tip 2: Batch similar tasks
```
@writer Create 5 social media posts about our product launch
```

### Tip 3: Leverage memory
```
Remember that I prefer concise summaries over detailed reports
```

### Tip 4: Chain agents
```
@researcher Research competitors → @writer Create comparison doc → @designer Suggest visuals
```

---

**You're all set!** 🎉  
Start with: `Initialize OpenFlo for my project`
