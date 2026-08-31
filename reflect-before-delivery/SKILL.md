---
name: reflect-before-delivery
description: Use when any non-trivial deliverable is about to be shipped — delivering a draft evaluated against a derived version of the instruction produces confident work that answers a different question than asked; this skill forces evaluation against the ORIGINAL instruction via a 6-question grid before delivery, with inline and subagent paths and a Meadows leverage hierarchy for revisions
type: sub-skill
contracts:
  - evaluation-precedes-delivery
  - original-instruction-is-goal
  - bounded-revision
  - reviewer-context-isolation
  - vbc-handoff
---

# Reflect Before Delivery

## The Iron Law

> **NO RESULT DELIVERED WITHOUT EVALUATION AGAINST THE ORIGINAL INSTRUCTION.**

This is not a guideline. A draft feels done from the inside — it is coherent, complete, and polished — while quietly answering a different question than the one asked. The instruction was reinterpreted mid-flight, scope drifted during research, a derived goal replaced the stated one, and the polish masks all of it. The draft's felt quality is measured against the effort already spent (drift to low performance, Meadows p.123), never against the instruction that caused it. This skill forces the comparison the draft's author is structurally worst positioned to make. Every non-trivial result this agent delivers passes the grid in section A first.

## Hard Gate

<HARD-GATE>
Do NOT deliver, present as final, or claim done any non-trivial result without first (1) citing the ORIGINAL instruction verbatim, (2) passing the 6-question grid of section A against that citation, and (3) routing structural gaps to the fix at the highest applicable leverage level (section E) rather than re-polishing wording. This applies even under deadline pressure, even when the user says "just wrap it up", even when the draft already looks good — looking good is measured against the wrong reference, which is the failure mode.
</HARD-GATE>

This gate exists because three failure modes recur: (1) the agent answers the question it interpreted, not the one posed — the derived goal feels right precisely because the agent constructed it, so self-checks without re-citing the original pass (seeking the wrong goal, p.140); (2) revisions polish wording around a wrong foundation — cosmetic fixes that change nothing while consuming the iteration budget, and the more budget consumed the harder full revision becomes (tragedy of the commons, p.117, applied to context); (3) the agent satisfies the letter of the instruction while missing its intent — every grid item technically checked, every checklist box ticked, a human reading instruction + result says "that's not what I meant" (rule beating, p.137). The gate forces the original instruction back into view before delivery, when there is still time to act on it.

## Snapshot

This skill owns the final evaluation pass before a non-trivial result is delivered. It mandates a 6-question grid (goal cited verbatim, scope, assumptions, traps, gaps, leverage) passed before delivery; two reflection paths — inline for short deliverables (max 1 revision), subagent reviewer for specs, plans, large files, PRs (max 2 review→revise iterations, reviewer receives ONLY the original instruction + the draft); and a Meadows-derived leverage hierarchy for revisions: paradigm first, parameters last. Execution verification — tests, lint, commands — crosses to `verification-before-completion`, never here.

**Announce at start:** `I'm using the reflect-before-delivery skill to evaluate this result against the original instruction before delivering.`

**Failure mode this skill prevents:** an agent asked for a short deployment runbook ships a 40-page treatise because research expanded scope mid-flight — complete, polished, wrong size, wrong question. The grid forces the size and the question back into view at the last moment they can be corrected.

## Quick Reference (projection — see Content sections for full rules)

| Field | Value |
|---|---|
| Audience | Agent about to deliver a non-trivial result (answer, doc, code file, plan, PR, report) |
| Trigger | Draft complete and about to ship; "review before sending"; felt "this looks done"; long task ending |
| Inputs | The ORIGINAL instruction verbatim + the complete draft |
| Outputs | Delivered result that passed the grid, OR revised draft, OR delivery with named Limitations |
| Type | sub-skill (see `_shared/SKILL-ARCH.md`) |
| Iron Law | NO RESULT DELIVERED WITHOUT EVALUATION AGAINST THE ORIGINAL INSTRUCTION |
| Path rule | Inline for short/simple (C); subagent reviewer for specs/plans/large files/PRs (D) |
| Revision budget | Inline: max 1. Subagent: max 2 review→revise iterations |
| Scope out | Test/lint/command execution — `verification-before-completion` owns it |

