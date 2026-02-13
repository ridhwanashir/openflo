# OpenFlo AI Agent Workflow System

> **A reusable, template-based AI Agent orchestration framework.**  
> Fork this repo, open in GitHub Copilot, give instructions, and your workflows are ready.

---

## 🚀 Quick Start (30 Seconds)

```bash
# 1. Clone/fork this template
git clone https://github.com/yourusername/openflo.git my-project
cd my-project

# 2. Open in VS Code + GitHub Copilot

# 3. Tell Copilot:
"Initialize OpenFlo for my [project-name] project"

# 4. Done! Start creating agents and workflows.
```

---

## 📋 What is OpenFlo?

OpenFlo is a **template-based AI Agent orchestration system** designed to be:

- **🍴 Forkable**: Copy and customize for any project
- **🤖 Copilot-Native**: Designed to work with GitHub Copilot/Claude/Cursor
- **📦 Ready-to-Use**: Pre-built templates, just fill in the blanks
- **🔄 Reusable**: Same structure works for any domain (software, business, creative)
- **📚 Self-Documenting**: Agents learn and improve automatically

---

## 🏗️ System Architecture

```
openflo/
├── 📁 agents/                    # AI Agent configurations
│   ├── 📄 MASTER_AGENT.md        # Central orchestrator (EDIT THIS FIRST)
│   ├── 📁 specialized/           # Your custom agents go here
│   └── 📁 templates/             # Agent creation templates
│
├── 📁 projects/                  # Project tracking
│   ├── 📄 PROJECT_TRACKER.md     # All projects status
│   └── 📁 [your-project]/        # Project-specific docs
│
├── 📁 workflows/                 # Reusable workflows
│   ├── 📄 WORKFLOW_GUIDE.md      # How to create workflows
│   └── 📁 templates/             # Ready-to-use workflow templates
│
├── 📁 memory/                    # Persistent context storage
│   ├── 📁 master/                # Master agent memory
│   └── 📁 specialized/           # Per-agent memory
│
├── 📁 documentation/             # Knowledge base
│   └── 📁 prompts/               # Reusable AI prompts
│
├── 📄 README.md                  # This file
├── 📄 QUICK_START.md             # 5-minute setup guide
└── 📄 COPILOT_INSTRUCTIONS.md    # Copilot-specific commands
```

---

## 🎯 Use Cases

| Use Case | What You Get |
|----------|--------------|
| **Software Development** | Project managers, ticket writers, code reviewers |
| **Content Creation** | Writers, editors, SEO specialists |
| **Business Operations** | Process automation, reporting, data analysis |
| **Product Management** | PRD writers, user story creators, roadmap planners |
| **Consulting** | Client onboarding, deliverable trackers, report generators |
| **Personal Productivity** | Task managers, meeting notes, goal trackers |

---

## 🛠️ Setup Instructions

### Step 1: Initialize the System

Open GitHub Copilot Chat and type:

```
Initialize OpenFlo for my project. My project is called "[PROJECT_NAME]" 
and it's about [BRIEF_DESCRIPTION].
```

**Copilot will:**
- Configure the Master Agent with your project details
- Create your first specialized agent
- Set up project tracking
- Initialize memory systems

### Step 2: Create Your First Agent

```
Create a new specialized agent for [TASK_TYPE]. 
This agent should handle [SPECIFIC_RESPONSIBILITIES].
```

**Example:**
```
Create a new specialized agent for content writing.
This agent should handle blog posts, social media content, and email newsletters.
```

### Step 3: Start Working

```
@content-writer Create a blog post about AI automation
```

---

## 📖 Copilot Commands Reference

### System Commands

| Command | What It Does |
|---------|--------------|
| `Initialize OpenFlo` | Set up the system for your project |
| `Create agent for [task]` | Create a new specialized agent |
| `List all agents` | Show all available agents |
| `Show project status` | Display current project status |
| `Update documentation` | Sync all docs with latest changes |

### Agent Commands

| Command | What It Does |
|---------|--------------|
| `@[agent-name] [task]` | Assign task to specific agent |
| `Create workflow for [process]` | Generate new workflow template |
| `Store in memory: [info]` | Save information for future reference |
| `What do we know about [topic]?` | Retrieve from memory |

---

## 🎨 Customization

### Edit These Files First:

1. **`agents/MASTER_AGENT.md`** - Set your name, preferences, working style
2. **`config/preferences.json`** - System-wide settings
3. **`documentation/prompts/DEFAULT_PROMPT.md`** - Your default AI behavior

### Add Your Own:

- **Agents**: Copy `agents/templates/AGENT_TEMPLATE.md` to `agents/specialized/`
- **Workflows**: Copy `workflows/templates/` and customize
- **Prompts**: Add to `documentation/prompts/`

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [QUICK_START.md](QUICK_START.md) | 5-minute setup walkthrough |
| [COPILOT_INSTRUCTIONS.md](COPILOT_INSTRUCTIONS.md) | Copilot-specific commands |
| [agents/MASTER_AGENT.md](agents/MASTER_AGENT.md) | Master agent configuration |
| [workflows/WORKFLOW_GUIDE.md](workflows/WORKFLOW_GUIDE.md) | Creating custom workflows |

---

## 🔌 Integrations (Optional)

OpenFlo supports these integrations via MCP (Model Context Protocol):

- **🌐 Browser Automation** - Web scraping, form filling
- **💻 System Commands** - File operations, shell commands
- **📧 Email** - Send/receive emails
- **📅 Calendar** - Schedule management
- **🎫 Jira/Linear** - Ticket management
- **📝 Notion** - Document syncing
- **💬 Slack/Discord** - Team notifications

**To enable:** Edit `config/mcp-config.json` with your API keys.

---

## 🧪 Example: Content Agency Setup

```bash
# 1. Fork openflo
git clone https://github.com/you/openflo.git my-agency
cd my-agency

# 2. In Copilot Chat:
"Initialize OpenFlo for my content agency. 
 We create blog posts, social media, and email campaigns for clients."

# 3. Copilot creates:
#    - Content Strategist Agent
#    - Blog Writer Agent
#    - Social Media Agent
#    - Client Project Tracker

# 4. Start working:
"@blog-writer Create a 1500-word article about AI in healthcare"
```

---

## 📊 Project Status

**Template Version**: 1.0  
**Last Updated**: 2026-02-13  
**Status**: ✅ Production Ready  
**Maintained By**: Community

---

## 🤝 Contributing

1. Fork this template
2. Customize for your use case
3. Share your improvements back
4. Help others get started

---

## 📄 License

MIT License - Feel free to use, modify, and distribute.

---

**Ready to start?** → Open [QUICK_START.md](QUICK_START.md) or type `Initialize OpenFlo` in Copilot Chat.
