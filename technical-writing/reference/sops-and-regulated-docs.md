# SOPs & Regulated Documents — Heavy Reference

Detail backing the **Document Architecture** and **Lifecycle & Compliance** contexts of `technical-writing`. Read this when writing SOPs, work instructions, deviations, RCA, or CAPA reports in a regulated environment (GMP, ISO 13485, 21 CFR, ICH Q7).

## 1. Doc Hierarchy — Policy / SOP / Work Instruction

| Doc | Scope | Granularity | When to use |
|---|---|---|---|
| **Policy** | Framework, decision rules | Broad | When behavior / decision-making must be guided |
| **SOP** | A complete process | Multi-person, multi-step | When a process must be repeatable across people and time |
| **Work instruction** | One task within an SOP | Single-person, single-task | When a step in an SOP needs detailed sub-steps; annex to the SOP |

If an SOP becomes too detailed, split: keep the SOP as the general process, annex work instructions for the detailed steps. This also helps translation and training: SOP stays in the master language, work instructions get translated.

## 2. SOP — Required Sections (in order)

1. **Header** — Document ID, title, revision, effective date, page count, company logo, document owner.
2. **Purpose** — one paragraph: why this SOP exists.
3. **Scope** — what this SOP covers AND what it explicitly does NOT cover.
4. **Audience** — primary + secondary readers, expertise level.
5. **Responsibilities** — table: role → responsibility.
6. **Definitions and Abbreviations** — every acronym and term used.
7. **Materials and Equipment** — list with IDs / part numbers / grades.
8. **Procedure** — numbered, active voice, present tense, one action per step.
9. **Records** — what to fill, where, retention time.
10. **References** — other SOPs, regulations, manuals cited **with clause numbers**.
11. **Revision History** — table: Rev | Date | Description | Author | Approver.
12. **Approvals** — table: role | name | signature | date.

### Effective Date rule

The Effective Date is the date the SOP becomes binding. It must be a **real future date**, set at approval. It must NOT be "TBD" — a SOP with TBD effective date is not effective and fails every audit.

### Procedure section rules

- Numbered list, active voice, present tense.
- One action per step. If a step needs sub-steps, use `1.1`, `1.2` numbering, not bullets.
- State the actor: "Operator dons cleanroom gloves." Not "Gloves are donned."
- State the trigger before the action: "If residue persists after two passes, repeat §7.2."
- State the bound: "within 5 minutes", "minimum 2 passes". Never "as soon as possible".
- Print-screens for IT procedures; diagrams for branching flows; tables for comparisons.

## 3. Work Instruction — Required Sections

Subset of an SOP:
1. Header (linked to parent SOP)
2. Purpose of this task
3. Prerequisites
4. Step-by-step (numbered, with printscreens)
5. Acceptance criteria
6. Records (form ID, fields to fill)

## 4. Deviation Report — Required Structure (compliance)

A deviation report documents an event that departed from an approved process. **Facts only in the event section.** Opinions and preliminary assessments live in their own section.

1. **Header** — Deviation No., date opened, classification (Minor / Major / Critical), status.
2. **Event description (5W1H)** — Who, What, When, Where, Why (unknown is OK), How detected.
   - Chronological order.
   - Concrete identifiers: names, equipment IDs, instrument IDs, batch numbers, dates, times.
   - Observed facts only. No "probably", no "likely", no "due to" in this section.
3. **Immediate actions taken** — numbered, with timestamp and actor.
4. **Impact assessment (preliminary)** — labelled "preliminary". Product, patient, batch, other batches, regulatory.
5. **Investigation plan** — scope, activities, owners, due dates.
6. **Root cause** — "Pending" until investigation completes. Method: 5-Why or Ishikawa.
7. **CAPA** — "Pending root cause" until investigation completes. Never stop at "human error".
8. **Batch disposition** — affected units, remainder of batch, other batches.
9. **References** — SOPs and regulations cited with clause numbers (21 CFR 211.22, ICH Q7 §8.14, ISO 13485 §4.2.4).
10. **Approvals** — table with QA, Production, Head of Quality, QP.

