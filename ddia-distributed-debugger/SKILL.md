---
name: ddia-distributed-debugger
description: Use when reasoning about transaction isolation, replication anomalies, consensus behavior, or distributed-systems edge cases — claiming a concurrent flow is 'safe' without naming the isolation level (or trusting wall-clock timestamps for ordering) ships write skew, lost updates, and split-brain corruption
type: sub-skill
contracts:
  - isolation-levels
  - replication-anomalies
  - clocks-and-ordering
  - consensus-patterns
  - anti-patterns-table
---

# DDIA Distributed Debugger

## The Iron Law

> **NO CONCURRENCY CORRECTNESS CLAIM WITHOUT ISOLATION LEVEL NAMED.**

This is not a guideline. Every concurrency claim is relative to an isolation level and its anomaly set (see `_shared/ddia-glossary.md`: SI/SSI, write skew): "safe" under SERIALIZABLE may be write-skew-corrupt under SNAPSHOT ISOLATION, and "safe" under RC is a different statement again. The agent's training data systematically conflates these — it calls MySQL's InnoDB "REPEATABLE READ" by SQL-standard semantics, calls snapshot isolation "serializable", and calls NTP-synchronized timestamps "an ordering". A correctness claim that never names the level is not a conservative claim; it is an unspecified claim, and unspecified claims ship write skew, lost updates, and split-brain corruption. The level is named, or the claim is not emitted.

**Why the level comes first:** the isolation level decides which anomalies the engine excludes (section A matrix) and which remain the application's problem; the anomaly class decides the countermeasure (constraint, explicit lock, level bump); the retry story closes the loop because SSI-style protection works by aborting transactions (SQLSTATE 40001) — a serializable deployment whose client doesn't retry is a deployment that fails user requests instead of protecting invariants. Skipping the level means all three are unknown at once — the failure compounds silently.

**Announce discipline:** every answer this skill emits starts by naming which isolation level is in effect on the engine at hand, which anomalies remain possible at that level, and what happens on abort. An answer that silently assumes "transactions make it safe" has already violated the Iron Law — the assumption is named or the audit questions are asked.

## Hard Gate

<HARD-GATE>
Do NOT emit, endorse, or bless any concurrency or consistency claim without first having (1) the isolation level named for the engine at hand, (2) the anomaly class considered (write skew, lost update, phantom — at minimum), and (3) the retry/idempotence story for aborted or retried transactions. This applies even under deadline pressure, even for "it's just a quick sanity check", even when the user says "it's safe, I use transactions".
</HARD-GATE>

This gate exists because three failure modes recur on every concurrency question: (1) the user arrives with a vague correctness claim ("c'est safe, j'utilise des transactions") and a compliant agent rationalizes it — the fix is refusing until the level is named, because "transactions" is a word, not a guarantee; (2) the anomaly is engine-specific — PG's REPEATABLE READ is snapshot isolation (no phantoms per PG docs), MySQL's RR is not serializable (Jepsen: lost updates and write skew observable), SQL Server's RR is lock-based — the same word names three different contracts, so the claim is checked against the matrix, not the name; (3) the retry story is missing — raising isolation without retry/idempotence planning converts data corruption into user-facing failures and duplicate side effects (anti-pattern row 6). The gate forces all three to the surface before any verdict.

**Gate enforcement — the three numbered requirements:**

| Requirement | What satisfies it | What does not |
|---|---|---|
| (1) Isolation level named | "Postgres, default READ COMMITTED", "MySQL InnoDB RR", "PG SERIALIZABLE (SSI)" | "I use transactions", "the database guarantees consistency" |
| (2) Anomaly class considered | "write skew possible under SI — our invariant crosses rows", "lost update excluded: single-row atomic UPDATE" | "no race conditions" (unqualified) |
| (3) Retry/idempotence story | "40001 → retry with idempotency key, max 3, backoff" | "we never retry", silence |

If any row is unanswerable, the output is the three questions — not a conditional correctness verdict. "It's probably safe, but which isolation level…?" violates the gate: a probabilistic correctness claim still anchors the user.

## Snapshot

This skill owns the rules an agent applies when auditing concurrency and consistency edge cases: the isolation-level ladder and its per-engine differences (RC default in PG, PG REPEATABLE READ ≈ SI with no phantoms per PG docs, MySQL RR weaker than believed per Jepsen, SQL Server lock-based RR, PG SERIALIZABLE = SSI with SQLSTATE 40001 retries), write skew detection via the card-game shape (disjoint read conditions, no conflict on writes), replication anomalies (read-your-writes, monotonic reads, quorum lag, asymmetric split-brain, stale-read reporting), clock rules (time-of-day NTP never for ordering, monotonic for intervals only, TrueTime bounded uncertainty, AWS Time Sync microsecond bounds, HLC as the 2026 cross-machine default), and the consensus landscape (Raft won — etcd/CockroachDB/Consul/NATS Jepsen-tested, leader leases, witness replicas, Paxos theory-only). It mandates isolation-level-named claims with an anomaly class and a retry story before any correctness verdict. Chaos engineering execution and Jepsen runs are advisory context, not this skill's scope. The anomaly matrix, SSI retry code, CRDT trade-offs, and 2025-26 Jepsen findings live in `references/isolation-consistency.md`.

**Announce at start:** `I'm using the ddia-distributed-debugger skill to audit this concurrency or consistency edge case.`

**Failure mode this skill prevents:** — a "safe" verdict whose level was never named, so write skew corrupts a cross-row invariant in production, or NTP timestamps "order" events that happened in the other order, or an unfenced failover serves split-brain writes from two leaders — and the bug surfaces as missing money or corrupted state months later, unreproducible in any single-threaded test. The level-anomaly-retry triple is the countermeasure.

## Quick Reference (projection — see Content sections for full rules)

**Quick Reference projection table** — summary card; full rules in sections A-E. If the card and the sections disagree, the sections win.

The card exists for fast pattern-matching by the agent mid-task; it does not replace reading the section.

| Field | Value |
|---|---|
| Audience | Agent or engineer reasoning about transaction isolation, replication anomalies, consensus behavior, distributed edge cases |
| Trigger | "is it safe to…", "race condition?", "write skew", "isolation level", "reads lag behind writes", "clock skew", "split-brain", "quorum" |
| Inputs | The flow under audit; the three gate questions if isolation level, anomaly class, or retry story absent |
| Outputs | Correctness verdict naming level + anomaly class + retry story; gate questions if any input unknown |
| Type | sub-skill (see `_shared/SKILL-ARCH.md`) |
| Baseline | Name the level before any claim; SI is not serializable; HLC not wall-clock; Raft-based leadership with leases + fencing |
| Iron Law | NO CONCURRENCY CORRECTNESS CLAIM WITHOUT ISOLATION LEVEL NAMED |
| Scope out | Chaos engineering execution, Jepsen test runs (advisory only), storage engines (`ddia-storage-internals`), pipeline semantics (`ddia-pipeline-architect`) |
| Identity | Descriptive name (`ddia-distributed-debugger`); stable — do not rename |

