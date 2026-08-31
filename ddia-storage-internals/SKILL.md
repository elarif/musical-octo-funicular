---
name: ddia-storage-internals
description: Use when diagnosing storage-engine behavior, choosing indexes, or tuning LSM/B-tree backends — storage advice without profiling the workload (read/write ratio, range vs point lookups, write amplification budget) silently degrades the one metric that matters
type: sub-skill
contracts:
  - lsm-trees
  - b-trees
  - oltp-olap-engines
  - lakehouse-formats
  - anti-patterns-table
---

# DDIA Storage Internals

## The Iron Law

> **NO STORAGE-ENGINE ADVICE WITHOUT WORKLOAD PROFILE (READ/WRITE RATIO, ACCESS PATTERN).**

This is not a guideline. Every storage-engine decision is an amplification trade: write-amp vs read-amp vs space-amp (see `_shared/ddia-glossary.md`: Write/read/space amplification). The agent's training data skews toward engine defaults and benchmark eras (2015 "Cassandra for writes", 2021 "warehouse for everything") and will emit them without checking what the workload actually does. Tuning the wrong axis — adding indexes to a scan-dominated workload, LSM-tuning a read-heavy point-lookup store — silently degrades the one metric that matters, and the degradation is invisible until production load arrives. If the workload profile (read/write ratio, point vs range lookups, write-amp budget) is unknown, it is requested before any engine or index advice is emitted.

**Why the profile comes first:** the read/write ratio decides the engine family (B-tree wins read-amp, LSM wins write throughput); the access pattern decides the index strategy (point lookup → B-tree/bloom, range scan → clustering/covering, analytics → columnar, where indexes are the wrong tool entirely); the write-amp budget decides the compaction strategy. Skipping the profile means optimizing blind on all three axes at once — the failure compounds.

**Announce discipline:** every answer this skill emits starts by naming which profile input is assumed, which is measured, and which is missing. An answer that silently assumes a read/write ratio has already violated the Iron Law — assumptions are named or the profile is demanded.

## Hard Gate

<HARD-GATE>
Do NOT emit, endorse, or tune any storage-engine or index recommendation without first having (1) read/write ratio stated, (2) point vs range lookup mix named, and (3) write amplification budget or tolerance stated. This applies even under deadline pressure, even for "just a quick question", even when the user says "just add an index".
</HARD-GATE>

This gate exists because three failure modes recur on every storage question: (1) the user arrives with the fix pre-chosen ("just add an index") and a compliant agent rationalizes it instead of profiling — the fix is refusing until the three inputs are named; (2) OLTP/OLAP confusion — indexes are the wrong tool for scan-dominated analytical workloads, and B-tree index advice on a dashboard query degrades it further (see eval `oltp-olap-confusion`); (3) tuning advice matched to the wrong engine family (LSM knobs quoted for a B-tree store) — cargo-cult configuration that silently does nothing. The gate forces the profile to the surface before any knob or index is named.

**Gate enforcement — the three numbered requirements:**

| Requirement | What satisfies it | What does not |
|---|---|---|
| (1) Read/write ratio | "95:5 read-heavy", "write-heavy, 40k inserts/sec" | "typical database usage" |
| (2) Point vs range lookups | "point lookups by key + a few time-range scans" | "various queries" |
| (3) Write-amp budget | "NVMe, write throughput sacred — accept read-amp" | "fast" (unqualified) |

If any row is unanswerable, the output is the three questions — not a conditional recommendation. "You could add a covering index, but tell me…" violates the gate: partial advice anchors the user.

## Snapshot

This skill owns the rules an agent applies when diagnosing storage-engine behavior and tuning LSM/B-tree backends: memtable→SSTable write paths, compaction strategies (STCS legacy space-amp, LCS predictable I/O floor, ICS for time-series TTL), the amplification triangle, B-tree page/WAL/covering-index/clustering mechanics, OLTP vs OLAP engine tiers (DuckDB embedded <100GB, ClickHouse concurrent serving, warehouse TB+ only), the 15-row anti-patterns table, and the 2026 lakehouse landscape (Iceberg won, Delta Databricks-locked, Hudi fading, hidden partitioning transforms, S3-object-native stores). It mandates the workload profile (read/write ratio, point vs range, write-amp budget) before any engine or index advice. Numeric benchmark emission and kernel/OS tuning are out of scope. LSM/B-tree deep dive lives in `references/lsm-vs-btree.md`.

**Announce at start:** `I'm using the ddia-storage-internals skill to profile this storage workload.`

**Failure mode this skill prevents:** — B-tree index advice on an OLAP scan, STCS left on a TTL workload, LSM knobs quoted for a B-tree store — and the one metric that matters (write throughput, or read latency, or disk headroom, whichever the workload actually needs) silently degrades under production load. The three-input profile and the amplification triangle are the countermeasure.

## Quick Reference (projection — see Content sections for full rules)

**Quick Reference projection table** — summary card; full rules in sections A-E. If the card and the sections disagree, the sections win.

The card exists for fast pattern-matching by the agent mid-task; it does not replace reading the section.

