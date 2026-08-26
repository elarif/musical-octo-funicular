---
name: systematic-debugging
description: Use when the agent faces a bug, test failure, or unexpected behavior and is tempted to apply a fix before understanding it — random fixes waste time and create new bugs; this skill forces root-cause investigation before any fix is proposed.
type: sub-skill
---

# Systematic Debugging

Debug systematically: find the root cause of a defect before proposing any fix.

## Document Metadata

| Field | Value |
|---|---|
| Document ID | `SKILL-SD-001` |
| Revision | 2 |
| Effective Date | 2026-07-19 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |
| Identity strategy | descriptive-name, stable (`# identity: descriptive-name, stable`) |
| Maintainer | Skills maintainer |

## Snapshot

Random fixes waste time and create new bugs. This skill enforces a four-phase process — root cause investigation, pattern analysis, hypothesis testing, implementation — that the agent must complete before proposing any fix. The Iron Law: **no fixes without root cause investigation first**.

Use this skill for any test failure, bug in production, unexpected behavior, performance problem, build failure, or integration issue — especially under time pressure, after a failed fix, or when the agent does not fully understand the issue. Simple bugs and emergencies are NOT exceptions; simple bugs have root causes, and systematic debugging is faster than thrashing.

The agent completes each phase before moving to the next. Phase 1 reads errors, reproduces, checks recent changes, gathers evidence across component boundaries, and traces data flow. Phase 2 finds working examples and compares. Phase 3 forms one hypothesis and tests minimally. Phase 4 writes a failing test, applies a single fix, and verifies. Three or more failed fixes means the architecture is wrong — stop and question fundamentals.

Red flags ("just try changing X," "quick fix for now") mean: stop and return to Phase 1. Reading only this snapshot, the agent can announce the skill and begin.

## Quick Reference

| Field | Value |
|---|---|
| Audience | Any agent or engineer debugging a bug, test failure, or unexpected behavior |
| Triggers | Test failure; production bug; unexpected behavior; perf problem; build failure; integration issue; failed prior fix; time pressure |
| Inputs | Error message, stack trace, repro steps, recent git diff, failing test |
| Outputs | A root cause statement + a fix verified by a passing test (or an architectural escalation) |
| Key files | `root-cause-tracing.md`, `defense-in-depth.md`, `condition-based-waiting.md` (this directory) |
| Iron Law | No fixes without root cause investigation first |
| Public surface | The 4 phases, the Iron Law, the red flags (see Public Interface for Composition) |

*This table is a projection — see the Process (The Four Phases) for full rules. When this table and the Process disagree, the Process wins.*

## Related Skills

| Skill | Relationship | What this skill uses from it |
|---|---|---|
| `test-driven-development` | downstream | Phase 4 step 1 delegates the failing-test write to TDD |
| `verification-before-completion` | downstream | Phase 4 step 3 delegates fix verification to this skill |
| `dispatching-parallel-agents` | downstream | Phase 1 step 4 uses it when component boundaries span isolated contexts |
| `kibana-prod-investigation` | downstream | Phase 1 step 4 uses it when evidence lives in production logs/APM |
| `root-cause-tracing.md` | downstream | Phase 1 step 5 references its backward-trace technique |
| `defense-in-depth.md` | downstream | Phase 4 references it for layered validation after the fix |
| `condition-based-waiting.md` | downstream | Phase 4 references it when the fix involves timing/timeout |

*Translation note for each downstream reference: this skill calls the sibling by its `name` and hands it a fully-formed brief (failing-test requirement, verification target, component boundary, log query). It does not adopt the sibling's internal vocabulary — the sibling returns an artifact (a test, a verification ledger, an evidence report) which this skill consumes as opaque output.*

## Audience

The agent states the following audience attributes before applying this skill:

- **Primary audience**: Any agent or engineer who debugs a bug, test failure, or unexpected behavior.
- **Secondary audience**: Maintainers who edit this skill; reviewers who audit debugging sessions.
- **Expertise level**: Intermediate — the reader can write code already and needs the discipline that prevents symptom-fixing.
- **What they already know**: The reader can read code, run tests, and use git.
- **What they need to learn**: The four-phase root-cause process and the red flags that mark a skipped phase.
- **What they will do after reading**: Apply the four phases to find the root cause before the agent proposes any fix.