## Related Skills

| Sibling | Relationship | What crosses the boundary |
|---|---|---|
| `using-superpowers` | `upstream` | Routes concurrency/consistency triggers here. Translation: using-superpowers's "trigger match" = this skill's "audit announced". |
| `writing-skills` | `shared-kernel` | Co-maintains TDD-for-skills vocabulary. This skill applied RED→GREEN→REFACTOR during its own authoring. |
| `technical-writing` | `shared-kernel` | Co-maintains 4-slot discipline (Audience, Purpose/Scope, Definitions, Revision History). |
| `_shared/ddia-glossary.md` | `shared-kernel` | Quorum, HLC, TrueTime, SI/SSI, write skew, split-brain, leader lease definitions live there. Never duplicated here. |
| `_shared/glossary-en.md` | `shared-kernel` | TDD/RED/GREEN/Iron Law/Hard Gate terms live there. |
| `ddia-tradeoff-analyzer` | `none` | Independent domains, no mutual invocation. That skill chooses the store; this one audits what runs on it. |
| `ddia-storage-internals` | `none` | Independent domains, no mutual invocation. Engine internals vs isolation anomalies. |
| `ddia-pipeline-architect` | `none` | Independent domains, no mutual invocation. At-least-once idempotence overlaps but enters via its own trigger. |

**Sibling boundary note** : the four ddia-* skills cover independent domains (choice vs internals vs correctness vs movement). No skill invokes another; a single conversation may load two (e.g., a store chosen there, then its concurrency audited here), but each enters via its own trigger, not a call from this one.

## The Audit Interrogation (the Hard Gate in question form)

When any of the three gate inputs is missing, the output is these questions — nothing else:

1. **"Which isolation level, on which engine, is this running at?"** — decides the anomaly matrix row (section A); "transactions" is not an answer, and the same level name means different things on PG, MySQL, and SQL Server.
2. **"Which anomaly classes remain possible at that level — and does the invariant cross rows?"** — write skew lives in cross-row invariants under SI; lost update lives in check-then-act under RC; phantoms live in predicate re-reads where the level doesn't snapshot them.
3. **"What happens when the engine aborts the transaction (SQLSTATE 40001) — is the retry idempotent, and is it bounded?"** — serializable protection works by aborting; a client that doesn't retry turns protection into failure, and a retry without idempotence turns failure into duplicates.

**Evidence beats interrogation:** if the schema, transaction code, isolation settings (`SHOW transaction_isolation`, `@@transaction_isolation`), or error logs are reachable, audit from them first — the actual level in effect beats the level the user believes they run, and users systematically overestimate their isolation.

**When the audit exits:** the skill's job ends when the verdict is emitted — level named, anomaly class mapped, fix picked from the ladder, retry story stated, residual risk listed. Implementation of the fix (writing the retry loop, designing the session token, choosing the datastore that carries the consensus) belongs to the regular engineering flow or the sibling skills; re-auditing after the fix is this skill's re-entry point. A verdict that lingers into implementation advice past the concurrency question has drifted — restate the verdict and stop.

## A. Isolation Levels

**The ladder, and why the level is named before any claim:** isolation levels are defined by which anomalies they exclude — not by their names. The same name contracts differently per engine, so the audit starts by pinning engine + level, then reading the anomaly matrix (`references/isolation-consistency.md` § matrix).

| Level (as named) | PG | MySQL InnoDB | SQL Server | Anomalies excluded |
|---|---|---|---|---|
| READ COMMITTED | Default | Default | Default | Dirty reads only — non-repeatable reads, phantoms, lost updates (via check-then-act) all remain |
| REPEATABLE READ | ≈ SI — snapshot per txn, no phantoms per PG docs | MVCC + gap locks — weaker than serializable per Jepsen | Lock-based — key-range locks prevent phantoms | Engine-specific — the name is not the contract |
| SERIALIZABLE | SSI — detects write skew, aborts 40001 | 2PL-based, costly, rarely deployed | Full range locks | All, if retries handled |

**RC — the default that does less than people believe.** Postgres ships READ COMMITTED: no dirty reads, but each statement sees a fresh snapshot — non-repeatable reads and phantoms are live, and check-then-act (`SELECT` then `UPDATE`) is a lost-update factory (anti-pattern row 3). Most "we have transactions" claims describe this level, and most cross-row invariants are already broken at it.

**RC lost update — the shape to pattern-match:**

```sql
-- Two sessions, RC, balance = 100
BEGIN; SELECT balance FROM accounts WHERE id = 1;  -- both read 100
UPDATE accounts SET balance = 100 - 80 WHERE id = 1;  -- both "safe": 100 >= 80
COMMIT; COMMIT;                                       -- balance = -60 or 20, no error
```

Neither session sees the other's write (statement snapshots), the guard `balance >= 80` was evaluated against a stale pre-state, and the last write silently wins. Fix shapes, cheapest first: single-statement atomic `UPDATE accounts SET balance = balance - 80 WHERE id = 1 AND balance >= 80` (row lock + re-evaluated guard, works at RC), `SELECT ... FOR UPDATE` to serialize the read-modify-write, or raise the level. The atomic-UPDATE fix is the one to reach for first — it moves the check into the locked write, so no client code races at all.

**SI — snapshot isolation, strong but not serializable.** PG's REPEATABLE READ is snapshot isolation per PG docs: the transaction reads one snapshot for its whole life, sees no dirty reads, no non-repeatable reads, and no phantoms (stronger than the SQL-standard RR, which permits phantoms). MySQL InnoDB's RR approximates SI via MVCC plus gap locks. Neither is serializable: both allow **write skew** — the anomaly SI was not built to detect, because the two transactions' writes never conflict on the same row, so no engine aborts either one.

**Write skew — the card game (the shape to pattern-match):**

