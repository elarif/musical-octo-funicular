---
name: using-superpowers
description: Use when starting any conversation, before any response or action — fires a skill check so the agent loads the relevant skill first, preventing the failure mode where the agent proceeds without loading a relevant skill and re-derives the correct behavior ad hoc.
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## Snapshot

This skill is the entry router for every conversation. Before any response, action, or clarifying question, scan the available-skills list, match the user's request to a skill's trigger, and announce "Using [skill] to [purpose]." Then follow that skill exactly. When multiple skills apply, load process skills (brainstorming, systematic-debugging, writing-plans) before implementation skills so the approach is set before work begins. This skill does not restate child skills' processes; it is a Service-Factory (L11.4) that translates a raw user request into the brief each child skill expects. If the same skill is announced twice in one session, the second announcement is a no-op unless new context demands re-entry. Platform-specific overrides live in `references/` and are read only when the harness matches. Subagents are exempt (SUBAGENT-STOP block).

## Quick Reference

(projection — see The Rule and Skill Priority for full rules.)

| Field | Value |
|---|---|
| Primary audience | Any agent beginning a conversation or receiving a task |
| Trigger | Any first response, action, or clarifying question in a session |
| Input | A raw user request + the available-skills list |
| Output | One announced child skill, loaded and followed; or a decision to proceed without |
| Key files | `references/codex-tools.md`, `references/pi-tools.md`, `references/antigravity-tools.md` (read only when harness matches) |
| Idempotency | Second announcement of the same skill in one session = no-op unless new context arrives |
| Stable contract | This `description` + announce line + the loaded child skill's name; internal sections may evolve |

## Related Skills

(projection — see Process: Translate Request into a Child-Skill Brief for the routing logic.)

| Sibling | Relationship | What this skill uses from it |
|---|---|---|
| `brainstorming` | downstream — loaded first for creative work | Its trigger ("Let's build X") and announce line |
| `systematic-debugging` | downstream — loaded first for bugs | Its trigger ("Fix this bug") and announce line |
| `writing-plans` | downstream — loaded first for multi-step specs | Its trigger ("plan this task") and announce line |
| `test-driven-development` | downstream — loaded before implementing features/bugfixes | Its trigger and announce line |
| `subagent-driven-development` | downstream — loaded for multi-skill sagas | Its dispatch contract (run ID, brief fields) |
| `executing-plans` | downstream — loaded to run a written plan | Its checkpoint protocol |
| `verification-before-completion` | downstream — loaded before "done" claims | Its verification command list |
| `requesting-code-review` | downstream — loaded before merge/PR | Its review-request contract |
| `technical-writing` | downstream — loaded for doc authoring | Its required-slot invariants |
| all other skills (downstream — routed on trigger match) | downstream | The match between a user request and the skill's `description` |

Translation note at each cross-skill reference: this skill does not consume sibling skill internals. It consumes only each sibling's published contract — its `description` (the trigger) and announce line. Child skills translate this skill's brief into their own internal vocabulary; no Shared Kernel is assumed.

## Role: Service-Factory

This skill is a Service-Factory (L11.4), not an index. It does not merely call other skills; it translates a raw user request into the input contract each child skill expects. Its Process (below) shows how it reshapes a raw request into the brief each child needs:

- Raw request: "let's add a login flow" → brief for `brainstorming`: goal (login flow), scope (feature design before code), constraint (no implementation yet), expected output (a written approach to hand to implementation skills).
- Raw request: "tests are failing on CI" → brief for `systematic-debugging`: symptom (CI red), where (.github/workflows output), what changed (unknown — investigate), expected output (root cause + minimal fix).
- Raw request: "write me a quick SOP for onboarding" → brief for `technical-writing`: doc type (SOP), audience (new hires), purpose (onboarding), effective date (TBD until approved).

The Factory step is the announce line. The translation is the brief the agent carries into the child skill. The child skill owns its own Process; this skill never restates it.

## Document Metadata

| Field | Value |
|---|---|
| Document ID | `SKILL-US-001` |
| Revision | 2 |
| Effective Date | 2026-07-20 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |

## Audience

The writer states the following audience attributes for this skill:

