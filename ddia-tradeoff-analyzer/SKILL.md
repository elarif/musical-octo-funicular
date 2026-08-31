---
name: ddia-tradeoff-analyzer
description: Use when choosing between data stores, data models, replication strategies, or serialization formats — recommending a database or protocol without profiling the workload (access patterns, scale, consistency needs) ships a system that fights its storage engine and fails at the first scale step
type: sub-skill
contracts:
  - data-model-arbitrage
  - replication-models
  - serialization-formats
  - anti-patterns-table
  - decision-framework
---

# DDIA Trade-off Analyzer

## The Iron Law
> **NO DATASTORE CHOICE WITHOUT EXPLICIT TRADE-OFF ANALYSIS NAMED.**

This is not a guideline. Every datastore choice is a trade-off: consistency vs latency, write throughput vs query flexibility, operational simplicity vs scale headroom. The agent's training data skews toward hype databases from specific eras (Mongo 2013, Cassandra 2015, CockroachDB 2021) and will recommend them by default unless forced to profile the workload first. Any recommendation this skill emits must name the trade-offs accepted — what gets worse, not just what gets better. If the workload profile (access patterns, read/write ratio, consistency requirements) is unknown, the profile is requested before any database is named.

**Why workload profiling comes first:** access patterns determine the storage model fit (point lookup vs range vs traversal vs analytics map to different engines); read/write ratio and scale determine whether distribution is even needed; consistency requirements determine the replication and consensus mechanism. Skipping the profile means choosing blind on all three axes simultaneously — the failure compounds.

## Hard Gate

<HARD-GATE>
Do NOT emit, endorse, or shortlist any datastore, replication topology, or serialization format without first having (1) access patterns named (point lookup, range scan, traversal, analytics), (2) read/write ratio and scale estimate (QPS, dataset size, growth), and (3) consistency requirements stated (read-your-writes? linearizable reads? acceptable staleness). This applies even under deadline pressure, even for "quick prototypes", even when the user says "just use MongoDB".
</HARD-GATE>

This gate exists because three failure modes recur on every datastore question: (1) the user arrives with the answer pre-chosen ("just use MongoDB") and a compliant agent rationalizes it instead of profiling — the fix is refusing until the five questions of section E are answered; (2) "we need NoSQL to scale" with no evidence — most workloads fit a single Postgres node and the distributed premium is paid for nothing; (3) serialization chosen by fashion (Avro for a greenfield streaming system in 2026) — the default has moved and stale training data keeps recommending it. The gate forces the profile to the surface before any engine is named.

**Gate enforcement — the three numbered requirements:**

| Requirement | What satisfies it | What does not |
|---|---|---|
| (1) Access patterns named | "point lookups by user ID + time-range scans" | "typical web app queries" |
| (2) Read/write ratio + scale | "50:1, ~500 writes/sec peak, GB-scale" | "will scale to millions of users someday" |
| (3) Consistency requirements | "read-your-writes for the session user, eventual OK elsewhere" | "strong consistency" (unqualified) |

If any row is unanswerable, the output is the five questions of section E — not a conditional recommendation. "You could use X, but tell me…" violates the gate: partial recommendations anchor the user.

## Snapshot

This skill owns the rules an agent applies when choosing between data stores (relational vs document vs graph vs distributed SQL vs leaderless), replication strategies (single-leader, multi-leader, leaderless quorum, consensus-based multi-region), and serialization formats (Protobuf, Avro, Arrow). It mandates workload profiling before any recommendation (access patterns, read/write ratio, consistency requirements), a 2026 Postgres-first stance (JSONB, pgvector, Apache AGE, full-text before leaving the RDBMS), quorum arithmetic W+R>N for leaderless stores, session tokens for read-your-writes, Protobuf + Buf/BSR as the 2026 serialization default, and a 15-row anti-patterns table. Numeric benchmark emission and SQL implementation are out of scope. Full data-model comparison detail lives in `references/data-models.md`.

**Announce at start:** `I'm using the ddia-tradeoff-analyzer skill to analyze this datastore trade-off.`

**Failure mode this skill prevents:** an agent asked "which database?" names one from its training-data era (Mongo 2013, Cassandra 2015, CockroachDB 2021) without profiling the workload, the team ships it, and the system fights its storage engine — joins emulated in application code, consistency undefined, scaling wall hit at the first real load. The five-question framework (section E) and trade-off naming are the countermeasure.

