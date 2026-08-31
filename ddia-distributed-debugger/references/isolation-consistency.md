# Isolation & Consistency — Anomaly Matrix, SSI Retry, CRDTs, Jepsen Findings

| Field | Value |
|---|---|
| Document ID | `REF-D3-01` |
| Parent | `SKILL-D3-001` (ddia-distributed-debugger) |
| Revision | 1 |
| Effective Date | 2026-08-29 |
| Applies to | Sections A-D of parent skill |

Detail for sections A-D of `ddia-distributed-debugger/SKILL.md`. The per-engine anomaly matrix, the SSI retry pattern, the CRDT-vs-transactions decision, and the 2025-26 Jepsen findings cited by the parent skill. Read order: matrix → retry → CRDT → Jepsen — the retry code assumes the matrix, the CRDT decision assumes both.

**Header metadata** : REF-D3-01 under SKILL-D3-001; changes here flag the parent Revision History (footer).

## The anomaly catalogue (shapes before the matrix)

Six anomalies, each a shape the audit pattern-matches. Shared terms (SI, SSI, write skew) are in `_shared/ddia-glossary.md` — never duplicated; the shapes here are the audit-facing expansions, not re-definitions.

1. **Dirty read** — one transaction reads another's *uncommitted* write; if the writer aborts, the reader acted on data that never existed. Rare in modern engines (all mainline levels exclude it), but the baseline that makes the ladder legible.
2. **Non-repeatable read** — same row read twice in one transaction, different values (another txn committed in between). Statement-snapshot levels (RC) allow it; transaction-snapshot levels (SI) don't.
3. **Phantom** — a predicate re-read (`WHERE status = 'open'`) returns rows that weren't there the first time. Not a non-repeatable read: the *set* changed, not a row. Matters for uniqueness/coverage invariants computed over a predicate.
4. **Lost update** — two flows read-modify-write the same row; one write disappears with no error. The RC check-then-act signature (parent section A). Not "lost" as in deleted — silently overwritten.
5. **Write skew** — two transactions read disjoint conditions of a multi-row invariant, each writes what the other didn't read; invariant broken, no write conflict, no abort. The SI signature anomaly (glossary: write skew).
6. **Read skew** — a multi-row read observes a torn state: rows A and B consistent *before* and *after* another transaction, but the reader saw B's new version and A's old version. Different from non-repeatable read: within one read operation or across a non-transactional group of reads.

**Why shapes matter more than names:** the user never reports "we have write skew" — they report "sometimes two bookings get the last seat". The audit maps symptom → shape → matrix row: seat-double-booking = write skew over a predicate; balance-negative = lost update or write skew (depends whether flows write the same row); timeline regress = read skew at RC or monotonic-reads violation (replication side). Name the shape, then the level decides whether the engine protects.

## Anomaly × isolation level matrix

**SQL Standard vs the engines that actually run:** the standard's four levels are a floor, not a description. PG's REPEATABLE READ is stronger than the standard's (snapshot isolation — no phantoms per PG docs); MySQL's RR is neither the standard's nor SI; SQL Server's RR is range-lock-based. The level name is a pointer into this matrix, never the claim itself.

| Anomaly | RC (PG default) | SI (PG RR) | MySQL InnoDB RR | SSI (PG SERIALIZABLE) | SQL Server RR (locks) |
|---|---|---|---|---|---|
| Dirty read | No | No | No | No | No |
| Non-repeatable read | **Yes** | No | No | No | No |
| Phantom | **Yes** | **No** (per PG docs) | Blocked by gap locks in most cases | No | No (key-range locks) |
| Lost update | **Yes** (check-then-act) | No (aborts on conflicting write) | **Yes** (Jepsen: observable) | No (abort) | No (locks) |
| Write skew | **Yes** | **Yes** — the SI signature anomaly | **Yes** (Jepsen) | No — detected, abort 40001 | No (range locks serialize) |
| Read skew | **Yes** | No | Mostly no (snapshot per statement group) | No | No |

**How to read it:** find the engine + level the user actually runs (audit input 1), scan left for surviving anomalies (audit input 2), then check each survivor against the invariant shape — cross-row invariant + concurrent writers + surviving write-skew cell = the card game (parent section A). The matrix is per-engine-version; the Jepsen section below overrides optimistic cells with measured findings.

## PG 18 isolation summary (the parent skill's PG baseline)

