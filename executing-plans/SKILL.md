---
name: executing-plans
description: Use when a written implementation plan must be executed in a separate session with review checkpoints — prevents the failure mode where executing the plan in the main session pollutes the orchestrator's context with task-by-task detail and loses track of which tasks are confirmed complete
type: orchestrator
---

# Executing Plans

## Snapshot

This skill governs the in-session execution of a written implementation plan, task by task, with review checkpoints. The writer loads the plan, reviews it critically, executes each task in order, runs the verifications the plan specifies, and stops to ask the human partner on any blocker. It is the single-session counterpart to `subagent-driven-development`: same plan-consumption contract, no subagent dispatch.

Use it when the platform has no subagent support, or when the plan is small enough that one context can hold it without polluting the orchestrator. Do not use it to write the plan, to create the workspace, or to finish the branch — those are sibling skills referenced below.

The skill is a saga: it tracks each task's status (pending / in_progress / confirmed / blocked) in a workflow ledger and escalates to the human partner on timeout or repeated verification failure. On completion it hands off to `finishing-a-development-branch`. Announcing it twice in one session is a no-op unless the plan changed.

## Quick Reference

*(projection — see Process for full rules)*

| Field | Value |
|---|---|
| Audience | Agent executing a written plan in a separate session |
| Trigger | A written plan file exists and must be executed now |
| Inputs | Plan file path; isolated workspace (from `using-git-worktrees`) |
| Outputs | Completed tasks, verification results, workflow ledger |
| Key artifact | Workflow ledger (task status, escalations) |
| Handoff | To `finishing-a-development-branch` on completion |
| Stop conditions | Blocker, critical gap, unclear instruction, repeated verification failure |

## Related Skills

| Skill | Relationship | Notes |
|---|---|---|
| `writing-plans` | `upstream` | Produces the plan file this skill executes. |
| `using-git-worktrees` | `upstream` | Ensures an isolated workspace before execution begins. |
| `finishing-a-development-branch` | `downstream` | Consumed at the natural completion checkpoint. |
| `requesting-code-review` | `downstream` | Consumed at review checkpoints the plan designates. |
| `subagent-driven-development` | `none` (alternative) | Same plan-consumption contract, but dispatches subagents per task. |

**Choice criterion — `executing-plans` vs `subagent-driven-development`:** Use `subagent-driven-development` when the platform supports subagents and the plan's tasks are independent enough to parallelize; it keeps the orchestrator's context clean. Use `executing-plans` when subagents are unavailable, when tasks must run strictly sequentially in one context, or when the plan is small enough that in-session execution does not pollute the orchestrator. The two are `none` (alternatives), not `upstream`/`downstream` of each other — pick one per run, do not chain.

**Translation notes (ACL):**

- *From `writing-plans` (`upstream`):* writing-plans produces a task-by-task plan file (Markdown, ordered tasks, each with steps and verifications). This skill consumes that file as the execution script — it does not re-author or re-order tasks. The plan's task list is the source of truth; this skill only tracks status against it.
- *From `using-git-worktrees` (`upstream`):* using-git-worktrees produces an isolated workspace (a worktree path or confirmation one exists). This skill consumes that path as its working directory and does not create or switch worktrees itself.

## Document Metadata

| Field | Value |
|---|---|
| Document ID | `SKILL-EP-001` |
| Revision | 2 |
| Effective Date | 2026-07-19 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |
| Identity strategy | descriptive-name, stable (see `name` field; do not rename) |

## Definitions

| Term | Meaning (in this skill only) |
|---|---|
| Plan | The written implementation plan file produced by `writing-plans`; a task-by-task script. |
| Task | One unit of work inside the plan, with its own steps and verifications. |
| Workflow ledger | The status tracker for this run: per-task status plus escalation notes. |
| Review checkpoint | A point in the plan (or after a task) where the writer stops for human or code review. |
| Blocker | A condition that prevents continuing: missing dependency, failed verification, unclear instruction. |
| Confirmation | A task marked completed after its verifications pass. |

