---
name: using-git-worktrees
description: Use when feature work would otherwise happen on the main branch and collide with other work, or before executing an implementation plan that requires a separate workspace. Prevents uncommitted changes from leaking across features and avoids clobbering an in-progress branch.
type: sub-skill
---

# Using Git Worktrees

## Snapshot

This skill isolates feature work in its own git worktree so it cannot collide with other in-progress work. The flow is: detect existing isolation → prefer native worktree tools → fall back to `git worktree add` → run project setup → verify a clean test baseline. Always run detection first; never create a nested worktree inside an existing one. Always defer to a native worktree tool (`EnterWorktree`, `--worktree`, etc.) when present — using raw git when the harness offers isolation creates phantom state the harness cannot manage. Honor an explicit user preference for worktree directory location; otherwise default to `.worktrees/` at the project root and verify it is gitignored. If `git worktree add` is blocked by a sandbox, work in place and say so. The skill is a Domain Service: pure orchestration of detection + creation + setup + baseline; it carries no state between invocations.

## Quick Reference (projection — see Process for full rules)

| Field | Value |
|---|---|
| Audience | Agent or engineer starting isolated feature work |
| Triggers | Feature work that would land on the main branch; an implementation plan requiring a separate workspace |
| Inputs | Current working directory; declared user preference (instruction file or prompt); native-tool availability |
| Outputs | An isolated worktree path (or an in-place fallback notice); a clean test baseline report |
| Key files | `.worktrees/` or `worktrees/` (project-local, must be gitignored); `AGENTS.md` (for git workflow conventions) |
| Identity | `name: using-git-worktrees` (descriptive-name strategy) |

## Related Skills

| Sibling | Relationship | What crosses the boundary |
|---|---|---|
| `finishing-a-development-branch` | shared-kernel | Both skills co-maintain the worktree/branch/HEAD vocabulary and git workspace-state lifecycle. A change to worktree/branch/HEAD terms here must be flagged in both revision histories. |
| `subagent-driven-development` | downstream | SDD requires an isolated workspace before dispatching subagents; this skill supplies it. |
| `executing-plans` | downstream | Executing an implementation plan requires an isolated workspace; this skill supplies it. |

**Translation notes:**
- For `subagent-driven-development` and `executing-plans`: the "isolated workspace" they request arrives here as a worktree path on a named branch. They consume only the path + branch name + baseline-test result; they do not consume this skill's detection or fallback logic.
- For `finishing-a-development-branch`: both skills use `worktree`, `branch`, and `HEAD` with the same meaning (no translation needed — hence `shared-kernel`, not `upstream`).

## Document Metadata

| Field | Value |
|---|---|
| Document ID | `SKILL-UGW-001` |
| Revision | 2 |
| Effective Date | 2026-07-20 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |

## Audience

The writer states the following audience attributes before applying this skill:

- **Primary audience**: Any agent or engineer who starts feature work that needs an isolated workspace.
- **Secondary audience**: Reviewers who audit the agent's workspace-setup decisions.
- **Expertise level**: Intermediate — the reader knows git basics and needs the detection and fallback order.
- **What they already know**: The reader can run git commands and read a repository state.
- **What they need to learn**: The detection (Step 0), the native-tool preference (Step 1a), and the git fallback (Step 1b).
- **What they will do after reading**: Set up an isolated workspace, run project setup, and verify a clean test baseline.

## Purpose / Scope

**Purpose**: This skill ensures the agent works in an isolated workspace before starting feature work or executing an implementation plan, so concurrent features do not collide on a shared branch.

**Scope covers**:

- Detecting whether the agent already sits in an isolated workspace.
- Creating a workspace via native tools or the git worktree fallback.
- Running project setup and verifying a clean test baseline.

**Scope does NOT cover**:

- Branch-naming conventions (governed by the project's git conventions / AGENTS.md).
- Implementation-plan authoring (governed by the `writing-plans` skill — reference by name, do not inline its protocol).
- Test-framework selection (governed by the project's test conventions).

## Definitions

The writer defines every acronym on first use. This section collects them in one place for reference:

| Term | Meaning |
|---|---|
| GIT_DIR | Absolute path to the repository's `.git` directory for the current working tree |
| GIT_COMMON | Absolute path to the shared common directory that backs linked worktrees |
| HEAD | The currently checked-out commit reference |
| CWD | Current Working Directory — the directory the agent runs commands from |
| Linked worktree | A git working tree created with `git worktree add`, sharing one object store with the main checkout |
| Native worktree tool | A host-harness facility (e.g. `EnterWorktree`, a `/worktree` command, a `--worktree` flag) that creates and manages worktrees on the agent's behalf |
| Isolated workspace | A working tree whose changes cannot collide with another in-progress feature — either a linked worktree or a harness-managed equivalent |
| Baseline | The test result obtained in the fresh workspace before any feature work begins |

## Workspace Isolation Principle

The agent works in an isolated workspace. The agent prefers the platform's native worktree tools. The agent falls back to manual git worktrees only when no native tool is available.

**Core principle:** Detect existing isolation first. Then use native tools. Then fall back to git. Never fight the harness.

**Announce at start:** "I'm using the using-git-worktrees skill to isolate feature work in a git worktree."

## Environment Adapter

This skill runs git commands. **If `AGENTS.md` specifies git workflow conventions (branch-naming, worktree directory, ignore rules), use those; otherwise fall back to the defaults below.** The decision logic in the Process is tool-independent — only the concrete commands are git-specific, so they stay inline (this is a git-skill, not a skill that happens to mention git).

## Step 0: Detect Existing Isolation

**Before creating anything, the agent checks whether it already sits in an isolated workspace.**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside git submodules. Before the agent concludes "already in a worktree," the agent verifies it is not in a submodule:

```bash
# If this returns a path, you're in a submodule, not a worktree — treat as normal repo
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**If `GIT_DIR != GIT_COMMON` (and not a submodule):** The agent already sits in a linked worktree. The agent skips to Step 2 (Project Setup). The agent does NOT create another worktree.

The agent reports the branch state:
- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."

**If `GIT_DIR == GIT_COMMON` (or in a submodule):** The agent sits in a normal repo checkout.

The agent checks whether the user has already declared a worktree preference in the instructions. If not, the agent asks for consent before creating a worktree:

> "Would you like me to set up an isolated worktree? It protects your current branch from changes."

The agent honors any declared preference without asking. If the user declines consent, the agent works in place and skips to Step 2.

## Step 1: Create Isolated Workspace

**The agent has two mechanisms and tries them in this order:**

### 1a. Prefer a Native Worktree Tool

The user has asked for an isolated workspace (Step 0 consent). The agent checks whether it already has a way to create a worktree. Such a tool carries a name like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree` flag. If the agent has one, the agent uses it and skips to Step 2.

Native tools handle directory placement, branch creation, and cleanup automatically. Using `git worktree add` when the agent has a native tool creates phantom state the harness cannot see or manage.

The agent proceeds to Step 1b only when it has no native worktree tool available.

### 1b. Fall Back to a Git Worktree

**The agent uses this fallback only when Step 1a does not apply** — the agent has no native worktree tool. The agent creates a worktree manually with git.

#### Choose the Worktree Directory

The agent follows this priority order. Explicit user preference always beats observed filesystem state.

1. **The agent checks the instructions for a declared worktree directory preference.** If the user has already specified one, the agent uses it without asking.

2. **The agent checks for an existing project-local worktree directory:**
   ```bash
   ls -d .worktrees 2>/dev/null     # Preferred (hidden)
   ls -d worktrees 2>/dev/null      # Alternative
   ```
   If the agent finds one, the agent uses it. If both exist, `.worktrees` wins.

3. **When no other guidance exists**, the agent defaults to `.worktrees/` at the project root.

#### Verify the Directory Is Gitignored (project-local directories only)

**The agent MUST verify the directory appears in .gitignore before creating the worktree:**

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**If NOT ignored:** The agent adds the directory to .gitignore, commits the change, then proceeds.

**Why critical:** This check prevents the agent from accidentally committing worktree contents to the repository.

#### Add the Worktree

```bash
# Determine path based on chosen location
path="$LOCATION/$BRANCH_NAME"

git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

**Sandbox fallback:** If `git worktree add` fails with a permission error (sandbox denial), the agent tells the user the sandbox blocked worktree creation and the agent works in the current directory instead. The agent then runs setup and baseline tests in place.

## Step 2: Run Project Setup

The agent auto-detects and runs the matching setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

## Step 3: Verify a Clean Test Baseline

The agent runs tests to ensure the workspace starts clean:

```bash
# Use project-appropriate command
npm test / cargo test / pytest / go test ./...
```

**If tests fail:** The agent reports the failures and asks whether to proceed or investigate.

**If tests pass:** The agent reports ready.

### Baseline Report

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Worked Example (Given / When / Expect)

This example is a pure value object — copy-pasteable, side-effect-free, fully determined by its inputs. It doubles as a use case and as an in-memory micro-test input for `writing-skills`.

**Given** a normal repo checkout at `/home/elarif/myskills/toto` on branch `main`, no native worktree tool available, no declared worktree preference, and `.worktrees/` does not exist.
**When** the agent announces "I'm using the using-git-worktrees skill to isolate feature work in a git worktree," then runs Step 0 detection (concludes `GIT_DIR == GIT_COMMON`), asks for and receives user consent, runs Step 1b (chooses `.worktrees/feat-x`, verifies it is gitignored, runs `git worktree add .worktrees/feat-x -b feat-x`), then runs Step 2 (`npm install`) and Step 3 (`npm test`).
**Expect** the agent to report: "Worktree ready at /home/elarif/myskills/toto/.worktrees/feat-x / Tests passing (<N> tests, 0 failures) / Ready to implement feat-x", and to have left the original `main` checkout untouched.

## Quick Reference (projection — see Process for full rules)

| Situation | Action |
|-----------|--------|
| Already in linked worktree | Skip creation (Step 0) |
| In a submodule | Treat as normal repo (Step 0 guard) |
| Native worktree tool available | Use it (Step 1a) |
| No native tool | Git worktree fallback (Step 1b) |
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check instruction file, then default `.worktrees/` |
| Directory not ignored | Add to .gitignore + commit |
| Permission error on create | Sandbox fallback, work in place |
| Tests fail during baseline | Report failures + ask |
| No package.json/Cargo.toml | Skip dependency install |

## Common Mistakes

### Fighting the harness

- **Problem:** Using `git worktree add` when the platform already provides isolation
- **Fix:** Step 0 detects existing isolation. Step 1a defers to native tools.

### Skipping detection

- **Problem:** Creating a nested worktree inside an existing one
- **Fix:** Always run Step 0 before creating anything

### Skipping ignore verification

- **Problem:** Worktree contents get tracked, pollute git status
- **Fix:** Always use `git check-ignore` before creating project-local worktree

### Assuming directory location

- **Problem:** Creates inconsistency, violates project conventions
- **Fix:** Follow priority: explicit instructions > existing project-local directory > default

### Proceeding with failing tests

- **Problem:** Can't distinguish new bugs from pre-existing issues
- **Fix:** Report failures, get explicit permission to proceed

## Red Flags

**The agent never does the following** (each rule is motivated by ≥2 distinct scenarios):

- Create a worktree when Step 0 detects existing isolation. *(Scenario 1: agent already in a linked worktree creates a nested one and corrupts branch state. Scenario 2: harness-managed isolation is overwritten by a raw git worktree the harness cannot track.)*
- Use `git worktree add` when the agent has a native worktree tool (e.g., `EnterWorktree`). This is the #1 mistake — if the agent has it, the agent uses it. *(Scenario 1: harness loses visibility of the worktree and cannot clean it up. Scenario 2: branch creation diverges from the harness's own branch registry.)*
- Skip Step 1a by jumping straight to Step 1b's git commands. *(Scenario 1: a `--worktree` flag exists but goes unused, doubling worktree state. Scenario 2: a `/worktree` command exists but goes unused, leaving the harness with stale workspace metadata.)*
- Create a worktree without verifying the directory appears in .gitignore (project-local). *(Scenario 1: `git status` floods with worktree files. Scenario 2: an accidental `git add .` commits the entire worktree into the parent branch.)*
- Skip baseline test verification. *(Scenario 1: a pre-existing test failure is later attributed to the new feature. Scenario 2: a missing dependency (skipped setup) surfaces as a test error that looks like a feature bug.)*
- Proceed with failing tests without asking. *(Scenario 1: the agent implements on top of a red baseline and cannot bisect its own breakage. Scenario 2: the user wanted to investigate the baseline first but was never given the choice.)*

**The agent always does the following** (each rule is motivated by ≥2 distinct scenarios):

- Run Step 0 detection first. *(Scenario 1: avoid nested worktree. Scenario 2: respect a harness that has already isolated the agent.)*
- Prefer native tools over git fallback. *(Scenario 1: keep harness state coherent. Scenario 2: let the harness own cleanup.)*
- Follow directory priority: explicit instructions > existing project-local directory > default. *(Scenario 1: respect a user-declared `.worktrees/` convention. Scenario 2: respect an inherited repo convention that already uses `worktrees/`.)*
- Verify the directory appears in .gitignore for project-local worktrees. *(Scenario 1: prevent `git status` pollution. Scenario 2: prevent accidental commit of worktree contents.)*
- Auto-detect and run project setup. *(Scenario 1: a Node feature branch needs `npm install` before tests compile. Scenario 2: a Rust feature branch needs `cargo build` before `cargo test` resolves.)*
- Verify a clean test baseline. *(Scenario 1: distinguish new bugs from pre-existing ones. Scenario 2: catch a missing-dependency failure before attributing it to the feature.)*

## Deviations

None at this revision. All structural rules from the IDDD layer are honored: git commands remain inline because this is a git-specific skill and the decision logic is tool-independent only at the level of "detect → prefer native → fall back → setup → baseline" (C6 audit — git commands may stay; only the abstract role/decision would be abstracted, and that is already done in the Process headings).

## Revision History

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-07-19 | Technical-writing compliance rewrite: added Document Metadata, Audience, Purpose/Scope, Definitions; active voice throughout; lead sentences on all lists; Revision History | Skills maintainer | Skills maintainer |
| 2 | 2026-07-20 | IDDD-layer application: added Snapshot, Quick Reference (DTO + projection label), Related Skills with typed relationships (subagent-driven-development, executing-plans downstream; finishing-a-development-branch shared-kernel) and Translation notes; Environment Adapter note (AGENTS.md git conventions); rewritten description as specific trigger naming the failure mode; announce line verb aligned with skill name; renamed generic headings (Overview → Workspace Isolation Principle, Step 2/3 to work-speak verbs, 1a/1b to intent-revealing verbs); added Worked Example as pure VO in Given/When/Expect form; expanded each "always/never" rule with ≥2 motivating scenarios; added "Deviations" note (none); preserved all bash commands, Step 0 detection, Step 1a/1b creation, Step 2 project setup, Step 3 baseline verification, quick reference table, common mistakes, red flags; `name` unchanged. | Skills maintainer | Skills maintainer |
| 3 | 2026-08-26 | IDDD typology sweep: added type frontmatter, reordered Related Skills by category per _shared/SKILL-ARCH.md | Skills maintainer | Skills maintainer |