# LSM vs B-Tree — Write Path, Read Path, Tuning

| Field | Value |
|---|---|
| Document ID | `REF-D2-01` |
| Parent | `SKILL-D2-001` (ddia-storage-internals) |
| Revision | 1 |
| Effective Date | 2026-08-29 |
| Applies to | Sections A-B of parent skill |

Detail for sections A-B of `ddia-storage-internals/SKILL.md`. Walkthrough of the LSM write path, the read path, a production diagnostic, tuned LCS parameters, and the 2026 NVMe impact on amplification math. Read order: write path → read path → diagnostic → tuning → NVMe — each section assumes the previous one.

**Header metadata** : REF-D2-01 under SKILL-D2-001; changes here flag the parent Revision History (footer).

## SSTable flush walkthrough (the LSM write path)

1. **Write arrives** → appended to the WAL (crash recovery) + inserted into the memtable (sorted in-memory structure, typically a skiplist).
2. **Memtable fills** (`write_buffer_size` reached) → frozen, a fresh memtable rotates in; writes never stall.
3. **Flush**: frozen memtable serialized to an **SSTable** — immutable, sorted, with sparse key index + per-SSTable bloom filter. Lands at level 0 (L0).
4. **L0 accumulates overlapping SSTables** → each holds a range of the keyspace; reads must check all of them. This is the read-amp cliff (see read path below).
5. **Compaction** merges L0 runs into L1 (LCS: each level ~10x larger than the previous, sorted runs non-overlapping within a level; STCS: merge similar-sized tiers).

**What is inside an SSTable** (why the read path is what it is): sorted key-value blocks, a sparse key index (first key per block) loaded with the file footer, a bloom filter block, and (2026 default) per-block checksums + optional per-block compression. The sparse index is why a point lookup is index binary-search + one block read, not a file scan; the bloom filter is why absent keys cost ~0. Tombstones and obsolete versions ride along as regular entries until a merge drops them — space-amp lives here.

**Write cost**: one WAL append + one memtable insert per write; one sequential file write per flush. Sequential, batched, no in-place page rewrites — the source of LSM's write advantage.

**B-tree write path for contrast (same step, other engine)**: the write locates its home leaf page (tree descent), modifies the page in place, appends to the WAL. No memtable batch, no deferred work — the page write is immediate and random. LSM defers and rewrites later (compaction); B-tree pays now, at the home page. Every LSM-vs-B-tree trade in the parent skill follows from this one structural difference.

## Bloom filters and the read path

1. **Point lookup** → check memtable, then newest→oldest SSTables.
2. **Bloom filter consulted before touching each SSTable**: absent keys are skipped in memory — no I/O. This is what makes LSM point lookups viable despite dozens of live SSTables.
3. **Present-maybe** → SSTable sparse index consulted (binary search on the in-memory key index), then the block fetch — usually one page read.
4. **Bloom filters do not answer range scans**: a range query must merge every SSTable overlapping the range. Heavy L0 under write load = dozens of runs merged per scan — the starvation symptom (below).

**Read cost**: bloom miss = 0 I/O; bloom hit = index + page read; range scan = merge of all overlapping runs. The read path is why the amplification triangle (write/read/space) decides compaction tuning — compaction rewrites data so reads don't merge it.

**Bloom filter detail (because "verify bloom filters" advice needs a number)**: false-positive rate ≈ (1 − e^(−k·n/m))^k for k hash functions and n keys over m bits; practically, RocksDB's default ~10 bits/key buys ~1% FPR, 14 bits/key ≈ 0.5%. A 1% FPR on a 30-SSTable lookup chain still costs ~0.3 wasted page reads per lookup on average — acceptable on NVMe, painful on HDD (the NVMe section reprices exactly this). Bloom filters are per-SSTable and rebuilt at compaction: an engine without per-SSTable filters (or with them disabled) multiplies read-amp by run count — that is anti-pattern row 11, and "verify" means check the config and the FPR budget, not just that the feature exists.

## B-tree read path (the comparison baseline)

1. **Point lookup** → tree descent from root: each level is one page read, top levels ~always cached → effective cost ≈ one leaf page read. No merge, no bloom dependency.
2. **Range scan** → descent to the left-most leaf, then sequential leaf-page walk via right sibling pointers. Bounded, merge-free — the structural opposite of LSM's multi-run merge.
3. **No read-amp growth with write history**: the tree stays balanced; old versions are pruned by vacuum/MVCC, not accumulated as immutable layers. The cost moved to write path (in-place rewrites) and bloat (space), not reads.

**Why this baseline matters for LSM advice**: every LSM tuning trade is measured against it — bloom miss = 0 I/O approximates "not in memtable" for free, but every bloom hit still pays index+page, and every range still merges. The 2026 NVMe shift (below) narrows the gap on random reads but never the merge itself.