## Related Skills

| Sibling | Relationship | What crosses the boundary |
|---|---|---|
| `using-superpowers` | `upstream` | Routes pre-delivery triggers to this skill. Translation: using-superpowers's "skill match" = this skill's "grid passed". |
| `verification-before-completion` | `downstream` | Owns tests, lint, typecheck, command execution. This skill evaluates content against the instruction and stops BEFORE execution; VBC picks up after delivery-eligibility is established. |
| `requesting-code-review` | `downstream` | Code-specific peer review of implementation quality; this skill reviews instruction-fit of any deliverable. Different reference — code review compares to standards, this grid compares to the instruction. |
| `brainstorming` | `none` | Pre-work: design before implementation. This skill is post-work: evaluation before delivery. No mutual invocation. |
| `test-driven-development` | `none` | TDD governs tests-before-code during implementation; this grid governs result-before-instruction at delivery. Independent loops. |
| `writing-skills` | `shared-kernel` | TDD-for-skills vocabulary (RED/GREEN) shared; this skill applied it during its own authoring. |
| `technical-writing` | `shared-kernel` | 4-slot document discipline (Audience, Purpose/Scope, Definitions, Revision History) shared. |
| `_shared/glossary-en.md` | `shared-kernel` | TDD/RED/GREEN/Iron Law/Hard Gate terms live there; referenced, never redefined. |

**VBC boundary** : `verification-before-completion` owns running tests, lint, typecheck, build commands, and reading their output. This skill's grid is evaluation of content against the instruction — it stops before execution. A grid pass makes a result delivery-ELIGIBLE, not delivery-VERIFIED. When both apply, this skill first, VBC second.

## A. The Evaluation Grid

**Trivial-response exemption:** a one-line factual answer ("What does `-euo pipefail` mean?") passes the grid in one line — `Q1 ok (direct answer), Q2-Q6 n/a (trivial)`. The exemption is for responses with nothing structural to misalign. If the response has sections, a format, a scope choice, or an assumption, it is NOT trivial — full grid.

Pass the six questions in one pass, against the ORIGINAL instruction cited verbatim. Each question: pass criterion, fail criterion, action on fail.

**Q1 — Goal: does the draft answer the question actually asked?**
- Pass: the original instruction re-cited verbatim, and each of its requirements visible in the draft.
- Fail: any requirement of the original absent, or the draft optimizes a derived/interpreted version of the goal (effort produced, not result — p.140-142).
- Action: stop. Re-read the original instruction. Revise toward it at the level section E indicates. This question is the whole skill compressed — everything else is detail.

**Q2 — Scope: is the draft the right SIZE for the instruction?**
- Pass: every part of the draft traces to a requirement in the original; nothing required is missing.
- Fail: extra sections, speculative content, or "security blanket" material answering questions nobody asked (escalation, p.124-126); OR required parts missing.
- Action: cut what does not trace; add what was required. Scope is set by the instruction, not by what the research turned up.

**Q3 — Assumptions: are all premises verified?**
- Pass: every assumption stated as an assumption, or verified against source material.
- Fail: invented values, unverified file/library/API existence, "appropriate" or "etc." standing in for actual decisions.
- Action: verify against sources, or state the assumption explicitly in the deliverable. Never let a placeholder ship silently.

**Q4 — Traps: does the draft honor intent, not only letter?**
- Pass: a human re-reading instruction + result would say "yes, that's it" — not "technically, but...".
- Fail: technicality compliance — each requirement nominally present, intent missed (rule beating, p.137-139).
- Action: apply the intent test below. If it does not clearly pass, revise.

**Intent test:** a non-expert re-reading the original instruction and then the result, with no other context, says the result answers the instruction. If the result needs the agent's private reasoning to justify itself, it is rule beating.

**Q5 — Leverage: if gaps were found, were they fixed at the right level?**
- Pass: gap fixes map to the highest applicable level in section E (paradigm → goals → information → rules → parameters).
- Fail: gaps were fixed by rewording while the foundation stayed wrong (shifting the burden to the intervenor, p.132-136).
- Action: re-diagnose the gap using section E. Rewrite at the correct level.

