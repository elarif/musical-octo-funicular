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

## A. Strict Mode Header

Every bash script this skill produces or approves starts with this exact header (lines 1-3):

```bash
#!/usr/bin/env bash
set -euo pipefail
shopt -s inherit_errexit 2>/dev/null || true  # bash 4.4+; no-op on older
IFS=$'\n\t'
```

**Why each line:**

- `#!/usr/bin/env bash` — finds bash on PATH regardless of install location (works on NixOS, Homebrew, multi-distro).
- `set -euo pipefail` — `-e` exit on first error, `-u` error on unset variable expansion, `-o pipefail` propagate pipeline failures.
- `shopt -s inherit_errexit` — closes the bash trap: `set -e` is silently disabled inside `$( ... )` command substitution without it (ShellCheck SC2312 class). Requires bash 4.4+. Guarded `|| true` so older bash does not error out.
- `IFS=$'\n\t'` — word-splits only on newline and tab; never space. Prevents the classic "filename with space" corruption.

**Known exceptions (rare, must be justified in commit message):** (1) Embedded heredoc inside a Dockerfile `RUN` (no `shopt` available at parse time); (2) Makefile recipes where each line is a separate shell. Document any other exception in a comment at the offending line.

**Quoting escape hatch (bash 4.4+):** for safe serialization use `"${var@Q}"` which bash-escapes the value. Prefer it over hand-rolled `sed`-escapes.

## B. Quoting Discipline

**Always quote variable expansions.** `"$var"` — not `$var`. Word-splitting + glob expansion on unquoted expansion is the #1 shell bug class.

**Arrays:**
- Iterate array elements: `"${arr[@]}"` (each element as separate word, safe with spaces)
- Never use `${arr[*]}` unquoted — joins with IFS then re-splits
- Never use `$@` unquoted — always `"$@"`

**Capture subcommand output safely** (fixes ShellCheck SC2155):

```bash
# ❌ WRONG — masks exit code of cmd
local x
x=$(cmd)          # but written as 'local x=$(cmd)' hides SC2155

# ✅ CORRECT — declaration and assignment separated
local x
x=$(cmd)          # now $? reflects cmd's exit code
```

**Parameter expansion defaults:**

- `${var:?message}` — abort if unset, with custom error (good for required config)
- `${var:-default}` — use default if unset (does NOT mutate var)
- `${var:+alternate}` — expand to alternate only if var is set (feature flags, verbosity)
- `${#var}` — length of var (strlen equivalent)

**Heredocs:**
- `<<'EOF'` quoted delimiter — literal text, no expansion. Use for code or secrets: password variables inside stay literal.
- `<<EOF` unquoted — `$var` and `$(cmd)` expand. Use deliberately, never by accident.

## C. Modern Idioms 2026

Use these when target bash is ≥ 4.4 (default on any modern distro, macOS via Homebrew `brew install bash`).

**Conditionals — `[[ ]]` not `[ ]`:**

- `[[ -f "$file" ]]` — test builtin with no word splitting, pattern matching, safer operators
- `[[ "$a" == "$b" ]]` — string equality
- `[[ "$n" -gt 7 ]]` — numeric comparison (`-gt`, not `>` — `>` inside `[[ ]]` is locale-dependent string compare, classic bug)
- `[[ "$s" =~ ^[0-9]+$ ]]` — regex match
- Never use `[ ]` in new bash code. `[ "$var" = "x" ]` breaks on unset var and looks POSIX-by-accident.

**Arithmetic — `(( ))` not `let`:**

- `(( count++ ))` — increment
- `(( total = a + b * 2 ))` — arithmetic assignment
- `if (( n > 10 )); then` — numeric condition
- Trap: `(( i++ ))` returns exit status 1 when i=0 → kills `set -e` scripts. Use `: $(( i++ ))` or `(( ++i ))` (pre-increment never returns 0).

**Bash 5.3 forkless command substitution (2025):**

```bash
result=${ cmd; }       # runs in current shell, no fork, no subshell-loss of state
output=${| cmd; }      # same for pipelines
```

Fallback when bash < 5.3 or unclear: stick with `result=$( cmd )` — universally supported.

**Reading into arrays — `mapfile`:**

```bash
mapfile -t lines < input.txt           # replaces while-read loop
mapfile -t files < <( find . -name '*.log' -print0 | tr '\0' '\n' )
```

**NUL-delimited safe read (filenames with spaces/newlines):**

```bash
while IFS= LC_ALL=C read -r -d '' f; do
  do_something "$f"
done < <( find . -type f -print0 )
```

**Process substitution — `<( cmd )` and `>( cmd )`:**

- `<( cmd )` — capture cmd stdout as file descriptor (fd) without subshell for while loop
- `>( cmd )` — pipe into cmd stdin
- Use to avoid `cmd | while read` subshell-loss trap: `while read ... done < <( cmd )` preserves variable mutations.

**Name references (bash 4.3+):**

```bash
declare -n ref=actual_var    # ref is alias to actual_var
ref="new value"              # modifies actual_var
```

Use for: passing arrays by name to functions (`local -n arr_ref="$1"`).

**Associative arrays (bash 4+):**

