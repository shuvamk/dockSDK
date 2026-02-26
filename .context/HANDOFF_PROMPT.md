# Session Handoff Prompt

Use this prompt at the end of every LLM coding session to ensure continuity.

---

## End-of-Session Instructions

Before ending this session, please update the `.context/` directory:

### 1. Update `CURRENT_STATE.md`

Re-read the file, then update every section to reflect the current state of the codebase after your changes. Specifically:

- Update **Current Status** table with any features added, changed, or broken
- Update **Known Issues & Tech Debt** with any new issues discovered or old ones resolved
- Update **In Progress / Next Steps** with what should happen next
- Update **Tech Stack** if any new dependencies were added
- Update **Architecture Summary** if the structure changed

### 2. Update `DECISIONS.md`

Add an entry for every architectural or significant technical decision made during this session, using the format:

```markdown
## YYYY-MM-DD: Decision Title

- **Context**: Why this decision was needed
- **Options considered**: What alternatives existed
- **Decision**: What was chosen
- **Tradeoffs**: What was gained and what was sacrificed
- **Affected areas**: Which parts of the codebase this impacts
```

### 3. Update `ARCHITECTURE.md`

If you changed the directory structure, added key files, changed data flow, or introduced new abstractions, update the relevant sections.

### 4. Update `CHANGELOG.md`

Add a new entry at the top:

```markdown
## YYYY-MM-DD — Brief Description of Changes

- Bullet point summary of what changed
- Include files added, modified, or deleted
- Note any breaking changes
```

### 5. Create a session log (optional but recommended)

Create a file at `.context/sessions/YYYY-MM-DD-brief-description.md` with:

```markdown
# Session: Brief Description

**Date**: YYYY-MM-DD
**Duration**: Approximate
**Goal**: What was the objective

## What was done
- Detailed list of changes

## Decisions made
- Reference decisions added to DECISIONS.md

## Issues encountered
- Any problems and how they were resolved

## Next session should
- Specific actionable items for the next session
```

### 6. Verify consistency

Re-read all `.context/` files and ensure they are consistent with each other and with the actual codebase. Fix any contradictions.