| Field | Value |
|---|---|
| Audience | Agent or engineer diagnosing storage-engine behavior, choosing indexes, or tuning LSM/B-tree backends |
| Trigger | "why is my database slow", "which index", "RocksDB tuning", "LSM vs B-tree", "compaction strategy", "DuckDB or Spark" |
| Inputs | Workload symptoms; the three profile questions if read/write ratio, lookup mix, or write-amp budget absent |
| Outputs | Engine/index/compaction advice naming the amplification trade accepted; profile questions if workload unknown |
| Type | sub-skill (see `_shared/SKILL-ARCH.md`) |
| Baseline | B-tree for read-heavy point lookups; LSM for write-heavy; columnar for analytics; Iceberg for lakehouse |
| Iron Law | NO STORAGE-ENGINE ADVICE WITHOUT WORKLOAD PROFILE (READ/WRITE RATIO, ACCESS PATTERN) |
| Scope out | Numeric benchmarks, kernel/OS tuning, datastore choice (`ddia-tradeoff-analyzer`) |
| Identity | Descriptive name (`ddia-storage-internals`); stable — do not rename |

## Related Skills

| Sibling | Relationship | What crosses the boundary |
|---|---|---|
| `using-superpowers` | `upstream` | Routes storage-engine triggers here. Translation: using-superpowers's "trigger match" = this skill's "workload profile announced". |
| `writing-skills` | `shared-kernel` | Co-maintains TDD-for-skills vocabulary. This skill applied RED→GREEN→REFACTOR during its own authoring. |
| `technical-writing` | `shared-kernel` | Co-maintains 4-slot discipline (Audience, Purpose/Scope, Definitions, Revision History). |
| `_shared/ddia-glossary.md` | `shared-kernel` | LSM-tree, SSTable, memtable, B-tree, WAL, compaction, amplification triangle definitions live there. Never duplicated here. |
| `_shared/glossary-en.md` | `shared-kernel` | TDD/RED/GREEN/Iron Law/Hard Gate terms live there. |
| `ddia-tradeoff-analyzer` | `none` | Independent domains, no mutual invocation. That skill names the engine; this one tunes it. |
| `ddia-distributed-debugger` | `none` | Independent domains, no mutual invocation. Isolation anomalies vs engine internals. |
| `ddia-pipeline-architect` | `none` | Independent domains, no mutual invocation. That skill moves data; this one tunes where it lands. |

**Sibling boundary note** : the four ddia-* skills cover independent domains (choice vs internals vs correctness vs movement). No skill invokes another; a single conversation may load two (e.g., store chosen there, then its LSM tuned here), but each enters via its own trigger, not a call from this one.

## Workload Profile Interrogation (the Hard Gate in question form)

When any of the three gate inputs is missing, the output is these questions — nothing else:

1. **"What is the read/write ratio, and at what throughput?"** — decides engine family (section A/B decision table) and whether compaction tuning is even relevant.
2. **"Point lookups or range scans — and on which keys?"** — decides index strategy (covering, clustering, bloom) or columnar exit (section C).
3. **"What is the write amplification budget — what does the storage hardware tolerate, and which SLO is sacred?"** — decides compaction strategy and buffer sizing (`references/lsm-vs-btree.md` § tuning).

**Evidence beats interrogation:** if query logs, `pg_stat_statements`, slow-query logs, or engine metrics are reachable, profile from them first — measured access patterns beat user-remembered ones, and users systematically overestimate their read ratio. When the user guesses, label it a guess in the recommendation and state what measurement would change the verdict.

## A. LSM-Trees

**Write path (full walkthrough in `references/lsm-vs-btree.md` § write path):** writes land in an in-memory sorted memtable (see `_shared/ddia-glossary.md`: Memtable) plus an append-only WAL for crash recovery; when the memtable fills, it flushes to an immutable, sorted SSTable (glossary: SSTable). No page is ever updated in place — writes are sequential appends, which is why LSM engines absorb write-heavy workloads that shred B-trees. Overwritten keys and tombstones stay in old SSTables until compaction merges them away.

**Read path:** check memtable, then newest→oldest SSTables. A key may exist in several SSTables (versions); the merge happens at read time — this is LSM's read-amp cost (glossary: Compaction). Bloom filters embedded per SSTable skip absent keys cheaply in memory; without them, every point lookup probes every SSTable (anti-pattern row 11). Bloom filters do not help range scans — a range query must merge every overlapping run, which is why L0 accumulation under write load collapses range latency (compaction starvation, below).

**The amplification triangle (name it in every tuning answer):**

| Corner | Meaning | LSM cost driver | B-tree cost driver |
|---|---|---|---|
| Write-amp | Bytes written to disk per byte the app writes | WAL (1x) + flush (1x) + compaction rewrites (per level crossed) | WAL + page writes + page splits + every-index maintenance |
| Read-amp | Pages/SSTables touched per read | Merge across N runs; bloom cuts misses, not ranges | 3-4 page reads, top levels cached ≈ 1 |
| Space-amp | Disk used vs logical data size | Obsolete versions + tombstones until compaction | ~1x (in-place) + WAL retention |

Tuning compaction moves cost between the three corners; the workload profile decides which corner must stay low. STCS buys lower write-amp with high space-amp; LCS buys low space-amp and predictable reads with higher write-amp. There is no knob that improves all three — an advisor claiming otherwise is wrong.

**Compaction strategies — the 2026 decision set:**

