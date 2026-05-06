# Workflow: Feature Development

> Complete workflow for developing a new feature from idea to deployment

---

## Purpose

Transform a feature idea into a deployed, tested feature in production.

---

## Trigger

- New feature request received
- Product roadmap item prioritized
- Stakeholder asks for new capability

---

## Participants

- **Product Manager** (or Master Agent): Overall coordination
- **PRD Writer**: Creates product requirements
- **Tech Lead**: Technical design and architecture
- **Ticket Writer**: Breaks work into tickets
- **Developers**: Implementation
- **QA/Tester**: Testing and validation
- **Code Reviewer**: Code quality review

---

## Steps

### Step 1: Request Intake
**Who**: Master Agent  
**What**: 
- Receive feature request
- Ask clarifying questions
- Identify stakeholders and constraints
- Determine priority

**Output**: Clarified feature request with context

**Next**: Proceed to PRD creation

---

### Step 2: Create PRD
**Who**: @prd-writer  
**What**:
- Write Product Requirements Document
- Define user stories
- Specify acceptance criteria
- Include UI/UX requirements
- Document technical constraints

**Output**: Complete PRD document in `/projects/[name]/specs/`

**Next**: Owner reviews PRD

---

### Step 3: PRD Review
**Who**: Owner/Stakeholders  
**What**:
- Review PRD for completeness
- Approve or request changes
- Confirm scope and timeline

**Output**: Approved PRD

**Next**: Technical design

---

### Step 4: Technical Design
**Who**: @tech-lead  
**What**:
- Design system architecture
- Define API contracts
- Plan database changes
- Identify dependencies
- Estimate effort

**Output**: Technical design document

**Next**: Ticket creation

---

### Step 5: Create Tickets
**Who**: @ticket-writer  
**What**:
- Break PRD into implementable tickets
- Write ticket descriptions
- Add acceptance criteria
- Estimate story points
- Link related tickets

**Output**: Tickets created in project management tool

**Next**: Sprint planning/assignment

---

### Step 6: Development
**Who**: Developers  
**What**:
- Implement features per tickets
- Write unit tests
- Update documentation
- Commit code

**Output**: Implemented code in repository

**Next**: Code review

---

### Step 7: Code Review
**Who**: @code-reviewer  
**What**:
- Review code for quality
- Check for security issues
- Verify test coverage
- Approve or request changes

**Output**: Approved pull request

**Next**: Testing

---

### Step 8: Testing
**Who**: QA/Tester  
**What**:
- Run automated tests
- Perform manual testing
- Verify acceptance criteria
- Report bugs if found

**Output**: Tested, verified feature

**Next**: Deployment

---

### Step 9: Deployment
**Who**: DevOps/Developer  
**What**:
- Deploy to staging
- Run smoke tests
- Deploy to production
- Monitor for issues

**Output**: Feature live in production

**Next**: Documentation update

---

### Step 10: Documentation Update
**Who**: @documentation-manager  
**What**:
- Update user documentation
- Update technical documentation
- Update API docs if needed
- Announce feature release

**Output**: Updated documentation

---

## Success Criteria

- [ ] PRD approved by stakeholders
- [ ] Technical design reviewed
- [ ] All tickets completed
- [ ] Code reviewed and approved
- [ ] Tests passing
- [ ] Feature deployed to production
- [ ] Documentation updated
- [ ] Stakeholders notified

---

## Common Variations

### Hotfix Workflow
- Skip PRD, go straight to fix
- Fast-track code review
- Deploy immediately after tests pass

### Spike/Research Workflow
- Steps 1-4 only
- Output is research findings, not implementation
- Decision point before full development

### MVP Workflow
- Simplified PRD
- Minimal technical design
- Focus on core functionality only
- Iterate after initial release

---

## Troubleshooting

### "PRD keeps changing"
**Solution**: Lock PRD after approval; changes require new version/tickets

### "Tickets are too vague"
**Solution**: Include technical design details in ticket creation step

### "Code review takes too long"
**Solution**: Set SLA (e.g., 24 hours); consider pair programming

### "Testing finds issues late"
**Solution**: Add test planning step after technical design

---

## Time Estimates

| Step | Typical Duration |
|------|------------------|
| Request Intake | 1-2 hours |
| PRD Creation | 2-4 hours |
| PRD Review | 1-2 days |
| Technical Design | 2-4 hours |
| Ticket Creation | 1-2 hours |
| Development | Varies by feature |
| Code Review | 2-4 hours |
| Testing | 1-2 days |
| Deployment | 1-2 hours |
| Documentation | 2-4 hours |

---

**Template Version**: 1.0  
**Last Updated**: [DATE]