- **Primary audience**: Any agent that begins a conversation or receives a task from a human partner.
- **Secondary audience**: Maintainers who edit this skill; reviewers who audit agent behavior against it.
- **Expertise level**: Intermediate — the agent already converses with users and needs the rule that forces skill use first.
- **What they already know**: The agent can read and invoke skills from the available-skills list.
- **What they need to learn**: The single rule that governs every conversation start, the priority order of skills, and the rationalizations to reject.
- **What they will do after reading**: Run a skill check before any response or action, then follow the matched skill exactly.

## Purpose / Scope

**Purpose**: Force the agent to invoke any relevant or requested skill before any response, action, or clarifying question, and translate the raw request into the brief each child skill expects.

**Scope covers**:

- The rule that governs skill invocation at conversation start.
- The priority order when multiple skills apply.
- The rationalization thoughts the agent must reject.
- The translation step that turns a raw request into a child-skill brief.
- Platform-specific reference files the agent reads when the harness matches.

**Scope does NOT cover**:

- The content of the individual skills the agent invokes (each child owns its Process).
- Implementation guidance for a specific domain (that lives in the matched skill).
- Subagent task execution (the SUBAGENT-STOP block exempts subagents).
- User-instruction precedence rules beyond the statement in the User Instructions section.

## Definitions

The writer defines every acronym and term on first use. This section collects them in one place for reference.

| Term | Meaning |
|---|---|
| Skill | A specialized instruction set the agent loads via the `skill` tool before acting on a task. |
| Harness | The runtime environment that hosts the agent (Codex, Pi, Antigravity, or another platform). |
| Process skill | A skill that sets the approach before implementation skills run (for example, brainstorming or systematic-debugging). |
| Implementation skill | A skill that carries out a defined task (for example, frontend-design). |
| Brief | The translated input this skill hands a child skill: goal, scope, constraints, expected output. |
| Entry router | This skill's role: the first skill considered in any conversation; routes to one child skill or proceeds without. |
| Service-Factory | A service that translates foreign inputs into the local types each consumer expects (IDDD L11.4); this skill's role. |

## The Rule

**Invoke relevant or requested skills BEFORE any response or action** — including clarifying questions, exploring the codebase, or checking files. If it turns out wrong for the situation, the agent does not have to use it.

**Before entering plan mode:** if the agent has not already brainstormed, the agent invokes the `brainstorming` skill first.

The agent then announces "Using [skill] to [purpose]" and follows the skill exactly. If the skill has a checklist, the agent creates one todo per item.

This "Always invoke before responding" rule is motivated by two distinct scenarios: (1) a user asks "let's build X" and the agent starts coding without brainstorming the design, producing unmaintainable direction; (2) a user asks a "simple" question that actually requires a skill (e.g., "can you commit this?" touches git-safety skills) and the agent answers from memory, skipping the skill that enforces the safety check.

## Skill Priority

When multiple skills apply, process skills come first — they set the approach, then implementation skills (frontend-design, and others) carry it out. `brainstorming` and `systematic-debugging` are Superpowers' most common process skills, but the rule holds for any of them.

The agent handles these cases as follows:

- "Let's build X" → the agent invokes `brainstorming` first, then implementation skills. (Translation note: `brainstorming` is referenced by `name`; see its SKILL.md for its Process.)
- "Fix this bug" → the agent invokes `systematic-debugging` first, then domain skills. (Translation note: `systematic-debugging` is referenced by `name`; see its SKILL.md for its Process.)

This "process-before-implementation" rule is motivated by two distinct scenarios: (1) building a feature without a design first leads to rework when the approach is wrong; (2) debugging by trial-and-error without a systematic method leads to symptom-fixing the wrong cause.

## Red Flags

These thoughts mean STOP — the agent is rationalizing:

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for skills. |
| "Let me gather information first" | Skills tell you HOW to gather information. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "This doesn't count as a task" | Action = task. Check for skills. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
| "I know what that means" | Knowing the concept ≠ using the skill. Invoke it. |

## Process: Translate Request into a Child-Skill Brief

### Step 1: Scan the available-skills list before any response

Before producing any output (answer, question, tool call), the agent reads the available-skills list and matches the user's request against each skill's `description` trigger. The first match wins; process skills win over implementation skills when both match.

### Step 2: Translate the raw request into the child-skill brief