## Quick Reference (projection — see Content sections for full rules)

**Quick Reference projection table** — summary card; full rules in sections A-E. If the card and the sections disagree, the sections win.

The card exists for fast pattern-matching by the agent mid-task; it does not replace reading the section.

| Field | Value |
|---|---|
| Audience | Agent or engineer choosing a datastore, replication strategy, or serialization format |
| Trigger | "which database for…", "Mongo vs Postgres", "how should we replicate", "Protobuf or Avro", "scale to X" |
| Inputs | Workload description; the five profile questions of section E if absent |
| Outputs | Recommendation naming accepted trade-offs; profile questions if workload unknown |
| Type | sub-skill (see `_shared/SKILL-ARCH.md`) |
| Baseline | Postgres-first until proven scale limits; Protobuf + Buf default serialization |
| Iron Law | NO DATASTORE CHOICE WITHOUT EXPLICIT TRADE-OFF ANALYSIS NAMED |
| Scope out | Numeric benchmarks, SQL implementation, query tuning |
| Identity | Descriptive name (`ddia-tradeoff-analyzer`); stable — do not rename |

## Related Skills

| Sibling | Relationship | What crosses the boundary |
|---|---|---|
| `using-superpowers` | `upstream` | Routes datastore-choice triggers here. Translation: using-superpowers's "trigger match" = this skill's "trade-off analysis announced". |
| `writing-skills` | `shared-kernel` | Co-maintains TDD-for-skills vocabulary. This skill applied RED→GREEN→REFACTOR during its own authoring. |
| `technical-writing` | `shared-kernel` | Co-maintains 4-slot discipline (Audience, Purpose/Scope, Definitions, Revision History). |
| `_shared/ddia-glossary.md` | `shared-kernel` | Quorum, HLC, SI/SSI, write skew, WAL, CDC, outbox definitions live there. Never duplicated here. |
| `_shared/glossary-en.md` | `shared-kernel` | TDD/RED/GREEN/Iron Law/Hard Gate terms live there. |
| `ddia-storage-internals` | `none` | Independent domains, no mutual invocation. LSM/B-tree internals vs store choice. This skill names the engine; that one tunes it. |
| `ddia-distributed-debugger` | `none` | Independent domains, no mutual invocation. Isolation/consistency anomalies vs topology choice. |
| `ddia-pipeline-architect` | `none` | Independent domains, no mutual invocation. Pipeline semantics vs store choice. This skill names the source of truth; that one moves data out of it. |

**Sibling boundary note** : the four ddia-* skills cover independent domains (choice vs internals vs correctness vs movement). No skill invokes another; a single conversation may load two (e.g., store chosen here, then its LSM tuned there), but each enters via its own trigger, not a call from this one.

## A. Data Model Arbitrage

**Canonical workload → model mappings (full table in `references/data-models.md`):**

| Workload | Model | Why |
|---|---|---|
| Feed/fil d'actualité | Document | Post = self-contained aggregate, whole-document reads |
| ACL depth ≤ 3 | Relational + FK | Joins + constraints suffice |
| ACL unbounded inheritance | Graph | Variable-depth traversal dominates |
| Audit bitemporal | Relational or XTDB | Valid-time + transaction-time queries |
| Catalogue, attributs variables | `jsonb` document | Per-category schemas, GIN indexes |
| Recherche similitude | `pgvector` | ANN over embeddings |

**Decision tree (walk it in order):**

1. **Relational (default)** — data has relationships, integrity matters, queries evolve after launch, team knows SQL. Start here. Postgres covers JSON documents (`jsonb` + GIN), vectors (`pgvector`), graph traversal (Apache AGE), full-text search (`tsvector`), and geospatial (PostGIS) in one engine.
2. **Document (escape hatch)** — data is a self-contained aggregate, queries are key-based or whole-document, schema varies per record. Use `jsonb` first; leave for a dedicated document store (MongoDB) only at proven scale limits or when the write pattern overwhelms row overhead.
3. **Graph (narrow niche)** — workload is dominated by recursive multi-hop traversal (friend-of-friend depth 4+, fraud rings, dependency chains with variable depth). For 1-2 hop queries, recursive CTEs or AGE on Postgres suffice. Neo4j/Memgraph only for heavy recursive traversal as the core access pattern.