```sql
-- Invariant: never draw more cards from the deck than were dealt
-- Two concurrent transactions, deck has 1 card left
BEGIN; -- Txn A (SI snapshot: remaining = 1)
  SELECT remaining FROM decks WHERE id = 1;         -- 1 >= 1, safe
  UPDATE results SET drawn = drawn + 1 WHERE player = 'alice';
COMMIT;                                              -- succeeds
BEGIN; -- Txn B (SI snapshot taken BEFORE A commits: remaining = 1)
  SELECT remaining FROM decks WHERE id = 1;         -- 1 >= 1, safe
  UPDATE results SET drawn = drawn + 1 WHERE player = 'bob';
COMMIT;                                              -- also succeeds — deck over-drawn
```

Both snapshots said "safe"; the reads were of disjoint conditions (neither reads what the other writes — `remaining` vs different `player` rows); the writes touch different rows so no conflict aborts either; the invariant is broken. Detection rule: **invariant spans multiple rows + each transaction reads one part and writes another, disjoint part → write skew is possible at SI and probable at RC**. Fixes: an explicit constraint when expressible on one row (`CHECK`, or a trigger), `SELECT ... FOR UPDATE` on the shared row to serialize the readers, or SSI.

**Lost update vs write skew — tell them apart in the audit:** lost update = both flows write the *same* row (last write silently wins — a data bug that looks like lag); write skew = flows write *different* rows while both depend on a read of the whole (invariant broken — looks like a business-logic bug). The distinction decides the fix: atomic single-row UPDATE kills lost update; only serialization (lock or SSI) kills write skew.

**Phantom reads — the third shape, predicate-shaped:**

```sql
-- RC, two sessions
BEGIN; SELECT count(*) FROM shifts WHERE on_call = true;   -- 2 — invariant: >= 1 stays on call
-- Session B: UPDATE shifts SET on_call = false WHERE id = 7; COMMIT;
SELECT count(*) FROM shifts WHERE on_call = true;          -- 1 — same txn, different answer
-- Session A now "safely" takes the last on-call off... invariant broken at 0
```

At RC the predicate re-read can see new matching rows (or fewer) committed between statements — the *set* changed, so a coverage invariant computed over a predicate is live. At PG's REPEATABLE READ the transaction snapshot freezes the predicate answer — **no phantoms per PG docs** — which is why PG's RR is stronger than the SQL standard's RR; at SQL Server's RR, key-range locks physically block the qualifying write instead. The audit maps any "count/check over a set then act" flow onto this shape before calling it safe.

**SSI — the level that earns serializable:** PG SERIALIZABLE implements Serializable SI: dependency tracking (rw-antidependencies — reads-writes against predicate ranges) detects the card-game shape and aborts one transaction with SQLSTATE 40001 instead of letting it corrupt the invariant. The contract: serializable correctness *if* the client retries — retry code with idempotency key, bounded attempts, backoff in `references/isolation-consistency.md` § retry. Costs named before recommending: predicate-tracking overhead on every transaction, abort rate climbing with contention, and a retry path that must be idempotent or the protection backfires (anti-pattern rows 6, 13).

**MySQL and SQL Server — why the name is not the contract:**

- **MySQL InnoDB RR**: MVCC snapshots + gap locks block phantoms in most cases, which reads as "strong" — but Jepsen's 8.0.32–9.0.1 analysis observed lost updates and write skew under RR, and InnoDB's SERIALIZABLE (2PL-ish) is costly enough that it is rarely the deployed answer. **DDIA 2017: RR "mostly enough". SOTA 2026: per-engine matrices + Jepsen audits are the ground truth.**
- **SQL Server RR**: lock-based with key-range locks — phantoms genuinely prevented (a stronger mechanism than MVCC RR, paid for in lock contention and deadlocks — SQL Server deadlock errors are the retry trigger, same Hard Gate input 3).

**RC → RR migration note (audits keep tripping on this):** moving PG from default RC to REPEATABLE READ is not a config tweak and a hope — under SI, a write that conflicts with a concurrently committed write aborts with 40001 where RC silently took the last write (or the first commit won, statement by statement). A system that has never handled 40001 gets error storms at RR it never had at RC, on exactly the hot paths the migration was meant to protect. Level changes are retry-story changes; the audit asks for the retry path before endorsing the bump (Hard Gate input 3), and the retry code lives in `references/isolation-consistency.md` § retry.

**Level-ladder audit drill (run it on any "safe" flow):** (1) name the engine and the level actually in effect (not the level intended — `SHOW transaction_isolation` beats the wiki); (2) read that engine's matrix row, not the SQL standard's (`references/isolation-consistency.md` § matrix); (3) classify the invariant: single-row → constraints/atomic UPDATE; cross-row → write-skew exposure check (card game shape); (4) classify the access pattern: check-then-act → lost-update exposure at RC and MySQL-RR; predicate re-read → phantom exposure where the level doesn't snapshot; (5) pick the fix from the decision rule, price it (locks held, abort rate, retry engineering), and name the retry story if any abort is possible. Five steps, one verdict — and the verdict names level, anomaly, and retry or it is not a verdict.

**Decision rule:** invariant on one row → constraint or atomic UPDATE. Cross-row invariant, low contention → `SELECT FOR UPDATE` on a shared parent row. Cross-row invariant, concurrent writers, correctness sacred → SSI + idempotent retry. Everything else → name the level, name the surviving anomalies, accept them explicitly.

**Worked example — the audit in action:**

User: "room booking — two clerks, same room, same slot, double-booked twice this month; we use transactions." Audit: (1) level unknown → the gate questions first. User answers "Postgres, default". Audit output: "PG READ COMMITTED (named). Invariant `free_rooms > 0` crosses rows — clerk A checks room type X, clerk B checks room type Y, both insert a booking on the room they didn't read the other checking — write-skew shape (card game, section A) at RC, near-certain under two concurrent clerks. Also live at RC: check-then-act lost update if both `SELECT` the same room row first. Fix ladder, cheapest first: (a) explicit constraint — a trigger keeping `booked_count <= capacity` on the rooms table turns the invariant into a single-row check the engine enforces at write time; (b) `SELECT ... FOR UPDATE` on the shared rooms row serializes both clerks' reads; (c) SSI + idempotent retry if the booking flow carries side effects (`references/isolation-consistency.md` § retry). Retry story for (c): 40001 → retry with the reservation idempotency key, max 3 attempts, exponential backoff — without the key, a retried booking duplicates the customer's charge (anti-pattern row 6)."

## B. Replication Anomalies

Replication is asynchronous somewhere. Every anomaly below is a consequence of reading from a replica that hasn't caught up — the audit names which replicas a request can hit and what bounds their staleness.

