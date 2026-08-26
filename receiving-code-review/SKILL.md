---
name: receiving-code-review
description: Use when code review feedback arrives and the agent must decide whether to implement it — prevents performative agreement that ships unverified changes
type: sub-skill
---

# Code Review Reception

> **Snapshot** — An agent facing review feedback must verify each item against the codebase before acting, refuse to perform agreement ("You're absolutely right!"), and push back with technical reasoning when a suggestion is wrong, unclear, or breaks existing behavior. This skill owns the six-step response protocol (READ → UNDERSTAND → VERIFY → EVALUATE → RESPOND → IMPLEMENT), the forbidden responses, the push-back conditions, and the YAGNI check. It is the protocol a parent skill (e.g., `subagent-driven-development`'s task reviewer) invokes when a review event fires. Read this snapshot to begin; read the body for depth.

**Announce:** Receive code review feedback by verifying each item against the codebase before implementing any of it.

## Quick Reference (projection — see Process for full rules)

| Field | Value |
|---|---|
| Audience | Agents receiving review feedback |
| Triggers | Review feedback received; external reviewer comment; partner "Fix items" request |
| Inputs | Review feedback (items, source) |
| Outputs | Technical acknowledgment OR reasoned pushback; implemented fix |
| Key sections | Response Pattern, Forbidden Responses, Push-Back Rules, YAGNI Check |
| Stable contract | `description` + Response Pattern + Forbidden Responses + Push-Back Rules |
| Composable by | `subagent-driven-development` (task review), `verification-before-completion` (evidence-before-claims) |

## Related Skills

| Sibling | Relationship | Translation (what arrives → what this skill calls it) |
|---|---|---|
| `verification-before-completion` | `shared-kernel` — both enforce "evidence before claims"; co-maintain the verification vocabulary (verify, check, evidence) | Shared terms: "verify", "evidence". Changes require flagging both revision histories. |
| `subagent-driven-development` | `downstream` — SDD's task-review step invokes this skill's Response Pattern when reviewing a subagent's output | Inbound: a task-review event. This skill calls it a "review item" and applies the 6-step protocol. |
| `requesting-code-review` | `conformist` — this skill receives what that skill produces; same team, adopts its review-item vocabulary wholesale | No translation: shared review vocabulary (review item, feedback, pushback). This skill speaks the same terms. |

*Cap: 3 of ~10 entries. Informal map, not a formal taxonomy — keep current over complete.*

## Document Metadata

| Field | Value |
|---|---|
| Document ID | `SKILL-RCR-001` |
| Revision | 2 |
| Effective Date | 2026-07-19 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |

## Audience

The writer states the following audience attributes before applying this skill:

- **Primary audience**: Any agent that receives code review feedback and decides whether to implement it.
- **Secondary audience**: The agent's human partner who reviews the agent's responses; external reviewers who read the agent's replies.
- **Expertise level**: Intermediate — the agent writes code already and needs the rules that prevent performative agreement and blind implementation.
- **What they already know**: The agent can read review feedback and edit code.
- **What they need to learn**: The verification pattern, push-back rules, and forbidden responses that keep reviews technically rigorous.
- **What they will do after reading**: Apply the response pattern to evaluate each review item before implementing it.

## Purpose / Scope

**Purpose**: This skill gives the agent the rules it follows when it receives code review feedback, so the agent verifies each item against the codebase before it acts.

**Scope covers**:

- The response pattern the agent follows for every review item.
- The forbidden responses and the accepted alternatives.
- Handling of unclear feedback and source-specific handling.
- The YAGNI check, implementation order, and push-back rules.
- Real examples and GitHub thread replies.
- The public interface a parent skill invokes when composing this skill.

**Scope does NOT cover**:

- How the agent writes code (governed by code conventions).
- How the agent runs tests (governed by the test runner skill).
- How the agent commits changes (governed by the git workflow skill).

## Definitions

The agent defines every acronym on first use. This section collects them in one place for reference.

| Term | Meaning |
|---|---|
| Review item | One discrete piece of review feedback the agent must evaluate and act on |
| Pushback | A reasoned technical objection to a review item, with evidence |
| Performative agreement | Agreement expressed as social performance ("You're absolutely right!") without prior verification |
| YAGNI | You Aren't Gonna Need It — the rule that the agent does not add features the codebase does not use |
| your human partner | The human the agent reports to; source of trusted feedback and architectural decisions |

## Reception Discipline

Code review requires technical evaluation, not emotional performance.

**Core principle:** The agent verifies before it implements. The agent asks before it assumes. Technical correctness over social comfort.

## The Response Pattern

```
WHEN receiving code review feedback:

1. READ: Complete feedback without reacting
2. UNDERSTAND: Restate requirement in own words (or ask)
3. VERIFY: Check against codebase reality
4. EVALUATE: Technically sound for THIS codebase?
5. RESPOND: Technical acknowledgment or reasoned pushback
6. IMPLEMENT: One item at a time, test each
```

## Forbidden Responses

These rules are `Always` rules. Each is motivated by at least two distinct scenarios: (a) performative agreement ships unverified changes the reviewer never asked to be merged blindly; (b) social performance substitutes for the technical evaluation the review actually needs.

**NEVER:**
- "You're absolutely right!" (explicit instruction-file violation)
- "Great point!" / "Excellent feedback!" (performative)
- "Let me implement that now" (before verification)

**INSTEAD:**
- Restate the technical requirement
- Ask clarifying questions
- Push back with technical reasoning if wrong
- Just start working (actions > words)

## Handling Unclear Feedback

```
IF any item is unclear:
  STOP - do not implement anything yet
  ASK for clarification on unclear items

WHY: Items may be related. Partial understanding = wrong implementation.
```

**Example:**
```
your human partner: "Fix 1-6"
You understand 1,2,3,6. Unclear on 4,5.

❌ WRONG: Implement 1,2,3,6 now, ask about 4,5 later
✅ RIGHT: "I understand items 1,2,3,6. Need clarification on 4 and 5 before proceeding."
```

## Source-Specific Handling

### From your human partner

The agent applies the following handling to feedback from its human partner:

- **Trusted** - implement after understanding
- **Still ask** if scope unclear
- **No performative agreement**
- **Skip to action** or technical acknowledgment

### From External Reviewers

The agent performs the following checks before it implements any feedback from an external reviewer:
```
BEFORE implementing:
  1. Check: Technically correct for THIS codebase?
  2. Check: Breaks existing functionality?
  3. Check: Reason for current implementation?
  4. Check: Works on all platforms/versions?
  5. Check: Does reviewer understand full context?

IF suggestion seems wrong:
  Push back with technical reasoning

IF can't easily verify:
  Say so: "I can't verify this without [X]. Should I [investigate/ask/proceed]?"

IF conflicts with your human partner's prior decisions:
  Stop and discuss with your human partner first
```

**your human partner's rule:** "External feedback - be skeptical, but check carefully"

## YAGNI Check for "Professional" Features

```
IF reviewer suggests "implementing properly":
  grep codebase for actual usage

  IF unused: "This endpoint isn't called. Remove it (YAGNI)?"
  IF used: Then implement properly
```

**your human partner's rule:** "You and reviewer both report to me. If we don't need this feature, don't add it."

## Implementation Order

```
FOR multi-item feedback:
  1. Clarify anything unclear FIRST
  2. Then implement in this order:
     - Blocking issues (breaks, security)
     - Simple fixes (typos, imports)
     - Complex fixes (refactoring, logic)
  3. Test each fix individually
  4. Verify no regressions
```

## When To Push Back

The agent pushes back when any of the following conditions holds (each motivated by recurring scenarios: suggestions that broke existing tests, suggestions from reviewers who lacked multi-platform context, suggestions that added unused features, suggestions incompatible with the stack's legacy constraints):
- Suggestion breaks existing functionality
- Reviewer lacks full context
- Violates YAGNI (unused feature)
- Technically incorrect for this stack
- Legacy/compatibility reasons exist
- Conflicts with your human partner's architectural decisions

**How to push back:**
- Use technical reasoning, not defensiveness
- Ask specific questions
- Reference working tests/code
- Involve your human partner if architectural

**If you're uncomfortable pushing back out loud:** Name that tension, then tell your partner about the issue you've seen. They'll appreciate your honesty.

## Acknowledging Correct Feedback

When feedback IS correct:
```
✅ "Fixed. [Brief description of what changed]"
✅ "Good catch - [specific issue]. Fixed in [location]."
✅ [Just fix it and show in the code]

❌ "You're absolutely right!"
❌ "Great point!"
❌ "Thanks for catching that!"
❌ "Thanks for [anything]"
❌ ANY gratitude expression
```

**Why no thanks:** Actions speak. Just fix it. The code itself shows you heard the feedback.

**If you catch yourself about to write "Thanks":** DELETE IT. State the fix instead.

## Gracefully Correcting Your Pushback

If you pushed back and were wrong:
```
✅ "You were right - I checked [X] and it does [Y]. Implementing now."
✅ "Verified this and you're correct. My initial understanding was wrong because [reason]. Fixing."

❌ Long apology
❌ Defending why you pushed back
❌ Over-explaining
```

State the correction factually and move on.

## Common Mistakes (projection — see Process for full rules)

| Mistake | Fix |
|---------|-----|
| Performative agreement | State requirement or just act |
| Blind implementation | Verify against codebase first |
| Batch without testing | One at a time, test each |
| Assuming reviewer is right | Check if breaks things |
| Avoiding pushback | Technical correctness > comfort |
| Partial implementation | Clarify all items first |
| Can't verify, proceed anyway | State limitation, ask for direction |

## Real Examples

**Given / When / Expect (canonical trace — the skill's self-test):**
- **Given** a reviewer suggests "Remove legacy code"
- **When** the agent receives the feedback
- **Expect** the agent verifies the build target and API requirements before acting, then replies: "Checking... build target is 10.15+, this API needs 13+. Need legacy for backward compat. Current impl has wrong bundle ID - fix it or drop pre-13 support?"

**Performative Agreement (Bad):**
```
Reviewer: "Remove legacy code"
❌ "You're absolutely right! Let me remove that..."
```

**Technical Verification (Good):**
```
Reviewer: "Remove legacy code"
✅ "Checking... build target is 10.15+, this API needs 13+. Need legacy for backward compat. Current impl has wrong bundle ID - fix it or drop pre-13 support?"
```

**YAGNI (Good):**
```
Reviewer: "Implement proper metrics tracking with database, date filters, CSV export"
✅ "Grepped codebase - nothing calls this endpoint. Remove it (YAGNI)? Or is there usage I'm missing?"
```

**Unclear Item (Good):**
```
your human partner: "Fix items 1-6"
You understand 1,2,3,6. Unclear on 4,5.
✅ "Understand 1,2,3,6. Need clarification on 4 and 5 before implementing."
```

## GitHub Thread Replies

When the agent replies to inline review comments on GitHub, the agent replies in the comment thread (`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a top-level PR comment.

## Public Interface for Composition

This skill is a sub-skill: a parent skill (e.g., `subagent-driven-development`'s task reviewer) may invoke it when a review event fires. The public surface is thin; the body is private.

**A parent skill may invoke:**
- **The Response Pattern** — the 6-step protocol (READ → UNDERSTAND → VERIFY → EVALUATE → RESPOND → IMPLEMENT) applied to each review item.
- **The Forbidden Responses** — the constraint that no performative agreement ("You're absolutely right!") and no pre-verification implementation ("Let me implement that now") is emitted.
- **The Push-Back Rules** — the conditions list and the "how to push back" protocol.

**A parent skill expects back:**
- A technical acknowledgment ("Fixed. [description]") OR a reasoned pushback ("Checking... [verification result]. [question or counter]").
- One item implemented and tested at a time; no batch-and-hope.
- A version/timestamp on any output artifact so the orchestrator can detect stale handoffs.

**A parent skill must NOT:**
- Restate this skill's Process (delegate by `name` — see `subagent-driven-development`).
- Bypass the VERIFY step.
- Accept performative agreement as a valid response.

*Stable contract: only the `description`, the Response Pattern, the Forbidden Responses, and the Push-Back Rules are public. All other sections (Examples, Common Mistakes, Source-Specific Handling) are implementation detail and may change.*

## Reception Discipline (Bottom Line)

**External feedback = suggestions to evaluate, not orders to follow.**

Verify. Question. Then implement.

No performative agreement. Technical rigor always.

## Revision History

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-07-19 | Initial technical-writing-compliant rewrite: added Document Metadata, Audience, Purpose/Scope (with "does NOT cover"), Definitions (YAGNI), active voice throughout, lead sentences on all lists, Revision History | Skills team | Skills maintainer |
| 2 | 2026-07-19 | IDDD layer: added Snapshot, Quick Reference (projection-labeled), Related Skills (typed: conformist/downstream/shared-kernel + Translation notes), Public Interface for Composition; rewrote `description` to name the failure mode (performative agreement ships unverified changes); added announce line; renamed generic headings (Overview→Reception Discipline, Common Mistakes→projection, The Bottom Line→Reception Discipline); converted one Real Example to Given/When/Expect; expanded Definitions to cover Review item/Pushback/Performative agreement; cited ≥2 motivating scenarios for Always/When rules (Forbidden Responses, When To Push Back); labeled projections. Deviations: none — no structural rules broken. | Skills team | Skills maintainer |
| 3 | 2026-08-26 | IDDD typology sweep: added type frontmatter, reordered Related Skills by category per _shared/SKILL-ARCH.md | Skills maintainer | Skills maintainer |