---
name: writing-plans
description: Use when the writer has a spec or requirements for a multi-step task and has not yet produced a task-by-task plan — implementing a multi-step task without a plan produces inconsistent, unreviewable work that an engineer cannot execute first-time-right
---

# Writing Plans

## Snapshot

This skill turns a design spec or requirements list into a complete, placeholder-free implementation plan an engineer with zero codebase context executes first-time-right. The writer maps the file structure, decomposes the work into bite-sized TDD tasks (each with its own RED/GREEN/commit cycle), and writes every step as concrete code, exact paths, and exact commands — no "TBD," no "add appropriate error handling." The plan is saved to `docs/superpowers/plans/YYYY-MM-DD-<feature>.md`, self-reviewed against the spec, then handed off to `subagent-driven-development` (recommended) or `executing-plans` for task-by-task execution. An agent reading only this snapshot can announce the skill and begin drafting the plan header.

## Document Metadata

| Field | Value |
|---|---|
| Document ID | `SKILL-WP-001` |
| Revision | 2 |
| Effective Date | 2026-07-20 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |

## Quick Reference (projection — see Process for full rules)

| Aspect | Value |
|---|---|
| Audience | Agent or engineer writing an implementation plan from a spec |
| Triggers | A spec or requirements for a multi-step task exists; no plan yet |
| Inputs | Design spec (from `brainstorming`); zero-codebase-context engineer assumption |
| Outputs | Saved plan file at `docs/superpowers/plans/YYYY-MM-DD-<feature>.md` |
| Key files touched | The plan file only (the codebase is touched by executors) |
| Required sub-skills (execution) | `subagent-driven-development` (recommended), `executing-plans` (alternative) |
| Shared kernel | TDD/RED/GREEN vocabulary co-maintained with `test-driven-development` |

## Related Skills

| Sibling | Relationship | What crosses the boundary |
|---|---|---|
| `brainstorming` | upstream | brainstorming produces a design spec; this skill consumes it as the input requirements |
| `subagent-driven-development` | downstream | this skill produces a task-by-task plan file; SDD consumes it as the execution script |
| `executing-plans` | downstream | alternative executor; consumes the same plan file as an inline batch script |
| `test-driven-development` | shared-kernel | plans use TDD steps; co-maintain TDD/RED/GREEN vocabulary |

**Translation notes:**

- From `brainstorming` (upstream): the design spec arrives as a Markdown document with Goal, Architecture, and requirements. This skill treats each spec requirement as a unit of work to be covered by at least one task; it does not re-derive the design, only decompose it.
- To `subagent-driven-development` (downstream): this skill emits a plan file whose task blocks are the command objects SDD dispatches — each task's Files/Interfaces/Steps is the brief; SDD does not re-plan, only execute.
- To `executing-plans` (downstream): the same plan file is consumed as an inline checklist with `- [ ]` tracking; no format conversion is required.
- With `test-driven-development` (shared-kernel): the terms RED ("write the failing test"), GREEN ("make it pass"), and TDD cycle are used identically in both skills; a change to that vocabulary here must be flagged in both revision histories.

## Audience

The writer states the following audience attributes before drafting any plan this skill governs:

- **Primary audience**: Any agent or engineer who writes an implementation plan from a spec or requirements.
- **Secondary audience**: Engineers who execute the plan; reviewers who audit the plan before execution.
- **Expertise level**: Intermediate — the writer can code already and needs the rules that make a plan survive execution.
- **What they already know**: The writer can read a spec and write Markdown.
- **What they need to learn**: The plan structure, task granularity, and style rules that turn a spec into a plan an engineer executes first-time-right.
- **What they will do after reading**: Apply this skill to produce a complete, placeholder-free implementation plan and hand it off for execution.

## Purpose / Scope

**Purpose**: This skill gives the rules a writer follows to produce an implementation plan that an engineer with zero codebase context executes first-time-right.

**Scope covers**:

- Plan structure: header, global constraints, task structure, file mapping.
- Task granularity: bite-sized steps with their own test cycles.
- Style rules for plan prose: active voice, exact paths, complete code, no placeholders.
- Execution handoff to the implementing sub-skills.

**Scope does NOT cover**:

- Brainstorming the spec (governed by the `brainstorming` skill).
- Executing the plan (governed by the `executing-plans` and `subagent-driven-development` skills).
- Code conventions inside the plan's code blocks.
- Regulated-document controls (deviations, RCA, CAPA).

## Definitions

The writer defines these acronyms on first use:

| Term | Meaning |
|---|---|
| TDD | Test-Driven Development |
| DRY | Don't Repeat Yourself |
| YAGNI | You Aren't Gonna Need It |
| RED | The "write the failing test and watch it fail" step of a TDD cycle |
| GREEN | The "write minimal code to make the test pass" step of a TDD cycle |
| Plan | The Markdown document this skill produces; its identity is its path |

## Overview

Write the plan.

Assume the engineer is a skilled developer who knows almost nothing about our toolset or problem domain. Assume the engineer does not know good test design. Document everything the engineer needs: which files to touch per task, the code, the tests, the docs to check, how to test each piece. Give the engineer the whole plan as bite-sized tasks. Apply DRY, YAGNI, and TDD. Commit frequently.

**Announce at start:** "I'm using the writing-plans skill to write the implementation plan."

**Context:** The writer creates any isolated worktree via the `using-git-worktrees` skill at execution time.

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`. The writer honors these overrides:

- User preferences for plan location override this default.

## Scope Check

If the spec covers multiple independent subsystems, the writer should have broken it into sub-project specs during `brainstorming`. If the writer did not, the writer suggests breaking this into separate plans — one per subsystem. Each plan produces working, testable software on its own.

## File Structure

Before defining tasks, the writer maps out which files the plan creates or modifies and what each one is responsible for. The writer locks decomposition decisions in here.

The writer follows these principles when mapping the file structure:

- Design units with clear boundaries and well-defined interfaces; give each file one clear responsibility.
- Prefer smaller, focused files over large ones that do too much; the writer reasons best about code held in context at once, and edits land more reliably when files stay focused.
- Group files that change together; split by responsibility, not by technical layer.
- Follow established patterns in existing codebases; do not unilaterally restructure large-file codebases — but if a file the writer modifies has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task produces self-contained changes that make sense independently.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and earns a fresh reviewer's gate. When drawing task boundaries, fold setup and configuration steps into the task whose deliverable needs them. Fold scaffolding and documentation steps in the same way. Split only where a reviewer could meaningfully reject one task while approving its neighbor. Each task ends with an independently testable deliverable.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**

- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Remember

The writer keeps these invariants throughout the plan:

- Exact file paths always
- Complete code in every step — if a step changes code, show the code
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Public Interface for Composition

This skill is composed by `brainstorming` (brainstorming hands off to writing-plans once the design spec is settled). A parent skill may invoke and inspect only the following surface; everything else in this file is private implementation.

**A parent may invoke:**
- The announce line: "I'm using the writing-plans skill to write the implementation plan."
- The Plan Document Header template (above) — the parent may pre-fill Goal/Architecture/Tech Stack from the spec it produced.
- The Task Structure template (above) — the parent may pass the spec's requirements list as the seed for task decomposition.
- The Self-Review checklist (above) — the parent may request the writer run it and report gaps.

**A parent may expect back:**
- A saved plan file at `docs/superpowers/plans/YYYY-MM-DD-<feature>.md`, containing the header, global constraints, and one task block per unit of work.
- A one-line handoff message naming the saved path and the two execution options (see Execution Handoff).

**A parent must NOT expect:**
- Re-derivation of the design (that is `brainstorming`'s job).
- Execution of the plan (that is `subagent-driven-development` / `executing-plans`'s job).
- The plan prose to duplicate this skill's Process — the plan is the artifact, not a restatement of the skill.

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using `executing-plans`, batch execution with checkpoints

**Which approach?"**

**If the writer chooses Subagent-Driven:**

- **REQUIRED SUB-SKILL:** Use `subagent-driven-development`
- Fresh subagent per task + two-stage review

**If the writer chooses Inline Execution:**

- **REQUIRED SUB-SKILL:** Use `executing-plans`
- Batch execution with checkpoints for review

## Deviations

None. No structural rule from the IDDD layer was broken for this skill. If a future revision breaks one (e.g., inlines a sibling's prose because a subagent cannot read the filesystem), the author must record it here with the reason.

## Revision History

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-07-19 | Self-compliance rewrite: added Document Metadata, Audience, Purpose/Scope, Definitions, and Revision History; applied active voice, lead sentences, and parallel lists throughout | Skills team | Skills maintainer |
| 2 | 2026-07-20 | IDDD-layer rewrite: added Snapshot, Quick Reference (labeled projection), Related Skills with typed relationships + Translation notes, Public Interface for Composition, Deviations note; refactored description to name the failure mode; renamed announce verb to match the skill name; added RED/GREEN/Plan to Definitions; replaced sibling-skill prose with `name` references. Preserved all code blocks, the Plan Document Header and Task Structure templates, the file path references, and the technical-writing layer. | Skills team | Skills maintainer |