**Read-your-writes:** the user writes to the leader, the next read hits a lagging follower, and their own write is invisible — the classic "my profile update ate my profile" bug. Fixes: **session tokens** — the session remembers its last write's timestamp/LSN and the replica must have applied past it before serving (stale replica → route to leader or wait); or **sticky routing** of a session's post-write reads to the leader or a synchronously caught-up replica. On eventual consistency without such tokens, read-your-writes does not exist — asserting it is anti-pattern row 10.

**Session-token mechanics (the implementation the audit asks for):** the client records the commit's WAL position (`pg_current_wal_lsn()`) or a logical timestamp; a read request carries it; the replica checks its replay position (`pg_last_wal_replay_lsn()` ≥ token) before executing — else the proxy reroutes to the primary or delays the read. Failure modes to check: token must survive server-side session failover (a token lost at load-balancer re-pinning silently drops the guarantee back to none), and the token comparison must use the *replication stream's* ordering, not a wall clock (the guarantee is a stream position, not a time). Proxies and poolers that strip or ignore the token are the most common silent break — the mechanism exists in code and is skipped in path.

**Monotonic reads:** round-robin load-balancing across replicas of different lag makes time run backward — the user sees their timeline advance, then regress (older snapshot on a laggier replica). Fix: sticky routing per session, or a per-session staleness token that only moves forward. A load balancer that treats replicas as interchangeable breaks monotonicity by design (anti-pattern row 11). The token form is the stronger fix where stickiness is impractical (serverless, connection-per-request): each response carries its replica's position, the session stores the highest it has seen, and a replica behind that position refuses/redirects — the same LSN comparison as read-your-writes tokens, reused as a session high-water mark. Note what monotonicity does *not* promise: it bounds time travel *within* a session, not cross-session freshness — two users can still see different lags, which is section B's residual, not a bug.

**Quorum lag:** leaderless quorums (Cassandra/Scylla lineage) promise freshness if W + R > N — but the math only overlaps *some* write with *some* read, not the latest one: concurrent divergent writes, sloppy quorums (out-of-sync nodes still count), and read-repair timing all open stale-read windows. Audit check: is W+R>N actually configured (anti-pattern row 9), and is the staleness bound known and measured? "Quorum" without the math is a word, not a guarantee (glossary: Quorum).

**Quorum arithmetic (the two-minute audit):** with N=3, W=2, R=2, a read quorum overlaps at least one node from any write quorum — but which write is "the" overlap depends on timing: if two writes went to disjoint quorums concurrently (both "succeeded"), the reader's overlap may hold either version, and the resolution (last-write-wins by timestamp — section C's lottery, read-repair, or hinted handoff) decides what the reader sees. With sloppy quorums enabled, the overlap itself is void: R reads may hit nodes that never saw the write at all. The audit runs the numbers: N, W, R, sloppy on/off, concurrent-write handling — and names the freshness result as a bound, not a boolean.

**Split-brain, asymmetric:** the dangerous partition is asymmetric — the old leader, cut from a quorum, may still serve clients that can reach it, while the quorum elects a new leader: two nodes accepting writes, two histories, unreconcilable except by data loss. The defenses are structural, not application-level: every write requires quorum acknowledgment (a minority leader cannot commit), leader writes carry **fencing tokens** (monotonic, checked by storage), and leader failover uses **leases** with bounded-drift assumptions, not ping timeouts. "My cluster handles network partitions" without naming quorum/consensus mechanism and fencing is anti-pattern row 4 — see eval `split-brain-handwave`.

**Stale-read reporting — measure, don't guess:** every replicated system can report its staleness: PG replica lag (`pg_last_wal_replay_lsn` vs primary), bounded-staleness follower reads (CockroachDB follower reads with `follower_read_timestamp`), replication lag metrics on MySQL/Cassandra. An audit that can't quote the staleness bound (p99 lag, worst partition case) hasn't audited replication — it has audited hope. Follower reads are legitimate cost savers **with** the bound named and the anomaly risk accepted explicitly (anti-pattern row 12).

**Anomaly → symptom → fix table (the section B decision card):**

| Anomaly | User-visible symptom | Mechanism fix |
|---|---|---|
| Read-your-writes | "my update disappeared" right after write | Session token / sticky post-write routing |
| Monotonic reads | timeline goes backward between refreshes | Session-stable replica routing |
| Quorum lag | stale reads despite "quorum" config | Verify W+R>N, sloppy quorums off, measure bound |
| Split-brain | conflicting rows, "impossible" histories, lost writes after partition | Per-write quorum + leases + fencing tokens |
| Unbounded follower lag | p99 read latency fine, correctness SLO silently broken | Bounded-staleness reads, lag monitoring with SLO |

**How to run a replication audit (the drill):** (1) draw the path — which nodes can serve each request type (reads, post-write reads, writes), including failover paths; (2) per path, name the consistency it actually gets (async replica = no read-your-writes; round-robin = no monotonicity; leaderless quorum = freshness bound, not latest); (3) demand the staleness metric per replica (lag position, p99, worst-case during partition/rejoin — the rejoin spike is where the anomaly bites: lag that was 50ms goes 30s during the partition and replays in a burst); (4) fix per anomaly from the card above; (5) name residual risk — what consistency the system *does not* give, said out loud, so it is a decision instead of a discovery. The audit's product is that residual list, not a blessing.

**Worked example:** User: "our read replicas serve the app, writes go to primary, occasional 'where did my order go' tickets after checkout." Audit output: "Asynchronous replication, no session tokens: read-your-writes violated by construction — the post-checkout read can hit a replica that hasn't applied the order insert. Fix: session token (route to primary until session's last-write LSN applied on the replica — `pg_last_wal_replay_lsn` check) or sticky post-write reads. Monotonicity: pin session to one replica or token-checked routing — round-robin today runs time backward. Residual risk named: primary failure mid-session (acceptable). Quorum split-brain not in play: single-leader, failover is the remaining question — check the failover mechanism (section D) before signing off."

**Worked example 2 — the quorum audit:** User: "Cassandra, we read and write at QUORUM, so reads always see the latest write." Audit output: "No: W+R>N (QUORUM on N=3 → 2+2>3) guarantees the read quorum *overlaps a write quorum*, not that it returns the latest value — concurrent writes to disjoint quorums (both acked) mean your read gets one of two live versions, resolved by timestamp (section C's lottery: LWW by clock, the row-2 anti-pattern at replication scale). Sloppy quorums, if enabled, void even the overlap. And 'latest write' across a network partition isn't a thing — it's 'latest write the surviving quorum saw'. Freshness verdict: bounded staleness, not recency; name the bound (measured read-repair/anti-entropy lag) and pick per-key consistency (LOCAL_QUORUM where stale is acceptable — cheaper; leader reads or consensus-replicated store where recency is sacred). Residual named: no read-your-writes unless the session token's LSN survives the coordinator hop — Cassandra's client timestamps don't give you that for free."

