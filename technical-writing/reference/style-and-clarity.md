# Style & Clarity — Heavy Reference

Detail backing the **Writing Craft** and **Formatting & Tooling** contexts of `technical-writing`. Read this when you are drafting or revising prose.

## 1. Active Voice — Default

Procedures, descriptions of actions, and event reports use **active voice, present tense**.

| ❌ Passive | ✅ Active |
|---|---|
| "The line was stopped by the operator at 14:35." | "Operator stops the line at 14:35." |
| "Cleaning is performed by operators at the start of each shift." | "Operators clean the line at the start of each shift." |
| "Records must be retained for 3 years." | "QA retains records for 3 years." |

Exceptions where passive is allowed:
- The actor is genuinely unknown: "The vials were contaminated before delivery." (with explicit note that actor is unknown)
- Emphasizing the receiver for flow: limited to one sentence per paragraph, max.

## 2. Sentence Length

- One idea per sentence.
- Aim for ≤ 25 words. Hard limit: 35 words.
- If a sentence has more than two commas, split it.
- Avoid stacking clauses with "and" / "which" — use two sentences or a list.

## 3. Paragraph Length

- One topic per paragraph.
- ≤ 5 sentences. ≤ half a page.
- First sentence is the **lead sentence**: states the paragraph's conclusion.
- Don't make paragraphs one sentence long unless it is a deliberate emphasis (signs of disorganized thinking otherwise).

## 4. Lists — Bulleted vs Numbered

- **Numbered list** = ordered steps the reader performs in sequence.
- **Bulleted list** = unordered items the reader scans.
- Every list needs a **lead sentence** that ends with a colon and frames what the list contains.
- Parallel structure: every item starts with the same part of speech (all verbs, all nouns, all imperative).
- Maximum 7 ± 2 items per list. Beyond that, group into sub-lists or a table.

## 5. Tables

Use a table when the reader needs to **look up** a value by row/column. Use a list when the reader reads sequentially.

- First row = header row.
- One concept per column.
- Sort by the column the reader searches on.

## 6. Audience Analysis

Before writing, answer (write the answers at the top of the doc):

1. **Primary audience** — who reads this to do their job?
2. **Secondary audience** — who else reads it (auditors, new hires, translators)?
3. **Expertise level** — novice / intermediate / expert. Pick one. Do not write "all levels" — pick the lowest that must succeed.
4. **What they already know** — list assumptions.
5. **What they need to learn** — list learning goals.
6. **What they will do after reading** — the action the doc enables.

The **curse of knowledge**: experts forget what it was like not to know. Test: have someone outside the domain read it. If they cannot perform the task or explain the concept, the audience analysis was wrong.

## 7. Terminology — Consistency

- One term per concept. Don't alternate "cleaning", "wipe-down", "sanitization" for the same action.
- Define every acronym on first use: "Standard Operating Procedure (SOP)".
- Keep a **Definitions** section at the top of long docs.
- Avoid idioms ("hit the ground running", "low-hanging fruit") — they do not translate.

## 8. Banned Vague Words — Full List

| Word | Why banned | Replacement pattern |
|---|---|---|
| soon, ASAP, promptly, quickly, immediately* | No measurable bound | Concrete duration: "within 5 minutes" |
| often, sometimes, frequently, regularly, occasionally | No measurable frequency | Concrete frequency: "every shift", "3×/day" |
| some, many, a few, several, various, certain | No measurable count | Concrete count or range: "7 vials", "3–5 batches" |
| appropriate, applicable, relevant, suitable | Doesn't name the thing | Name it: "21 CFR 211.22" |
| properly, correctly, adequately, sufficiently | Doesn't name the criterion | Name it: "per SOP-CR-0042 §7.2" |
| generally, typically, usually | Hides exceptions | State the rule, then list exceptions |
| *immediately | OK if literal ("call EHS immediately upon skin contact"); banned if vague | Use a concrete bound |

## 9. Markdown Conventions

- ATX headings (`#`), one `#` per level, blank line before and after.
- Fenced code blocks with language: ` ```ts `. Never indent code blocks.
- Inline code with backticks: `resolveKey`. Not quotes, not bold.
- Bold (`**`) for UI elements and key terms on first use; italic (`*`) for emphasis only.
- Tables with `|` and `---` separator; one concept per column.
- Link text describes the target: "see [SOP-CR-0042](...)" not "see [here](...)".
- One sentence per line in source (git-diff friendly) OR one paragraph per line — pick the repo's convention.

## 10. Accessibility (Formatting context)

- Every image has `alt` text describing the content, not the file name.
- Color is never the only signal — pair with text or shape.
- Headings form a real outline (no skipped levels: H1 → H2 → H3, not H1 → H3).
- Code blocks have a language so screen readers handle them.
- Avoid all-caps paragraphs (screen readers spell them out).

## 11. Error Messages (Formatting context)

A good error message answers four questions:
1. **What happened** — the failure, in user terms.
2. **Why** — the cause, if known; if not, say "unknown".
3. **What the user can do** — a concrete next action, not "contact support".
4. **Reference** — error code or doc link.

```text
❌ "Error: invalid input."
✅ "Cannot parse '2026-13-45' as a date. Expected ISO format YYYY-MM-DD.
    Edit the value at line 12 and retry. Code: PARSE_DATE."
```

## 12. Visuals — When and How

- Use a visual when the relationship between items is spatial, hierarchical, or quantitative.
- Don't use a visual for decoration.
- Captions below every figure, numbered ("Figure 1: ...").
- Reference the figure from the text: "see Figure 1".
- For procedures, a flowchart beats a numbered list when there are branches.
- For comparisons, a table beats prose.

## 13. Review Checklist (before publishing)

Read the doc aloud once. Then check:

- [ ] Audience stated.
- [ ] Purpose / Scope stated (with explicit "does NOT cover").
- [ ] No banned vague words.
- [ ] Active voice in procedures.
- [ ] Every acronym defined on first use.
- [ ] Regulations cited with clause numbers.
- [ ] Cross-references point to existing docs or are marked `(to be published)`.
- [ ] No invented types / parameters / return values.
- [ ] Effective Date is a real date (no "TBD").
- [ ] Revision History updated.
- [ ] Approver slot present and named (not blank).
- [ ] Visuals have alt text and captions.
- [ ] Headings form a valid outline.
- [ ] Read-aloud pass complete (typos, broken sentences).

## Sources

- Google Technical Writing One — <https://developers.google.com/tech-writing/one>
- Microsoft Writing Style Guide — <https://learn.microsoft.com/style-guide/>
- Scilife — "Best practices and tips for technical writing"
- Markdown Guide — <https://www.markdownguide.org/basic-syntax/>