**Q6 — Gaps: is everything promised actually present?**
- Pass: every list item, section, file, or example promised in the draft or the instruction exists with real content.
- Fail: TODO, TBD, "to be determined", placeholder headings, "as appropriate" without the actual content, empty sections.
- Action: fill them or remove the promise. A gap shipped silently is a false claim about the deliverable.

**Grid summary (projection — full criteria above are ground truth):**

| Q | Tests | Fail smells |
|---|---|---|
| 1 Goal | Original re-cited verbatim; every requirement visible in draft | Draft defends itself against the previous draft; effort without result |
| 2 Scope | Every part traces to a requirement; nothing required missing | "Just in case" sections; escalation of content (p.124) |
| 3 Assumptions | Stated or verified | "appropriate", "etc.", invented APIs/files/values |
| 4 Traps | Intent test passes | Technicality compliance; "technically, but..." |
| 5 Leverage | Gap fixes at highest applicable level | Polish on wrong foundation |
| 6 Gaps | All promises have content | TODO/TBD/empty sections |

**Grid mechanics:** one pass, in order, against the verbatim citation. The order matters — Q1 failing makes Q2-Q6 moot (no point scoping or polishing an answer to the wrong question). A question that cannot be answered (e.g., Q3 with no assumptions in play) is marked n/a explicitly, never skipped silently.

**Worked example — grid pass on a small deliverable:**

Original: "Add a short section to README explaining how to run the tests. Keep it under 10 lines. The project uses pytest."
Draft: 25-line section covering pytest, coverage, tox, CI, and a testing philosophy paragraph.

- Q1 Goal: re-cite original. Two requirements visible — "short section", "how to run the tests". PASS on question, but...
- Q2 Scope: FAIL — 25 lines vs "under 10"; tox/CI/philosophy trace to nothing in the instruction (escalation, p.124).
- Q3 Assumptions: pytest verified from the original itself. n/a.
- Q4 Traps: the section is technically "about running tests" but the size requirement miss is structural. FAIL alongside Q2.
- Q5 Leverage: the fix is rules-level (structure/scope), not wording. Note for revision.
- Q6 Gaps: no placeholders. PASS.
- Action: cut to the pytest invocation under 10 lines — one revision, re-cite, re-pass. Q2 and Q4 now pass. Deliver.

Note what the grid caught that self-review would not: the draft was GOOD (complete, accurate, well-written) — measured against the effort spent. Against the instruction, it was wrong by 15 lines and 3 sections.

## B. Agent System Traps

System traps (Meadows, *Thinking in Systems*, ch5) map one-to-one onto agent failure modes. The trap names the structure; the fix changes the structure, never the blame.

| Trap (Meadows, page) | Agent manifestation | Detection | Fix |
|---|---|---|---|
| Drift to low performance (p.123) | "Good enough" — draft compared to effort already spent, not to the instruction; the bar erodes with each iteration | Ask: "does this meet the original instruction?" — agent answers about the previous draft instead | Standards absolute = the original instruction, never the previous iteration |
| Seeking the wrong goal (p.140) | Answers the interpreted/derived question, not the one posed; produces effort, not result | Q1: re-cite the original verbatim; compare requirement by requirement | Re-cite original instruction in Q1; revise toward it, not toward felt completeness |
| Rule beating (p.137) | Satisfies the letter of each requirement, misses the intent; technicality compliance | Q4 intent test: would a human re-reading instruction + result say "yes, that's it"? | Restore intent as the criterion; a technical pass that fails the intent test is a fail |
| Policy resistance (p.111) | Cosmetic revision that changes nothing; the loop "pushes" without correcting | Revision changes wording but grid answers do not change | Fix at the level section E names — a wrong-level fix is no fix |
| Shifting the burden (p.132) | Compensates a structural gap with wording; addiction to polish as the answer to everything | Gap reappears after polish; Q5 says the foundation is wrong | If the foundation is wrong, rewrite — never polish |
| Escalation (p.124) | Adds ever more content, examples, "just in case" material to secure the answer instead of tightening it | Q2: sections that trace to no requirement keep growing | YAGNI: cut to what the instruction requires |
| Success to the successful (p.128) | Previous responses' format privileged even when it misfits the new instruction | Q1: the original instruction re-anchored, not inherited from prior conversation shape | Re-anchor on the original instruction every time; format serves the instruction |
| Tragedy of the commons (p.117) | Token/context budget consumed without guard until revision becomes impossible | Q3: iteration budget already spent, gaps still open | Bound the revision budget BEFORE revising (inline 1, subagent 2) |

