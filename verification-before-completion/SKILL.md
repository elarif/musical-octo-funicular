---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, or before committing, pushing, or creating a pull request. Prevents the failure mode of shipping defects by asserting completion without first running fresh verification evidence and reading its full output.
---

# Verification Before Completion

Verify before claiming complete. Run the command, read the full output, then — and only then — make the claim.

## Snapshot

This skill enforces one rule: **no completion, fix, or pass claim without fresh verification evidence gathered in the same message.** It fires the moment the agent is about to state that work is complete, fixed, passing, committed, pushed, or ready for review — and again before any commit, push, PR, or handoff.

The agent runs a four-step **Gate Function**: identify the command that proves the claim, run it fresh, read the full output and exit code, then state the claim with evidence or state the actual status with evidence. Skipping any step counts as lying, not verifying.

The skill owns the vocabulary of *verified claim*, *fresh evidence*, *actual status*, and *rationalization*. It does not choose which command to run (test-driven-development owns that), review prose (technical-writing owns that), or diagnose failures (systematic-debugging owns that). It only gates the claim.

Read this snapshot to announce and begin; read the body for the Iron Law, the Gate Function, the failure-mode tables, and the public interface parent skills invoke.

## Quick Reference

| Field | Value |
|---|---|
| Audience | Any agent about to claim a task complete, fixed, or passing |
| Triggers | Success/completion claim, commit, push, PR creation, task transition, delegation handoff |
| Inputs | The claim the agent is about to make; the verification command that proves it |
| Outputs | A verified claim with evidence, or a stated actual status with evidence |
| Key artifacts | None written to disk; the claim itself is the output |
| Parent skills | subagent-driven-development, executing-plans, finishing-a-development-branch (see Public Interface for Composition) |

*(projection — see Process sections for full rules)*

## Related Skills

| Skill | Relationship | Notes |
|---|---|---|
| `test-driven-development` | `shared-kernel` | Both enforce "watch it fail / prove it works"; co-maintain the *verify* vocabulary. Translation: TDD's "red-green" = this skill's "evidence before claims"; the red-green cycle is one acceptable verification source. |
| `systematic-debugging` | `shared-kernel` | Both enforce "evidence before claims"; co-maintain the *evidence* vocabulary. Translation: a debugging hypothesis is not evidence here — only a re-run verification command output is. |
| `subagent-driven-development` | `downstream` | SDD's per-subagent verification step invokes this skill before marking a subagent confirmed-complete. |
| `executing-plans` | `downstream` | Each plan step's "done" gate is this skill's Gate Function. |
| `finishing-a-development-branch` | `downstream` | Invoked before merge/PR to gate the "ready to integrate" claim. |

*(projection — see Process sections for full rules. Cap: 5 of ~10.)*

## Document Metadata

| Field | Value |
|---|---|
| Document ID | `SKILL-VBC-001` |
| Revision | 2 |
| Effective Date | 2026-07-19 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |
| Identity strategy | descriptive-name, stable — `name` is modify-once; referenced by siblings |

## Audience

The agent states the following audience attributes before applying this skill:

- **Primary audience**: Any agent that is about to claim a task complete, fixed, or passing.
- **Secondary audience**: Maintainers who edit this skill; reviewers who audit agent output; parent skills that invoke this skill as a sub-skill.
- **Expertise level**: Intermediate — the agent writes completion claims already and needs the rule that makes them honest.
- **What they already know**: The agent can run shell commands and read their output.
- **What they need to learn**: The Gate Function and the evidence rule that turns a claim into a verified claim.
- **What they will do after reading**: Run the verification command, read the full output, and only then make the claim.

## Purpose / Scope

**Purpose**: This skill gives the rule an agent follows before the agent states that work is complete, fixed, or passing. The rule is evidence before claims, always.

**Scope covers**:

- Completion, fix, and pass claims the agent makes about its own work.
- Verification commands the agent runs in the current message.
- Commit, push, and pull-request creation as claim triggers.
- Delegation to other agents as a claim source.
- The public interface parent skills invoke when gating a sub-step (see Public Interface for Composition).

**Scope does NOT cover**:

- Choosing which verification command to run — governed by the `test-driven-development` skill. *Translation:* TDD owns the red-green cycle; this skill only consumes its output as evidence.
- Writing the test plan itself — governed by the `test-driven-development` skill.
- Reviewing another agent's prose — governed by the `technical-writing` skill.
- Diagnosing a failing verification — governed by the `systematic-debugging` skill. *Translation:* a debugging hypothesis is not verification evidence; this skill hands the failure off, it does not investigate.

## Definitions

The agent defines every acronym on first use. This section collects them in one place for reference:

| Term | Meaning |
|---|---|
| VCS | Version Control System (for example, git) |
| TDD | Test-Driven Development |
| PR | Pull Request |
| Claim | Any statement that work is complete, fixed, passing, ready, or successful — exact phrase, paraphrase, synonym, or implication |
| Verification evidence | The full, fresh output of a command run in the current message, including exit code and failure count |
| Fresh evidence | Evidence produced in the same message as the claim, not carried over from a previous run |
| Verified claim | A claim stated together with its verification evidence |
| Actual status | The true state of the work, stated with evidence when the claim does not hold |
| Rationalization | Any wording ("should", "probably", "seems", "just this once") used in place of evidence |

## Core Principle — Evidence Before Claims

Claiming work complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If the agent has not run the verification command in this message, the agent cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Common Failures