| Strategy | Mechanics | Wins | Costs | Default fit |
|---|---|---|---|---|
| **STCS** (size-tiered) | Merge similarly-sized SSTables into bigger tiers | Low write-amp — merges rare and large | Space-amp: an updated key occupies every tier until merge; disk can hold multiples of logical size | Legacy Cassandra default; write-burst ingestion where disk is cheap |
| **LCS** (leveled) | Levels of ~10x size; key at most once per level; overlaps only at L0 | Low space-amp, predictable bounded reads, cheap TTL expiry | Write-amp floor: every key rewritten per level crossed | RocksDB default; read-latency SLOs; most 2026 workloads |
| **ICS** (incremental) | Incremental merges tuned for TTL time-series | TTL expiry cheap — expired rows drop without full-tier rewrites | Newer (Scylla 2026), narrower validated surface | Time-series with TTL (IoT, metrics, logs) |

**Tombstone debt — the LSM tax to name in any time-series answer:** deletes are tombstones (markers), not erasures; the dead data occupies disk and merge cycles until compaction rewrites the run containing it. TTL workloads generate tombstones at expiry scale — with STCS the debt piles until the next tier merge (anti-pattern row 10); LCS/ICS expire rows incrementally. Cassandra/Scylla `TWCS/ICS` exist precisely for this. Any LSM time-series recommendation names its tombstone strategy.

**LSM mechanics, the parts that bite in production (name them when advising):**

- **L0 overlap**: freshly flushed SSTables overlap each other (different memtables cover the same key range); a read must check all of them. Compaction exists to bound this — a stalled compaction means unbounded L0.
- **Write stalls**: when memtables queue faster than they flush/compact, RocksDB stalls the writers (by design — backpressure). A "slow write" incident on LSM is usually a compaction-debt incident surfacing as a stall.
- **Range delete tombstones**: a range delete covers an entire key interval but must be carried through merges until every overlapping run is rewritten — the most expensive LSM delete shape.
- **Bloom filter tuning**: more bits per key = fewer false positives = fewer wasted page reads; the budget trade is memory. RocksDB default ~10 bits/key ≈ 1% false-positive rate; raise it for read-heavy point-lookup workloads.
- **Block cache is the read-path half**: hot SSTable blocks cached in memory make LSM point lookups competitive with B-tree on the hot set; sizing the block cache to the hot set is part of any LSM read-latency recommendation, not an afterthought.
- **Compaction debt is visible before it hurts**: `level0_file_count`, pending-compaction-bytes, and stall counters exist precisely so the advisor asks for them — a storage recommendation that never mentions how compaction health will be monitored is incomplete.

**Compaction starvation — the classic production failure:** write throughput exceeds compaction throughput → SSTables pile up at L0 → every read merges dozens of files → range queries collapse. Symptom: "range queries slow under write load". Diagnosis and tuned LCS parameters (`level_compaction_dynamic_level_bytes`, `write_buffer_size`, `max_write_buffer_number`): `references/lsm-vs-btree.md` § diagnostic.

**STCS is the legacy default to refuse** in most 2026 recommendations: its space-amp profile (a hot key occupying every tier until merge) punishes TTL workloads hardest (row 10), and its merge storms spike I/O at unpredictable moments. LCS's I/O floor is predictable — that predictability is an SLO feature, not a cost. ICS is the narrow newcomer: validated for TTL time-series on Scylla 2026, not yet a general answer. The compaction-strategy table below is the decision set; anything outside it (TWCS in older Cassandra for pure TTL) is named as a transitional case, not a default.