## Diagnostic: range queries slow under write load

**Symptom**: point lookups fine; range scans degrade sharply during sustained writes; `p99` climbs with write throughput.

**Diagnosis — compaction starvation**: write throughput exceeds compaction throughput → L0 accumulates overlapping SSTables faster than LCS merges them down → every range query merges N growing runs → read-amp explodes. This is not a "slow disk" problem; it is an under-provisioned/under-tuned compaction problem.

**Checks**: L0 file count (RocksDB: `level0_file_count`, alarm past ~20), pending compaction bytes, `compaction score` per level. Sustained L0 growth = starvation confirmed.

**Diagnostic discipline**: before touching knobs, confirm the shape — point lookups unaffected + range scans degrading + L0 growing = starvation; all reads degrading + cache misses up = block cache undersized; writes stalling = flush/compaction queue full (a different fix). The symptom triple is the profile; the knob follows, never the reverse (parent skill Iron Law).

**Fix escalation order** (cheapest first, one at a time): (1) more compaction threads — pure headroom if CPU idle; (2) `compaction_readahead_size` — sequential-read merges, cheap on NVMe; (3) bigger write buffers — slower L0 arrival, watch flush latency; (4) re-profile — sustained writes structurally above compaction capacity mean ICS (TTL workloads) or shard, not knobs. Applying (3) before (1) hides starvation until it returns worse.

**Fixes**: (a) larger/increased write buffers to slow L0 arrival; (b) more compaction threads (`max_background_compactions`); (c) larger `compaction_readahead_size` on NVMe; (d) re-profile the workload — if writes structurally exceed compaction capacity, ICS (time-series TTL) or sharding is the honest answer.

## Tuned LCS RocksDB parameters

**Starting points** for a write-heavy LCS deployment (NVMe, 16GB memory budget) — tune against the measured write-amp budget, not copied:

```
write_buffer_size: 128MB                     # memtable size before flush
max_write_buffer_number: 6                   # memtables in flight + queued
level_compaction_dynamic_level_bytes: true    # last level holds the full dataset;
                                              # L0→L1 write-amp drops vs fixed sizes
compression: lz4 (hot levels) / zstd (cold)   # cheap CPU for hot data
max_background_compactions: 4                 # headroom > write rate, or starvation
compaction_readahead_size: 16MB               # sequential-read compaction on NVMe
bloom filter: whole_key_filtering=true        # default on; verify per column family
```