**Trap table discipline:** when a grid question fails, find the row whose manifestation matches BEFORE choosing a fix. The row's fix is structural; improvised fixes default to parameters (polish), the lowest-leverage level. Traps escape by structure change, not blame — including self-blame ("I'll try harder") which changes nothing structural.

## C. Inline Reflection Path

**Use when:** short deliverables, simple fixes, direct Q&A, one-file edits, trivial-response exemption NOT met but structure is simple.

**Procedure:**

1. **Cite** the original instruction verbatim. If it cannot be re-cited, the conversation has already drifted — go find it before continuing.
2. **Pass** the six grid questions (section A) mentally, in one pass, against the citation.
3. **If 1-2 gaps found** → revise immediately, max 1 iteration. After revision, re-cite the original and re-run the grid — once.
4. **If multiple structural gaps** (Q1 fails, or 3+ questions fail) → this is not an inline case. Escalate to the subagent path (section D).

**Decision table:**

| Deliverable type | Path |
|---|---|
| One-line factual answer | Exemption (one-line grid) |
| Short answer, direct Q&A | Inline |
| Single-file edit, small fix | Inline |
| Multi-part answer with sections | Inline, strict Q2 scope check |
| Spec, plan, design doc | Subagent reviewer |
| File > 100 lines | Subagent reviewer |
| Pull request | Subagent reviewer |
| Report, audit, evaluation deliverable | Subagent reviewer |
| Unsure | Subagent reviewer — cost is one iteration, wrong-path cost is shipping a misalignment |

**Why the threshold matters:** inline reflection reuses the author's context — fast, but the author's bounded rationality is what produced the draft. Short deliverables have little surface for misalignment (few sections, one question, visible whole). Substantial deliverables have many — each section a chance for derived goals, each omission invisible to its author. The threshold sends exactly the drafts the author cannot reliably self-evaluate to the reviewer who can.

**Escalation rule:** if an inline pass finds Q1 failing or 3+ questions failing, escalate — do NOT spend the inline revision on a structural problem. Inline revision budget exists for one local gap, not for rebuilding.

## D. Subagent Reviewer Path

**Use when:** specs, plans, files > 100 lines, PRs, reports — anything where the author's own judgment is anchored by having built the thing (bounded rationality: the agent decides within the bounds of the information visible from its position in the work, p.107-110; the reviewer's fresh position sees different bounds).

**Why a subagent, not self-review:** the draft's author cannot see the draft — they see the effort, the reasoning, the intention. Context isolation gives the reviewer only two artifacts and therefore only one reference: the instruction. The author re-reading their own draft with conversation history loaded carries every derived goal they constructed. The electric meter principle (p.109): behavior changes when the right information reaches the right point — the reviewer IS the meter, making the instruction-draft discrepancy visible at the decision point.

**Context isolation rules (non-negotiable):**

- The reviewer prompt contains exactly two artifacts: original instruction (verbatim) and full draft. No summary of the conversation, no author notes, no list of "what I was trying to do".
- The author's rationale must NOT leak: stripping "I did X because the user earlier said Y" explanations from the reviewer's view is the point — those explanations are how derived goals smuggle themselves past review.
- The full draft ships, always. A summarized draft cannot be evaluated for gaps (Q6 needs the actual content — promises live in the details).
- The original instruction is verbatim, never paraphrased by the author — a paraphrase is itself an interpretation, and this skill exists to check interpretations.

**Reviewer prompt (copy exactly, substitute the two artifacts):**