## Audience

The writer states the following audience attributes before executing any plan this skill governs:

- **Primary audience**: Any agent that executes a written implementation plan in a separate session.
- **Secondary audience**: Maintainers who edit this skill; human partners who review the agent's output.
- **Expertise level**: Intermediate — the reader can run an implementation plan already and needs the rules that keep execution reviewable and recoverable.
- **What they already know**: The reader can read a plan file, create todos, and run verifications.
- **What they need to learn**: The three-step process, the stop-and-ask rules, and the handoff to the finishing skill.
- **What they will do after reading**: Load the plan, review it critically, execute all tasks, and report completion.

## Purpose / Scope

**Purpose**: This skill tells the writer how to execute a written implementation plan in a separate session so the work stays reviewable and recoverable, and so no task is silently dropped.

**Scope covers**:
- Loading and critically reviewing a written plan.
- Executing each plan task in order with verifications.
- Stopping and asking the human partner when the writer hits a blocker.
- Maintaining a workflow ledger of task status and escalations.
- Handing off to the finishing-a-development-branch skill on completion.

**Scope does NOT cover**:
- Writing the plan itself (governed by `writing-plans`).
- Creating the isolated workspace (governed by `using-git-worktrees`).
- Subagent-driven execution (governed by `subagent-driven-development`).
- Finishing the branch after execution (governed by `finishing-a-development-branch`).

## Idempotency

If this skill is announced twice in one session against the same plan file, the second announcement is a no-op unless the plan file changed. The writer does not re-execute confirmed tasks; it re-reads the ledger and resumes from the first non-confirmed task. A deliberate re-entry with a new or revised plan is a fresh run, not a duplicate.

## The Process

### Step 1: Load and Review the Plan

The writer performs the following actions to load and review the plan:

1. Read the plan file.
2. Review the plan critically and identify any questions or concerns.
3. If the writer finds concerns, raise them with the human partner before starting.
4. If the writer finds no concerns, create todos for the plan items and proceed.

### Step 2: Execute Each Task in Order

The writer performs the following actions for each task:

1. Mark the task as `in_progress` in the workflow ledger.
2. Follow each step exactly as written in the plan.
3. Run the verifications the plan specifies.
4. On verification pass, mark the task as `confirmed` in the ledger.
5. On verification failure, follow the stop-and-ask rules below (do not silently retry past the threshold).

### Step 3: Complete Development and Hand Off

The writer performs the following actions after all tasks are `confirmed`:

- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use `finishing-a-development-branch`.
- Follow that skill to verify tests, present options, and execute the chosen option.

## Workflow Ledger

This skill is a saga: it tracks each task's status across the run so no task is silently dropped. The writer maintains a ledger (in the session, or in a file the orchestrator reads and writes) with the following shape:

| Task | Status | Notes / Escalation |
|---|---|---|
| _(task id from plan)_ | `pending` / `in_progress` / `confirmed` / `blocked` | _(verification result, blocker, or escalation)_ |

**Escalation path:**
- A task `blocked` for longer than one stop-and-ask cycle is escalated to the human partner with the blocker stated in the ledger.
- If the human partner does not respond within the session, the writer leaves the task `blocked`, records the escalation, and does not proceed past it (sequential execution contract).
- On session resumption, the writer re-reads the ledger and resumes from the first non-`confirmed` task.

**Retry policy:** Re-run a failed verification once after a targeted fix. A second failure is a `blocked` task — do not loop silently.

## When to Stop and Ask for Help

The writer stops execution at once when any of these conditions occur:

- The writer hits a blocker (missing dependency, test fails, instruction unclear).
- The plan has critical gaps that prevent starting.
- The writer does not understand an instruction.
- Verification fails repeatedly (after the single retry above).

The writer asks for clarification rather than guessing. Two distinct scenarios motivate this rule: (1) a missing dependency that the writer cannot install without partner consent, and (2) an instruction that two reasonable readings of the plan would satisfy differently — in both, guessing produces unreviewable work.