The `transaction-iso` table as the parent skill consumes it:

- **READ COMMITTED (default)** — statement-level snapshot: each statement sees a fresh view. All anomalies except dirty read possible. The level most "we have transactions" systems actually run at.
- **REPEATABLE READ** — transaction snapshot for the txn's whole life. PG docs: no dirty, no non-repeatable, no phantom reads — but **write skew remains possible** (this is SI, not serializable). The gap between "RR sounds strong" and "write skew lives here" is the parent skill's most common audit finding.
- **SERIALIZABLE** — SSI: dependency tracking (rw-antidependencies on predicate ranges) detects the card-game shape and aborts one transaction with SQLSTATE 40001. Serializable correctness holds **only if the client retries** — the retry pattern below is part of the level's contract, not an optimization.

**Migration note for audits:** moving RC → RR is not a config tweak and a hope — under SI an update conflicting with a concurrent committed update aborts (40001) where RC silently took the last write. A system that never handled 40001 gets *error storms* at RR it never had at RC. The audit asks for the retry path before endorsing any level bump.

## SSI retry pattern (SQLSTATE 40001)

PG SERIALIZABLE works by aborting: when SSI detects a dangerous dependency structure (the card-game shape), one transaction is killed with `40001 serialization_failure`. The pattern is a bounded, backoff-driven retry loop **with an idempotency key**, because a retried transaction may have already produced side effects out of the database's sight (emails, charges, third-party calls).

```sql
-- Run inside a retry loop keyed on an idempotency key
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT ... ;          -- reads tracked by SSI predicate ranges
UPDATE ... ;          -- the write side of the invariant
COMMIT;               -- may fail: 40001 serialization_failure
```

```python
# Pseudo-shape: retry with exponential backoff + jitter, bounded
for attempt in range(MAX_ATTEMPTS):           # 3-5, not infinite
    try:
        with tx(isolation="SERIALIZABLE"):
            do_work(idempotency_key=op_id)    # key makes re-run safe
        break
    except SerializationFailure:               # SQLSTATE 40001
        backoff = base * 2**attempt + jitter()  # 50ms, 100ms, 200ms...
        sleep(backoff)
else:
    surface_to_user_or_queue(op_id)           # bounded retries exhausted:
                                              # do NOT silently drop
```