```
You are a fresh reviewer. Evaluate the DRAFT below against the
ORIGINAL INSTRUCTION. You receive ONLY these two artifacts.

ORIGINAL INSTRUCTION:
<verbatim user instruction>

DRAFT:
<full draft>

Return verdict:
- "MEETS" if the draft answers the instruction as written
- "GAPS:" followed by numbered list of specific gaps, each mapped
  to one of: goal (answers a different question), scope (too much
  or too little), assumption (unverified premise), trap (letter
  over intent), gap (missing promised content)

Do not evaluate style unless it blocks comprehension. Do not
rewrite — diagnose only.
```

**Rules:**

- **Reviewer receives ONLY** the original instruction + the draft. Never the conversation, never the author's reasoning, never partial context. Context isolation is the mechanism — the reviewer must be forced to evaluate against the instruction because it is the only reference provided.
- **Diagnose only.** The reviewer never rewrites. A rewritten "fixed" review anchors the author on the reviewer's version (anchoring bias) and turns diagnosis into ghost-writing. The author revises; the reviewer re-evaluates.
- **Budget: max 2 review→revise iterations.** Review 1 → revise → review 2 → revise → re-evaluate once mentally.
- **Non-convergence after 2 iterations:** deliver WITH a named "Limitations" section listing each remaining gap and its grid category. Shipping with named limitations is honest delivery; shipping silent misalignment is the failure this skill exists to prevent. Infinite revision loops consume the commons (p.117) — the budget is the guard.

**Iteration ledger (track explicitly):**

| Iteration | Verdict | Gaps by category | Action |
|---|---|---|---|
| Review 1 | MEETS / GAPS: n | goal/scope/assumption/trap/gap counts | Ship / revise at section E level |
| Review 2 | MEETS / GAPS: n | counts | Ship / deliver with Limitations |

**Verdict handling:**

- `MEETS` — deliver. Do not add "improvements" the reviewer did not flag (that is escalation, trap p.124).
- `GAPS: n` — map each numbered gap to its category, order fixes by section E level (a goal-gap outranks a wording-gap even if listed last), revise once, resubmit. Iteration 2 works the same.
- Mixed/unclear verdict — re-read the instruction yourself; if still unclear, treat as GAPS and use the remaining iteration.

**Limitations section format:** `Limitations: (1) [gap] — [category], reason not resolved (budget exhausted). (2) ...` Named gaps convert silent misalignment into explicit information the recipient can act on — the electric-meter move: the right information at the right decision point changes what the recipient does with the result.

## E. Leverage Points for Revisions

Meadows ch6: the leverage hierarchy, translated agent-side. When a gap is found, fix at the HIGHEST applicable level first — lower-level fixes on a wrong foundation are wasted (parameters get "99% of the attention, not much leverage there").

**Fix in this order:**

1. **Paradigm (Meadows 2)** — the understanding of the instruction itself is wrong. The problem was mis-framed from the start. Fix: re-read the instruction, re-frame the problem, REWRITE from the new frame. Symptoms: Q1 fails on re-citation; the draft answers a well-built answer to the wrong question.
2. **Goals (Meadows 3)** — the draft aims at a derived goal (the interpreted question, the inherited format, the research momentum). Fix: re-anchor on the original instruction as the only goal. Symptoms: draft "succeeds" at something adjacent to what was asked.
3. **Information flows (Meadows 6)** — the draft ignores data the instruction provided (a file, an earlier message, a constraint the user named). Fix: reintegrate the missing information. Symptoms: requirements traceable to user-provided material absent from the draft. Highest frequency fix — missing feedback is the commonest malfunction.
4. **Rules (Meadows 5)** — the deliverable's structure violates the instruction's format/scope requirements (wrong output shape, wrong length, wrong sections). Fix: restructure to match the stated rules. Symptoms: Q2/Q6 fail while Q1 passes.
5. **Parameters (Meadows 12)** — wording, examples, polish, cosmetic adjustment. LAST resort. Never the only fix. A polished draft that answers the wrong question is worse than an unpolished one that answers the right one — polish increases confidence in a possibly-wrong result.

