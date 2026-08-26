---
name: requesting-code-review
description: Use when a task is completed or about to be merged; fires the moment unreviewed work would cascade defects into the next task, before the agent proceeds, merges, or builds on top of it
type: sub-skill
---

# Requesting Code Review

## Snapshot

This skill dispatches a code reviewer subagent against a committed git range so defects are caught before they propagate into the next task, merge, or dependent change. The agent gathers a base/head SHA pair, hands a `general-purpose` subagent the dispatch template at `code-reviewer.md` plus a description and the plan/requirements, and acts on the returned report: fix Critical immediately, fix Important before proceeding, note Minor for later, push back with reasoning when the reviewer is wrong. The reviewer evaluates the work product only — never the session history — which preserves the agent's own context for continued work. Core principle: review early, review after each task. Parent skills (`subagent-driven-development`, `executing-plans`) invoke this skill at checkpoints; this skill is a sub-skill and publishes a composition interface below.

## Quick Reference

| Attribute | Value |
|---|---|
| Audience | Agents completing tasks, implementing features, or preparing a merge |
| Triggers | Task completed; major feature done; before merge to main; stuck; pre-refactor baseline; post-complex-bugfix |
| Inputs | BASE_SHA, HEAD_SHA, description of work, plan or requirements |
| Outputs | Review report: Strengths, Issues (Critical/Important/Minor), Recommendations, Assessment |
| Key files | `code-reviewer.md` — dispatch template the subagent fills |
| Parent skills | `subagent-driven-development`, `executing-plans` (invoke at checkpoints) |
| Sibling skill | `receiving-code-review` (acts on the returned feedback) |

*(projection — see Process for full rules)*

## Related Skills

| Sibling skill | Relationship | What this skill uses from it |
|---|---|---|
| `subagent-driven-development` | `upstream` | SDD invokes this skill at the end of each task for the whole-branch review. Translation: SDD passes the task framing and the per-task SHAs; this skill treats them as the BASE_SHA/HEAD_SHA contract and the description. |
| `executing-plans` | `upstream` | Invokes this skill at natural plan checkpoints. Translation: executing-plans hands the completed checkpoint's commit range and the plan section as requirements; this skill maps them to BASE_SHA/HEAD_SHA and PLAN_OR_REQUIREMENTS. |
| `verification-before-completion` | `shared-kernel` | Both enforce "evidence before a success claim." Shared terms: verify, evidence, claim. Flag both revision histories if either changes the definition of "verified." |
| `receiving-code-review` | `none` / `conformist` | This skill *requests*; that skill *receives* the same feedback shape. Adopt its severity vocabulary (Critical/Important/Minor) wholesale so the two compose without translation. |

## Document Metadata

| Field | Value |
|---|---|
| Document ID | `SKILL-RQCR-001` |
| Revision | 2 |
| Effective Date | 2026-07-20 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |
| Identity strategy | Descriptive name (stable); see `name` field |

## Audience

The writer states the following audience attributes before applying this skill:

- **Primary audience**: Any agent that completes tasks, implements features, or prepares a merge.
- **Secondary audience**: Maintainers who edit this skill; reviewers who audit subagent dispatches.
- **Expertise level**: Intermediate — the reader dispatches subagents already and needs the rules that make reviews catch real issues.
- **What they already know**: The reader can run git commands and dispatch a `general-purpose` subagent.
- **What they need to learn**: The context the reviewer needs, the dispatch template, and the triage rules for feedback.
- **What they will do after reading**: Dispatch a code reviewer subagent with the correct SHAs and act on the returned issues.

## Purpose / Scope

**Purpose**: This skill gives the rules the agent follows to dispatch a code reviewer subagent that catches issues before they cascade. The reviewer evaluates the work product, not the session history, which preserves the agent's own context for continued work.

**Scope covers**:

- When the agent requests a review.
- How the agent dispatches the code reviewer subagent.
- How the agent triages and acts on the returned feedback.
- How the skill integrates with subagent-driven development, executing plans, and ad-hoc work.

**Scope does NOT cover**:

- The internal prompts the reviewer subagent uses (see [code-reviewer.md](code-reviewer.md)).
- Authoring or revising implementation plans.
- Merging branches or resolving merge conflicts.

## Definitions

The writer defines every acronym and term on first use. This section collects them in one place for reference.

| Term | Meaning |
|---|---|
| SHA | Secure Hash Algorithm — here, the git commit identifier returned by `git rev-parse` |
| PR | Pull Request — a proposed merge of a branch into a target branch |
| BASE_SHA | The starting commit of the review range — the last reviewed or merged state |
| HEAD_SHA | The ending commit of the review range — the work product's tip |
| Review report | The structured artifact the subagent returns: Strengths, Issues, Recommendations, Assessment |

## Request the Review Early

I request code review to catch issues before they cascade into the next task or merge.

The agent dispatches a code reviewer subagent to catch issues before they cascade. The reviewer receives crafted context for evaluation, never the session history. This keeps the reviewer focused on the work product, not the agent's thought process, and preserves the agent's own context for continued work.

**Core principle:** Review early; review after each task.

**Cost/Benefit:** Invoke this skill whenever the cost of a defect propagating to the next task or a merge exceeds the cost of one subagent dispatch. Below that bar (a one-line typo fix with no dependents) → skip and rely on the next checkpoint's review.

## When to Request Review

**Mandatory** — each trigger below names a moment where unreviewed work would compound. Two distinct scenarios motivate every rule:

- **After each task in subagent-driven development.** Scenario 1: task N introduces a subtle API contract break that task N+1 then builds on, forcing a rework of two tasks. Scenario 2: a task's tests pass locally but miss an edge case that the reviewer surfaces before the next task assumes the interface is stable.
- **After the agent completes a major feature.** Scenario 1: the feature touches three modules and a cross-module inconsistency would only surface at merge. Scenario 2: the feature is large enough that the agent has lost sight of an earlier design decision the reviewer can re-check against.
- **Before the agent merges to main.** Scenario 1: main is shared; a defect here blocks every other agent. Scenario 2: merge is irreversible enough that a pre-merge review is cheaper than a revert.

**Optional but valuable:**

- When the agent is stuck (fresh perspective).
- Before the agent refactors (baseline check).
- After the agent fixes a complex bug.

## How to Request

### Gather the git SHAs

The agent captures the review range as a base/head pair so the reviewer diff is fully determined by two commits.

```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

### Dispatch the code reviewer subagent

The agent dispatches a `general-purpose` subagent and fills the dispatch template at [code-reviewer.md](code-reviewer.md). That file is the Repository entry for the reviewer prompt — it defines the subagent's role, what to check, calibration, output format, and critical rules. The agent passes the placeholders below; it does not inline the template's contents here.

**Placeholders:**

- `{DESCRIPTION}` — a brief summary of what the agent built.
- `{PLAN_OR_REQUIREMENTS}` — what the work should do.
- `{BASE_SHA}` — the starting commit.
- `{HEAD_SHA}` — the ending commit.

### Triage and act on the feedback

The agent sorts returned issues by severity and acts before it proceeds:

- Fix Critical issues immediately.
- Fix Important issues before the agent proceeds.
- Note Minor issues for later.
- Push back when the reviewer is wrong, with reasoning.

Triage of the returned feedback itself — verifying each item against the codebase before implementing it — is governed by the `receiving-code-review` skill. See that skill for the response pattern; this skill stops at "the report is in hand."

## Example

Given a completed task with a committed range, when the agent announces this skill, expect a dispatched reviewer and a triaged report.

Given/When/Expect:

- **Given** Task 2 ("Add verification function") just completed and committed, with Task 1's commit as the base.
- **When** the agent announces this skill and dispatches a `general-purpose` subagent with the SHAs, description, and plan reference.
- **Expect** a review report (Strengths / Issues / Assessment) that the agent triages before starting Task 3.

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code reviewer subagent]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: Task 2 from docs/superpowers/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```

## Integration with Workflows

**Subagent-Driven Development:**

- Review after each task.
- Catch issues before they compound.
- Fix before the agent moves to the next task.

**Executing Plans:**

- Review after each task or at natural checkpoints.
- Apply feedback, then continue.

**Ad-Hoc Development:**

- Review before the agent merges.
- Review when the agent is stuck.

## Public Interface for Composition

This skill is a sub-skill. Parent skills (`subagent-driven-development`, `executing-plans`) invoke it at the end of a task or at a plan checkpoint. The contract below is the only surface a parent may depend on; everything else in this file is implementation.

**What a parent may invoke:**

- The dispatch template at `code-reviewer.md` — a `general-purpose` subagent prompt with placeholders `{DESCRIPTION}`, `{PLAN_OR_REQUIREMENTS}`, `{BASE_SHA}`, `{HEAD_SHA}`.
- The BASE_SHA / HEAD_SHA contract — two git commit identifiers bounding the review range. The parent supplies them; this skill does not guess them.

**What a parent should pass in:**

- `BASE_SHA` / `HEAD_SHA` — the committed range to review.
- `DESCRIPTION` — what was built, in one or two lines.
- `PLAN_OR_REQUIREMENTS` — the plan file path or the requirement text the work is measured against.
- Working directory and task framing, so the subagent reads the right checkout.

**What a parent gets back:**

- A review report artifact with four sections: Strengths, Issues (Critical / Important / Minor), Recommendations, Assessment.
- The Assessment carries a merge verdict (Yes / No / With fixes) and 1-2 sentences of reasoning.

**What a parent must NOT assume:**

- That this skill merges the branch, resolves conflicts, or revises the plan — it does not. Those belong to other skills.
- That the subagent sees the parent's session history — it does not; everything must be passed in the dispatch prompt (cross-context boundary, [L13.1]).

## Red Flags

**Never:**

- Skip review because "it's simple."
- Ignore Critical issues.
- Proceed with unfixed Important issues.
- Argue with valid technical feedback.

**If the reviewer is wrong:**

- Push back with technical reasoning.
- Show code or tests that prove the work.
- Request clarification.

See the dispatch template at: [code-reviewer.md](code-reviewer.md)

## Deviations

No structural rules from the IDDD layer were broken in this revision. The dispatch template (`code-reviewer.md`) is inlined by reference rather than pasted into this file — this is the collection-oriented Repository default (L12.1/L12.2), not a deviation. If a future parent skill dispatches this skill into a subagent context that cannot read the filesystem, the template may need to be inlined there; that deviation would be recorded here with the "missing mechanism" reason ([L10.7]).

## Revision History

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-07-19 | Technical-writing compliance rewrite: added Document Metadata, Audience, Purpose/Scope, Definitions; active voice and lead sentences throughout; Revision History | Skills team | Skills maintainer |
| 2 | 2026-07-20 | IDDD layer: added Snapshot, Quick Reference (projection), Related Skills with typed relationships, Translation notes at upstream refs, Public Interface for Composition, Deviations note; rewrote `description` as a specific trigger naming the cascade failure mode; added announce line; renamed "Overview"→"Request the Review Early"; labeled quick-reference table as projection; converted the example to Given/When/Expect; added second motivating scenario to each mandatory When-to-Request rule; replaced inline template reference with path + one-line purpose; added Cost/Benefit line | Skills team | Skills maintainer |
| 3 | 2026-08-26 | IDDD typology sweep: added type frontmatter, reordered Related Skills by category per _shared/SKILL-ARCH.md | Skills maintainer | Skills maintainer |