**Rationale per knob**: bigger `write_buffer_size` = fewer, larger SSTables = slower L0 arrival rate, but flush stalls get longer (watch flush latency); `max_write_buffer_number` absorbs write bursts without stalling (a write stall at 6 queued memtables shows the burst is bigger than planned — resize, don't just raise the count); `level_compaction_dynamic_level_bytes` is the single highest-leverage LCS knob — sizes levels from the bottom up so the last level holds the data, cutting L0→L1 write-amp roughly in half on large datasets; `max_background_compactions` must be provisioned against the measured write rate — it is the starvation valve (see diagnostic above); `compaction_readahead_size` turns compaction's random reads into sequential ones on NVMe — the 2026 flip applied to the maintenance path; compression split (lz4 hot / zstd cold) trades CPU (cheap, parallel) for I/O and space (expensive).

**Knob → triangle mapping (why each knob exists):**

| Knob | Corner moved | Direction |
|---|---|---|
| write_buffer_size ↑ | write-amp ↓ / space-amp ↑ | Bigger SSTables, fewer levels crossed, more mem memory |
| max_write_buffer_number ↑ | write stalls ↓ | Burst absorption, memory cost |
| level_compaction_dynamic_level_bytes | write-amp ↓ | Bottom-up sizing halves L0→L1 |
| max_background_compactions ↑ | read-amp ↓ | Keeps L0 shallow; CPU/IO cost |
| bloom bits ↑ | read-amp ↓ | Memory cost |
| block cache ↑ | read-amp ↓ | Memory cost |

Every knob trades memory or CPU for a triangle corner — "more is better" tuning advice is how the Iron Law gets violated twice (advice without profile, tuning without budget).

**Write-amp budget arithmetic (do this before quoting knobs)**: estimate bytes written to disk per byte written by the app = WAL (1x) + flush (1x) + compaction rewrites (LCS ~ level count x amplification). If the budget is "NVMe, throughput sacred, reads hot-cache" → larger buffers, fewer levels. If it is "read SLO, disk 80% full" → LCS default is already the right corner of the triangle.

## Compaction strategies in mechanics terms

Parent skill section A holds the decision table; here is what each strategy does physically:

- **STCS** — waits for N similarly-sized SSTables, merges them into one bigger tier. Merges are rare and large: write-amp low, but a hot key occupies one entry per tier until the merge — space-amp can reach multiples of logical size on update-heavy workloads. Merge timing is bursty: long quiet periods, then a big I/O storm.
- **LCS** — maintains levels of ~10x size, sorted non-overlapping within a level. Each level's runs get merged into the next as they accumulate; every key rewrite crosses each level once — write-amp floor predictable, space-amp ~1.1x, reads touch at most one run per level. The cost is constant background I/O: compaction runs all the time, quietly, forever.
- **ICS** — incremental merges sized for TTL: expired rows leave at merge boundaries without rewriting whole tiers. The narrow newcomer (Scylla 2026): validated for time-series TTL, not yet general-purpose advice.

**Selection rule** (maps to parent profile inputs): write-amp budget sacred + disk cheap → STCS; read latency SLO + predictable ops → LCS; TTL time-series → ICS. Space-amp sensitive workloads on STCS is the classic mis-deployment (parent anti-pattern row 10).

## Worked comparison — same workload through both engines

**Workload**: 10k writes/sec sustained, mixed point lookups (70%) + time-range scans (30%), 500GB, NVMe.

| Aspect | B-tree (e.g., Postgres) | LSM (e.g., RocksDB, LCS) |
|---|---|---|
| Write I/O shape | Random page rewrites + WAL | Sequential appends; compaction deferred |
| Write-amp | ~2x + every index | ~4-6x total (WAL + flush + levels) but sequential — NVMe absorbs it |
| Point lookup (hot) | ~1 cached page | Bloom + block cache ≈ comparable on NVMe |
| Range scan | Sequential leaf walk | Merge of overlapping runs; starves if compaction behind |
| Space | ~1x + bloat (vacuum debt) | >1x until compaction; LCS bounds it |
| Ops surface | Vacuum tuning, index bloat | Compaction tuning, tombstone debt |
| Verdict at this profile | Viable if writes stay under ceiling; watch buffers/bloat | Viable if compaction headroom > write rate; watch L0 |

**Neither verdict is "better"** — the profile (ratio 30:70 read:write, mixed lookups) keeps both viable, and the deciding factors are ops maturity and which corner of the triangle the SLO protects. This table is the artifact to show a user who asks "which is faster": the question is malformed until the workload profile names the corner that matters.

**How to use this reference from the parent skill**: the parent SKILL.md sections A-B hold the decision rules and the Iron Law; this file holds the mechanisms and the numbers-behind-the-rules. When advising: profile first (parent Hard Gate), pick the engine family (parent decision table), then justify with the mechanism detail here (write path, read path, knobs, hardware pricing). A recommendation citing this file without having named the three profile inputs is out of order — the gate precedes the walkthrough.

## NVMe impact 2026 — amp math flipped

HDD-era advice priced random reads at ~100x sequential — this priced the LSM read-amp penalty high (dozens of random page reads per lookup vs one) and made bloom filters the make-or-break feature. On 2026 NVMe (queue depth >64, random ≈ sequential within a factor of ~2), the read-amp penalty of LSM is far cheaper: merging 30 runs = 30 page reads ≈ a few ms, not disk-seek death.

**Consequences for advice**: (1) the B-tree read-amp advantage shrinks on NVMe — LSM becomes competitive for read-heavy point-lookup workloads that would previously have demanded B-tree; (2) read-amp tuning (bloom bits, block cache) matters less than write-amp tuning (buffer sizes, compaction threads) — the bottleneck moved; (3) HDD-era benchmark intuitions in training data ("B-tree for reads, always") are stale — price the amp triangle on the actual storage hardware, or the advice is for a machine the user does not run.

**Still true regardless of hardware**: bloom filters do not cover range scans (compaction is the only fix for L0 read-amp); warehouse cost floors do not care about NVMe; the amplification triangle still binds — NVMe reprices the corners, it does not remove the trade.

**NVMe-era advice checklist (what changes in the answer):**

1. LSM read-amp penalty quoted from HDD-era intuition → repriced: random ≈ sequential within ~2x, so "B-tree for reads, always" is stale — say which corner the workload actually protects.
2. Read-amp tuning (bloom bits, block cache) demoted below write-amp tuning (buffers, compaction threads) — the bottleneck moved.
3. `compaction_readahead_size` raised: compaction is now sequential-read-shaped on hardware that rewards it — cheap headroom against starvation.
4. HDD-era benchmarks in training data: flag them as stale when they surface in advice; hardware generation is part of the workload profile (Iron Law input 3 — the write-amp budget is hardware-denominated).

---

**Modification footer** : any change to this file requires flagging the parent skill's Revision History (SKILL-D2-001) — see ddia-glossary.md modification protocol.

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-08-29 | Initial: SSTable flush walkthrough, bloom/read path, compaction-starvation diagnostic, tuned LCS RocksDB params, NVMe 2026 impact. | Skills maintainer | Skills maintainer |