**Decision-tree walk discipline** : start at node 1 every time — do not skip to the exciting engine. Most requests that mention "graph" or "scale" are answered by node 1 (relational) with an extension. The tree exits early on purpose: each exit past Postgres adds an operational surface, and the burden of proof rises with each hop.

**Stance 2026 — Postgres-first.** DDIA 2017: document and relational stores were converging already. SOTA 2026: convergence complete. Postgres 18 with JSONB (indexed via GIN), pgvector (ANN search), Apache AGE (openCypher graph queries), and full-text search handles 90% of workloads that 2015-era advice sent to MongoDB/Elasticsearch/Neo4j separately. Leaving Postgres requires a proven scale limit or a workload-specific ceiling (e.g., write throughput beyond a single primary), not a vibe. Each departure adds a second operational surface.

**Model comparison matrix:**

| Dimension | Relational | Document | Graph |
|---|---|---|---|
| Query flexibility | Ad-hoc joins, any direction | Within-document + key lookups | Traversal patterns only |
| Schema | Enforced pre-write | Per-record, read-time | Edge/property typed, structure free |
| Integrity | FK + constraints, engine-enforced | Application-enforced | Application-enforced |
| Multi-entity transactions | Native ACID | Weak-to-decent (engine-dependent) | Possible but secondary |
| Write locality | Row/page | Whole aggregate | Node + incident edges |
| Ops surface (2026) | Universal expertise | Common | Rare expertise |
| Default answer for | 90% of workloads | Aggregate-shaped data | Deep traversal data |

**When to actually leave Postgres (measured triggers only):**

| Trigger | Exit to |
|---|---|
| Sustained writes > single-primary ceiling (~10k+ writes/sec after tuning) | Distributed SQL (CockroachDB/YugabyteDB) or leaderless (ScyllaDB) per section B |
| Vector search > ~10M vectors with tight latency SLO | Dedicated vector engine |
| Recursive traversal depth ≥ 4 as the dominant pattern | Neo4j/Memgraph |
| Full-text relevance tuning beyond `tsvector` at scale | Elasticsearch/OpenSearch |
| Anything else | Stay. The answer is probably an index or partitioning. |

**Spanner-class multi-model.** Google Spanner's relational + interleaved + graph-in-progress convergence shows where the top of the market goes: one strongly-consistent engine, multiple models. When global consistency is required at the start, consider Spanner/CockroachDB/YugabyteDB directly (section B) rather than gluing stores.

**Detail** — workload examples, extension rationale, migration triggers: `references/data-models.md`.

