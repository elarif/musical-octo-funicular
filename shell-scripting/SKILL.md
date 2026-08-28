---
name: shell-scripting
description: Use when writing, editing, reviewing, or debugging a Bash 4.4+ script — emitting a script without `set -euo pipefail` and `inherit_errexit` silently hides failures, and unquoted variables split on whitespace or glob unexpected filenames in production
type: sub-skill
contracts:
  - strict-mode-header
  - quoting-discipline
  - modern-idioms-2026
  - anti-patterns-table
  - error-traps
  - tests-and-ci
---

# Shell Scripting

## The Iron Law

> **NO BASH SCRIPT WITHOUT `set -euo pipefail` AND `shopt -s inherit_errexit` IN THE FIRST THREE LINES.**

This is not a guideline. A script without strict mode silently hides failures: a command that returns 1 mid-pipeline is ignored, an unset variable expands to empty string, and `local x=$(cmd)` masks the subshell's exit code (ShellCheck SC2155). Every snippet this skill produces or reviews starts with the strict-mode header from section A. If you are about to write or quote a bash snippet without it, stop and add the header.

## Hard Gate

<HARD-GATE>
Do NOT emit, quote, review, or validate any bash script or bash snippet longer than 2 lines without first applying the strict-mode header from section A, and without scanning the snippet against the anti-patterns table (section D). This rule applies even under deadline pressure, even for "trivial" one-liners that might grow, even when the user says "skip the boilerplate".
</HARD-GATE>

This gate exists because three failure modes recur: (1) `local x=$(cmd)` masks subshell exit codes and the caller sees success on failure — SC2155; (2) `x && y || z` runs `z` when `y` fails — users read it as if/else; (3) unquoted `"$var"` word-splits on filenames with spaces — silent data corruption. The gate forces these to the surface before any shell is emitted.

## Snapshot

This skill owns the rules an agent applies when writing, editing, reviewing, or debugging a Bash 4.4+ script. It mandates the strict-mode header (set -euo pipefail + inherit_errexit + IFS), systematic quoting discipline, modern idioms 2026 (`[[ ]]`, `(( ))`, `mapfile`, process substitution, bash 5.3 forkless `${| cmd; }`), a forbidden→fix anti-patterns table, trap-based error handling, and bats-core + shellcheck testing. It is opinionated bash-only: POSIX-sh (Alpine, busybox, init.d) is out of scope and the skill will decline rather than mix syntaxes.

**Announce at start:** `I'm using the shell-scripting skill to <verb: write|edit|review|debug> this <script|snippet>.`

## Quick Reference (projection — see Content sections for full rules)

| Field | Value |
|---|---|
| Audience | Agent or engineer writing/editing/reviewing Bash 4.4+ scripts |
| Trigger | "write bash script", "edit .sh", "review shell script", "shellcheck", "why does my bash script fail silently" |
| Inputs | Script or snippet (existing or to-create); target environment hint (container Alpine vs host bash) |
| Outputs | Script with strict-mode header, quoting clean, anti-pattern-free, bats test if applicable |
| Type | sub-skill (see `_shared/SKILL-ARCH.md`) |
| Baseline | bash 4.4+ ; refuse or explicitly downgrade for POSIX-sh context |
| Iron Law | NO BASH SCRIPT WITHOUT set -euo pipefail + inherit_errexit |
| Identity | Descriptive name (`shell-scripting`); stable — do not rename |

## Related Skills

| Sibling | Relationship | What crosses the boundary |
|---|---|---|
| `using-superpowers` | `upstream` | Routes shell-authoring triggers to this skill. Translation: using-superpowers's "trigger match" = this skill's "bash task announced". |
| `writing-skills` | `shared-kernel` | Co-maintains TDD-for-skills vocabulary. This skill applied RED→GREEN→REFACTOR during its own authoring. Translation: writing-skills's "skill" = this SKILL.md. |
| `technical-writing` | `shared-kernel` | Co-maintains 4-slot discipline (Audience, Purpose/Scope, Definitions, Revision History). Changes to slot shapes flagged in both revision histories. |
| `verification-before-completion` | `downstream` | After emitting a script, this skill hands off to run `shellcheck <script>` and `bats <tests>` before claiming done. |
| `requesting-code-review` | `downstream` | Emitted scripts are artifacts for code review. |
| `_shared/glossary-en.md` | `shared-kernel` | TDD/RED/GREEN/Iron Law/Hard Gate terms live there; this skill references, never redefines. |
| `test-driven-development` | `shared-kernel` | RED/GREEN/REFACTOR discipline applies to bats tests as to code. |

## Scope Out — POSIX-sh

This skill is Bash 4.4+ opinionated. If the user's target is Alpine Linux, busybox, init.d scripts, or cross-distro packaging where `/bin/sh` may be dash, **decline or downgrade explicitly** rather than emit bash-only syntax that fails elsewhere. POSIX-sh authoring deserves a separate skill (`sh-posix-scripting`, not yet written). Mentioning `${| cmd; }`, `[[ ]]`, `mapfile`, `declare -n`, or `inherit_errexit` to a POSIX target is a violation.

---