```bash
declare -A config
config[host]="example.com"
config[port]="443"
for k in "${!config[@]}"; do echo "$k → ${config[$k]}"; done
```

**Timestamps (bash 5.0+):** `EPOCHSECONDS`, `EPOCHREALTIME` — use instead of `date +%s` forks.

## D. Anti-Patterns Table

Never emit, recommend, or leave unflagged any pattern on the left column. When you encounter one in existing code, refactor to the right column immediately or flag with a `⚠️` comment plus the fix.

| ❌ Forbidden | ✅ Fix | Why |
|---|---|---|
| `local x=$(cmd)` | `local x; x=$(cmd)` | SC2155 — masks subshell exit code. Caller sees success on failure. |
| `cmd file.txt > file.txt` | `cmd file.txt > tmp && mv tmp file.txt` | Shell truncates redirection target BEFORE cmd reads it. Data loss. |
| `x && y \|\| z` | `if x; then y; else z; fi` | `z` runs if `y` fails. Not equivalent to if/else. |
| `for f in $(ls)` | `for f in *` (glob) or `find . -print0` + `while read -d ''` | Parsing `ls` is fundamentally broken (filenames with spaces/newlines). |
| `` `cmd` `` | `$(cmd)` | Backticks don't nest, deprecated since 1990s POSIX. |
| `eval "$var"` | `declare -n ref="$var"` or just call function | Injection vector, uncheckable. Almost never needed. |
| `echo "$data"` with arbitrary data | `printf '%s\n' "$data"` | `echo` inconsistent across shells/args starting with `-`; `printf` portable and deterministic. |
| `[[ "$a" > "$b" ]]` for numbers | `[[ "$a" -gt "$b" ]]` or `(( a > b ))` | `>` in `[[ ]]` is locale-dependent string compare. |
| `(( i++ ))` with i=0 under `set -e` | `: $(( i++ ))` or `(( ++i ))` | Post-increment returns 1 when result was 0. Kills strict-mode script. |
| `exit 1` inside a function (non-top-level) | `return 1` | `exit` kills whole script. Caller loses control. |
| `cat file \| cmd` | `cmd < file` | Useless use of cat. Spawns extra process, loses exit code in pipefail-less mode. |
| `cd "$dir" && rm -rf ./*` | `cd "$dir" || exit` then explicit list, never `rm -rf` | If `cd` fails, `rm` runs in current dir. Disaster. |
| `while read line; do ... done <<< "$(cmd)"` | `while IFS= read -r line; do ... done < <(cmd)` | Here-string forces subshell, loses variable mutations outside loop. |
| `$*` in arguments | `"$@"` quoted | `$*` joins with IFS then re-splits. Loses structure. |
| No IFS=`read` for line splitting | `while IFS= read -r line` | Default IFS strips leading/trailing whitespace from line content. |
| `set -e` alone as "strict mode" | Header from section A | `set -e` silently disabled in `$( )` without `inherit_errexit`. |

## E. Error Handling and Traps

**`trap` on `EXIT`, not per-signal lists:**

```bash
cleanup() {
  # rm tempfiles, kill background jobs, release locks
  rm -f -- "$tmpfile"
}
trap cleanup EXIT
```

`EXIT` covers: normal completion, error under `set -e`, explicit `exit N`, and most signals (INT, TERM) because bash converts them to exit. One trap, one cleanup function.

**Inherit error traps into functions (bash 4.4+):**

```bash
set -E
trap 'report_failure "line $LINENO: exit code $?"' ERR
```

Without `-E`, an `ERR` trap does not propagate into functions, command substitutions, or subshells. Pair with `inherit_errexit` (section A) for full coverage.

**stderr logging helper (Google Shell Guide §3.1):**

```bash
err() {
  printf '[%s] ERROR: %s\n' "$(date +%Y-%m-%dT%H:%M:%S%z)" "$*" >&2
}
```

- Errors and diagnostics go to stderr (`>&2`), not stdout.
- Never interleave user data on stdout with log lines.

**Functions `return`, scripts `exit`:**

- Function: `return 1` on failure, never `exit 1` (which kills whole process).
- Top-level script only: `exit 0` / `exit 1`.

**Detect failure portably:**

```bash
if ! do_thing; then
  err "do_thing failed"
  return 1
fi
```

Avoid `do_thing || die "..."` chains — they hide the failing command's stderr and conflate "didn't run" with "failed".

**Required var checks:**

```bash
: "${CONFIG_PATH:?CONFIG_PATH must be set}"
```

Fails fast with clear message if env var absent.

**PS4 debug traces:**

```bash
PS4='+ ${BASH_SOURCE[0]}:${LINENO}: '
set -x   # trace with file+line context
```

Then `set +x` to stop. Never commit scripts with `set -x` left enabled.

## Scope Out — POSIX-sh

This skill is Bash 4.4+ opinionated. If the user's target is Alpine Linux, busybox, init.d scripts, or cross-distro packaging where `/bin/sh` may be dash, **decline or downgrade explicitly** rather than emit bash-only syntax that fails elsewhere. POSIX-sh authoring deserves a separate skill (`sh-posix-scripting`, not yet written). Mentioning `${| cmd; }`, `[[ ]]`, `mapfile`, `declare -n`, or `inherit_errexit` to a POSIX target is a violation.

---