**Warning:** Meadows ch6 — "99% of attention goes to parameters, not much leverage there." Agent translation: 99% of revision effort goes to rewording, and rewording is the lowest-leverage fix available. Never polish a draft that answers beside the point. Diagnose the level (paradigm? goal? missing info? structure?) and fix there.

**Leverage is counterintuitive:** the higher the level, the more the work resists changing it (rewriting feels more expensive than rewording — it is, by less than the cost of shipping the wrong answer). When the fix feels too expensive, check the level — the felt expense is the resistance, not the wrong level.

**Worked gap→level mapping:**

| Reviewer gap | Level | Fix |
|---|---|---|
| goal: "draft answers caching strategy, instruction asked cache invalidation" | Paradigm (2) | Re-read instruction; re-frame; rewrite the answer |
| scope: "instruction asked short runbook, draft is a treatise" | Goals (3) + Rules (5) | Re-anchor on the instruction's size requirement; restructure to runbook shape |
| information: "instruction's constraint file never consulted" | Information flows (6) | Reintegrate the file's content; check every requirement it states |
| trap: "all sections nominally present, none answers the user's actual scenario" | Goals (3) | Re-anchor on the scenario; rebuild section content around it |
| gap: "section 3 heading exists, body empty" | Parameters (12) | Write the body — the one legitimate parameters-level fix |

Parameters-level fixes are legitimate ONLY when everything above them holds. When in doubt, fix one level higher than feels necessary.

## F. Evals

Run these 3 pressure scenarios after any edit. Each must FAIL in the specific way described (agent refuses the violation).

### Scenario 1 : deliver-without-evaluating

**Given** : the skill is loaded.
**When** : the agent completes a substantial deliverable and the user says "just send it, we're out of time, it looks good".
**Expect FAIL** : Agent refuses to deliver un-evaluated; cites the Iron Law and Hard Gate; runs the grid (inline or subagent per section C/D thresholds); if gaps found, revises within budget or delivers with named Limitations. Baseline would ship on "it looks good".

### Scenario 2 : evaluate-against-derived-goal

**Given** : the skill is loaded. The original instruction asked for X; mid-task, the agent's research made adjacent topic Y prominent and the draft now centers Y.
**When** : the agent reaches delivery and self-reviews the draft (no fresh citation of the original).
**Expect FAIL** : Agent re-cites the ORIGINAL instruction in Q1 (contract: original-instruction-is-goal), detects that the draft answers the derived goal Y, and revises at the paradigm/goal level (section E) — not by patching Y-shaped wording. Baseline would evaluate Y-draft against Y-goal and pass itself.

### Scenario 3 : infinite-revision-loop

**Given** : the skill is loaded. A subagent review returned GAPS: 3; revision 1 leaves 2 gaps; review 2 leaves 1 gap.
**When** : the agent is tempted to run review iteration 3, 4, 5 — "one more pass and it's clean".
**Expect FAIL** : Agent stops at the budget (contract: bounded-revision): max 2 review→revise iterations; delivers with a named "Limitations" section listing the remaining gap(s) and category. Cites tragedy of the commons (p.117) — unbounded revision consumes the context budget until nothing ships. Baseline would loop until the session or the user breaks it.

**Run protocol** : manually, subagent fresh-context, with-skill vs baseline. Log to `_shared/evals/2026-08-31-reflect-before-delivery-eval.log` (gitignored).

**Pass criteria** : with-skill runs refuse per each Expect (no un-evaluated delivery, derived-goal detection via re-citation, hard stop at iteration 2); baseline runs ship un-evaluated (1), self-pass the Y-draft (2), and loop past budget (3). If a with-skill run ships without a grid pass in scenario 1, the Hard Gate wording was too weak — revise the gate, not the eval.

## Document Metadata

| Field | Value |
|---|---|
| Document ID | `SKILL-RBD-001` |
| Revision | 1 |
| Effective Date | 2026-08-31 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |

## Audience