Once a skill matches, the agent translates the raw request into the brief that child expects: goal (what the user wants), scope (what is and isn't in this task), constraints (any stated limits), expected output (what "done" looks like). The brief is carried into the child skill, not handed to the child as the child's Process.

### Step 3: Announce the skill and follow it

The agent announces "Using [skill] to [purpose]" and follows the matched skill exactly. If the skill has a checklist, the agent creates one todo per item. The announce verb matches the skill's `name` (e.g., "Using `systematic-debugging` to find the root cause").

### Step 4: Handle the no-match case

If no skill's `description` matches the request, the agent proceeds without a skill — but states that it checked and found no match, so the decision is auditable. This is the only path that does not announce a skill.

## Platform Adaptation

If the agent's harness appears below, the agent reads the reference file for platform-specific tool mapping. These files are a Repository indexed by path (L12.1); the agent reads them on demand, never inlines their contents:

- Codex: `references/codex-tools.md` — defines Codex's multi-agent config and environment-detection signals.
- Pi: `references/pi-tools.md` — maps skill actions to Pi's available subagent and task-list tools.
- Antigravity: `references/antigravity-tools.md` — maps skill actions to the `agy` CLI's `invoke_subagent` and task-artifact model.

If the harness is none of these, the agent skips this section and proceeds with the default tool surface.

## User Instructions

User instructions (CLAUDE.md, AGENTS.md, GEMINI.md, and others, plus direct requests) take precedence over skills, which in turn override default behavior. The agent skips skill workflows or instructions only when the human partner explicitly says so.

## Idempotency

This skill is the entry router. If it fires twice in one session, the second invocation is a no-op: the skill is already loaded and the brief already translated. A deliberate re-entry is permitted only when new context arrives that changes which child skill should match (L13.5).

## Public Interface for Composition

This skill is composed by the agent harness itself, not by other skills. The harness may invoke the following, and may expect the following back (L13.4):

**The harness may invoke:**

- The Rule (the "invoke before responding" mandate).
- The Skill Priority order (process skills before implementation skills).
- The Red Flags table (the rationalizations to reject).
- The Process (translate request → brief → announce → follow).

**The harness expects back:**

- One announced child skill, loaded and followed; or
- A stated decision to proceed without a skill (with the no-match reason auditable).

Nothing else in this file is part of the public contract; internal sections may evolve without notice.

## Examples

(projection — see The Rule and Process for full rules.)

**Given** a user opening a session with "let's add a login flow," **when** the agent announces the skill, **expect** the agent invokes `brainstorming` first, announces "Using `brainstorming` to design the login flow before implementation," and hands `brainstorming` a brief containing goal (login flow), scope (design before code), and expected output (a written approach).

**Given** a user asking "tests are failing on CI," **when** the agent announces the skill, **expect** the agent invokes `systematic-debugging`, announces "Using `systematic-debugging` to find the root cause," and hands it a brief containing symptom (CI red), where (.github/workflows output), and expected output (root cause + minimal fix).

**Given** a second "let's build X" message later in the same session with no new context, **when** the agent would re-announce this skill, **expect** the second announcement is a no-op (idempotency).

## Deviations

No structural rules from the IDDD layer are broken in this revision. If a future revision deviates (e.g., inlining a reference file because a subagent cannot read the filesystem), the deviation will be recorded here with the reason (one of: UI convenience, missing mechanism, global transaction, query performance — L10.7).

## Revision History

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-07-19 | Technical-writing compliance rewrite: added Document Metadata, Audience, Purpose/Scope (with "does NOT cover"), Definitions; converted prose to active voice and present tense; added lead sentences before every list; added Revision History | Skills maintainer | Skills maintainer |
| 2 | 2026-07-20 | IDDD-layer rewrite: added Snapshot, Quick Reference (labeled projection), Related Skills with typed relationships + translation notes, Role: Service-Factory subsection (L11.4), Process (split god-method into 4 intent-revealing steps), Examples in Given/When/Expect form, Idempotency line (L13.5), Public Interface for Composition (L13.4), Deviations note (L10.7); rewrote `description` to name the failure mode (L1.5, L8.1); converted reference files to path + one-line purpose (L12.1); added "Always" rule motivating scenarios (L10.5); labeled quick-reference and Related-Skills tables as projections (LA.3) | Skills maintainer | Skills maintainer |