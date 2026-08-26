---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and the writer must decide how to integrate the work — prevents unverified branches from being merged or shipped with failing tests, unpushed commits, or orphaned worktrees left behind
type: sub-skill
---

# Finishing a Development Branch

## Snapshot

This skill completes a development branch safely. The writer verifies the test suite, detects whether the workspace is a normal repo, a named-branch worktree, or a detached HEAD, presents a short fixed menu (4 options, or 3 for detached HEAD), executes the chosen workflow (merge locally, push + PR, keep, or discard), and cleans up the worktree by provenance. It exists because the failure mode it prevents is real: unverified branches get merged with failing tests, worktrees get left behind after PR, or a harness-owned workspace gets destroyed by an over-eager `git worktree remove`. An agent reading only this snapshot should announce the skill, run the test suite, run the two `GIT_DIR`/`GIT_COMMON` probes, and present the correct menu. The full Process is the source of truth; the quick-reference table and common-mistakes list are disposable projections of it.

## Document Metadata

| Field | Value |
|---|---|
| Document ID | `SKILL-FDB-001` |
| Revision | 2 |
| Effective Date | 2026-07-20 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |

## Quick Reference

*Projection — see the Process for full rules. When this table and the Process disagree, the Process wins.*

| Field | Value |
|---|---|
| Audience | Any agent completing a development branch and deciding how to integrate it |
| Triggers | Implementation complete; tests pass; writer must decide merge / PR / keep / discard |
| Inputs | A branch with finished work; a passing test suite; a detected workspace state |
| Outputs | A merged branch, a pushed branch + PR, a kept branch, or a discarded branch; a cleaned or preserved worktree |
| Key files | None — this skill emits commands, not artifacts |
| Announce | "I'm using the finishing-a-development-branch skill to finish this branch." |

## Related Skills

Cap at ~10 entries. Each entry names the sibling by `name` and the relationship type.

- **subagent-driven-development** — `upstream`. SDD invokes this skill at the end of a dispatched run to complete the branch.
  - *Translation:* SDD hands off a finished task tree with all subagents confirmed complete; this skill treats that as "implementation complete, proceed to Step 1."
- **executing-plans** — `upstream`. executing-plans invokes this skill at the end of plan execution.
  - *Translation:* executing-plans hands off a fully executed plan with all steps confirmed; this skill treats that as "implementation complete, proceed to Step 1."
- **requesting-code-review** — `upstream`. Review must pass before this skill runs; a branch cannot be finished until review is green.
  - *Translation:* requesting-code-review hands off an approved review verdict; this skill treats that as "quality gate satisfied, proceed to integration."
- **verification-before-completion** — `upstream`. The "verify tests pass" gate is owned by that skill; this skill delegates the verification protocol to it by name and only re-states the project-test-runner command for convenience.
  - *Translation:* verification-before-completion hands off a verification ledger; this skill treats a green ledger as the signal to present the menu.
- **using-git-worktrees** — `shared-kernel`. Both skills manage git workspace state and co-maintain the `GIT_DIR` / `GIT_COMMON` / worktree-provenance terms. A change to those terms here must be flagged in both revision histories.

## Audience

The writer states the following audience attributes before applying this skill:

- **Primary audience**: Any agent that completes a development branch and must decide how to integrate the work.
- **Secondary audience**: Maintainers who edit this skill; reviewers who audit the workflow.
- **Expertise level**: Intermediate — the reader runs git already and needs the structured options.
- **What they already know**: The reader can run git commands and read test output.
- **What they need to learn**: The six-step process, the option menus, and the cleanup rules.
- **What they will do after reading**: Verify tests, detect the environment, present options, execute the choice, and clean up.

## Purpose / Scope

**Purpose**: This skill guides the writer through finishing a development branch by presenting clear options and executing the chosen workflow.

**Scope covers**:

- Test verification before integration.
- Environment detection for normal repos and worktrees.
- The four-option menu and the three-option menu.
- Merge, pull request, keep, and discard workflows.
- Worktree cleanup based on provenance.

**Scope does NOT cover**:

- Writing or debugging the implementation itself.
- Reviewing code quality before merge (owned by `requesting-code-review`).
- Configuring git or the remote repository.
- Managing long-lived release branches.

## Definitions

The writer defines every acronym on first use. This section collects them in one place for reference.

| Term | Meaning |
|---|---|
| HEAD | The currently checked-out commit that git tracks as the working position |
| PR | Pull Request — a request to merge a branch into a target branch on a remote |
| CWD | Current Working Directory — the directory the shell resolves relative paths against |
| GIT_DIR | The path to the `.git` directory for the current repository or worktree |
| GIT_COMMON | The path to the shared `.git` directory of the main repository |
| branch | A named line of development; the unit this skill finishes |
| base branch | The target branch a feature branch will merge into (typically `main` or `master`) |
| feature branch | The branch holding the finished work this skill integrates |
| worktree | A linked working directory sharing one repository's `.git` (created by `git worktree add` or a native worktree tool) |
| provenance | Who created a worktree — `superpowers` (`.worktrees/` or `worktrees/`) or the host harness; decides who owns cleanup |
| detached HEAD | HEAD pointing at a commit, not a branch; treated as externally managed |