## Purpose / Scope

**Purpose**: This skill gives the rules the agent follows to find the root cause of a defect before the agent proposes any fix. The process must also prevent symptom-fixing and rework.

**Scope covers**:

- The four phases: root cause investigation, pattern analysis, hypothesis and testing, implementation.
- Red flags and partner signals that mark a skipped phase.
- Supporting techniques: root-cause tracing, defense-in-depth, condition-based waiting.
- Quick reference for phase activities and success criteria.

**Scope does NOT cover**:

- Writing code (governed by code conventions, not this skill).
- Test design beyond the failing-test requirement in Phase 4.
- Architectural redesign beyond the "question architecture" trigger.
- Incident communication outside the debugging session.

## Definitions

The agent defines every acronym on first use. This section collects them in one place for reference.

| Term | Meaning |
|---|---|
| CI | Continuous Integration |
| API | Application Programming Interface |
| Root cause | The earliest point in the call/data flow where a wrong value or wrong assumption originates; fixing here resolves the symptom without masking |
| Symptom fix | A change that suppresses an observable error without addressing its origin; tends to create new bugs |
| Red flag | A thought pattern ("just try X") that marks a skipped phase; on noticing one, return to Phase 1 |

## Why Random Fixes Fail

Random fixes waste time and create new bugs. Quick patches mask underlying issues.

**Core principle**: The agent always finds the root cause before the agent attempts any fix. Symptom fixes are failure.

**Two scenarios that motivate "always":**

1. **CI signing failure** — an agent applies a `--deep` flag to quiet a codesign error; the build passes locally, then fails at distribution because the real cause was a missing keychain entry. The "quick fix" masked the root cause and surfaced it later, at higher cost.
2. **Flaky test** — an agent adds a retry around a failing test; the test "passes," then a production outage reveals the test was correctly catching a race condition. The retry buried the bug the test was paid to find.

**Violating the letter of this process is violating the spirit of debugging.**

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

The agent cannot propose fixes until Phase 1 is complete.

## When to Use

Use this skill for any of the following technical issues:

- Test failures
- Bugs in production
- Unexpected behavior
- Performance problems
- Build failures
- Integration issues

**Use this skill especially when one of the following conditions holds**:

- Time pressure makes guessing tempting
- A "quick fix" seems obvious
- The agent has already tried multiple fixes
- A previous fix did not work
- The agent does not fully understand the issue

**Do not skip the process when one of the following conditions holds**:

- The issue seems simple (simple bugs have root causes too)
- The agent is in a hurry (rushing guarantees rework)
- A manager demands a fix now (systematic is faster than thrashing)

## Environment Adapter

This skill triggers tool calls: bash instrumentation, test commands, git diffs, and (for production evidence) log queries. The concrete commands vary per repo and host.