### Facts vs Opinions — the discipline

```text
❌ "Particles were observed in vials 12–18 due to a likely filter failure."
✅ Facts:  "Operator J. Martin observed particles in vials 12–18 of rack B at 14:35."
   Assessment (separate section): "Probable root cause: filter integrity failure — to be confirmed by §5.2.4."
```

### Citing regulations in deviations

- "Per applicable regulation" → ❌ auditor rejects.
- "Per 21 CFR 211.22(a)" → ✅ auditor accepts.
- "Per SOP-CR-0042 §7.2" → ✅ auditor accepts.

Common citations for life sciences:
- 21 CFR Part 211 (cGMP for finished pharmaceuticals)
- 21 CFR Part 820 (QSR for medical devices)
- 21 CFR Part 11 (electronic records)
- ICH Q7 (API GMP)
- ICH Q9 (Quality Risk Management)
- ISO 13485 (QMS for medical devices)
- EU GMP Annex 1 (sterile products)

## 5. Root-Cause Analysis (RCA) — Required Structure

1. **Event reference** — link to the deviation report.
2. **Method** — 5-Why, Ishikawa (fishbone), FMEA. State which.
3. **Evidence** — data, observations, interviews. Cite batch records and log entries.
4. **Analysis** — walk through the method step-by-step. For 5-Why: each "Why" with the evidence that supports it.
5. **Root cause** — the fundamental cause. If not identified, state "Probable root cause: <hypothesis>, based on <evidence>".
6. **Out-of-specification results (QC)** — examine sampling, reagents, instruments, procedures separately.
7. **Trend** — historical data tabled / graphed.
8. **Affected batches** — list all, including potentially affected.
9. **Immediate risk control** — what was done to contain.

**Never stop at "human error" or "equipment failure".** These are symptoms. Dig:
- Human error → was the procedure clear? was training adequate? was the workload realistic?
- Equipment failure → was maintenance on schedule? was calibration current? was the right equipment specified?

## 6. CAPA — Required Structure

1. **Linked deviation / RCA** — reference numbers.
2. **Root cause addressed** — explicit, copied from RCA conclusion.
3. **Corrective action** — fixes the specific incident. Concrete, owned, dated.
4. **Preventive action** — prevents recurrence in similar processes. Concrete, owned, dated.
5. **Effectiveness check** — what will be measured, when, by whom, what threshold counts as effective.

**Training alone is rarely the right CAPA.** Training addresses one operator; the next operator will repeat the error. Fix the procedure, the process, or the equipment.

If the root cause was a poorly-described procedure, the CAPA is to **rewrite the procedure**, not to retrain on the bad procedure.

## 7. Lifecycle — Versioning & Approval

- Every revision increments the Rev number (0, 1, 2, ...).
- Revision History is mandatory — audit trail of what changed and why.
- Effective Date changes with each new revision.
- Old revisions are archived, not deleted.
- The current revision is the only one in force. Printed copies are "uncontrolled" — always reference the electronic system.
- Approval signatures: Author → Reviewer → Approver (typically QA). QP for release-impacting docs.

## 8. Common Regulated SOPs (examples)

Life-sciences organizations must typically have SOPs for:
- Document control
- Record control
- Training management
- Change control
- Deviation / non-conformance management
- CAPA
- Internal audit
- Management review
- Supplier qualification
- Calibration / maintenance
- Cleaning (per process)
- Line clearance
- Batch release
- Complaint handling
- Adverse event / vigilance reporting
- Sterilization validation
- Stability program

## Sources

- Scilife — "A Guide on How to Write Effective SOPs"
- Scilife — "Best practices and tips for technical writing"
- 21 CFR Part 211 — cGMP for finished pharmaceuticals
- 21 CFR Part 820 — Quality System Regulation (medical devices)
- ICH Q7 — GMP for APIs
- ICH Q9 — Quality Risk Management
- ISO 13485 — Medical devices QMS