## Workflow at a Glance

The writer finishes development work by presenting clear options and handling the chosen workflow.

**Core principle:** Verify tests → Detect environment → Present options → Execute choice → Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to finish this branch."

## The Process

### Step 1: Verify Tests

The writer verifies tests pass before presenting options. The full verification protocol is owned by the `verification-before-completion` skill; this step re-states only the project test-runner command for convenience:

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

The writer stops. The writer does not proceed to Step 2.

**If tests pass:** The writer continues to Step 2.

### Step 2: Detect Environment

The writer determines the workspace state before presenting options:

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

This determines which menu to show and how cleanup works:

| State | Menu | Cleanup |
|-------|------|---------|
| `GIT_DIR == GIT_COMMON` (normal repo) | Standard 4 options | No worktree to clean up |
| `GIT_DIR != GIT_COMMON`, named branch | Standard 4 options | Provenance-based (see Step 6) |
| `GIT_DIR != GIT_COMMON`, detached HEAD | Reduced 3 options (no merge) | No cleanup (externally managed) |

### Step 3: Determine Base Branch

The writer determines the base branch with the following command:

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or the writer asks: "This branch split from main - is that correct?"

### Step 4: Present Options

**Normal repo and named-branch worktree — the writer presents exactly these 4 options:**

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Detached HEAD — the writer presents exactly these 3 options:**

```
Implementation complete. You're on a detached HEAD (externally managed workspace).

1. Push as new branch and create a Pull Request
2. Keep as-is (I'll handle it later)
3. Discard this work

Which option?
```

The writer does not add explanation — the writer keeps options concise.

### Step 5: Run the Chosen Workflow

#### Option 1: Merge Locally

The writer runs the following commands to merge locally:

```bash
# Get main repo root for CWD safety
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"

# Merge first — verify success before removing anything
git checkout <base-branch>
git pull
git merge <feature-branch>

# Verify tests on merged result
<test command>

# Only after merge succeeds: cleanup worktree (Step 6), then delete branch
```

Then the writer cleans up the worktree (Step 6) and deletes the branch:

```bash
git branch -d <feature-branch>
```

#### Option 2: Push and Create PR

The writer pushes the branch with the following command:

```bash
# Push branch
git push -u origin <feature-branch>
```

The writer does NOT clean up the worktree — the user needs it alive to iterate on PR feedback.

#### Option 3: Keep As-Is

The writer reports: "Keeping branch <name>. Worktree preserved at <path>."

The writer does not clean up the worktree.

#### Option 4: Discard

The writer confirms first:
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

The writer waits for exact confirmation.

If confirmed, the writer runs the following commands:
```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
```

Then the writer cleans up the worktree (Step 6) and force-deletes the branch:
```bash
git branch -D <feature-branch>
```

### Step 6: Remove Worktree by Provenance

This step only runs for Options 1 and 4. Options 2 and 3 always preserve the worktree.

The writer runs the following commands to inspect the workspace:

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

**If `GIT_DIR == GIT_COMMON`:** The workspace is a normal repo, so the writer has no worktree to clean up. Done.

**If the worktree path is under `.worktrees/` or `worktrees/`:** Superpowers created this worktree, so the writer owns cleanup.