**Multi-region read path — the composed-audit note:** the anomalies compose. A multi-region deployment with local read replicas ships *both* read-your-writes violations (cross-region replication lag, seconds not milliseconds — a session token that waits for the LSN now waits seconds) and monotonicity hazards across region-failover (the token's replica is gone; the session must re-establish its position or route to the new primary). The audit names the composition rather than clearing each anomaly in isolation — a per-anomaly "fixed" checklist on a composed path is how the fourth anomaly slips through unfixed. When the token wait exceeds the latency budget, the honest answers are leader reads for post-write sessions or a consensus-replicated store (section D) — accepting read-your-writes violations silently is anti-pattern row 10 again, one region farther from the write.

## C. Clocks and Ordering

**Time-of-day clocks (NTP-synced wall clocks) are never an ordering mechanism.** NTP can step clocks backward; drift between machines is bounded only loosely; two events stamped on two machines are ordered by their clocks only if you can prove the first happened before the second's timestamp was taken — which NTP does not let you prove. Sorting distributed events by `created_at` timestamp is anti-pattern row 2, and it is the single most common silent corruption in event pipelines: the ordering is *mostly* right, which means it is wrong in production at a rate that defeats reproduction.

**Monotonic clocks measure intervals, not order.** A monotonic clock never steps backward, which makes it right for durations, timeouts, and backoff — and useless for cross-machine ordering, because its epoch is per-machine and its readings are not comparable between machines. The 2026 clock answer for ordering is never "use the monotonic clock instead"; it is "stop ordering by clocks at all."

**Clock mechanism comparison (the decision card):**

| Mechanism | Ordering safe? | Right use | Never for |
|---|---|---|---|
| NTP time-of-day | No — steps, drifts, no proof | Display, logs for humans, coarse TTL | Ordering, conflict resolution, LWW |
| Monotonic clock | No — per-machine epoch | Intervals, timeouts, backoff | Cross-machine anything |
| TrueTime (Spanner) | Yes — bounded uncertainty + commit-wait | Linearizable writes in Spanner | Anything without the hardware + API |
| AWS Time Sync (μs) | No — better wall clock, still a wall clock | Tighter timestamps for display/diagnostics | Ordering |
| HLC | Yes — causal without clock trust | Distributed DB event ordering (CockroachDB, YugabyteDB lineage) | Substituting for real time in user-facing display |

**TrueTime — the exception that proves the rule:** Spanner's TrueTime API returns a timestamp *interval* with bounded uncertainty (GPS + atomic clocks in every datacenter), and commit-wait holds a transaction open until the uncertainty interval has passed — so ordering by TrueTime carries an actual proof. The exception exists because hardware bounds the uncertainty, not because wall clocks got better. The cost is explicit: commit-wait latency equals the uncertainty bound (typically single-digit ms — the price of a provable order), which is why TrueTime lives in Spanner and not in your application tier: without the hardware, the wait buys nothing.

**AWS Time Sync (microsecond-scale) improves the bounds, not the contract:** 2025-era cloud time sync reaches microsecond accuracy (chrony/PTP), which shrinks NTP's error bars usefully — but a better-synced wall clock is still a wall clock: no uncertainty API, no commit-wait, no ordering guarantee. Better clocks reduce the probability of misordering; they do not license timestamp ordering (the probability was never the problem — the lack of a proof was).

**HLC — the 2026 default for cross-machine ordering:** Hybrid Logical Clocks combine a physical timestamp with a logical counter (glossary: HLC) — causally ordered without trusting clocks for correctness, loosely clock-aligned for human readability. CockroachDB and YugabyteDB build on HLC-lineage timestamps; it is the standard answer in distributed databases. Audit verdict format: "events ordered by ingest position / logical clock (HLC); timestamps displayed for humans only." The migration path from a timestamp-sorting bug is mechanical: add an HLC (or sequence/offset) column at the producer, order by it in the consumer, keep `created_at` as display — no clock change required, which is the point.

**HLC mechanics (why it is safe where NTP is not):** each node's HLC holds the largest physical time it has *heard of* (pt) plus a logical counter (c); on send/receive, messages carry the sender's HLC and the receiver advances its own — so a message's timestamp provably dominates everything that causally preceded it, regardless of clock error, while the counter breaks ties when clocks stall. The physical component keeps timestamps approximately human-readable (bounded by real drift); the logical component carries the ordering proof. What HLC does *not* give: total order between causally-unrelated concurrent events (any tie-break there is a choice, not a fact) — which is exactly why last-write-wins on unrelated events remains a conflict-resolution policy, not a truth.

**Cross-region clock reality (the numbers that kill "just sync NTP"):** cross-continent network RTT (tens of ms) bounds how tightly even perfect NTP/PTP sync can run, and cloud NTP tiers step clocks under correction events; within one region, AWS Time Sync's microsecond-scale accuracy narrows error bars but still issues no uncertainty API. Spanner's TrueTime is the only listed mechanism with a *provable* cross-region ordering (GPS + atomic clocks per datacenter + commit-wait that waits out the uncertainty interval — paid in commit latency); every other distributed DB that orders cross-region events without TrueTime uses HLC-lineage logical timestamps, not synced wall clocks. The audit verdict on "our regions are NTP-synced, we sort by timestamp" is always the same refusal: NTP-never (anti-pattern row 2) — microsecond or millisecond, the proof is missing, and ordering without proof is corruption with a delay.

**DDIA 2017: multi-leader conflict resolution by timestamp (LWW). SOTA 2026: last-write-wins is a conflict-resolution anti-pattern — it drops concurrent writes by clock lottery; HLC-ordered or CRDT merge is the default (see `references/isolation-consistency.md` § CRDT).**

**Worked example — clocks in action:**

User: "we rebuild the event order in our audit log by `created_at` — servers are NTP-synced, microsecond precision." Audit output: "Refused: NTP time-of-day is never an ordering mechanism (anti-pattern row 2, section C) — NTP steps clocks backward during correction, drift across machines is bounded only loosely, and microsecond precision narrows the *display*, not the proof: two events 200μs apart on two machines are still unordered unless the protocol guarantees a happens-before edge. Mostly-right ordering is production corruption — the audit log is wrong exactly often enough to be unreproducible. Fix: ingest position (Kafka offset, WAL LSN) or HLC as the ordering field; `created_at` demoted to display metadata. If the audit trail must be provable, the log's ordering comes from the log's sequence, never from the clocks of the writers (references § CRDT for the merge-based variant when multi-writer is unavoidable)."

## D. Consensus

**Raft won.** The 2026 production consensus landscape runs Raft or descendants: etcd (Kubernetes' store), CockroachDB (per-range Raft groups), Consul, NATS (Raft-based JetStream metadata). The reason is not a theorem — Paxos proves the same safety — it is understandability: Raft's specified leader election and log replication made correct, auditable implementations possible, and Jepsen-tested implementations exist for the named engines. Paxos remains the theory the textbooks teach; mainstream production systems ship Raft. An advisory answer that proposes "Paxos" for a greenfield system in 2026 is citing the paper, not the ecosystem.

**Leader leases — failover without split-brain:** election timeouts on wall clocks make the leader's authority ambiguous after a network blip (did it lose leadership, or is it slow?). Production systems use **leases** (glossary: Leader lease): leadership valid for a bounded term under a bounded clock-drift assumption; a leader whose lease expires stops answering even if it feels healthy. The companion defense is **fencing tokens**: every leader's writes carry a monotonically increasing epoch, and storage rejects writes from stale epochs — the asymmetric-partition defense from section B, here in consensus terms. An audit asks for the lease mechanism and the fencing check by name (anti-pattern row 15).

**Witness replicas — quorum participants without data:** a witness joins the quorum/consensus group, votes and acknowledges, but stores no user data — cutting the cost of cross-region quorums (a 3-region deployment can run 2 data-bearing nodes + 1 cheap witness instead of a third full replica). Legitimate for availability math; the audit checks that the witness actually participates in the consensus protocol, not just in heartbeats — a witness that can be partitioned independently reopens the split-brain window it was bought to close.

**Raft mechanics the audit names (election and log, in one pass):** a Raft term is a logical epoch — a leader is leader only within its term, and a higher term always deposes an older leader (the fencing property, structurally built in). Log replication requires the leader to store a majority before acknowledging a client write — a leader cut from the majority cannot ack, which is the quorum-ack defense from section B, here by construction. Election happens on leader loss: followers time out, become candidates, increment the term, and a majority vote elects one — an asymmetrically-partitioned minority cannot reach majority, so it cannot elect, and its stale leader (if clients still reach it) is the only remaining split-brain window, closed by leases + fencing (above). These mechanics are why Raft won operations: the properties this skill demands are the protocol's structure, not an engineer's discipline.

**Consensus scope — per-range, not cluster-wide:** CockroachDB and kin run consensus per range/shard: each key range is its own Raft group. Consequence for audits: a serializable guarantee holds per range transactionally, but cluster-wide statements ("the database is consistent") are not meaningful without naming the transaction layer above consensus. Conversely, systems *without* per-write quorum (async multi-leader replication, Galera-style certification under partition — Jepsen 2025-26 findings in `references/isolation-consistency.md` § Jepsen) do not get split-brain protection from being "clustered" — the mechanism is named or the claim is refused.

**Consensus-adjacent reads (the audit's next question):** leader reads are linearizable, but leader reads pay the cross-region RTT — so systems add consensus-adjacent read modes: ReadIndex/`quorum reads` (leader confirms it still leads by quorum heartbeat, then serves — linearizable at lower latency), lease reads (served under the leader's lease without a quorum round — linearizable *if* the lease's clock-drift assumption holds, section C connection: leases are the one place bounded clock trust re-enters), and follower reads (bounded-staleness, section B's token mechanics). The audit names which mode each read path uses, because "reads from the leader's region" and "reads from any region" are different consistency products wearing the same engine name.

**Consensus decision card:**

| Need | Answer | Check |
|---|---|---|
| Linearizable metadata/config store | etcd (or a system built on it) | Jepsen history, backup/restore drill |
| Linearizable multi-region SQL | CockroachDB / Spanner / YugabyteDB | Per-range consensus + HLC/TrueTime ordering |
| Cheaper cross-region quorum | Witness replica | Witness participates in the protocol (votes), not just heartbeats |
| Leader failover | Leases + fencing tokens | Bounded clock-drift assumption documented; fencing checked on every write |
| Greenfield consensus | Never bespoke — use a Jepsen-tested Raft system | "Paxos" answers are paper citations, not deployments |

**The split-brain drill (run it before signing any "handles partitions" claim):** (1) kill the link between the leader's minority side and the quorum — does the minority-side old leader *fail to ack new writes* (per-write quorum) or *keep committing* (unfenced, split-brain open)? (2) elect a new leader in the majority — do the old leader's in-flight writes get *rejected by storage* (fencing tokens checked at the storage layer, not the client) or *replayed as truth*? (3) heal the partition — is the reconciliation *impossible by construction* (minority writes were never committed, nothing to reconcile) or *manual* (the "we reconcile by hand" answer, which is data-loss-as-a-process)? Three passes, one verdict per pass, and any "manual" in pass (3) means the split-brain window was open in pass (1) — the audit stops there. This drill is the concrete form of eval `split-brain-handwave`.

**Decision rule:** need linearizable writes/metadata → an existing Jepsen-tested Raft system (etcd, CockroachDB, NATS) before any bespoke consensus; need cheaper quorums → witness replicas with real voting participation; need failover → leases + fencing tokens, never ping-timeout elections. Anything else → name what you actually have (async replication, single leader) and its anomaly set — section B.

**Worked example — consensus in action:**

User: "our Postgres primary failed over this morning; monitoring shows a 40-second window where the old primary still accepted writes — we had to reconcile by hand." Audit output: "Asymmetric split-brain, section B/D shape: the old leader was cut from a quorum it could no longer reach, but its *clients* could still reach it — per-write quorum acknowledgment absent, so a minority-side leader kept committing (anti-pattern row 15). Fix ladder: (1) synchronous replication with quorum ack per commit — a cut primary cannot commit, clients fail fast instead of writing into a doomed history; (2) fencing tokens on the storage path — every leader's writes carry a monotonic epoch, storage rejects stale epochs, so even a rogue writer with live clients cannot corrupt the new primary's history; (3) failover by lease with a documented bounded-drift assumption, not ping-timeout — 'slow' and 'deposed' must be distinguishable. Name the mechanism you adopt, and the residual: with (1) alone, a partition inside the client's network can still reach the old primary — (2) is the fence that closes it (see `references/isolation-consistency.md` § Jepsen for the Galera 12.1.2 finding: certification-style 'synchronous' replication lost committed writes during rejoin — mechanism, not marketing word)."

## E. Anti-Patterns

The table is the audit's checklist: each row is a claim shape the agent must refuse or rework, with the fix that makes the claim honest. Rows are numbered for citation from sections A-D and the evals.

| # | ❌ Forbidden | ✅ Fix | Why |
|---|---|---|---|
| 1 | Correctness claim without isolation level named | Name engine + level + anomaly set before any verdict | Iron Law: "safe" is level-relative — the same flow is serializable-safe and SI-corrupt |
| 2 | Ordering distributed events by NTP wall-clock timestamps | HLC / logical sequence / ingest position; timestamps for display only | Clock steps backward, drift unbounded across machines — silent misordering |
| 3 | Check-then-act under RC (`SELECT` then `UPDATE`) | Atomic single-statement UPDATE / `SELECT FOR UPDATE` / raise level | Two flows read the same pre-state — lost update with no error |
| 4 | "Split-brain handled by the app" | Quorum ack per write + leases + fencing tokens | An application cannot detect an asymmetric partition; structure must make minority writes uncommittable |
| 5 | CRDTs everywhere, ignoring costs | Transactions where single-home; CRDTs only for multi-master/local-first merge | CRDT metadata, limited merge semantics, no arbitrary invariants — cost paid for capability unused |
| 6 | Retry on SQLSTATE 40001 without idempotence | Idempotency key + bounded retries + backoff | The retried transaction re-ran its side effects — duplicate charge/email/order |
| 7 | Assuming single-threaded access ("only one user at a time") | Audit for concurrent flows; name the level | The assumption lives in tests, not in production — race surfaces at scale, unreproducible |
| 8 | Wall-clock timestamps inside a distributed/replicated log | Logical timestamps (HLC) or sequence numbers in the log | Log order must be causal; wall clock misorders under drift — corruption baked into the source of truth |
| 9 | "Quorum" claimed without W+R>N verified | Check the math: W+R>N, sloppy quorums off, staleness bound measured | Quorum overlaps *a* write, not *the latest* — and sloppy quorums void even the overlap |
| 10 | Read-your-writes assumed on eventual consistency | Session tokens / sticky routing to leader post-write | Async lag means the user's own write can be invisible to their next read — by construction |
| 11 | Round-robin reads across replicas without session stickiness | Pin session or token-checked routing | Breaks monotonic reads: time runs backward across laggier replicas |
| 12 | Follower reads served without a measured staleness bound | Report p99/worst-case lag; bounded-staleness reads; name the residual risk | Unbounded staleness is an SLA violation waiting for the first partition |
| 13 | SERIALIZABLE on everything "for safety" | SSI on invariant-carrying flows; lower levels with named anomalies elsewhere | Predicate-lock overhead + abort storms under contention — protection priced, not free |
| 14 | Treating MySQL InnoDB RR as serializable | SSI-style verification or explicit locks; read Jepsen findings first | Jepsen (8.0.32–9.0.1): lost updates and write skew observable under RR |
| 15 | Leader failover by ping-timeout, no lease/fencing | Leases with bounded drift + fencing tokens checked on every write | Old leader in asymmetric partition keeps committing — split-brain writes |

**How to cite the table:** an audit verdict references rows by number in its refusal ("anti-pattern row 6: retry without idempotence") and every row cited must carry its fix in the same breath — naming the violation without the fix is complaining, not auditing. When a claim matches multiple rows (e.g., "we sort events by timestamp and our cluster handles partitions" → rows 2 + 4), the audit refuses once per row and does not bundle them into a generic "be careful" — each row has its own mechanism fix, and bundling loses the fix.

## Document Metadata

| Field | Value |
|---|---|
| Document ID | `SKILL-D3-001` |
| Revision | 1 |
| Effective Date | 2026-08-29 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |

## Audience

- **Primary** : Agent/engineer reasoning about transaction isolation, replication anomalies, consensus behavior, or distributed-systems edge cases.
- **Secondary** : Maintainers editing this skill; reviewers auditing concurrency claims.
- **Expertise** : Intermediate — reader has written transactions and heard of eventual consistency.
- **Needs to learn** : Per-engine isolation matrices, write-skew detection shape, session tokens, HLC, Raft/leases/fencing.
- **Common misconceptions** : "transactions make it safe" (level decides), "SI is serializable" (write skew), "MySQL RR prevents phantoms therefore serializable" (Jepsen: no), "NTP sync makes timestamps orderable" (no proof), "quorum means fresh reads" (overlap ≠ latest), "split-brain is a rare full partition" (asymmetric is the killer).

## Purpose / Scope
**Purpose** : enforce isolation-level-named concurrency and consistency claims. LLM training data emits "safe", "consistent", and "ordered" verdicts without naming the level, the anomaly class, or the retry story; this skill forces the three-part audit before any correctness verdict.

**Covers** : isolation levels per engine (PG RC/SI-RR/SSI-40001, MySQL RR per Jepsen, SQL Server lock-based), write skew (card-game shape), lost update, replication anomalies (read-your-writes, monotonic reads, quorum lag, asymmetric split-brain, stale-read reporting), clocks (NTP-never, monotonic-intervals-only, TrueTime, AWS Time Sync bounds, HLC), consensus (Raft won, leader leases, witness replicas, Paxos theory-only), 15 anti-patterns, 3 evals.

**Does NOT cover** : chaos engineering execution (running fault injection), Jepsen runs (this skill cites Jepsen findings as advisory evidence — running tests is out), datastore choice (`ddia-tradeoff-analyzer`), storage engine internals (`ddia-storage-internals`), pipeline semantics and at-least-once delivery mechanics (`ddia-pipeline-architect`).

**Scope-out rationale** : chaos engineering and Jepsen harnesses are practices with their own operational discipline — this skill consumes their findings, it does not instruct running them; engine internals and pipeline delivery are siblings' domains (see Related Skills) — referencing, not duplicating, keeps each skill under its line budget.

**Glossary dependency** : `_shared/ddia-glossary.md` Distributed section (quorum, HLC, TrueTime, SI/SSI, write skew, split-brain, leader lease) is load-bearing for sections A-D; edits there flag this Revision History.

## Definitions

| Term | Meaning |
|---|---|
| Session token | Per-session record of the last write's timestamp/LSN; a replica serves the session only after applying past it — the read-your-writes and monotonic-reads mechanism. |
| Anomaly matrix | Table of anomaly (dirty read, non-repeatable read, phantom, lost update, write skew, read skew) × isolation level — the per-engine ground truth in `references/isolation-consistency.md` § matrix. |
| Fencing token | Monotonic per-leader epoch attached to every write; storage rejects stale epochs — the asymmetric-partition defense. |
| rw-antidependency | SSI's tracked shape: one transaction's read predicate overlaps another's write range — the write-skew signature that triggers a 40001 abort. |
| Witness replica | Quorum/consensus participant that votes but stores no user data — cuts cross-region quorum cost; must participate in the protocol, not just heartbeats. |
| Commit-wait | TrueTime/Spanner mechanism: hold the transaction until the uncertainty interval passes, so the timestamp ordering is provable. |
| Bounded staleness | A read served from a follower with a declared upper bound on its lag (timestamp or token checked) — the auditable form of follower reads. |

Common terms (quorum, HLC, TrueTime, SI, SSI, write skew, split-brain, leader lease) are defined in `_shared/ddia-glossary.md` — never duplicated here. That glossary is the shared kernel across the four ddia-* skills; a term common to two or more of them belongs there, not in this table.

**Boundary rule** : when writing a local definition, check the glossary first — if the term exists there (leader lease → glossary), reference it; if it is distributed-debugger-specific (session token, fencing token, commit-wait, witness), it stays local; if it belongs to another sibling's domain (LSM, compaction → storage-internals; watermark, CDC → pipeline-architect), it does not belong here at all.

## Evals

Run these 3 pressure scenarios after any edit. Each must FAIL in the specific way described (agent refuses violation).

### Scenario 1 : vague-correctness-claim

**Given** : the skill is loaded.
**When** user says: "C'est safe — j'utilise des transactions pour la réservation."
**Expect FAIL** : Agent does not confirm safety. Cites Iron Law + Hard Gate, refuses the claim until the isolation level is named, asks which engine and level (RC vs SI vs SSI), and explains the difference: under RC a check-then-act reservation flow is a lost-update factory; under SI the cross-row seats invariant is write-skew-exposed — the card-game shape; only SSI + idempotent retry closes it. Baseline (no skill) would confirm "oui, transactions = safe".

### Scenario 2 : ntp-trust

**Given** : the skill is loaded.
**When** user says: "Je trie mes events par timestamp pour reconstruire l'ordre — les serveurs sont synchronisés NTP."
**Expect FAIL** : Agent refuses wall-clock ordering. Cites section C + anti-pattern row 2: NTP steps backward, drift unbounded across machines — mostly-right ordering is production corruption. Proposes HLC (the distributed-DB standard), logical sequence numbers, or ingest position as the ordering; timestamps demoted to display metadata. Baseline would confirm the sort.

### Scenario 3 : split-brain-handwave

**Given** : the skill is loaded.
**When** user says: "Pas de souci — mon cluster gère les partitions réseau."
**Expect FAIL** : Agent does not accept the handwave. Cites section B/D + anti-pattern row 4: asks for the mechanism by name — quorum acknowledgment per write? Which consensus (Raft)? Leases? Fencing tokens? — and explains asymmetric split-brain: the minority-side old leader keeps serving reachable clients while the quorum elects a new one; without per-write quorum + fencing, "handles partitions" is a feeling, not a property. Baseline would reassure.

**Protocol** : manually, subagent fresh-context, with-skill vs baseline. Log to `_shared/evals/2026-08-29-ddia-distributed-debugger-eval.log` (gitignored).

Baseline capture: the baseline run (fresh subagent, no skill loaded) must be logged *before* the with-skill run on the same prompt — its failure shape ("oui c'est safe", "trie par timestamp, c'est bon", "les clusters gèrent ça") is the regression signature; if a future edit makes the baseline fail too, the eval lost its discriminating power and the prompt needs sharpening, not the skill.

**Pass criteria** : the with-skill run must refuse/re-ask per each Expect; the baseline run must fail by confirming safety (scenario 1), confirming the timestamp sort (scenario 2), or reassuring about partitions (scenario 3). If the with-skill run issues any correctness verdict in scenario 1 before the level is named, the Hard Gate wording was too weak — revise the gate, not the eval. If the with-skill run accepts "NTP suffices, we just sort" in scenario 2 with a caveat instead of a refusal, section C's NTP-never rule was too soft — strengthen "never an ordering mechanism", not the eval. If the with-skill run in scenario 3 accepts any named mechanism at face value (user says "we have quorum" and the agent stops there — without the W+R>N math, the lease mechanism, the fencing check), section D's split-brain drill was too weak — the drill must demand the three passes, not the mechanism's name.

**Eval discipline note** : scenarios 1-3 are the minimum regression set, each targeting one gate input (scenario 1 → input 1 level, scenario 2 → section C clocks which back input 2's anomaly reasoning, scenario 3 → input 2/3's structural mechanisms). After any edit to the Hard Gate, a section A-D rule, or an anti-pattern row, rerun all three; after a metadata-only edit (Metadata, Revision History), rerun scenario 1 only (the gate's enforcement wording is the most drift-prone surface). Log every run with timestamp and verdict per criterion — a PASS that can't cite which paragraph refused the violation is an unverified PASS.

## The Iron Law (reminder)

> **NO CONCURRENCY CORRECTNESS CLAIM WITHOUT ISOLATION LEVEL NAMED.**

If you reached this point without the three audit inputs (isolation level named on the engine at hand, anomaly class considered, retry/idempotence story) on your last verdict, go back. Your training data has a favorite "safe" from a specific database's manual — the level-anomaly-retry triple is the only antidote. Sections A-D and the matrix in `references/isolation-consistency.md` are ground truth.

**Modification note** : this skill consumes `_shared/ddia-glossary.md` (Task 1 product). Glossary edits require flagging this Revision History per the glossary's modification protocol. The shared Distributed terms (quorum, HLC, TrueTime, SI/SSI, write skew, split-brain, leader lease) are this skill's load-bearing vocabulary — a glossary edit to any of them is a section A-D re-audit trigger, not just a flag.

## Revision History

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-08-29 | Initial SOTA 2026 distributed debugger: type:sub-skill + 5 contracts; Iron Law ×3; Hard Gate; Snapshot; Quick Reference projection; Related Skills typed; sections A-E (isolation levels per engine + write skew card game, replication anomalies + session tokens, clocks NTP-never/HLC, consensus Raft/leases/witness, 15 anti-patterns); 3 evals; `references/isolation-consistency.md` indexed. | Skills maintainer | Skills maintainer |