**Why each piece is load-bearing:** bounded attempts — an unbounded loop under sustained contention converts a correctness mechanism into a livelock; backoff + jitter — synchronized retries re-collide in the same serialization window; idempotency key — the aborted transaction may have committed side effects elsewhere before aborting (SSI aborts *at commit*, late in the transaction's life); exhaustion path — surfacing or queueing the operation beats a silent drop, which is data loss wearing a retry costume. A retry loop missing any of the four is anti-pattern row 6 (parent section E).

**Retry budget arithmetic (before recommending SSI):** abort rate climbs with contention on overlapping predicate ranges. Estimate: concurrent writers to the same invariant × txn duration vs serialization window. Low contention (distinct sessions, short txns) → aborts rare, retries cheap. High contention (many writers, one hot predicate) → SSI abort-storms: split the hot range, shorten txns, or restructure the invariant to a single row. SSI is a scalpel, not a default (anti-pattern row 13).

## CRDTs and Automerge 3 — when merge beats transactions

**CRDTs (Conflict-free Replicated Data Types)** resolve concurrent edits by mathematically-guaranteed merge instead of abort: concurrent writes both survive and converge (registers LWW, counters G/C, sequences, maps/sets). The price is paid in what you can express — no arbitrary cross-row invariants, metadata overhead (tombstones, version vectors), and no abort semantics at all (conflicts merge, they don't fail).

**Automerge 3 (Kleppmann team, local-first lineage)** is the 2026 reference implementation: document state as a CRDT, merged across peers/offline replicas; suited to collaborative editing where both offline writes must survive. Its maturity makes the local-first pattern a real option for application state — not for transactional invariants.

**Decision table:**

| Property | Transactions (SSI) | CRDT |
|---|---|---|
| Cross-row invariants | Enforced (abort) | **Cannot express** |
| Concurrent writers | One aborts (40001) | Both survive, merge |
| Offline/multi-master writes | Not safe | The design point |
| Cost | Retry engineering, abort rate | Metadata, tombstone growth, limited merge semantics |
| Fits | Money, inventory, booking — invariants sacred | Collaboration, config, presence — merge acceptable |

**Audit stance:** CRDTs answer multi-master conflict *resolution*; transactions answer invariant *enforcement*. Deploying CRDTs everywhere because merge sounds safer (anti-pattern row 5) silently drops every invariant the workload actually carried — the merge converged, the money is still wrong. Conversely, a genuinely multi-writer offline workload with no cross-row invariants is the honest CRDT case — forcing single-home transactions on it buys aborts, not safety.

**DDIA 2017: multi-leader conflict resolution often LWW-by-timestamp. SOTA 2026: LWW is the anti-pattern (drops concurrent writes by clock lottery); HLC-ordered or CRDT merge is the default for multi-writer state.**

## Jepsen 2025-26 findings (cited as advisory evidence)

The parent skill cites Jepsen analyses as ground truth for what engines actually do under fault injection — running Jepsen is out of the parent skill's scope; consuming its findings is in scope.

- **MariaDB Galera Cluster 12.1.2** (2025 analysis): Galera's certification-based "virtually synchronous" replication did not prevent split-brain-shaped anomalies under partitions and reconfiguration — including the asymmetric case the parent skill section B describes: nodes accepting conflicting histories and losing committed writes during rejoin. The lesson: "synchronous replication" and "cluster" are marketing words; the mechanism (quorum math, fencing, reconfiguration protocol) is the guarantee.
- **NATS 2.12.1** (2025 analysis): the Raft-based JetStream metadata layer held up better than the data plane around it — a live demonstration of the parent skill section D split: consensus scope is per-subsystem, and a Raft-tested core does not automatically extend its guarantees to everything layered on it. Audit each layer's mechanism separately.
- **TigerBeetle** (2025 analysis): a deliberately adversarial design (VOPR — verified fault injection in CI, strict state-machine replication, no reliance on filesystem sync honesty) showing the 2026 frontier: consensus-correctness as a continuously tested property rather than shipped-and-hoped. Cited as evidence that "fault-injection-tested before release" is an achievable engineering bar, not just an audit practice.

**How to use these findings in an audit:** when a user claims a clustered store "handles partitions", map the claim to the mechanism Jepsen tested — per-write quorum acknowledgment (Galera finding: not sufficient without correct reconfiguration), which subsystem carries Raft (NATS finding: name the layer), and whether the vendor runs fault injection continuously (TigerBeetle bar). The finding beats the datasheet; the mechanism beats the name.

## Worked audit — matrix to verdict in five steps

**Case:** marketplace checkout, two `UPDATE`s per order (stock + payment), MySQL InnoDB default isolation, "occasional oversell during flash sales".

1. **Level** — InnoDB default = RR (audit input 1 satisfied).
2. **Matrix row** — MySQL RR: lost update **Yes** (Jepsen), write skew **Yes** (Jepsen), phantoms mostly blocked.
3. **Invariant shape** — stock >= 0 spans `stock` row read + `order` row write → cross-row ⇒ write skew shape; same-row read-modify-write on `stock` ⇒ lost update shape. Both live at this cell.
4. **Symptom match** — oversell during concurrency = lost update on the `stock` decrement (check-then-act: `SELECT stock` then `UPDATE`), plus possible write skew on the payment-side invariant.
5. **Fix ladder** — (a) atomic `UPDATE stock SET qty = qty - 1 WHERE id = ? AND qty >= 1` — kills the lost update at any level; (b) the cross-row payment invariant → `SELECT ... FOR UPDATE` on the order row or move to a serializable-verified flow; (c) name residual: InnoDB SERIALIZABLE exists but is rarely the deployed answer — Jepsen findings apply at RR, so the audit does not stop at "MySQL is fine at RR".

**Verdict format (what the parent skill's Hard Gate requires):** "InnoDB RR (named); lost update + write skew possible (matrix); retry story: atomic UPDATE has no retry path to need — 40001 handling required if level raised (named)." A verdict missing any of the three clauses violates the parent Iron Law.

---

**Modification footer** : any change to this file requires flagging the parent skill's Revision History (SKILL-D3-001) — see ddia-glossary.md modification protocol.

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-08-29 | Initial: anomaly shapes, anomaly × isolation matrix, PG 18 isolation summary, SSI retry pattern (40001 + backoff + idempotency), CRDT/Automerge 3 decision table, Jepsen 2025-26 findings (Galera, NATS, TigerBeetle), worked audit. | Skills maintainer | Skills maintainer |