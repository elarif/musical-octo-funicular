# Skill Type Schemas — Technique, Pattern, Reference

**Effective date:** 2026-08-25
**Owner:** writing-skills
**Parent skill:** `writing-skills` (body holds 10-line summary; this file holds the full rules).

## Skill Types

### Technique

Concrete method with steps to follow (condition-based-waiting, root-cause-tracing).

### Pattern

Way of thinking about problems (flatten-with-flags, test-invariants).

### Reference

API docs, syntax guides, tool documentation (office docs).

## Directory Structure

```
skills/
  skill-name/
    SKILL.md              # Main reference (required)
    supporting-file.*     # Only if needed
```

**Flat namespace** — all skills live in one searchable namespace.

**Separate files for:**

1. **Heavy reference** (100+ lines) — API docs, comprehensive syntax
2. **Reusable tools** — Scripts, utilities, templates

**Keep inline:**

- Principles and concepts
- Code patterns (< 50 lines)
- Everything else

## SKILL.md Structure

**Frontmatter (YAML):**

- Two required fields: `name` and `description` (see [agentskills.io/specification](https://agentskills.io/specification) for all supported fields)
- Max 1024 characters total
- `name`: Use letters, numbers, and hyphens only (no parentheses, special chars)
- `description`: Third-person, describes ONLY when to use (NOT what it does)
- Start with "Use when..." to focus on triggering conditions
- Include specific symptoms, situations, and contexts
- **NEVER summarize the skill's process or workflow** (see SDO section for why)
- Keep under 500 characters if possible

```markdown
---
name: Skill-Name-With-Hyphens
description: Use when [specific triggering conditions and symptoms]
---

# Skill Name

## Overview
What is this? Core principle in 1-2 sentences.

## When to Use
[Small inline flowchart IF decision non-obvious]

Bullet list with SYMPTOMS and use cases
When NOT to use

## Core Pattern (for techniques/patterns)
Before/after code comparison

## Quick Reference
Table or bullets for scanning common operations

## Implementation
Inline code for simple patterns
Link to file for heavy reference or reusable tools

## Common Mistakes
What goes wrong + fixes

## Real-World Impact (optional)
Concrete results
```

---

## Modification

Modifications à ce fichier nécessitent flag Revision History de `writing-skills`.