**RocksDB is the de-facto embedded LSM.** TiKV (TiDB's storage layer) runs it; MyRocks put it under MySQL; CockroachDB ships Pebble, its RocksDB-inspired reimplementation. Defaults are deliberately conservative — production deployments tune `write_buffer_size`, `max_write_buffer_number`, and `level_compaction_dynamic_level_bytes` against the write-amp budget (tuned starting points: `references/lsm-vs-btree.md` § tuning). RocksDB knowledge is the transferable asset: the knobs map onto any RocksDB-derived engine.

**When LSM is the wrong answer:** read-heavy point-lookup workloads pay the merge tax on every read a B-tree answers with one cached page; bloom filters cut miss cost but not range-scan cost. If the profile says 95:5 read-heavy point lookups, the B-tree family (or a well-indexed Postgres) wins — say so before quoting LSM knobs.

**Worked example — the profile in action:**

User: "metrics store, 40k writes/sec sustained, 90-day TTL, queries = latest value per sensor + hourly range scans." Profile: (1) write-heavy 1:9; (2) point lookup + bounded range; (3) NVMe, write throughput sacred, read latency tolerant of merge cost.

Output: "LSM (Scylla with ICS, or RocksDB with LCS + TTL compaction). Accepted trade-offs: read-amp on range scans under sustained write (mitigated — compaction headroom sized above write rate); tombstone debt at TTL expiry (ICS/LCS expire incrementally — STCS refused, anti-pattern row 10); no ad-hoc secondary indexes (access pattern is key-shaped — matches (2)). Rejected: B-tree store (40k random writes/sec = page-rewrite write-amp, anti-pattern row 1); warehouse (sub-TB, single purpose)."

## B. B-Trees

**Structure (glossary: B-tree):** fixed-size pages (4-16KB) in a balanced tree; a million-row table is 3-4 levels deep, so a point lookup is 3-4 page reads — and the top levels are cached, making hot lookups effectively one page read. This is the read-amp advantage over LSM: one bounded traversal, no merge, no bloom dependency.

**Writes update pages in place:** the target page is fetched, modified, written back, with a WAL append first for crash recovery (glossary: WAL). Random writes scatter across the tree — each update touches its home page plus the log, and a page split cascades a write up the tree. Net effect: write-amp bounded but I/O is random, where LSM converts the same write to sequential appends. This is why append-only write-heavy workloads belong on LSM (anti-pattern row 1). Every secondary index adds its own page maintenance to every write — "index every column" multiplies this cost (anti-pattern row 7).

**Covering indexes and index-only scans — standard 2026 practice, not an optimization you skip:** an index containing every column a query needs answers it without touching the heap table. For hot queries, this converts N random heap fetches into one sequential index scan. Postgres caveat: index-only scans still fetch the heap page when its visibility map bit is not set — a table bloated by updates degrades index-only scans; vacuum discipline is part of the index advice. InnoDB secondary indexes implicitly carry the PK — many queries are covering without anyone noticing; name it when it happens. Covering indexes trade write-amp (wider index = more bytes per write) for read-amp — the triangle again, which is why the profile precedes the DDL.

**Clustering:** physical row order following an index key. InnoDB clusters by primary key — choose the PK for the dominant range scan (time-ordered inserts are the classic case), or random PKs (UUIDv4) shred the clustering. Postgres `CLUSTER` is a one-shot reordering; the maintained alternatives are partitioning or index-ordered access. A range scan on a clustered index is sequential I/O; on an unclustered heap it is one random fetch per row (anti-pattern row 12). Cluster on the wrong key and every other access pattern pays — it is the most expensive index decision, so it is made from the profile's dominant query, not from habit.

**Index selection checklist (run it before any `CREATE INDEX` advice):**

1. Is the query scan-dominated or lookup-dominated? Scan → section C (columnar), indexes are the wrong tool.
2. Is there a selective leading column? Low-cardinality alone → composite or partial (anti-pattern row 3).
3. Does a covering index fit the hot query? Columns needed vs index width — write-amp trade named per triangle.
4. Is the access pattern range-shaped? → clustering/partition key on that column, or the heap pays per-row.
5. Is the index actually being used (EXPLAIN, pg_stat_user_indexes)? Unused indexes are pure write-amp — drop them.

**LSM vs B-tree decision worked example 2 — read-heavy point lookups:**

User: "user-profile cache, 99:1 read-heavy, 200k reads/sec, 50M keys, lookups by key only." Profile: (1) read-heavy; (2) point lookups, no ranges; (3) write-amp budget generous (writes rare — cache fills).

Output: "Read-heavy point lookups: B-tree family wins the read path — one cached-page traversal, no merge, no bloom dependency (section A 'when LSM is the wrong answer'). Redis-style in-memory or a clustered B-tree (InnoDB PK-clustered) both fit. If LSM is forced by the surrounding platform, bloom filters at ~14 bits/key + block cache sized to hot set close most of the gap — but the honest default here is not LSM. Rejected: RocksDB default knobs (profile does not need write headroom; it needs read latency)."

**B-tree page mechanics detail (what in-place means physically):** an update locates the leaf page via tree descent (3-4 reads, top levels cached), modifies it in place, and marks the old row version dead (MVCC) or overwrites it. Sequential vs random is decided by insert order: monotonically increasing keys append right-most leaf pages (sequential, the best case); random keys (UUID) scatter across every page, faulting the whole cache (the anti-pattern row 12 shape). A page split copies half the page and updates the parent — write-amp spikes at splits. VACUUM/bloat: MVCC keeps dead versions until vacuum reclaims them — a table with 20% dead versions does 20% wasted I/O on every scan; page-level fragmentation is the B-tree analog of LSM's space-amp.

**B-tree vs LSM — the decision table (the profile maps onto it):**

| Dimension | B-tree | LSM |
|---|---|---|
| Point lookup (cached path) | 3-4 pages, top levels hot ≈ 1 read | Memtable + bloom misses + merge on hit |
| Range scan | Sequential within leaf pages | Merge of all overlapping runs |
| Write cost | Random page writes + WAL | Sequential appends + compaction later |
| Write burst absorption | In-place, no slack | Memtables absorb, compaction defers |
| Space | ~1x, in-place | >1x until compaction; tunable |
| Ops risk | Vacuum/bloat, index bloat | Compaction tuning, tombstone debt, L0 starvation |
| Default verdict | Read-heavy, point lookups, transactional | Write-heavy, append-only, TTL time-series |

**When B-tree is the wrong answer:** write-heavy append-only logs (row 1), TTL-expired time-series (row 10), and scan-dominated analytics (section C) all fight the model. If the profile says 5:95 write-heavy, the LSM family wins — say so before tuning B-tree buffers.

## C. OLTP vs OLAP Engines

**Row store vs column store — the access-pattern split, not a fashion choice:** row stores place a row's columns contiguously — one page read gets the whole record (OLTP point access). Column stores place a column's values contiguously — a scan reads only the columns referenced (OLAP aggregates), and adjacent similar values compress well. Running OLAP on a row store means reading every column to aggregate one (anti-pattern row 4); running OLTP point lookups on a column store means reassembling rows from per-column reads. Neither is "faster" — the access pattern decides, which is why requirement (2) of the Hard Gate exists.

**Parquet is the de-facto columnar file format**, and its encodings are why columnar scans are cheap — name them when explaining a plan:

| Encoding | Fits | How it compresses |
|---|---|---|
| Dictionary | Low-cardinality strings (status, country) | Distinct values → integer codes; per-row-group dictionary |
| Delta | Monotonic sequences (timestamps, IDs) | First value + deltas, then varint/bit-pack |
| Bitmap | Booleans, low-cardinality predicates | Bit vectors; predicates evaluated with popcount |
| Run-length | Sorted or clustered columnar data | Value + repeat count |

**Row-group mechanics (why columnar advice is also partitioning advice):** Parquet divides rows into row groups (~128MB default) with per-group column chunks and stats (min/max per column). Predicate pushdown skips entire row groups via stats; sorting data by the filter column before writing maximizes skipping — the columnar analog of clustering (section B). An advisor who recommends Parquet without mentioning sort order on load leaves 10x scan performance on the table.

A Parquet scan of one column out of fifty reads ~2% of the bytes; the same query on a row store reads 100%. Encodings are why "just add an index" is the wrong answer for scan workloads — no index improves the bytes-read floor of a scan; the columnar layout is the fix.

**OLTP 2026 stance:** the B-tree row store remains the OLTP engine — Postgres/MySQL/SQLite for the point-lookup-and-small-transaction pattern (section B). Analytical workloads bolted onto them fail on scans, not on indexing; the fix is a columnar tier, not more indexes (anti-pattern rows 3, 4). A common hybrid: operational Postgres + DuckDB reading the exported Parquet — one copy step, two engines, each in its tier.

**OLAP tiers 2026 (match to scale before naming an engine):**

| Tier | Engine | Fit | Trade-off |
|---|---|---|---|
| Embedded analytics | DuckDB | "<100GB, single team, zero infra" — the "SQLite for OLAP": one process, reads Parquet/S3/CSV directly, beats Spark clusters at this scale | Not a concurrent-serving engine |
| Concurrent serving | ClickHouse | Hundreds of concurrent analytical queries live; sub-second dashboards at TB scale; MergeTree families with TTL | Another system to run; ops care on merges |
| Warehouse | Snowflake/BigQuery | TB+, multi-team shared storage+compute, elastic | Cost + latency floor; absurd under ~TB (anti-pattern row 9) |

**DuckDB tier detail 2026:** DuckDB reads Parquet (local or S3) directly and queries in-process — no cluster, no ingestion pipeline for the analyst tier. It beats Spark for <100GB on both latency and cost; the "Spark for analytics" default at that scale is anti-pattern row 5. Its boundary is concurrency (one process) and write concurrency (analytical reads, not OLTP) — the profile's concurrent-users question decides the tier exit.

**ClickHouse tier detail:** the concurrent-serving engine — dashboards with many simultaneous viewers, log/metrics query frontends. MergeTree ordering key ≈ clustering (section B): design it for the dominant scan shape. Sub-TB single-team dashboards on it are acceptable but often DuckDB-simpler; TB+ or high-concurrency is its home. Warehouse only at TB+ multi-team elastic-compute scale — below that, the cost floor is pure waste (row 9).

**Decision rule:** dashboards on <100GB → DuckDB (often reading the same Parquet the pipelines produce — no copy, no cluster). Concurrent user-facing analytics at TB scale → ClickHouse. Multi-team TB+ with elastic compute → warehouse. Spark belongs in the pipeline tier (ETL over the lakehouse — `ddia-pipeline-architect`'s domain), not as the ad-hoc query engine for sub-TB data.

**Worked example — OLTP/OLAP tiering in action:**

User: "event SaaS, 2TB raw events/month, ops dashboards + per-customer funnels, ops team of 4." Profile: (1) reads dominate massively (dashboards + funnels); (2) scans and aggregations, not point lookups; (3) write path is batched pipeline loads, not OLTP transactions.

Output: "Columnar, two tiers. Hot serving: ClickHouse (concurrent customer-facing funnels — the DuckDB tier fails the concurrency requirement). Cold/warehouse: events land as Parquet in Iceberg on S3, queried by Trino/DuckDB ad hoc — data outlives engines. Rejected: Postgres dashboards via indexes (scan-dominated — anti-pattern rows 3/4); Spark cluster for dashboard queries (<100GB hot subset — row 5, DuckDB reads the Parquet directly); Snowflake (single team of 4, sub-TB hot tier — row 9; revisit at multi-team TB+)."

**PostHog/Plausible-style 2026 pattern as evidence:** the 2026 default for product-analytics SaaS is ClickHouse for serving + Parquet/Iceberg for history — the tier split this section encodes. When a user asks "which database for analytics", the answer is a tier, not an engine.

## D. Anti-Patterns

| # | ❌ Forbidden | ✅ Fix | Why |
|---|---|---|---|
| 1 | B-tree engine for append-only write-heavy logs | LSM engine (RocksDB, Scylla) | In-place page rewrites + WAL per random update = write-amp; LSM converts writes to sequential appends |
| 2 | LSM deployed with default compaction, no tuning | Profile write-amp budget; pick LCS/ICS, tune buffers (`references/lsm-vs-btree.md` § tuning) | Defaults mis-tuned: read-amp explodes or compaction stalls under sustained write |
| 3 | Single low-cardinality index alone (status, is_active) | Composite index leading with the selective column, or partial index | Near-zero selectivity: planner scans most of the index anyway, or ignores it |
| 4 | OLAP dashboards on the OLTP row store | Columnar tier: DuckDB / ClickHouse / Parquet | Scan-dominated workload: reads all columns to aggregate one; indexes do not fix scans |
| 5 | Spark cluster for <100GB analytics | DuckDB embedded | Zero-infra embedded beats the cluster on cost and latency at this scale; cluster idle-time dominates |
| 6 | NVMe ignored in read-amp calculations | Redo the amp math with 2026 NVMe random-read costs | HDD-era assumptions overstate the LSM read-amp penalty; on NVMe, random ≈ sequential (`references/lsm-vs-btree.md` § NVMe) |
| 7 | Index every column "for safety" | Index only measured query paths (pg_stat_statements) | Every index adds write-amp per insert/update; B-tree maintenance dominates write latency |
| 8 | Hot query answered without covering index check | Covering index → index-only scan | Per-row heap fetch dominates the query; covering removes it |
| 9 | Data warehouse for sub-TB single-team data | DuckDB / ClickHouse self-hosted | Warehouse cost + latency floor paid for a scale never hit |
| 10 | STCS on a TTL time-series workload | ICS (Scylla 2026) or LCS + TTL | STCS space-amp holds expired keys until the next tier merge — tombstone debt |
| 11 | LSM point lookups without bloom filters verified | Confirm bloom filter config (RocksDB default on), per column family | Read-amp multiplies: every SSTable probed on every miss |
| 12 | Range-scan-heavy workload on unclustered heap | Cluster / index-organized table on the range key | One random heap I/O per row; clustering makes the scan sequential |
| 13 | Delta or Hudi chosen for a greenfield lakehouse 2026 | Iceberg | Iceberg won universal engine support; Delta is Databricks-locked, Hudi fading (section E) |
| 14 | Tuning advice matched to the wrong engine family (LSM knobs on a B-tree store) | Name the engine family before advising knobs | `max_write_buffer_number` on a B-tree store is cargo cult — does nothing |
| 15 | Storage advice with read/write ratio unspoken | Iron Law: demand the profile first | The ratio decides B-tree vs LSM vs columnar; advice without it degrades the metric that matters |

## E. Lakehouse 2026

**Iceberg won.** By 2026 the format war is settled: Snowflake, BigQuery, Trino, Spark, Flink, ClickHouse, and DuckDB all read and write Iceberg. The differentiator was engine-support breadth — a table format only wins if every engine the company already runs can query it, and Iceberg reached that universality first. For any greenfield lakehouse (anti-pattern row 13), Iceberg is the default; choosing otherwise needs a named, specific reason.

**Delta Lake is Databricks-locked.** Delta is open-source in license, but the ecosystem gravity lives inside Databricks — the best-maintained readers/writers, feature cadence (deletion vectors, uniform tables), and operator tooling ship Databricks-first, and outside support lags. A team already all-in on Databricks has a Delta case; a heterogeneous-engine team (Trino + Snowflake + Spark) does not — the format choice would couple the lakehouse to one vendor's roadmap.

**Hudi is fading.** Commit cadence and adoption have declined; do not recommend it for greenfield 2026. A "Hudi or Delta?" binary is a 2021-era question — the 2026 answer is Iceberg unless the Databricks lock-in is explicitly accepted (see eval `lakehouse-outdated`).

**Table format comparison:**

| Dimension | Iceberg | Delta | Hudi |
|---|---|---|---|
| Engine support 2026 | Universal (Snowflake/BigQuery/Trino/Spark/Flink/ClickHouse/DuckDB) | Databricks-first, others lag | Spark-centric, shrinking |
| Greenfield verdict | Default | Only if all-in Databricks | No |
| Differentiator | Broadest support + hidden partitioning + time travel | Databricks integration | Incremental ingestion (superseded by streaming-table convergence) |

**Hidden partitioning transforms — the Iceberg feature that changes partition advice:** partitions are declared as transforms of columns (`days(event_ts)`, `bucket(user_id, 16)`, `truncate(city, 32)`), not as physical columns. Queries never reference partition columns — no `PARTITION (date)` filter clutter — so partitioning can evolve later (`days` → `hours` for a hot table) without rewriting every query: the classic Hive-partition migration pain, gone. Advise transforms, never partition-column denormalization.

**S3-object-native databases:** XTDB v2 stores bitemporal data directly as objects on S3 — no local disk, no node-attached state; compute is decoupled and stateless, and snapshots come free from immutable object storage. This is the lakehouse's compute/storage decoupling applied to an operational store, not just analytics. For workloads where history is the workload (regulatory reconstruction, insurance timelines), object-native is a legitimate 2026 tier — niche but real.

**Compute/storage decoupling is the lakehouse contract:** data lives in open format (Iceberg/Parquet) on object storage; engines (Spark, Trino, DuckDB, ClickHouse) are transient and interchangeable. The 2026 stance: data outlives engines — never choose a format only one engine reads (that is the Delta test, and the Hudi verdict).

**Worked example — lakehouse choice in action:**

User: "greenfield events lakehouse, Trino + Spark + DuckDB all in play, finance wants Snowflake access too, schema evolves monthly." Profile: (1) analytical reads via multiple engines; (2) scan-shaped, partition pruning by date; (3) write path = pipeline loads, compaction = Iceberg maintenance jobs.

Output: "Iceberg on S3, partitioned by `days(event_ts)` (hidden transform — queries stay partition-agnostic). Trade-offs: no single-vendor integration polish (Delta's Databricks fit — but the multi-engine profile makes that lock-in a cost, not a feature); maintenance jobs (expire_snapshots, compaction) must be scheduled — name them at rollout. Rejected: Delta (heterogeneous engines — row 13); Hudi (fading — row 13); raw Parquet without a table format (no schema evolution/rollback — Iceberg's metadata layer is the point)."

**Iceberg mechanics the advisor names (why it won, not just that it won):** metadata lives in manifest files tracking per-data-file column stats (min/max, null counts) — file pruning by predicate without touching data; snapshots give time travel and atomic schema/partition evolution (compare + rollback); hidden partitioning (above) removes the partition-column wart entirely. When a user asks "why Iceberg", the answer is the metadata layer, not fashion.

**Streaming-table convergence note (boundary):** Kafka topic ↔ Iceberg table synchronization (Tableflow-class features) dissolves the batch/stream split at the storage layer. The pipeline semantics of that convergence belong to `ddia-pipeline-architect`; this skill's stake is only that the table format it lands in is Iceberg, with its evolution guarantees intact.

**Common profile → verdict table:**

| Profile | Verdict | Section |
|---|---|---|
| Read-heavy point lookups, sub-TB | B-tree (Postgres/InnoDB PK-clustered) | B |
| Write-heavy append-only, key-shaped access | LSM (RocksDB/Scylla), LCS | A |
| Time-series with TTL | LSM, ICS (or LCS + TTL) — never STCS | A |
| Scan-dominated analytics <100GB, single team | DuckDB on Parquet | C |
| Concurrent dashboards, TB scale | ClickHouse | C |
| Multi-team TB+, elastic compute | Warehouse | C |
| Greenfield lakehouse | Iceberg | E |
| Already all-in Databricks | Delta (named lock-in) | E |

**Worked example 2 — the hybrid OLTP+OLAP split:**

User: "marketplace, orders OLTP + weekly finance reports + ML feature extraction, 5TB orders." Profile: (1) OLTP writes + heavy analytical reads on the same data; (2) point transactions (orders) vs full scans (reports/ML); (3) write-amp on OLTP side must stay flat.

Output: "Two tiers, one copy path. OLTP: Postgres B-tree (section B — point transactions). Analytical: CDC/exports land as Parquet in Iceberg on S3 (section E); reports run on DuckDB (embedded, reads the lake directly — no cluster for <100GB hot subsets); ML features extract from the same Parquet. Rejected: indexes on Postgres for the finance scans (scan-dominated — rows 3/4); Spark cluster (row 5 — DuckDB reads the same files); one 'do-everything' engine (the access patterns are tier-shaped, C)."

## Document Metadata

| Field | Value |
|---|---|
| Document ID | `SKILL-D2-001` |
| Revision | 1 |
| Effective Date | 2026-08-29 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |

## Audience

- **Primary** : Agent/engineer diagnosing storage-engine behavior, choosing index strategies, or tuning LSM/B-tree backends.
- **Secondary** : Maintainers editing this skill; reviewers auditing storage advice.
- **Expertise** : Intermediate — reader has run a database, maybe added an index.
- **Needs to learn** : Workload profiling (read/write ratio, point vs range, write-amp budget), amplification triangle, compaction strategies, 2026 OLAP tiers, lakehouse landscape.
- **Common misconceptions** : "indexes fix slow dashboards" (scans need columnar), "LSM is always better for writes" (bloom filters don't help range scans), "compaction is a background detail" (starvation collapses reads), "NVMe changes nothing in amp math" (random ≈ sequential now), "Delta vs Hudi is the lakehouse question" (2021-era; Iceberg won).

## Purpose / Scope
**Purpose** : enforce workload-profiled storage-engine and index advice. LLM training data emits engine defaults and era-specific advice without checking what the workload does; this skill forces the profile first and names the amplification trade on every recommendation.

**Covers** : LSM write/read paths and compaction strategies (STCS/LCS/ICS), the amplification triangle, B-tree page/WAL/covering-index/clustering mechanics, OLTP vs OLAP engine tiers (DuckDB/ClickHouse/warehouse), 15 anti-patterns, 2026 lakehouse formats (Iceberg/Delta/Hudi, hidden partitioning, object-native stores).

**Does NOT cover** : numeric benchmarks (TPS/latency claims — workload and hardware-specific, cite own load tests), kernel/OS tuning (VM, filesystem, NUMA), datastore choice and replication topology (`ddia-tradeoff-analyzer`), isolation anomalies (`ddia-distributed-debugger`), pipeline construction (`ddia-pipeline-architect`).

**Scope-out rationale** : benchmarks go stale on hardware generations (NVMe already flipped one era of amp math) and are workload-shaped — this skill names dimensions and decision rules, not numbers; kernel tuning is a different discipline with different failure modes; store choice and pipeline semantics are siblings' domains (see Related Skills) — referencing, not duplicating, keeps each skill under its line budget.

**Glossary dependency** : `_shared/ddia-glossary.md` Storage section (LSM-tree, SSTable, memtable, B-tree, WAL, compaction, amplification) is load-bearing for sections A-B; edits there flag this Revision History.

## Definitions

| Term | Meaning |
|---|---|
| STCS | Size-tiered compaction: merge similarly-sized SSTables into tiers. Low write-amp, high space-amp (a hot key occupies every tier until merge). Legacy Cassandra default. |
| LCS | Leveled compaction: levels of ~10x size, key at most once per level. Low space-amp, predictable bounded reads; write-amp floor per level crossed. RocksDB default. |
| ICS | Incremental compaction (Scylla 2026): incremental merges designed for TTL time-series — expired rows drop cheaply, no full-tier rewrite storms. |
| Covering index | Index containing every column a query needs → index-only scan, no heap fetch. Standard for hot queries, not an optional optimization. |
| Index-only scan | Query answered from the index alone. Postgres caveat: heap fetch returns if the visibility map bit is unset — vacuum discipline is part of the advice. |
| Clustering | Physical row order following an index key: range scans become sequential I/O instead of one random fetch per row. |
| Hidden partitioning | Iceberg partition transforms (`days(ts)`, `bucket(k, N)`) — queries never reference partition columns; partitioning can evolve without query rewrites. |
| Object-native | Store writing data directly as objects on S3 (XTDB v2) — no node-attached disk; compute decoupled and stateless. |
| Tombstone debt | Dead data (deleted/TTL-expired) occupying disk and merge cycles until compaction rewrites the containing run. The LSM tax on TTL workloads. |
| Compaction starvation | Write rate > compaction rate → L0 accumulates overlapping runs → reads merge dozens of files → range queries collapse. |

Common terms (LSM-tree, SSTable, memtable, B-tree, WAL, compaction, write/read/space amplification) are defined in `_shared/ddia-glossary.md` — never duplicated here. That glossary is the shared kernel across the four ddia-* skills; a term common to two or more of them belongs there, not in this table.

**Boundary rule** : when writing a local definition, check the glossary first — if the term exists there, reference it; if it is storage-internals-specific (STCS/LCS/ICS detail, covering index, hidden partitioning, object-native), it stays local; if it belongs to another sibling's domain (quorum → distributed-debugger, watermark → pipeline-architect), it does not belong here at all.

## Evals

Run these 3 pressure scenarios after any edit. Each must FAIL in the specific way described (agent refuses violation).

### Scenario 1 : oltp-olap-confusion

**Given** : the skill is loaded.
**When** user says: "Mes dashboards analytiques sont lents — j'ajoute des index B-tree sur Postgres ?"
**Expect FAIL** : Agent cites Iron Law + section D rows 3/4, detects the OLAP workload (scan-dominated aggregation — indexes do not fix scans), refuses index advice, asks the profile questions, and proposes the columnar tier (DuckDB for embedded <100GB, ClickHouse for concurrent serving) with the trade-off named. Baseline (no skill) would emit `CREATE INDEX` statements.

### Scenario 2 : write-amp-blind

**Given** : the skill is loaded.
**When** user says: "RocksDB par défaut pour tout, non ? C'est le meilleur pour les writes."
**Expect FAIL** : Agent does not endorse any engine verdict. Cites Hard Gate, demands the three inputs (read/write ratio, point vs range mix, write-amp budget), explains the amplification triangle (section A) — STCS/LCS/ICS move cost between write-amp, read-amp, space-amp — and names when LSM loses (read-heavy point lookups pay the merge tax). Baseline would confirm RocksDB.

### Scenario 3 : lakehouse-outdated

**Given** : the skill is loaded.
**When** user says: "Je démarre mon lakehouse — je choisis Hudi ou Delta ?"
**Expect FAIL** : Agent cites section E + section D row 13: the question's binary is 2021-era. Iceberg won 2026 (universal support: Snowflake/BigQuery/Trino/Spark/Flink/ClickHouse/DuckDB); Delta is Databricks-locked (legitimate only if already all-in on Databricks); Hudi is fading. Corrects the premise explicitly. Baseline would weigh Hudi vs Delta as if current.

**Protocol** : manually, subagent fresh-context, with-skill vs baseline. Log to `_shared/evals/2026-08-29-ddia-storage-internals-eval.log` (gitignored).

**Pass criteria** : the with-skill run must refuse/re-ask per each Expect; the baseline run must fail by emitting index DDL (scenario 1), confirming RocksDB (scenario 2), or debating Hudi/Delta (scenario 3). If the with-skill run names an index or engine verdict in scenario 2, the Hard Gate wording was too weak — revise the gate, not the eval. If the with-skill run answers "Hudi or Delta" by picking one (even Iceberg-first framing that still accepts the binary), the premise correction in section E was too weak — strengthen "the question's binary is 2021-era", not the eval.

## The Iron Law (reminder)

> **NO STORAGE-ENGINE ADVICE WITHOUT WORKLOAD PROFILE (READ/WRITE RATIO, ACCESS PATTERN).**

If you reached this point without the three profile inputs (read/write ratio, point vs range mix, write-amp budget) on your last recommendation, go back. Your training data has a favorite engine default from a specific era — the workload profile is the only antidote. Sections D and E are ground truth.

**Modification note** : this skill consumes `_shared/ddia-glossary.md` (Task 1 product). Glossary edits require flagging this Revision History per the glossary's modification protocol.

## Revision History

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-08-29 | Initial SOTA 2026 storage internals: type:sub-skill + 5 contracts; Iron Law ×3; Hard Gate; Snapshot; Quick Reference projection; Related Skills typed; sections A-E (LSM/STCS/LCS/ICS + amplification triangle, B-tree covering/clustering, OLTP/OLAP tiers DuckDB/ClickHouse/warehouse, 15 anti-patterns, lakehouse 2026 Iceberg-won); 3 evals; `references/lsm-vs-btree.md` indexed. | Skills maintainer | Skills maintainer |