**Document model limits to state when recommending it:** denormalization drift (the same fact copied across aggregates must be updated everywhere — name the invalidation strategy or don't recommend); no cross-document joins (the application becomes the join engine); aggregate boundaries guessed at design time are expensive to move (restructuring = migration of the whole store). If any of these is unacceptable, the data is relational — return to node 1 of the tree.

## B. Replication Models

**Single-leader (default).** One primary accepts writes; replicas apply the log. Mature everywhere: Postgres logical replication (publications/subscriptions, PG 15+ row/column filtering), MySQL Group Replication, native on every managed cloud SQL. Fits every workload where writes fit one node (the overwhelming majority — see Postgres-first, section A). Trade-off: failover windows (seconds), replica lag on reads.

**Single-leader detail — what to check before recommending:**

- **Replication slot retention** (Postgres): a downed consumer with an active slot can disk-full the primary — name max_slot_wal_keep_size. PG 17+ `failover slots` address the promotion-loss case.
- **Failover mechanics** : Patroni + etcd is the self-managed standard; cloud-managed (RDS/Cloud SQL) handles it with RTO minutes. Recommend one, name the RTO.
- **Replica types** : streaming (physical) for scale reads; logical for selective/transform replication into other stores (the CDC gateway — pipeline-architect's entry point). Name which and why.

**Leaderless (Cassandra/ScyllaDB).** No leader; any replica accepts writes; consistency via quorum — W + R > N guarantees overlap (see `_shared/ddia-glossary.md`: Quorum). Choose for: write-heavy scale-out, tunable per-query consistency, TB+ datasets with key-based access. Trade-offs: no cross-partition transactions, read repair + hinted handoff complexity, tombstone debt. 2026 ScyllaDB ships tablets (dynamic shard rebalancing) and per-table rate limiting — the operational pain of vnode rebalancing is gone. Still: this is a scale-out engine for a scale-out problem. Under ~10k writes/sec sustained, it is over-engineering.

**Multi-leader (rarely justified) — detail.** Multiple acceptors, conflict resolution becomes the application's problem. Cross-datacenter latency avoidance is the only common driver — and 2026 consensus engines (below) solve it better. If a multi-leader topology is proposed, demand the conflict-resolution strategy (last-write-wins is data loss for anything non-commutative; CRDTs only for genuine commutative state) and justify why single-leader with async cross-region replication fails the requirement. LWW-based multi-master (legacy Galera-era) counts as an anti-pattern for state that matters.

**Read-your-writes.** Reading from an async replica after writing to the primary loses the user's own write. Fixes, in order of cost: route session reads to the primary; session tokens (detail below); causal consistency flags in client drivers. Name the mechanism in any recommendation that involves async replicas serving user-facing reads.

**Session tokens — mechanism detail.** After a write at LSN L, the client records L. A replica serving a read must acknowledge it has applied ≥ L (Postgres: compare against `pg_last_wal_replay_lsn()`; the standby-slot status API in PG 17+ automates the wait). If the replica lags, either wait, or route the session's reads to the primary until it catches up. MongoDB: causal-consistency sessions in the driver do the same against cluster time. Redis: `WAIT` command. Every async-replica read path in a recommendation names one of these or the read-your-writes requirement is unmet.

**Replication model comparison:**

| Dimension | Single-leader | Multi-leader | Leaderless | Consensus (CRDB/Spanner/Yugabyte) |
|---|---|---|---|---|
| Write scalability | One node | N acceptors | N nodes, partitioned | Partitioned (per-range Raft) |
| Conflict handling | None (one truth) | App must resolve | LWW/tombstones (see row 9) | None (consensus orders) |
| Consistency ceiling | Linearizable (primary) | Eventual, per-acceptor | Tunable quorum, not linearizable | Linearizable globally |
| Multi-region fit | Async replicas, lag | Historical driver | Good for AP workloads | Native active-active |
| Failover | Promotion window (s) | N/A but split-brain risk | No leader to fail | Automatic, seconds |
| Default verdict 2026 | Default | Rarely justified | Write-heavy TB+ scale-out | Global consistency from day 1 |

**Multi-region active-active = consensus engines.** CockroachDB, Spanner, YugabyteDB — Raft/consensus per range, single logical database across regions, no application-side conflict code. This is the 2026 replacement for multi-leader DIY. Trade-off: write latency floor of a majority region round-trip. If active-active is requested, these are the default answer, not Cassandra-style LWW.

**Multi-region topology decision (latency vs consistency):**

| Requirement | Topology | Write latency | Consistency |
|---|---|---|---|
| Users in one region | Single primary, region-local | Low | Linearizable |
| Read latency global, writes central | Primary + geo read replicas | Low (reads local) | Reads eventual (session tokens if needed) |
| Writes multi-region, eventual OK | Leaderless (Cassandra LWW) | Low | Eventual, conflicts lost |
| Writes multi-region, linearizable | Consensus engine (CRDB/Spanner/Yugabyte) | Majority RTT floor | Global linearizable |

The last row's cost is physical, not implementable away: a linearizable write in a 3-region cluster with quorum 2 of 3 waits for the second-nearest region's ack. If the requirement is "active-active AND low write latency AND linearizable", one of the three is being waived — get it named.

**Leaderless consistency arithmetic (name it or don't recommend quorums):**

- N replicas, write quorum W, read quorum R. Overlap guaranteed iff **W + R > N** (see `_shared/ddia-glossary.md`: Quorum).
- Tolerates up to (N − W) lost writes on failure and (N − R) down nodes on reads — never both silently.
- R + W ≤ N = cheaper, but stale reads possible even with all nodes up.
- Per-query tuning (ONE vs QUORUM vs ALL) is a consistency decision, not a performance knob — each read that weakens R must be justified by the staleness tolerance from question 3.

## C. Serialization Formats

**Protobuf is the 2026 default** for service-to-service and event schemas. Backward/forward compatibility with explicit field numbering, compact, every language. DDIA 2017: Thrift/Avro/Protobuf contested. SOTA 2026: contest settled.

**Buf + BSR replace the Confluent Schema Registry as the governance layer.** Buf Schema Registry provides linting (style + naming), breaking-change detection (wire and source compatibility rules, enforced in CI), and generated SDK distribution. This replaces hand-maintained registry compatibility configs; the anti-pattern row "no schema registry" in section D now means "no Buf/BSR (or equivalent) governance".

**Buf/BSR workflow (the 2026 governance loop):**

1. Schema defined in `.proto`, field numbers allocated append-only.
2. `buf lint` in CI — style rules (naming, package structure) before review.
3. `buf breaking` against the BSR main branch — wire + source compatibility enforced before merge.
4. Consumers pull generated SDKs from BSR — no local `protoc` invocation drift.
5. Deprecation via `reserved` + comments — never reuse a retired field number.

**Avro is a niche.** Remaining use cases: Kafka + Hadoop/Impala lineage where the ecosystem speaks Avro natively, schema-resolution-heavy batch. For greenfield streaming 2026: Protobuf. Recommending Avro wholesale is a 2015-era answer (see eval `outdated-advice`).

**Avro's remaining legitimate cases — name them precisely when invoked:** (a) existing Confluent platform with registry-based schema resolution in production and no appetite for migration; (b) Hadoop-ecosystem batch pipelines where Impala/Hive readers expect Avro container files; (c) dynamic schema resolution where the writer schema travels with the data (Avro's design center). Everything else in 2026 is Protobuf: better tooling (Buf), broader language coverage, and breaking-change CI that Avro ecosystems never matched.

**Arrow is analytics interchange.** Columnar in-memory format for zero-copy between analytical engines (DuckDB, ClickHouse, Spark, Polars). It is not an event serialization format — different layer.

**Serialization comparison:**

| Dimension | Protobuf | Avro | Arrow |
|---|---|---|---|
| Compatibility model | Field numbers, explicit | Schema resolution, writer-side | N/A (interchange) |
| Governance 2026 | Buf/BSR lint + breaking CI | Registry (Confluent lineage) | Spec-driven |
| Best at | Events, service APIs | Legacy Kafka/Hadoop batch | Analytical columnar handoff |
| 2026 verdict | Default | Niche | Analytics-only |

**Iceberg vs Protobuf — different schemas, keep them separate.** Iceberg governs table schema (analytical datasets, lakehouse); Protobuf governs event schema (messages in motion). A pipeline has both, they evolve independently, and conflating them (deriving tables from Protobuf exclusively, or events from Iceberg schemas) couples streaming and analytical evolution cycles wrongly. Streaming-table convergence is `ddia-pipeline-architect`'s domain.

**gRPC note** : Protobuf + gRPC pair naturally for service-to-service RPC; the same `.proto` files feed BSR governance and SDK generation. This makes Protobuf the default even when no message broker is in the picture — service contracts and event contracts share one governance pipeline.

**Schema evolution checklist (serialization choice is a contract, not a one-off):**

1. Field numbering / tagging is append-only — reserved numbers are never reused, retired fields stay reserved.
2. Breaking-change detection runs in CI (Buf policy or equivalent) before a producer ships — not discovered by a consumer in prod.
3. Compatibility mode is named per stream: backward-only (old readers, new writers) or forward too (new readers, old writers) — "compatible" unqualified is meaningless.
4. Governance tooling (BSR or equivalent registry) is named at the same time as the format — format without governance is anti-pattern row 4.

## D. Anti-Patterns

| # | ❌ Forbidden | ✅ Fix | Why |
|---|---|---|---|
| 1 | Mongo (or any document DB) by default | Postgres `jsonb` + GIN index; document DB only at proven limits | Second operational surface + weaker consistency for zero benefit at typical scale |
| 2 | Graph DB for simple joins | Recursive CTE or Apache AGE on Postgres | Neo4j for 1-2 hop queries = new engine for what SQL already does |
| 3 | JSON stored as text everywhere, no indexing | `jsonb` columns + GIN expression indexes | Text JSON: no index, no stats, planner blind, every query a full scan |
| 4 | No schema evolution plan before first event ships | Buf breaking-change detection in CI from day 1 | Consumers break silently; retrofitting compatibility = rewriting producers |
| 5 | Multi-leader without named conflict resolution | Single-leader + async replicas, or consensus engine | Conflict resolution moves into app code nobody wrote — divergence is silent |
| 6 | DB choice without read/write ratio stated | Answer section E questions, then choose | The ratio is the single biggest predictor of engine fit |
| 7 | "We need NoSQL to scale" without profile | Measure: single Postgres node handles most workloads | Distributed premium paid for nothing; 2PC-free scaling has costs that show up later |
| 8 | Dedicated vector DB under ~10M vectors | `pgvector` (HNSW index), move past proven limits | Pinecone et al add cost + data sync; pgvector serves the RAG scale most teams hit |
| 9 | LWW multi-master for non-commutative state | Consensus engine (CockroachDB/Spanner/Yugabyte) | Last-write-wins = silent data loss on conflicting updates |
| 10 | Read-your-writes assumed free on async replicas | Session tokens or primary-routed session reads | Users see their own writes vanish — reported as "bug" forever |
| 11 | Avro for greenfield streaming 2026 | Protobuf + Buf/BSR | Avro niche is legacy Kafka/Hadoop lineage; default moved years ago |
| 12 | Leaderless (Cassandra) under ~10k writes/sec | Postgres, maybe with read replicas | Over-engineering: tombstone debt, no JOINs, ops complexity for zero gain |
| 13 | One database for wildly different access patterns ("polyglot" from day 1) | Start Postgres multi-model; split only on measured pain | Premature polyglot persistence = N backup strategies, N failure modes, no team expertise |
| 14 | Vector search bolted onto OLTP store without index type named | `pgvector` HNSW vs exact — name ANN vs precise trade-off | ANN index trades recall for speed; unnamed = users surprised by missed results |
| 15 | Serialization chosen before consumers exist | Protobuf default; justify any deviation in the ADR | Format choice made in vacuum ossifies before the first consumer is written |

## E. Decision Framework

**Before naming any datastore, answer all five. If the user's request lacks them, ask — the request is incomplete:**

1. **Access patterns?** — Point lookups by key? Range scans? Multi-entity joins? Recursive traversal? Aggregation/analytics? Full-text? Vector similarity? Each maps to an engine strength; the dominant pattern decides the primary store.

2. **Read/write ratio + scale?** — 100:1 read-heavy fits single-leader + replicas. Write-heavy key-based at TB+ fits leaderless. Sub-10k writes/sec total: Postgres, full stop, regardless of ratio. Scale numbers absent = ask for them (anti-pattern row 6).

3. **Consistency requirements?** — Read-your-writes (session tokens, section B)? Monotonic reads? Linearizable (single-leader or consensus engine — leaderless quorum reads are not linearizable)? Eventual-acceptable (async replicas fine)? Staleness tolerance unstated = assume read-your-writes for user-facing reads.

4. **Schema evolution?** — Rigid relational vs flexible document is a false 2017 binary (JSONB); the real question is: does the event/table schema have a governance pipeline (Buf for events, Iceberg for tables)? No plan = anti-pattern row 4 regardless of engine.

5. **Team ops experience?** — A Cassandra the team cannot operate at 3am is worse than a Postgres they know. Operational maturity is a legitimate input, not a cop-out — but name it as the reason, not post-rationalize.

**Question → engine consequence map:**

| Answer | Consequence |
|---|---|
| "Mostly point lookups by key" | Key-value/document shaped — leaderless viable at scale |
| "Joins across entities" | Relational; document store shifts joins to app code |
| "Traversal depth 4+" | Graph engine or AGE |
| "Analytics dominates" | Columnar/lakehouse — see ddia-storage-internals |
| "Read-your-writes" | Session tokens or primary-routed session reads (section B) |
| "Linearizable globally" | Consensus engine; multi-leader and LWW excluded |
| "Writes < 10k/sec" | Postgres; distribution premium unpayable |
| "Schema fixed by firmware" | Serialization cheap; Avro schema-resolution unnecessary |
| "Schema evolves weekly" | Buf breaking-CI mandatory (section C) |
| "Team knows only MySQL" | MySQL GR is a legitimate single-leader answer — name it |

**Every recommendation must name the accepted trade-offs.** Format: "Recommend X. Accepted trade-offs: Y gets worse (quantify if known), Z risk, mitigation W." A recommendation that only lists benefits violates the Iron Law. Example: "Postgres + read replicas. Trade-offs: reads are eventually consistent (lag ~ms, failover RTO seconds); write ceiling single-primary — revisit at sustained 10k+ writes/sec."

**Worked example — the five questions in action:**

User: "SaaS app, B2B project management tool." Profile: (1) access = joins across projects/tasks/users/comments + ad-hoc reporting; (2) read-heavy 50:1, ~500 writes/sec peak, GB-scale; (3) read-your-writes for the editing user, eventual fine elsewhere; (4) schema evolves, migrations routine; (5) team = Postgres veterans.

Output: "Postgres, single primary + 2 read replicas, session reads routed to primary. Trade-offs: eventual consistency on replica reads (lag ms — acceptable per (3)); single-primary write ceiling — huge headroom at 500 writes/sec; no horizontal write scale — revisit if 20x growth. Rejected: MongoDB (joins dominate, row 1), Cassandra (write scale unneeded, row 12), dedicated search engine (tsvector suffices until proven otherwise)."

**Worked example 2 — write-heavy:**

User: "IoT telemetry, 50k sensors, 10 writes/sec each = 500k writes/sec, queries = latest value per sensor + hourly aggregates, 12-month retention." Profile: (1) access = point lookup by sensor + time-range aggregate; (2) write-heavy, 500k writes/sec — beyond single primary; (3) eventual consistency fine (telemetry), aggregates tolerate staleness; (4) schema fixed by device firmware; (5) team has Cassandra experience.

Output: "ScyllaDB, partition by sensor_id, clustering by timestamp, tablets enabled, LCS compaction for time-series TTL. Trade-offs: no cross-partition queries (per-sensor only — matches access pattern (1)); quorum reads not linearizable (acceptable per (3)); tombstone debt on TTL expiry — LCS mitigates; team experience satisfies (5). Aggregates: separate rollup pipeline (not this skill's scope — see ddia-pipeline-architect). Rejected: Postgres (500k writes/sec sustained beyond single-primary ceiling — the measured trigger from section A), TimescaleDB (viable up to ~100k writes/sec with tuning — borderline, name it as the conservative alternative)."

**Common profile → verdict table:**

| Profile | Verdict | Section |
|---|---|---|
| Read-heavy, joins, <10k writes/sec | Postgres + replicas | A, B |
| Write-heavy, key-access, TB+ | ScyllaDB/Cassandra | B |
| Global consistency from day 1 | CockroachDB/Spanner/YugabyteDB | A, B |
| Deep recursive traversal dominant | Neo4j/Memgraph | A |
| Variable-schema aggregates, moderate scale | Postgres `jsonb` | A |
| RAG similarity <10M vectors | Postgres + pgvector | A |
| Multi-region user latency, eventual OK | Single-leader + geo replicas | B |
| Multi-region writes, consistency required | Consensus engine | B |

## Document Metadata

| Field | Value |
|---|---|
| Document ID | `SKILL-D1-001` |
| Revision | 1 |
| Effective Date | 2026-08-29 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |

## Audience

- **Primary** : Agent/engineer choosing a datastore, replication topology, or serialization format for a system.
- **Secondary** : Maintainers editing this skill; reviewers auditing architecture decisions.
- **Expertise** : Intermediate — reader knows what a database is, maybe deployed one.
- **Needs to learn** : Workload profiling, 2026 landscape (Postgres-first, consensus engines, Buf), quorum arithmetic, trade-off naming discipline.
- **Common misconceptions** : "NoSQL scales better" (unprofiled), "MongoDB is the default for web apps" (2013-era), "Avro is the Kafka format" (2015-era), "graph DB for any relationship" (SQL joins suffice), "vector search needs a dedicated DB" (pgvector under 10M vectors), "active-active needs multi-master DIY" (consensus engines are the 2026 answer).

## Purpose / Scope

**Purpose** : enforce workload-profiled datastore choice with explicit trade-offs. LLM training data recommends hype databases from specific eras by default; this skill forces profiling first and trade-off naming on every recommendation.

**Covers** : relational vs document vs graph arbitrage, single/multi/leaderless replication models, serialization format choice (Protobuf/Avro/Arrow/Iceberg), multi-region topologies, the five-question decision framework.

**Does NOT cover** : numeric benchmarks (TPS claims, latency figures — workload-specific, cite own load tests), SQL implementation or query tuning, storage-engine internals (LSM/B-tree — `ddia-storage-internals`), isolation-level anomalies (`ddia-distributed-debugger`), pipeline construction (`ddia-pipeline-architect`).

**Scope-out rationale** : benchmarks go stale on hardware generations and are workload-shaped — this skill names dimensions and triggers, not numbers; engine internals and pipeline semantics are siblings' domains (see Related Skills) — referencing, not duplicating, keeps each skill under its line budget.

## Definitions

| Term | Meaning |
|---|---|
| Polyglot persistence | Multiple datastore types in one system, each matched to its workload. Justified only by measured pain per store — not day-1 architecture. |
| Schema registry | Governance layer enforcing compatibility on schema evolution. 2026: Buf Schema Registry (Protobuf) superseded Confluent registry as the general answer. |
| Document aggregate | Self-contained record loaded/stored as a whole; the unit document stores optimize for. |
| Interleaving | Spanner table layout nesting child rows under parents — co-location for parent-child reads. |
| LWW | Last-write-wins. Resolution by timestamp — data loss for non-commutative concurrent updates. |
| ANN search | Approximate nearest neighbor (HNSW). Vector similarity trading recall for speed vs exact scan. |
| Tablets | ScyllaDB dynamic shard rebalancing — replaces vnode rebalance pain (2026). |
| Consensus engine | Raft/Paxos-based distributed SQL (CockroachDB/Spanner/YugabyteDB) — linearizable across regions without app-side conflict code. |

Common terms (quorum, HLC, SI/SSI, write skew, WAL, CDC, outbox, watermark) are defined in `_shared/ddia-glossary.md` — never duplicated here. That glossary is the shared kernel across the four ddia-* skills; a term common to two or more of them belongs there, not in this table.

**Boundary rule** : when writing a local definition, check the glossary first — if the term exists there, reference it; if it is tradeoff-analyzer-specific (polyglot persistence, session token), it stays local; if it belongs to another sibling's domain (LSM compaction → storage-internals, watermark → pipeline-architect), it does not belong here at all.

## Evals

Run these 3 pressure scenarios after any edit. Each must FAIL in the specific way described (agent refuses violation).

### Scenario 1 : mongo-by-default

**Given** : the skill is loaded.
**When** user says: "Just use MongoDB for my new SaaS app — I've heard it scales better and is schemaless. Set it up."
**Expect FAIL** : Agent cites Iron Law + section D row 1, refuses to recommend without workload profile, asks the five questions of section E, cites Postgres-first stance (JSONB covers schemaless needs) and the decision tree in section A / `references/data-models.md`. Baseline (no skill) would rationalize MongoDB.

### Scenario 2 : recommend-without-context

**Given** : the skill is loaded.
**When** user says: "Quel DB pour mon app ?" (zero context: no domain, no scale, no access pattern).
**Expect FAIL** : Agent does not name any database. Cites Hard Gate, poses the five questions (access patterns, read/write ratio + scale, consistency, schema evolution, team ops), and explains why the profile precedes any recommendation. Baseline would emit "it depends" followed by a database anyway.

### Scenario 3 : outdated-advice

**Given** : the skill is loaded.
**When** user says: "Avro pour tout mon streaming — c'est ce que tout le monde utilise avec Kafka, non ?"
**Expect FAIL** : Agent cites section C + section D row 11: Protobuf is the 2026 default, Buf/BSR provides linting + breaking-change detection, Avro is a niche (Kafka/Hadoop lineage). Corrects the "tout le monde" premise explicitly — the Avro-as-default belief is 2015-era training data. Baseline would confirm Avro.

**Protocol** : manually, subagent fresh-context, with-skill vs baseline. Log to `_shared/evals/2026-08-29-ddia-tradeoff-analyzer-eval.log` (gitignored).

**Pass criteria** : the with-skill run must refuse/re-ask per each Expect; the baseline run must fail by naming a database (scenarios 1, 2) or confirming Avro (scenario 3). If the with-skill run names a store in scenario 2, the Hard Gate wording was too weak — revise the gate, not the eval.

## The Iron Law (reminder)

> **NO DATASTORE CHOICE WITHOUT EXPLICIT TRADE-OFF ANALYSIS NAMED.**

If you reached this point without answering the five questions of section E on your last recommendation, go back. Your training data has a favorite database from a specific era — the workload profile is the only antidote. Sections D and E are ground truth.

**Modification note** : this skill consumes `_shared/ddia-glossary.md` (Task 1 product). Glossary edits require flagging this Revision History per the glossary's modification protocol.

## Revision History

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-08-29 | Initial SOTA 2026 trade-off analyzer: type:sub-skill + 5 contracts; Iron Law ×3; Hard Gate; Snapshot; Quick Reference projection; Related Skills typed; sections A-E (data model arbitrage Postgres-first, replication models, serialization Protobuf+Buf, 15 anti-patterns, 5-question framework); 3 evals; `references/data-models.md` indexed. | Skills maintainer | Skills maintainer |