**If `AGENTS.md` (or the repo's equivalent) specifies test, lint, or build commands, use those.** Otherwise fall back to these defaults:

- Run tests: `npm test` / `pytest` / `go test ./...` / `cargo test` — whichever the repo's lockfile implies.
- Show recent changes: `git diff` and `git log -p -n 10`.
- Lint the changed files: the repo's configured linter (`npm run lint`, `ruff check`, etc.).
- Production logs/APM: delegate to the `kibana-prod-investigation` skill rather than hand-rolling queries.

When a sibling skill owns the command (`test-driven-development` for the failing test, `verification-before-completion` for the verify step), delegate by name — do not restate its commands here.

## The Four Phases

The agent must complete each phase before the agent proceeds to the next.

### Phase 1: Root Cause Investigation

**The agent completes the following steps before attempting any fix**:

1. **Read Error Messages Carefully**
   - Do not skip past errors or warnings
   - Look for the exact solution inside them
   - Read stack traces completely
   - Note line numbers, file paths, and error codes

2. **Reproduce Consistently**
   - Trigger the defect reliably
   - Record the exact steps
   - Confirm whether it happens every time
   - If it is not reproducible, gather more data — do not guess

3. **Check Recent Changes**
   - Identify what changed that could cause this
   - Review git diff and recent commits
   - Note new dependencies and config changes
   - Compare environmental differences

4. **Gather Evidence in Multi-Component Systems**

   **When the system has multiple components (CI → build → signing, API → service → database), the agent adds diagnostic instrumentation before proposing fixes**:

    ```
    For EACH component boundary:
      - Log what data enters component
      - Log what data exits component
      - Verify environment/config propagation
      - Check state at each layer

    Run once to gather evidence showing WHERE it breaks
    THEN analyze evidence to identify failing component
    THEN investigate that specific component
    ```

   **Example instrumentation (multi-layer system)**:

    ```bash
    # Layer 1: Workflow
    echo "=== Secrets available in workflow: ==="
    echo "IDENTITY: ${IDENTITY:+SET}${IDENTITY:-UNSET}"

    # Layer 2: Build script
    echo "=== Env vars in build script: ==="
    env | grep IDENTITY || echo "IDENTITY not in environment"

    # Layer 3: Signing script
    echo "=== Keychain state: ==="
    security list-keychains
    security find-identity -v

    # Layer 4: Actual signing
    codesign --sign "$IDENTITY" --verbose=4 "$APP"
    ```

   **This reveals**: Which layer fails (secrets → workflow ✓, workflow → build ✗)

   **When component boundaries span isolated execution contexts (separate subagents, separate services, separate hosts), delegate the per-component evidence gather to the `dispatching-parallel-agents` skill; when the evidence lives in production logs or APM, delegate the gather to the `kibana-prod-investigation` skill.** Both return an evidence report this skill consumes as opaque input — see each sibling's SKILL.md for its dispatch contract.

5. **Trace Data Flow**

   **When the error is deep in the call stack, see `root-cause-tracing.md` in this directory — it defines the backward tracing technique for tracing a bad value from symptom to origin.**

   **Quick version**:

   - Trace where the bad value originates
   - Identify what called this with the bad value
   - Keep tracing up until the agent finds the source
   - Fix at the source, not at the symptom

### Phase 2: Pattern Analysis

**The agent finds the pattern before fixing**:

1. **Find Working Examples**
   - Locate similar working code in the same codebase
   - Identify working code similar to the broken code

2. **Compare Against References**
   - Read the reference implementation completely
   - Read every line — do not skim
   - Understand the pattern fully before the agent applies it

3. **Identify Differences**
   - Compare the working code and the broken code
   - List every difference, however small
   - Do not assume any difference "can't matter"

4. **Understand Dependencies**
   - Identify the components this code needs
   - List the settings, config, and environment it requires
   - State the assumptions it makes

### Phase 3: Hypothesis and Testing

**The agent applies the scientific method**:

1. **Form Single Hypothesis**
   - State it clearly: "I think X is the root cause because Y"
   - Write it down
   - Be specific, not vague

2. **Test Minimally**
   - Make the smallest possible change to test the hypothesis
   - Change one variable at a time
   - Do not fix multiple things at once

3. **Verify Before Continuing**
   - If it works, proceed to Phase 4
   - If it did not work, form a new hypothesis
   - Do not add more fixes on top

4. **When the Agent Does Not Know**
   - Say "I don't understand X"
   - Do not pretend to know
   - Ask for help
   - Research more

### Phase 4: Implementation

**The agent fixes the root cause, not the symptom**:

1. **Create Failing Test Case**
   - Build the simplest possible reproduction
   - Write an automated test if possible
   - Write a one-off test script if no framework exists
   - Have a failing test before fixing
   - Delegate the failing-test write to the `test-driven-development` skill — see its SKILL.md for the protocol; pass it the reproduction and the failing assertion

2. **Implement Single Fix**
   - Address the root cause identified
   - Make one change at a time
   - Make no "while I'm here" improvements
   - Bundle no refactoring

3. **Verify Fix**
   - Confirm the test passes now
   - Confirm no other tests broke
   - Confirm the issue is actually resolved
   - Delegate the verification to the `verification-before-completion` skill — see its SKILL.md for the protocol; it returns a verification ledger this skill treats as the completion gate

4. **If the Fix Does Not Work**
   - Stop
   - Count how many fixes the agent has tried
   - If fewer than 3: return to Phase 1 and re-analyze with new information
   - If 3 or more: stop and question the architecture (step 5 below)
   - Do not attempt Fix #4 without an architectural discussion

5. **If 3 or More Fixes Failed: Question Architecture**

   **The following pattern indicates an architectural problem**:

   - Each fix reveals new shared state, coupling, or a problem in a different place
   - Fixes require "massive refactoring" to implement
   - Each fix creates new symptoms elsewhere

   **The agent stops and questions the fundamentals**:

   - Ask whether this pattern is fundamentally sound
   - Ask whether the team is "sticking with it through sheer inertia"
   - Decide whether to refactor the architecture vs. continue fixing symptoms

   **The agent discusses with the human partner before attempting more fixes**.

   This is NOT a failed hypothesis — this is a wrong architecture.

## Examples

**Given** a CI signing job fails with `no identity found`, **when** the agent announces `systematic-debugging` and follows Phase 1, **expect** a layer-by-layer evidence trace that names the failing boundary (e.g., "secrets → workflow ✓, workflow → build ✗") before any fix is proposed.

**Given** a flaky test passes locally but fails in CI, **when** the agent reaches Phase 4 step 1, **expect** a failing test case delegated to `test-driven-development` that reproduces the CI ordering/timing before the fix is applied.

**Given** three consecutive fixes each surface a new symptom, **when** the agent reaches Phase 4 step 5, **expect** the agent stops, names the architectural smell, and escalates to the human partner instead of attempting fix #4.

## Red Flags — STOP and Follow Process

**The agent stops and returns to Phase 1 on thinking any of the following**:

- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "Skip the test, I'll manually verify"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- "Pattern says X but I'll adapt it differently"
- "Here are the main problems: [lists fixes without investigation]"
- "I'll propose solutions before tracing data flow"
- "One more fix attempt" (when already tried 2+)
- "Each fix reveals a new problem somewhere else"

**Each of these means: stop and return to Phase 1.**

**If 3 or more fixes failed, the agent questions the architecture (see Phase 4, step 5)**.

## Human Partner Signals You Are Doing It Wrong

**The agent watches for the following redirections**:

- "Is that not happening?" — the agent assumed without verifying
- "Will it show us...?" — the agent should have added evidence gathering
- "Stop guessing" — the agent is proposing fixes without understanding
- "Ultra-think this" — question fundamentals, not just symptoms
- "We're stuck?" (frustrated) — the agent's approach is not working

**On seeing these, the agent stops and returns to Phase 1**.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Issue is simple, don't need process" | Simple issues have root causes too. Process is fast for simple bugs. |
| "Emergency, no time for process" | Systematic debugging is FASTER than guess-and-check thrashing. |
| "Just try this first, then investigate" | First fix sets the pattern. Do it right from the start. |
| "I'll write test after confirming fix works" | Untested fixes don't stick. Test first proves it. |
| "Multiple fixes at once saves time" | Can't isolate what worked. Causes new bugs. |
| "Reference too long, I'll adapt the pattern" | Partial understanding guarantees bugs. Read it completely. |
| "I see the problem, let me fix it" | Seeing symptoms ≠ understanding root cause. |
| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem. Question pattern, don't fix again. |

*This table is a projection — see the Process (The Four Phases) for full rules. When this table and the Process disagree, the Process wins.*

## Phase Quick Reference

| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **1. Root Cause** | Read errors, reproduce, check changes, gather evidence | Understand WHAT and WHY |
| **2. Pattern** | Find working examples, compare | Identify differences |
| **3. Hypothesis** | Form theory, test minimally | Confirmed or new hypothesis |
| **4. Implementation** | Create test, fix, verify | Bug resolved, tests pass |

*This table is a projection — see the Process (The Four Phases) for full rules. When this table and the Process disagree, the Process wins.*

## When Process Reveals "No Root Cause"

**If systematic investigation reveals the issue is truly environmental, timing-dependent, or external, the agent takes the following steps**:

1. The agent confirms it has completed the process
2. The agent documents what it investigated
3. The agent implements handling (retry, timeout, error message)
4. The agent adds monitoring/logging for future investigation

**But**: 95% of "no root cause" cases are incomplete investigation.

## Supporting Techniques

**The following techniques are part of systematic debugging and live in this directory**:

- **`root-cause-tracing.md`** — defines the backward tracing technique for tracing a bad value from symptom to origin through the call stack
- **`defense-in-depth.md`** — defines the layered-validation pattern to apply after the root cause is found, so the same class of bug is caught at multiple layers
- **`condition-based-waiting.md`** — defines the condition-polling pattern that replaces arbitrary timeouts when the fix involves timing

**The agent uses the following related skills** (see Related Skills above for relationship types and translation notes):

- **`test-driven-development`** — for creating the failing test case (Phase 4, Step 1)
- **`verification-before-completion`** — to verify the fix worked before claiming success
- **`dispatching-parallel-agents`** — for multi-component evidence gathering (Phase 1, Step 4)
- **`kibana-prod-investigation`** — for production log/APM evidence gathering (Phase 1, Step 4)

## Public Interface for Composition

This skill is designed to be invoked by parent skills (`test-driven-development`, `verification-before-completion`, `dispatching-parallel-agents`, `kibana-prod-investigation` all reference it, and orchestration skills may dispatch it on a failure signal). The following is the stable contract a parent may rely on.

**What a parent may invoke:**

- The four phases (Phase 1 root-cause investigation through Phase 4 implementation).
- The Iron Law (`NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST`) as a guard a parent may assert before accepting any fix from a child.
- The red flags list, as a self-check a parent may prompt a child to run.
- The "3+ failed fixes → question architecture" rule, as an escalation trigger a parent may listen for.

**What a parent should expect back:**

- A root cause statement (where the wrong value or wrong assumption originates).
- A fix verified by a passing test (the test was failing before, passing after), OR an architectural escalation that names the smell and asks for a human decision.
- The evidence trace gathered in Phase 1 (component boundaries, layer-by-layer results) so the parent can audit the investigation.

**What a parent must NOT assume:**

- This skill does not return a code change; it returns the decision to apply a specific fix and the verification that the fix works. The parent delegates the actual code authoring to `test-driven-development` and the verification to `verification-before-completion`.
- This skill's internal sections (Examples, Common Rationalizations, Real-World Impact) are implementation, not contract; they may change between revisions. Only the four phases, the Iron Law, the red flags, and the return shape above are stable.

## Real-World Impact

**The following results come from debugging sessions**:

- Systematic approach: 15-30 minutes to fix
- Random fixes approach: 2-3 hours of thrashing
- First-time fix rate: 95% vs 40%
- New bugs introduced: Near zero vs common

## Deviations

No structural rules from the IDDD spec were broken in this revision. If a future revision inlines a sibling's prose or pastes a reference file's contents (e.g., to support a subagent without filesystem access), the author must record here which of the four legitimate reasons applies (UI convenience, missing mechanism, global transaction, query performance) per L10.7, and flag it in Revision History.

## Revision History

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-07-19 | Self-compliance rewrite: added Document Metadata, Audience, Purpose/Scope, Definitions; active voice throughout; lead sentences on all lists; Revision History | Skills maintainer | Skills maintainer |
| 2 | 2026-07-19 | IDDD layer: added Snapshot, Quick Reference (DTO), Related Skills with typed relationships + translation notes, Public Interface for Composition, Environment Adapter, Deviations note, Examples (Given/When/Expect); rewrote `description` as a specific trigger naming the failure mode; added announce line; renamed Overview → Why Random Fixes Fail; added "always" scenarios to the core principle; labeled quick-reference tables as projections; replaced inline sibling-skill prose with `name` references + one-line purpose; abstracted tool commands behind AGENTS.md-first adapter | Skills maintainer | Skills maintainer |
| 3 | 2026-08-26 | IDDD typology sweep: added type frontmatter, reordered Related Skills by category per _shared/SKILL-ARCH.md | Skills maintainer | Skills maintainer |