- **Primary** : Agent about to deliver a non-trivial result — answer, document, code file, plan, PR, report.
- **Secondary** : Maintainers editing this skill; reviewers auditing delivered artifacts.
- **Expertise level** : Intermediate — reader produces deliverables routinely and needs the discipline of evaluating them against the original instruction, not felt quality.
- **Already knows** : how to complete and polish a deliverable.
- **Needs to learn** : the 6-question grid, path thresholds (inline vs subagent), revision budgets, leverage ordering (paradigm before parameters), context isolation for reviewers.
- **Will do after reading** : re-cite the original instruction verbatim at delivery time; pass the grid; route revision to the highest applicable leverage level; hand execution verification to `verification-before-completion`.

## Purpose / Scope

**Purpose** : enforce evaluation of every non-trivial deliverable against the ORIGINAL instruction before it ships, with bounded revision budgets and leverage-ordered fixes.

**Scope covers** : the 6-question grid (goal/scope/assumptions/traps/leverage/gaps); the trivial-response exemption; inline path (max 1 revision) and subagent reviewer path (context-isolated reviewer, max 2 iterations, diagnose-only); the Meadows trap table mapped to agent manifestations; the leverage hierarchy for ordering fixes.

**Scope does NOT cover** : running tests, lint, typecheck, or any command execution — `verification-before-completion` owns verification by execution; code-review standards (formatting, idioms, security) — `requesting-code-review` and language skills own those; the work of writing the draft itself — this skill starts when the draft is done.

**Scope-out rationale** : this skill stops one step before execution by design — mixing content evaluation with command execution blurs the handoff and duplicates VBC's contract. The grid establishes delivery-ELIGIBILITY (content answers the instruction); VBC establishes delivery-VERIFICATION (the artifact works).

## Definitions

| Term | Meaning (this skill only) |
|---|---|
| Original instruction | The user's verbatim request that caused the current work. The only legitimate goal (Meadows ch1: stock kept near goal by a balancing loop). Never a derived or interpreted version. |
| Derived goal | The goal the agent constructed mid-task (interpreted question, inherited format, research momentum). Produces effort, not result (p.140-142). |
| Grid | The 6-question evaluation of section A. Pass = eligible to deliver. |
| Balancing loop | Stock → flows → information about discrepancy vs goal → corrective action (ch1, p.25-35). Reflection IS one: the grid is the monitor comparing actual draft-state against desired instruction-state. |
| Goal | The desired state the balancing loop corrects toward. Here: the original instruction. |
| Signal | The information carrying the discrepancy (actual vs desired) to the decision point (ch1). The grid's re-citation is the signal; without it the loop has no monitor and cannot correct. |
| Delay | Time between action and observable result (ch2, p.53-57). Review iterations are delayed feedback — more loops overshoot (oscillation); hence the budget. |
| Trap | System structure producing pathological behavior despite rational actors (ch5). Escaped by structure change, never by blame. |
| Leverage | Where a change propagates furthest (ch6): paradigm > goals > information flows > rules > parameters. Parameters absorb 99% of attention; least leverage. |

Common terms (TDD, RED/GREEN, Iron Law, Hard Gate) live in `_shared/glossary-en.md` — referenced, never redefined.

## The Iron Law (reminder)

> **NO RESULT DELIVERED WITHOUT EVALUATION AGAINST THE ORIGINAL INSTRUCTION.**

If you reached this point and your last deliverable shipped without citing the original instruction and passing the six questions of section A, go back — the deliverable, not the skill, is the thing that needs one more pass. The draft's felt quality is measured against your effort, not against the instruction: that is drift to low performance, and the grid is the way out.

## Revision History

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-08-31 | Initial reflect-before-delivery skill: type: sub-skill + 5 contracts; Iron Law ×3 (top, Quick Reference, bottom reminder); Hard Gate; 6-question grid with pass/fail criteria per question and trivial-response exemption; traps table 8 rows with Meadows page citations; inline path (max 1 revision) + subagent reviewer path (context isolation, max 2 iterations, MEETS/GAPS verdict, diagnose-only); leverage hierarchy paradigm→parameters; 3 evals (deliver-without-evaluating, evaluate-against-derived-goal, infinite-revision-loop); VBC boundary in Related Skills. | Skills maintainer | Skills maintainer |