*(projection — see the Iron Law and the Gate Function for the authoritative rule)*

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags — Stop And Re-Plan

The agent stops and re-plans on catching any of these thoughts:

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Feeling tired and wanting work over
- ANY wording implying success without having run verification

## Rationalization Prevention

*(projection — see Core Principle for the authoritative rule)*

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

## Worked Example (Given/When/Expect)

- **Given** the agent has just finished editing a source file and is about to reply "the fix is in, tests pass."
- **When** the agent announces `verification-before-completion` and runs the Gate Function.
- **Expect** the agent identifies the project's test command, runs it fresh, reads the full output and exit code, and replies either `"All tests pass: 34/34 (npm test, exit 0)"` or `"Actual status: 2 tests fail — foo.spec.ts:12, bar.spec.ts:47. Fix incomplete."` — never the unsupported original claim.

## Why This Matters

From 24 failure memories:

- your human partner said "I don't believe you" - trust broken
- Undefined functions shipped - would crash
- Missing requirements shipped - incomplete features
- Time wasted on false completion → redirect → rework
- Violates: "Honesty is a core value. If you lie, you'll be replaced."

## When To Apply

The agent applies this skill ALWAYS before the following triggers:

- ANY variation of success or completion claims.
- ANY expression of satisfaction.
- ANY positive statement about work state.
- Committing, PR creation, task completion.
- Moving to the next task.
- Delegating to agents.

The rule applies to the following forms of wording:

- Exact phrases.
- Paraphrases and synonyms.
- Implications of success.
- ANY communication suggesting completion or correctness.

**Two motivating scenarios per "always" rule** [L10.5]:

- *Always before commit/push/PR* — (1) shipping undefined functions that crash because the agent committed without re-running the build; (2) merging a "fixed" bug that still reproduces because the agent trusted the prior test run instead of a fresh one.
- *Always before delegating to agents* — (1) a subagent reports "success" but its VCS diff is empty; (2) a subagent reports "tests pass" from a stale run cached before its own edits.

## Environment Adapter

The skill's domain verb is *run the verification command*; the concrete command varies per project.

- If `AGENTS.md` specifies test, lint, typecheck, or build commands, use those.
- Otherwise fall back to these defaults: `npm test` / `npm run lint` / `npm run build` (Node); `pytest` / `ruff` (Python); `go test` / `go build` (Go); `make` targets where a Makefile exists.
- If no command can be identified, the agent must state that explicitly rather than claim completion on inspection alone.

## Public Interface for Composition

This skill is a sub-skill. Parent skills (`subagent-driven-development`, `executing-plans`, `finishing-a-development-branch`) may invoke only the surface below; everything else in this file is private implementation.

**What a parent may invoke:**

- The **Iron Law** — `NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE`.
- The **Gate Function** — the five-step IDENTIFY/RUN/READ/VERIFY/ONLY-THEN procedure.
- The **Common Failures** table — the per-claim-type minimum evidence requirements.

**What a parent should expect back:**

- A **verified claim with evidence** — the claim text plus the command, its exit code, and the failure count, all from the current message.
- Or a **stated actual status with evidence** — when the claim does not hold, the true state plus the same evidence, with no satisfaction expressed.

**What a parent must not assume:**

- That the child has chosen the verification command — that is the parent's (or TDD's) job.
- That a previous verification run still counts as fresh — it does not.
- That a subagent self-report counts as evidence — it does not; only re-run output does.

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result.

This is non-negotiable.

## Deviations

- The Common Failures and Rationalization Prevention tables are labeled as projections (LA.3) but retained verbatim because they are the operational form of the Iron Law; the prose is the source of truth and the tables are consistent with it. Justification: query performance — agents scan the table faster than the prose during a verification gate.
- The "Public Interface for Composition" exposes three internal artifacts (Iron Law, Gate Function, Common Failures) as the published contract (L13.4) rather than the full body. Justification: parent skills need a thin, stable surface; exposing the full body would couple them to private revision of Red Flags, Key Patterns, etc.

## Revision History

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-07-19 | Self-compliance rewrite: added Document Metadata, Audience, Purpose/Scope, Definitions, Revision History; converted prose to active voice; added lead sentences to all lists; preserved Iron Law, Gate Function, Common Failures, Red Flags, Rationalization Prevention, Key Patterns, Why This Matters, When To Apply, Bottom Line | Skills maintainer | Skills maintainer |
| 2 | 2026-07-19 | IDDD layer applied (additive over technical-writing). A1 Snapshot; A2 Quick Reference table; A3 Related Skills with typed relationships (shared-kernel: test-driven-development, systematic-debugging; downstream: subagent-driven-development, executing-plans, finishing-a-development-branch); A4 Translation notes at cross-skill refs; A7 Public Interface for Composition; A8 Environment Adapter note; A9 Deviations note. B1 description rewritten to name the failure mode; B2 announce line added; B3 Overview→Core Principle; B5 Worked Example as Given/When/Expect; B6 projection labels on quick-reference tables; B7 sibling prose referenced by name only; B9 two motivating scenarios per "always" rule. C1 Definitions expanded (claim, verification evidence, fresh evidence, verified claim, actual status, rationalization); C5 four required slots preserved and consistent; C6 tool names already abstract roles, adapter note added; C7 trigger→actions stays inside this skill's territory. `name` unchanged. | Skills maintainer | Skills maintainer |