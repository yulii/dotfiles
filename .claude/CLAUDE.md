# Global Coding Rules

## Startup Summary
- **MANDATORY**: Upon receiving the FIRST user message, immediately:
  1. Search and read all CLAUDE.md files (`find . -name "CLAUDE.md" -path "*/.claude/*" | sort`)
  2. Display concise summary of all active rules **BEFORE any other response**
  3. THEN respond to the user's actual request
- **EVERY SESSION**: This happens automatically on first message only
- **NO EXCEPTIONS**: This rule must be executed 100% of the time
- **TECHNICAL REALITY**: Cannot send messages before user input

## Security
- Never commit sensitive information such as API keys, passwords, or tokens
- Files like `.env`, `credentials`, and `secrets` must be excluded from commits
- If accidentally committed, must be completely removed from history

## Implementation Rules
- **MANDATORY**: Always present implementation plan to user BEFORE making any changes
- **CONFIRM FIRST**: Explain what will be done and ask for user approval before proceeding
- **NO AUTOMATIC CHANGES**: Do not modify, create, or delete any files without user approval
- **PROACTIVE PLANNING**: Analyze requirements, create task list, and present approach for user review

## Git Branch Strategy
- **Never commit directly to default branches (main/master/develop)**
- Always create a feature branch before starting work
- Apply this rule even for personal projects

## GitHub Operations
- **Always use `gh` command when referencing GitHub Issues or PRs**
- Do not access GitHub URLs with WebFetch

## Pre-work Checklist
1. **Locate all rule files**: Run `find . -name "CLAUDE.md" -path "*/.claude/*" | sort`
2. **Read in order**: From current directory up to home directory
3. **Apply rules**: When conflicts occur, project rules override global rules

---

## CLAUDE File Update Guidelines

**RULE**: CLAUDE.md edits MUST start with checklist results (✅/❌) as FIRST output

**CHECKLIST**:
- Clarity: Are all instructions unambiguous?
- Conciseness: Is there any redundant content to remove?
- Order: Are sections arranged by importance?
- Review: Does the entire file maintain coherence?

**NO EXCEPTIONS**: All edits require checklist first

## Important Reminders
- Do what has been asked; nothing more, nothing less
- NEVER create files unless they're absolutely necessary for achieving your goal
- ALWAYS prefer editing an existing file to creating a new one
- NEVER proactively create documentation files (*.md) or README files unless explicitly requested