The writer runs the following commands to remove the worktree:

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git worktree remove "$WORKTREE_PATH"
git worktree prune  # Self-healing: clean up any stale registrations
```

**Otherwise:** The host environment (harness) owns this workspace. The writer does NOT remove it. If the platform provides a workspace-exit tool, the writer uses it. Otherwise, the writer leaves the workspace in place.

## Examples

Each example is a pure, copy-pasteable unit whose output is fully determined by its inputs.

### Given/When/Expect — named-branch worktree, merge chosen

- **Given** a linked worktree at `.worktrees/feat-x` on branch `feat-x`, with a passing test suite and `GIT_DIR != GIT_COMMON`.
- **When** the writer announces this skill and the user picks Option 1 (Merge locally).
- **Expect** the writer to: `cd` to the main repo root, checkout the base branch, merge `feat-x`, re-run tests on the merged result, run `git worktree remove "$WORKTREE_PATH"` and `git worktree prune` from the main root, then `git branch -d feat-x`. The worktree directory is gone; the branch is deleted.

### Given/When/Expect — detached HEAD, PR chosen

- **Given** a detached-HEAD workspace (`GIT_DIR != GIT_COMMON`, no branch name) with a passing test suite.
- **When** the writer announces this skill and the user picks Option 1 from the 3-option menu (Push as new branch and create a Pull Request).
- **Expect** the writer to: push the branch with `git push -u origin <new-branch>`, leave the worktree in place, and report the PR path. No cleanup runs (the harness owns the workspace).

## Quick Reference

*Projection — see the Process for full rules. When this table and the Process disagree, the Process wins.*

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | yes | - | - | yes |
| 2. Create PR | - | yes | yes | - |
| 3. Keep as-is | - | - | yes | - |
| 4. Discard | - | - | - | yes (force) |

## Common Mistakes

**Skipping test verification**
- **Problem:** The writer merges broken code and creates a failing PR.
- **Fix:** The writer verifies tests before offering options.

**Open-ended questions**
- **Problem:** "What should I do next?" is ambiguous.
- **Fix:** The writer presents exactly 4 structured options (or 3 for detached HEAD).

**Cleaning up worktree for Option 2**
- **Problem:** The writer removes the worktree the user needs for PR iteration.
- **Fix:** The writer only cleans up for Options 1 and 4.

**Deleting branch before removing worktree**
- **Problem:** `git branch -d` fails because the worktree still references the branch.
- **Fix:** The writer merges first, removes the worktree, then deletes the branch.

**Running git worktree remove from inside the worktree**
- **Problem:** The command fails silently when CWD sits inside the worktree the writer removes.
- **Fix:** The writer always `cd`s to the main repo root before `git worktree remove`.

**Cleaning up harness-owned worktrees**
- **Problem:** The writer removes a worktree the harness created and causes phantom state.
- **Fix:** The writer only cleans up worktrees under `.worktrees/` or `worktrees/`.

**No confirmation for discard**
- **Problem:** The writer accidentally deletes work.
- **Fix:** The writer requires typed "discard" confirmation.

## Red Flags

**Never:**
- Proceed with failing tests — motivated by (a) a merge that landed broken code on `main`, and (b) a PR that failed CI after push.
- Merge without verifying tests on result — motivated by (a) a merge that introduced a conflict-resolution bug not present on the branch, and (b) a base-branch pull that brought in failing tests from upstream.
- Delete work without confirmation — motivated by (a) a `git branch -D` run on the wrong branch, and (b) a discard executed against a stale worktree path.
- Force-push without explicit request — motivated by (a) a rewrite of published history that broke a teammate's rebase, and (b) a force-push to a shared integration branch.
- Remove a worktree before confirming merge success — motivated by (a) a merge that reported success but left conflicts unresolved, and (b) a merge that succeeded but tests failed on the merged result.
- Clean up worktrees the writer did not create (provenance check) — motivated by (a) a harness-created workspace that lost phantom state on removal, and (b) a `.worktrees/` path that was actually user-managed.
- Run `git worktree remove` from inside the worktree — motivated by (a) a silent failure that left a stale registration, and (b) a CWD that became invalid mid-command.

**Always:**
- Verify tests before offering options — motivated by (a) the failure mode in the first Never rule, and (b) a branch where tests passed locally but failed in CI due to environment drift.
- Detect environment before presenting menu — motivated by (a) a detached-HEAD workspace that cannot merge, and (b) a normal repo where worktree cleanup is a no-op.
- Present exactly 4 options (or 3 for detached HEAD) — motivated by (a) an open-ended "what next?" that produced a wrong guess, and (b) a menu that offered merge on a detached HEAD and failed.
- Get typed confirmation for Option 4 — motivated by (a) an accidental discard of uncommitted work, and (b) a discard that hit the wrong branch name.
- Clean up worktree for Options 1 and 4 only — motivated by (a) a PR whose worktree was removed mid-iteration, and (b) a keep-as-is branch whose worktree was deleted before the user returned.
- `cd` to main repo root before worktree removal — motivated by (a) the silent in-worktree failure above, and (b) a relative path that resolved against the soon-to-be-removed worktree.
- Run `git worktree prune` after removal — motivated by (a) a stale registration that blocked a later `git worktree add`, and (b) a `git worktree list` that reported a worktree removed hours earlier.

## Environment Adapter

This skill runs git commands. If AGENTS.md specifies git workflow conventions (commit message format, push policy, base branch name, worktree directory preference, cleanup policy), use those; otherwise fall back to the defaults in the Process above.

## Deviations

None. This skill follows the standard required slots, the small-aggregate rule (one responsibility: finishing a branch), and reference-by-name for all cross-skill handoffs. Git commands are intentionally retained as concrete commands rather than abstracted to roles (per C6: only abstract where the decision is tool-independent; git commands are the decision here, not the tool surface).

## Revision History

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-07-19 | Self-compliance rewrite: added Document Metadata, Audience, Purpose/Scope, Definitions; applied active voice and lead sentences throughout; added Revision History | Skills team | Skills maintainer |
| 2 | 2026-07-20 | IDDD layer: added Snapshot, Quick Reference table (labeled projection), Related Skills with typed relationships + Translation notes, Examples in Given/When/Expect, Environment Adapter, Deviations; expanded Definitions; renamed announce verb to match name; renamed Step 5 / Step 6 headings to work-speak; added ≥2 motivating scenarios per Never/Always rule; delegated test-verification protocol to `verification-before-completion` by name | Skills team | Skills maintainer |
| 3 | 2026-08-26 | IDDD typology sweep: added type frontmatter, reordered Related Skills by category per _shared/SKILL-ARCH.md | Skills maintainer | Skills maintainer |