## When to Revisit Earlier Steps

The writer returns to Step 1 (Load and Review the Plan) when any of these conditions occur:

- The partner updates the plan based on the writer's feedback.
- The fundamental approach needs rethinking.

The writer does not force through blockers; the writer stops and asks. Two scenarios motivate this: (1) mid-execution the partner revises a task in a way that invalidates downstream tasks, and (2) a verification failure reveals the plan's approach is wrong for the codebase — in both, continuing would compound the error.

## Remember

The writer follows these rules throughout execution:

- Review the plan critically first.
- Follow the plan steps exactly.
- Do not skip verifications.
- Reference skills when the plan says to — invoke them by `name`, do not re-implement their Process.
- Stop when blocked; do not guess.
- Never start implementation on main/master branch without explicit user consent.

## Examples

### Example 1 — Clean run (Given/When/Expect)

**Given** a plan file at `docs/plans/2026-07-19-add-login.md` with three tasks, each with steps and a verification command, in an isolated worktree.
**When** the writer announces "I'm using the executing-plans skill to implement this plan," loads the plan, finds no concerns, creates todos, executes each task in order, runs each verification, and all pass.
**Expect** the ledger shows all three tasks `confirmed`; the writer announces `finishing-a-development-branch` and hands off. No human partner intervention was required.

### Example 2 — Blocker escalates

**Given** a plan with a task whose verification is `npm test`, and the test suite fails on a pre-existing breakage unrelated to the task's changes.
**When** the writer runs the verification, it fails; the writer attempts one targeted fix; the second run also fails.
**Expect** the writer marks the task `blocked` in the ledger, states the blocker to the human partner, and stops — it does not mark the task `confirmed` and does not proceed to the next task.

### Example 3 — Plan revised mid-run

**Given** a plan being executed, the human partner edits task 2 to change the approach after seeing the writer's feedback on task 1.
**When** the writer is notified of the revision.
**Expect** the writer returns to Step 1, re-reads the revised plan, re-confirms or re-raises concerns, and resumes from the first non-`confirmed` task.

## Integration

The writer uses the following required workflow skills, each invoked by `name`:

- **`using-git-worktrees`** — ensures an isolated workspace (creates one or verifies an existing one). *Translation:* it supplies the worktree path; this skill consumes it as the working directory.
- **`writing-plans`** — creates the plan this skill executes. *Translation:* it supplies the plan file; this skill consumes it as the execution script and does not re-author it.
- **`finishing-a-development-branch`** — completes development after all tasks finish. *Translation:* this skill hands off the confirmed ledger; the finishing skill takes the branch from there.

See each skill's own SKILL.md for its protocol — do not restate it here.

## Deviations

- **Workflow ledger as a section, not a separate file.** Per L13.6 the ledger may be a file the orchestrator reads and writes; this skill permits an in-session ledger when the run is single-session and no cross-session resumption is expected. Reason: query/load convenience (the agent has the ledger in context already); if the run may span sessions, write the ledger to a file. [L10.7 — query performance / load convenience]

## Revision History

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-07-19 | Technical-writing compliance rewrite: added Document Metadata, Audience, Purpose/Scope (with "does NOT cover"), active voice throughout, lead sentences on all lists, Revision History | Skills maintainer | Skills maintainer |
| 2 | 2026-07-19 | IDDD layer: added Snapshot, Quick Reference (projection), Related Skills with typed relationships + Translation notes, Idempotency line, Workflow ledger subsection, Definitions, Examples in Given/When/Expect, Deviations note; rewrote `description` as specific trigger naming failure mode; renamed Process headings to work-speak; added ≥2 scenarios per stop-and-ask rule; replaced sibling-skill prose with `name` references | Skills maintainer | Skills maintainer |
| 3 | 2026-08-26 | IDDD typology sweep: added type frontmatter, reordered Related Skills by category per _shared/SKILL-ARCH.md | Skills maintainer | Skills maintainer |