---
name: ddia-pipeline-architect
description: Use when designing data pipelines, CDC flows, event-driven integrations, or stream/batch processing — pipeline advice without naming delivery semantics (at-least/exactly/effective-once) and without the outbox pattern ships silent data divergence between primary store and derived views
type: sub-skill
contracts:
  - cdc-patterns
  - kafka-2026
  - stream-processing
  - streaming-tables
  - anti-patterns-table
---

# DDIA Pipeline Architect

## The Iron Law

> **NO PIPELINE ADVICE WITHOUT DELIVERY SEMANTICS STATED.**

This is not a guideline. Every pipeline is a delivery-semantics contract: at-least-once means duplicates reach the consumer; exactly-once means transactions and checkpointing overhead; effective-once means at-least-once wire plus idempotent consumers. The agent's training data emits "sync X to Y" advice that never says which one it is — and the unspecified contract is the divergence: the primary store and the derived view disagree, silently, at a rate that defeats reproduction (glossary: dual-write, at-least/exactly/effective-once). A pipeline recommendation that never names the semantics is not a conservative recommendation; it is an unspecified one, and unspecified pipelines corrupt derived state months later. The semantics are named, or the recommendation is not emitted.

**Announce discipline:** every answer this skill emits starts by naming which delivery semantics the proposed flow runs at, whether a dual-write window exists (and its outbox fix), and how the consumer survives redelivery. An answer that says "we'll sync the data" without the triple has already violated the Iron Law.

**Why the triple comes first:** the delivery semantics decide the failure mode (section A: what happens on crash mid-flight — duplicate, loss, or transaction); the dual-write check decides whether the source of truth can diverge at all (outbox pattern — glossary — is the only safe shape, and the hidden dual-write of "commit then call the API" is the same window); the consumer idempotence story closes the loop, because at-least-once delivery is the 2026 default and a non-idempotent consumer turns every redelivery into corruption. Skipping the semantics means all three are unknown at once — the divergence compounds silently.

## Hard Gate

<HARD-GATE>
Do NOT emit, endorse, or bless any pipeline recommendation without first having (1) delivery semantics named (at-least-once / exactly-once / effective-once), (2) the dual-write check run — two stores written in one flow require the outbox pattern, no exceptions, and (3) the consumer idempotence story (dedup key, upsert shape, or window). This applies even under deadline pressure, even for "it's just a simple sync", even when the user says "it's only a cache, it can drift".
</HARD-GATE>

This gate exists because three failure modes recur on every pipeline question: (1) the user arrives with a sync request ("j'écris dans Postgres et ES en même temps") and a compliant agent wires it — the fix is refusing until the outbox replaces the dual-write, because two sequential writes without a transaction cross them is divergence by construction (anti-pattern row 1); (2) "Kafka gives us exactly-once" is asserted without the cost named — exactly-once is real but paid in transactional overhead, checkpoint latency, and throughput, and the 2026 pragmatic default is effective-once (at-least-once + idempotent consumer) — the claim is priced or it is refused; (3) the "simple sync" handwave — even a cache-refresh flow carries a semantics contract (drift accepted? rebuilt how? on crash mid-write?), and every pipeline this skill blesses states it. The gate forces all three to the surface before any architecture.

**Gate enforcement — the three numbered requirements:**

| Requirement | What satisfies it | What does not |
|---|---|---|
| (1) Delivery semantics named | "at-least-once + idempotent consumer (effective-once)", "Kafka transactions, exactly-once within the pipeline" | "reliable sync", "we don't lose data" |
| (2) Dual-write check + outbox | "two stores in one request → outbox table + CDC extraction" | "we write PG then ES, it's fast" |
| (3) Consumer idempotence story | "upsert by event_id + dedup window on redelivery" | "we process each message once" (assertion, not mechanism) |

If any row is unanswerable, the output is the three questions — not a conditional pipeline sketch. "Here's the sync design, but which delivery semantics…?" violates the gate: a partial pipeline still anchors the user.

## Snapshot

This skill owns the rules an agent applies when designing data movement: CDC patterns (Debezium 3.7 dominant under the Commonhaus foundation, PG logical decoding stable, outbox pattern mandatory against dual-write, Fivetran/Airbyte as the SaaS ELT layer above), the Kafka 2026 landscape (4.3 KRaft-only — ZooKeeper removed in 4.0, tiered storage GA, Redpanda as the serious C++ Jepsen-tested alternative, WarpStream zero-broker cloud-native, Pulsar/NATS niche), stream processing (Flink 2.3 dominant — materialized tables, changelog SQL; Kafka Streams JVM steady; watermarks + lateness handling; Spark Structured Streaming), and the streaming-tables convergence (Tableflow GA — Kafka topics to Iceberg direct via REST catalog, no separate pipeline; the DDIA ch10/11 batch/stream split dissolving; DuckDB+dbt for small/medium batch; Ray for ML pipelines; Airflow default with Dagster/Prefect asset-centric growing). It mandates delivery-semantics naming, the dual-write check, and the consumer idempotence story before any pipeline verdict, plus the proportionality reflex (does this load need a broker at all). Kafka cluster operations/tuning and pipeline security are advisory context, not this skill's scope. The outbox schema, Debezium config, Tableflow flow, idempotent consumer pattern, and event-sourcing verdict live in `references/streaming-tables.md`.

**Announce at start:** `I'm using the ddia-pipeline-architect skill to design this data flow.`

**Failure mode this skill prevents:** — a "simple sync" whose semantics were never stated, so Postgres and Elasticsearch drift apart after the first crash mid-write — the dual-write window was open by construction, redeliveries duplicated the consumer's side effects, and the divergence surfaces as stale search results or double-charged orders months later, invisible to every test that ran without a crash. The second failure is quieter: the over-built pipeline — Kafka standing guard over 100 events/day — fails financially, its ops cost eating the feature budget, its complexity eating the team's attention. The semantics-outbox-idempotence triple plus the proportionality reflex are the countermeasure.

## Quick Reference (projection — see Content sections for full rules)

**Quick Reference projection table** — summary card; full rules in sections A-E. If the card and the sections disagree, the sections win.

The card exists for fast pattern-matching by the agent mid-task; it does not replace reading the section.

| Field | Value |
|---|---|
| Audience | Agent or engineer designing data pipelines, CDC flows, event-driven integrations, stream/batch processing |
| Trigger | "sync X to Y", "CDC", "Kafka", "stream processing", "how do we update ES/Redis when PG changes", "exactly-once", "webhooks" |
| Inputs | The flow under design; the three gate questions if semantics, dual-write status, or idempotence absent |
| Outputs | Pipeline design naming semantics + dual-write verdict + consumer idempotence + tier proportionality; gate questions if any input unknown |
| Type | sub-skill (see `_shared/SKILL-ARCH.md`) |
| Baseline | Outbox before any dual-write; effective-once default; Debezium for CDC; broker only when volume earns it |
| Iron Law | NO PIPELINE ADVICE WITHOUT DELIVERY SEMANTICS STATED |
| Scope out | Kafka cluster ops/tuning (brokers, partitions math, ISR), pipeline security — advisory only |
| Identity | Descriptive name (`ddia-pipeline-architect`); stable — do not rename |

## Related Skills

| Sibling | Relationship | What crosses the boundary |
|---|---|---|
| `using-superpowers` | `upstream` | Routes pipeline/CDC/streaming triggers here. Translation: using-superpowers's "trigger match" = this skill's "design announced". |
| `writing-skills` | `shared-kernel` | Co-maintains TDD-for-skills vocabulary. This skill applied RED→GREEN→REFACTOR during its own authoring. |
| `technical-writing` | `shared-kernel` | Co-maintains 4-slot discipline (Audience, Purpose/Scope, Definitions, Revision History). |
| `_shared/ddia-glossary.md` | `shared-kernel` | CDC, outbox, dual-write, watermark, at-least/exactly/effective-once, streaming table definitions live there. Never duplicated here. |
| `_shared/glossary-en.md` | `shared-kernel` | TDD/RED/GREEN/Iron Law/Hard Gate terms live there. |
| `ddia-tradeoff-analyzer` | `none` | Independent domains, no mutual invocation. That skill names the source of truth; this one moves data out of it. |
| `ddia-storage-internals` | `none` | Independent domains, no mutual invocation. This skill moves data; that one tunes where it lands. |
| `ddia-distributed-debugger` | `none` | Independent domains, no mutual invocation. Isolation anomalies enter via their own trigger, not a call from this one. |

**Sibling boundary note** : the four ddia-* skills cover independent domains (choice vs internals vs correctness vs movement). No skill invokes another; a single conversation may load two (e.g., a store chosen there, then its CDC designed here), but each enters via its own trigger, not a call from this one.

## The Design Interrogation (the Hard Gate in question form)

When any of the three gate inputs is missing, the output is these questions — nothing else:

1. **"Which delivery semantics does this flow run at — and what happens on a crash mid-flight?"** — at-least-once: redelivery, consumer must dedup; exactly-once: transactions + checkpointing, priced; effective-once: at-least-once wire + idempotent consumer, the 2026 pragmatic default (section A). The crash question is the semantics made concrete: "the process dies between write 1 and write 2 — now what?" — the answer names the semantics, or the flow has none.
2. **"Does the flow write two stores in one request path — and if yes, where is the outbox?"** — two sequential writes without a distributed transaction is the dual-write anti-pattern (glossary): the first can commit while the second fails, and the stores diverge silently. The outbox pattern — event row written inside the business transaction, extracted by CDC — is the only safe shape. The hidden variant counts: any non-database effect after the commit (webhook, email, API call) is the same window.
3. **"How does the consumer survive redelivery — dedup key, upsert shape, or window?"** — "we process each message once" is an assertion, not a mechanism; rebalances and restarts re-deliver structurally (section C restart mechanics), so the mechanism is named or the consumer is assumed correct without evidence.

**Evidence beats interrogation:** if the producer code, transaction boundaries, consumer loop, or connector configs are reachable, design from them first — the actual at-least-once reality of the deployed consumer beats the intended design, and teams systematically believe they have effective-once while running bare at-least-once with no dedup.

**The proportionality reflex (asked before any architecture):** the three questions above assume a pipeline is warranted; the interrogation's question zero is whether one is. Event volume, consumer count, freshness need, and replay need decide the tier: 100 events/day → LISTEN/NOTIFY, cron, or polling (anti-pattern row 3); GB-scale nightly transforms → DuckDB + dbt (row 12); sustained high volume + multiple consumers + replay → a broker. The reflex is the workload profile from the tradeoff sibling, carried into movement design: the expensive architecture answers a question the load never asked, and every component this skill blesses gets its "why this tier" named. The outbox travels free across tiers — a cron dispatcher and a Debezium extraction read the same table — so the *event* shape is decided once, and the transport is swapped when its trigger arrives (section B scale card).

**When the design exits:** the skill's job ends when the verdict is emitted — semantics named, dual-write resolved (outbox or single-store), consumer idempotence mechanism stated, lateness/watermark policy declared if streaming, tier proportionality justified. Cluster sizing, broker tuning, and security hardening belong to the regular engineering flow (scope-out); re-designing after a schema change is this skill's re-entry point. A verdict that lingers into Kafka ops tuning has drifted — restate the design and stop.

## A. CDC Patterns

**Change Data Capture — read the WAL, don't poll the table.** CDC extracts committed changes from the database's transaction log (glossary: CDC) instead of `SELECT`-polling the source — no load on the primary, no missed rows between polls, ordering preserved from the log. **Debezium 3.7 is the dominant engine**, now under the **Commonhaus foundation** (community-governed, vendor-neutral — the project outlived any single corporate sponsor); connectors for Postgres, MySQL, MongoDB, SQL Server, Oracle. **PG logical decoding** (the `pgoutput` plugin) is stable and production-standard — the replication-slot mechanism Debezium builds on, usable directly when a pipeline needs no Debezium features. **DDIA 2017: log-derived streams sketched conceptually. SOTA 2026: Debezium under Commonhaus is the default CDC answer, PG logical decoding the stable substrate.**

**Log-based beats polling on three axes at once.** A polling loop (`SELECT * WHERE updated_at > last_check`) fails differently from log-based extraction: it loads the primary with full-scan frequency, misses rows that changed and changed back between polls (unless `updated_at` is write-protected against it), loses transaction order (two polls can see a later write before an earlier one committed), and can't see deletes without soft-delete columns. The log sees committed changes exactly once, in commit order, with zero primary load beyond the slot. The polling shape survives only where the source offers no log access (some SaaS sources, section A's inbox case) — and even then the design names the polling contract's misses rather than pretending parity (anti-pattern row 10).

**The outbox pattern — mandatory, not optional.** The pipeline question that matters first is not "which connector" but "how does the event leave the transaction". Writing the business row and then publishing to Kafka (or ES, or Redis) in the same request path is **dual-write** (glossary: dual-write): the second write can fail after the first commits — app crash, network blip, broker down — and no retry loop closes it, because the retry that succeeded creates a duplicate window on other failure shapes. The outbox pattern (glossary: outbox pattern) is the fix: the event is written **into an outbox table inside the same database transaction** as the business change (one commit — atomic), and CDC (Debezium's outbox event router, or a relay) extracts the outbox rows and publishes. Either both land or neither does. Full schema + config: `references/streaming-tables.md` § outbox. The transactionality is the entire point — an outbox written *after* the commit (separate transaction) is the dual-write with extra steps, and the audit checks where the `BEGIN` boundary sits, not whether an outbox table exists.

**Dual-write verdict format:** "two stores, one request path → outbox + CDC (atomic by construction). Dual-write with retry → refused: divergence by construction (anti-pattern row 1)." There is no configuration of sequential writes that closes the window — the fix is structural, not tuning.

**Dual-write check, the two shapes the agent must recognize:** shape 1 — explicit dual-write ("write PG then ES in the handler"): refused, outbox (row 1). Shape 2 — the hidden dual-write: "save the record, then call the webhook / send the notification / call the API" — any code path where a non-database effect follows a database commit inside one request is the same window; the fix is the same (effect becomes an outbox event consumed by a sender, so the effect's delivery inherits the wire semantics and dedup instead of the request's lifetime). The interrogation's question 2 catches both by asking "what else happens in this request path after the commit?".

**The outbox schema is small and fixed — don't redesign it.** The canonical table (full SQL + Debezium config in `references/streaming-tables.md` § outbox): `id` (uuid), `aggregate_id` (the consumer's upsert key), `event_type`, `payload` (jsonb), `created_at` — insert-only, no updates, no deletes by the app. Two design rules travel with it: the payload is the event the consumer needs, **not** a reference to the business row (a consumer that re-reads the source table reintroduces coupling and races the next change), and `aggregate_id` routes to one Kafka partition so per-aggregate order survives the wire. Ops consequences decided at design time: rows accumulate → archiving job; the replication slot holds WAL → lag monitoring.

**Event granularity — what one outbox event contains.** The event carries a business fact, not a row diff: `OrderCreated` with the customer-visible payload, not `orders.row.inserted` with column values. Granularity rule: one event per state transition the downstream *acts on* — consumers that filter out 90% of events mean the producer modeled wrong facts (row-shaped instead of fact-shaped), and every consumer pays the filter tax forever. Schema governance rides on the fact shape: `event_type` is the contract, Buf/BSR governs its evolution (row 7), and the payload versioning discipline is fact-versioning — additive fields default, breaking changes get a new event type, old types retired only after consumer census.

**CDC extraction tier (the decision card):**

| Flow need | Answer | Check |
|---|---|---|
| DB → stream, ordering preserved | Debezium 3.7 (Commonhaus) | Outbox router for app events; connector for table-level CDC |
| DB → stream, no Debezium features | PG logical decoding direct | Slot lag monitored; you own the extraction code |
| SaaS/OLTP → warehouse, minutes-fresh | Fivetran / Airbyte | Not an event stream — analytical replication only |
| Table → cache/search, seconds-fresh | CDC + sink connector | Consumer upserts by key (gate input 3) |

**Ordering — what the log gives and what it doesn't.** Debezium (and logical decoding) preserve per-table transaction order: events arrive in commit order per source table, and the outbox's `aggregate_id` key routes each aggregate's events to one Kafka partition — so per-aggregate order survives the wire. What the log does NOT give: a total order across aggregates or across sources. A consumer that needs cross-aggregate ordering has a design problem the source can't solve — the fix is a logical timestamp (HLC lineage — glossary sibling section) or an explicit coordination point, never `created_at` sorting (anti-pattern row 9). The design verdict names which order the consumer actually gets: "per-key order guaranteed, cross-key unordered — downstream must not correlate by arrival".

**Consumer idempotence — the three mechanism shapes (gate input 3's menu):** (1) **upsert by key** — state merges instead of duplicating (`ON CONFLICT ... DO UPDATE`, ES doc id, Flink materialized table); (2) **dedup table** — `processed_events(event_id)` PK-inserted in the same transaction as the side effect; a PK conflict means redelivery → skip; (3) **natural idempotency** — the operation re-applied twice lands in the same state (`set status = 'shipped'`, absolute value not increment). The design picks per leg: state views → upsert; effects (emails, charges, HTTP) → dedup table or idempotency key; control flows → natural idempotency where honestly available. Code for all three: `references/streaming-tables.md` § idempotent.

**When the source has no transaction to hook (SaaS APIs, third-party systems):** the outbox needs a database transaction to be atomic in; a SaaS source offers none — the honest designs are polling with a cursor + watermark (change feeds where offered, `updated_since` cursors otherwise, accepting the miss-window between polls) or vendor webhooks + a local inbox table (webhook lands in your DB first — *then* the outbox flows — so retries at the webhook layer dedup at the inbox PK). "Webhook handler writes the SaaS data and calls downstream services in one request path" is the dual-write shape with a third party holding the transaction — same row 1, same fix at your boundary.

**Initial snapshot + incremental — the two-phase contract.** Debezium's default flow snapshots the table first (consistent, streaming the full current state), then tails the log from the snapshot's LSN — the union is exactly-once into the topic (a row captured before its snapshot row is deduplicated by the connector's metadata, not by your consumer). The design question that recurs: destination-side idempotence during snapshot replay — a full table dumped into a consumer built for trickle rates is the anti-pattern row 8 shape. The design names the sink's replay behavior before blessing the mode.

**Fivetran/Airbyte — the SaaS ELT layer above.** When the flow is "replicate SaaS APIs / OLTP stores into the warehouse" (Salesforce→Snowflake, PG→BigQuery), Fivetran and Airbyte sit above the CDC tier: managed connectors, schema drift handling, no Debezium to operate. They are the right answer for analytical replication where minutes-scale freshness suffices; Debezium-class CDC remains the answer when the event must stream onward (caches, search indexes, downstream services) with seconds-scale freshness and ordering preserved. Decision rule: destination is a warehouse and freshness ≥ minutes → Fivetran/Airbyte; destination is a stream/cache/index and freshness ≤ seconds → CDC + outbox. The boundary is a freshness + ordering question, not a tooling-fashion question — and the boundary can sit mid-flow: Fivetran feeds the warehouse while Debezium feeds the operational views off the same source, each leg with its own semantics named.

**Snapshot mode — decide it, don't inherit it.** Every CDC connector offers initial snapshot + incremental or incremental-only. The snapshot mode decides what happens on first deploy and on re-sync (full re-snapshot vs offset resume) — a connector left at defaults will re-snapshot on config drift and replay the entire table into consumers that were never idempotent for full replay (gate input 3 again). The pipeline design names the mode and the consumer's replay behavior together.

**Worked example — the audit in action:**

User: "orders table in Postgres, need it searchable in Elasticsearch, we'll update ES right after the insert in the app code." Design output: "Dual-write, refused (anti-pattern row 1): insert commits, ES update fails or crashes mid-flight → Postgres has an order Elasticsearch never saw; every retry variant leaves either a loss or a duplicate window. Fix: outbox table + Debezium outbox event router → Kafka topic → ES sink connector (upsert by `order_id` — idempotent on redelivery, gate input 3 satisfied). Delivery semantics: at-least-once on the wire, effective-once at the index (upsert by key). Snapshot mode: initial snapshot + incremental; ES sink replays idempotently by key, so re-snapshot is safe. The schema and connector config are in `references/streaming-tables.md` § outbox."

**Worked example 2 — the SaaS source:**

User: "Stripe webhooks update our billing table, then we call the provisioning API in the same handler — worked fine until Stripe retried a webhook." Design output: "Two issues, one root: the webhook is at-least-once over HTTP and the handler is a request-path dual-write (hidden shape, section A). Fix: webhook handler writes to an inbox table (PK = Stripe event id — retry deduped at the boundary), commits, returns 200; a consumer processes inbox rows → provisioning API call carries idempotency key (Stripe-side dedup) → outbox event for downstream views. Semantics: at-least-once at every hop, effective-once at the billing table (upsert) and at provisioning (idempotency key). The 200-after-commit rule matters: acknowledging before commit loses the event on crash — the inbox makes ack safe."

**Worked example 3 — the hidden dual-write:**

User: "our signup handler creates the user row then calls Stripe to create the customer — if Stripe 500s we retry, it's fine." Output: "Hidden dual-write, same window (section A shape 2): row commits, Stripe call fails — retry duplicates or the user proceeds without a billing identity, depending which failure wins. Retry makes it worse, not better (row 1). Fix: `signup_requested` row + outbox event; a Stripe sender consumes it with the Stripe idempotency key (the call's dedup is Stripe-side, named); failure parks in DLQ with a replay tool + alert (row 15). Semantics: at-least-once from the outbox, effective-once at Stripe (idempotency key), and the user creation stays atomic with the event — the Stripe leg has its own retry budget without ever re-risking the commit."

## B. Kafka 2026

**Kafka 4.3 — KRaft-only.** ZooKeeper was **removed in Kafka 4.0** (the KRaft migration completed): metadata lives in the Raft-committed log, brokers scale to thousands of partitions without the ZK ceiling, and every "Kafka + ZooKeeper" deployment recipe in training data is obsolete. Any 2026 design that sizes a ZooKeeper ensemble or cites ZK-based rebalancing is citing a removed architecture. **DDIA 2017: ZooKeeper-based coordination assumed. SOTA 2026: KRaft-only since 4.0.**

**Tiered storage — GA.** Kafka's storage model changed: old segments upload to cheap object storage (S3-class) and brokers keep only the tail hot — retention stretches from days to months/forever without broker-disk proportionality, and the historical "Kafka is expensive to retain" objection to log-based architectures dissolves. Consequences for design: long retention + Tableflow-class topic-to-table sync (section D) become one economics decision; consumers can re-read history without re-ingesting source systems — the re-snapshot answer for downstream rebuilds (and the enabler of the Kappa replay pattern, anti-pattern row 14's fix). The design names its retention budget: how far back a consumer may need to replay (consumer rebuild, new consumer onboarding, bug investigation) × topic rate = the tiered-storage economics; retention chosen by default (7 days) is the replay promise row 11 makes and can't keep.

**Redpanda — the serious C++ alternative.** Redpanda (protocol-compatible, thread-per-core C++) is the production alternative for latency-sensitive deployments: lower tail latencies at high throughput, no JVM tuning, **Jepsen-tested**. The design rule: workload is JVM-hostile (no ops team for GC tuning) or tail-latency SOTA is contractual → Redpanda is a legitimate drop-in; otherwise Kafka's ecosystem gravity (connectors, Tableflow, exactly-once transactions maturity) wins. **WarpStream — zero-broker cloud-native:** WarpStream's architecture separates compute (stateless agents) from storage (object store directly, no brokers writing local disks) — the Kafka-compatible answer for cloud-economics-first deployments where throughput-to-S3 beats tail latency. Pulsar and NATS JetStream remain **niche**: Pulsar's multi-tenancy/segment architecture serves specific large-fleet cases; NATS JetStream serves lightweight/edge messaging — neither displaces Kafka for event-backbone pipelines.

**Exactly-once in Kafka 2026 — the mechanics the design must name.** Kafka's exactly-once is transactional producer + idempotent consumer configured to read only committed transactions (`isolation.level=read_committed`), plus Kafka Streams transactions binding input offsets to output writes (consume-transform-produce atomic). It is real, mature in the KRaft era, and it scopes: **within** the Kafka+Streams boundary. The moment the consumer writes to Postgres, calls an HTTP API, or sends an email, the exactly-once is over — that leg runs at-least-once + the consumer's own idempotence (the effective-once pattern, `references/streaming-tables.md` § idempotent). The design verdict never extends Kafka's exactly-once past the boundary it holds.

**The "do we even need a broker" scale card (the proportionality reflex in numbers):**

| Signal | Answer |
|---|---|
| ~100 events/day, one consumer | PG LISTEN/NOTIFY, cron, or polling — no broker (row 3) |
| Thousands/day, 2-3 consumers, freshness ≥ minutes | Queue-as-needed: PG SKIP LOCKED workers still fit |
| Sustained hundreds+/sec, many consumers, replay, ordering | Kafka-class broker earns its ops cost |
| JVM-hostile or tail-latency contractual | Redpanda on the same flows |
| S3-economics-first, cloud-native | WarpStream |

**Decision card — broker/transport choice:**

| Need | Answer | Check |
|---|---|---|
| Event backbone, ecosystem-first | Kafka 4.3 (KRaft) | Exactly-once transactions + Tableflow available |
| Tail latency, no JVM ops | Redpanda | Protocol-compatible; Jepsen-tested |
| Cloud economics, S3-resident | WarpStream | No-broker model; latency tradeoff named |
| Lightweight/edge messaging | NATS JetStream | Not a pipeline backbone — niche |
| Multi-tenant fleet messaging | Pulsar | Niche — name why Kafka insufficient |

**Worked example:** User: "Kafka 3.5 cluster on ZooKeeper, planning upgrade to 4.x — anything architectural?" Output: "Yes: 4.x is KRaft-only (ZK removed in 4.0) — the upgrade is a metadata-mode migration (ZK → KRaft), not a version bump; run the migration tooling on a rehearsal cluster, brokers cannot see ZK again after cutover. While you're there: tiered storage is GA — move old segments to object storage and the retention economics change (months of retention without broker disk proportionality); evaluate Tableflow (section D) before building a separate topics→warehouse pipeline."

**Worked example 2 — the proportionality audit:**

User: "new service, ~5k events/day projected, we'll stand up a 3-broker Kafka." Output: "Run the scale card first (section B): 5k/day ≈ 0.06/sec — three brokers to carry a rounding error. The broker answer unlocks at sustained hundreds/sec + multiple independent consumers + replay need; none apply. Answer: outbox table + a cron-driven dispatcher (or PG LISTEN/NOTIFY for live legs), polling consumers with SKIP LOCKED if worker-fanout appears. The outbox is the design's insurance — if volume does cross the line, the extraction side swaps (Debezium on the same outbox table) and nothing else changes; that's the architecture that scales by *replacing the transport*, not by pre-building it. Kafka arrives when its trigger arrives, with the events already flowing."

## C. Stream Processing

**Flink 2.3 — dominant.** Apache Flink is the 2026 default for stateful stream processing: true event-time processing, **materialized state** that survives failure (checkpointed), and **changelog SQL** — `CREATE TABLE ... AS SELECT` over streams whose result is a continuously-updated table, with the changelog stream queryable. The materialized-table abstraction is the one to reach for when the requirement is "maintain a derived view/aggregation over the stream" — the processor owns the state, not the consumer. **DDIA 2017: stream processing sketched as derived-state maintenance. SOTA 2026: Flink 2.3 materialized tables + changelog SQL are the shipping form of that idea.**

**Failure semantics — checkpointing is the contract.** Flink's failure story is consistent checkpoints: state + input offsets snapshotted together (chandy-lamport lineage), and on failure the job restores to the last checkpoint and replays the input from the stored offsets — which means the sink sees a window of **replayed output**. The design consequence: sinks must be idempotent over re-fires (upsert by key — the same gate-input-3 mechanism) or the replay becomes duplicate side effects. Checkpointing interval is the latency-vs-recovery-cost dial the design names: 30s intervals → up to 30s of replay on recovery, paid back as bounded recovery time instead of reprocessing from zero.

**Kafka Streams — the JVM steady default.** For Kafka-centric pipelines without a separate compute cluster, Kafka Streams (and its exactly-once semantics within the app: transactional producer + committed offsets) remains the steady answer: state stores local to the app, no external coordinator, the operational surface of one JVM service. Decision rule: processing is within-Kafka transforms/aggregations and the team runs JVM services anyway → Kafka Streams; cross-source joins, large keyed state, event-time watermarks at scale, SQL interface wanted → Flink.

**Consumer restart mechanics — where at-least-once actually bites.** The wire's at-least-once is not a rare crash scenario; it is every routine event: consumer group rebalance (deploy, scale event, broker blip) reassigns partitions and the new owner re-reads from the last **committed** offset — messages processed after the last commit are re-delivered, always. A consumer that commits per-batch with processing after receive has a redelivery window equal to the batch; a consumer that commits per-message shrinks it but pays throughput. The design names the commit cadence *and* the dedup it implies — sizing one without the other is how "we don't see duplicates" deployments get surprised by the first rebalance under load. This is the concrete reason gate input 3 refuses "we process each message once": rebalances are scheduled, duplicates are structural.

**Backpressure — the consumer owns its fate.** A consumer slower than its topic falls behind, and the design decides what happens at the lag boundary: bounded consumer lag with an SLO (the honest default — lag monitored, alerts before the tail), or skip-with-record for time-decayed workloads (alerts, recommendations — where old events have negative value; the skip policy is named, and the skipped count is measured). The design refuses the silent third option — falling behind until retention truncates the unread head (anti-pattern row 11's cousin: data loss via ops neglect). DLQ (row 15) pairs with this: poison messages that stall the consumer loop get parked with a replay story, so one bad event doesn't turn lag into truncation.

**Watermarks + lateness — event time, not wall time.** Stream correctness over event-time requires **watermarks** (glossary: watermark — the completeness bound): a watermark at time T asserts no events older than T will arrive; window aggregations fire when the watermark passes. The design decision that recurs: what happens to **late data** — events past the watermark. The options are named, not defaulted: drop (lateness tolerance > delay), side-output for manual reprocessing, or allowed-lateness with window re-fire. A stream design that never states its lateness policy has an implicit one (drop silently) — that's gate-input-3 territory again: the policy is stated or the design is incomplete. Source ordering note: watermarks assume per-source monotonicity (Kafka offsets within a partition); cross-source joins must handle the skew explicitly.

**The lateness policy card (state it in these exact terms):**

| Requirement | Policy shape |
|---|---|
| Aggregates for display, 1% loss tolerable | Watermark 30s bounded out-of-orderness; late → drop; metric on drop count |
| Billing / financial aggregation | Allowed-lateness hours-days + re-fire with retraction (changelog SQL) |
| Anomaly review pipeline | Late → side-output topic → batch reprocessing leg |
| Cross-source join | Watermark per source + join-window sized to measured skew — named, not hoped |

**State size — the Flink-vs-Streams tiebreaker.** Both engines hold keyed state; the difference shows at scale: Flink's RocksDB-backed state stores hold keyed state well past RAM (TB-scale keyed aggregates live in production), checkpoint asynchronously to object storage, and reshard by key without the job redesign; Kafka Streams state stores are local (RocksDB too) but bound to the instance's disk and the app's partition count. The design tiebreaker: state per key is bounded and total state fits a JVM service's disks → Kafka Streams; state grows with key cardinality or must survive topology changes → Flink. **DDIA 2017: stream state as tables sketched conceptually. SOTA 2026: state backends are the operational reality that decides the engine.**

**Spark Structured Streaming — the batch-team on-ramp.** Micro-batch streaming with the DataFrame API: the answer when the team already runs Spark and the pipeline shares code/batch with Spark jobs; its continuous mode remains narrower than Flink's true event-time engine. Decision: greenfield low-latency stateful processing → Flink; existing Spark estate, pipeline shared with batch → Structured Streaming.

**Worked example — lateness in action:**

User: "per-user session windows over clickstream for live anomaly alerts, watermark set, but alerts fire twice sometimes and some never fire." Output: "Three named decisions missing, not one: (1) watermark generation — bounded out-of-orderness sized to *measured* inter-event delay, not default; if the source is multi-partition, per-partition watermarks merge at the operator — a slow partition holds the global watermark (starvation: alerts 'never fire'); (2) lateness policy — alerts firing twice = window re-fire on late arrival without downstream idempotence: the alert sink must dedup by (user, window, event) or re-fires are duplicates on the wire; (3) sink semantics — the alert is a side effect, so dedup table (section A idempotence shapes), not upsert. Verdict: at-least-once from Kafka, effective-once into the alert sink (dedup by key), lateness = allowed-lateness 5min + side-output past it. The 'sometimes twice, sometimes never' pair is always a watermark + idempotence double-miss."

**Worked example:** User: "fraud rules over payment stream, need per-user rolling window aggregates under 2s, Kafka source." Output: "Flink 2.3: keyed state per user, event-time sliding windows over the payment topic. Semantics named: at-least-once from Kafka, effective-once into the sink (aggregation results upserted by window key — idempotent on failure recovery). Watermark: 30s bounded out-of-orderness; lateness policy named: allowed-lateness 10min with re-fire + downstream retraction via changelog SQL, events past that side-output for review — drop silently is refused (anti-pattern row 5). Checkpointing: 30s to object storage; on recovery, state restores and the window re-fires from the checkpoint — consistent snapshots, not replay-entire-stream. Alternative rejected: Kafka Streams would work within-Kafka, but per-user state scale + SQL interface + lateness retraction point to Flink."

## D. Streaming Tables Convergence

**Tableflow — topics ARE tables, GA.** The 2026 convergence: **Tableflow** (Confluent's GA feature) syncs Kafka topics directly to **Iceberg tables** — the broker layer writes to the table format (via the **REST catalog**), no separate pipeline, no separate consumer cluster to operate, and the topic and the table stay aligned by construction. The batch/stream split that DDIA chapters 10-11 drew — "streaming = unbounded, batch = bounded, different systems" — is dissolving at the storage layer: the same data is a topic (to stream consumers) and an Iceberg table (to SQL engines), with one copy and one lineage. **DDIA 2017: batch and stream as separate layers. SOTA 2026: the split dissolves — topics→tables direct, Tableflow-class sync GA.** The flow diagram and boundary conditions: `references/streaming-tables.md` § tableflow.

**Why the REST catalog matters (the design consequence):** the catalog is the coordination point — registration, schema, partition metadata — and a REST catalog means no legacy metastore cluster to co-locate, secure, and keep in sync with the broker. The deeper consequence: tables become addressable the way topics are — a consumer group or SQL engine discovers the table by catalog lookup with the same authentication boundary as the topic, and access to "the orders data" is one grant whether consumed as a stream or queried as a table. Designs that still build a metastore-bridging pipeline between the log and the lake are paying for the pre-GA split (row 14's shape, infrastructure edition).

**Tableflow's boundary — what GA does not cover.** Tableflow syncs topic→table; it does not transform. Derived aggregates (`daily_revenue`, joins, enrichment) still need a processing tier (Flink changelog SQL writing its own topic→table pair, or dbt-on-Iceberg batch) — the convergence removed the *copy* pipeline, not the *transform* pipeline. And it assumes Confluent's broker (or an equivalent GA feature elsewhere — self-managed Kafka Connect + Iceberg sinks exist but reintroduce the pipeline you removed, anti-pattern row 11's "reprocess" promise now includes operating it). The design names which leg Tableflow covers and which leg still runs code.

**Freshness is a per-view property, named per view.** The convergence makes "real time" a design smell: each derived view gets its own freshness contract, and the contract is the design's product. Search index: seconds (CDC + outbox + sink). Warehouse tables: minutes-to-hours (Tableflow sync cadence / batch). Dashboards on aggregates: whatever the decision cadence needs — often hourly, never "live" by default. The design lists each destination with its freshness + rebuild mechanism, and the list is the answer to "is this real-time?" — a pipeline that claims one freshness for all views has claimed nothing.

**The per-view contract card (the design's deliverable):**

| View | Freshness | Mechanism | Rebuild |
|---|---|---|---|
| Search index | seconds | outbox + CDC + sink (upsert by key) | reindex from snapshot + tail |
| Cache entries | seconds-minutes | same CDC fan-out or TTL | TTL expiry (cache = disposable) |
| Warehouse table | minutes-hours | Tableflow (Iceberg) or ELT | re-sync from topic retention |
| Aggregates/dashboards | hourly-daily | dbt-on-Iceberg batch | re-run from table history |
| Live anomaly view | seconds | Flink materialized table | restore from checkpoint |

**What the convergence changes in design:** the "stream to Kafka, then build an ETL pipeline to the lakehouse" two-system answer becomes one decision — enable table sync on the topic, and the warehouse reads Iceberg directly. What it does NOT change: consumer idempotence (table sync is by-key upsert under the hood — the key must exist), schema governance (the topic's schema registry still governs; see anti-pattern row 7), and non-tabular flows (ES/Redis caches remain sink-connector territory). Design rule: analytical destination → Tableflow/Iceberg direct; operational destination (cache/search) → connector + idempotent sink as before.

**Batch is not dead — it got smaller.** Small/medium batch (GB-scale, nightly-to-hourly, transforms on structured data) runs on **DuckDB + dbt**: SQL-native transforms over files (Parquet) or a warehouse, no cluster. The design rule from the storage sibling holds: pipelines under the TB-scale / sub-hourly-freshness line don't need a distributed batch engine at all — DuckDB's columnar scan on modern hardware covers the range. **Ray** owns the ML pipeline tier: distributed Python (training, feature pipelines, inference batch) where dataframe+task parallelism is the workload — not a SQL ETL substitute. **Airflow** remains the default orchestrator; **Dagster and Prefect** grow as the **asset-centric** alternatives (define the data asset and its lineage, the scheduler derives the graph) — the choice is team-model-shaped, not capability-shaped, at current maturity.

**Orchestration decision card:**

| Pipeline shape | Answer |
|---|---|
| Topics → analytical tables | Tableflow (Iceberg direct, no pipeline) |
| Small/medium SQL batch | DuckDB + dbt |
| ML training/features/inference | Ray |
| DAG orchestration, default | Airflow |
| Asset-centric lineage-first | Dagster / Prefect |

**Kappa vs the rebuilt Lambda (anti-pattern row 14 in design terms).** The historic Lambda answer (batch layer + speed layer + merge at query time) is the two-code-path pipeline the convergence retired: with tiered storage retention (section B) + idempotent consumers, the log replay covers recomputation — one code path, one semantics. The design refuses a new Lambda construction unless the batch leg has an explicit justification (batch-leg economics on true-DB-scale history, regulatory reprocessing), and names it; "we'll maintain both paths for safety" is two divergence surfaces for one feature.

**Worked example — convergence in action:**

User: "we have the orders topic, and a Spark job that reads it hourly to build `daily_revenue` for the finance dashboard — thinking of moving it to Flink for real time." Output: "Name the freshness the decision-maker consumes: if finance reads the dashboard daily, hourly Spark is over-provisioned and Flink is over-over-provisioned — the answer is Tableflow (GA): topic → Iceberg direct, the dashboard queries the table, the hourly job and its cluster disappear. If a *live* view exists later (ops monitoring on the same stream), that's a separate Flink consumer with its own watermark + lateness policy (section C) — not a reason to make finance real-time. Per-view freshness (this section): finance = daily, ops = seconds; one topic, two views, no shared pipeline code between them."

**Worked example:** User: "orders topic needs daily revenue dashboards — building a Spark job that reads Kafka hourly and writes Parquet." Output: "That's the two-system answer the convergence replaced: Tableflow syncs the topic to Iceberg GA — same data, one lineage, no hourly job to operate, dashboards query the table (and the topic stays the stream source). If dashboards were already on Parquet nightly: the DuckDB+dbt tier covers the transform SQL at this scale — Spark is paying cluster cost for GB-scale scans. Name the sink idempotence anyway: Tableflow upserts by key, so the topic must carry the key. Lateness: Kafka→table sync aligns on topic offsets, no watermark policy needed for the table copy — that policy lives in stream consumers (section C) if you also aggregate live."

## E. Anti-Patterns

The table is the designer's checklist: each row is a design shape the agent must refuse or rework, with the fix that makes it honest. Rows are numbered for citation from sections A-D and the evals.

| # | ❌ Forbidden | ✅ Fix | Why |
|---|---|---|---|
| 1 | Dual-write without outbox (two stores, one request path) | Outbox table inside the business txn + CDC extraction | Second write can fail after first commits — divergence by construction, silent |
| 2 | Exactly-once assumed without cost named | Price it: transactional producer + checkpointing overhead, or effective-once | Exactly-once is real but paid; the unnamed cost is a false economy |
| 3 | Kafka for ~100 events/day | PG LISTEN/NOTIFY, cron jobs, or polling | Operational surface 100× the load; the queue is an ops liability at trivial volume |
| 4 | No consumer idempotence on at-least-once wire | Upsert by key / dedup table / idempotency key | Redelivery is the contract; "once" was an assertion, not a mechanism |
| 5 | Watermark ignored on late data | State the lateness policy: drop / side-output / allowed-lateness re-fire | Silent drop is the default nobody chose — late events vanish unreported |
| 6 | Event sourcing for simple CRUD | Plain tables + outbox events where events needed | ES adds replay/versioning machinery to state that doesn't benefit — see `references/streaming-tables.md` § es |
| 7 | No schema registry on evolving events | Buf/BSR (Protobuf) with compatibility enforcement | Untracked schema drift breaks consumers at deploy time, not design time |
| 8 | Connector snapshot mode ignored (defaults inherited) | Name initial+incremental and the replay behavior | Config drift triggers full re-snapshot into non-replay-safe consumers |
| 9 | Wall-clock `created_at` as event ordering | Log offsets / HLC / ingestion position | Clock skew misorders silently — same lottery as replication LWW |
| 10 | Table-polling CDC (`SELECT` loops on the source) | Log-based CDC (WAL/logical decoding) | Polling misses mid-poll changes, loads the primary, loses ordering |
| 11 | "We'll reprocess from the beginning if it breaks" with no replay design | Tiered storage retention + keyed idempotent sinks | Replay into non-idempotent consumers duplicates everything — the promise is untested |
| 12 | Flink/Spark for GB-scale transforms | DuckDB + dbt | Cluster cost for single-node scans — the batch engine tier shrank |
| 13 | One giant topic with `type` field as router | Topic per domain/event type; keys for partitioning | Schema governance and consumers both pay the union-tax; one schema change breaks all |
| 14 | Lambda architecture rebuilt by hand (batch + speed layer) | Kappa (log replay) or Tableflow convergence | Maintaining two code paths for one result is the legacy split dissolving (ch10/11) |
| 15 | Dead-letter queue as a black hole | DLQ with replay tooling + metric + owner | Events parked without reprocessing design are silent data loss with a dashboard |

**How to cite the table:** a design verdict references rows by number in its refusal ("anti-pattern row 1: dual-write — outbox required") and every row cited carries its fix in the same breath. When a request matches multiple rows ("Kafka for 100 events/day, no schema registry" → rows 3 + 7), refuse once per row — each row has its own mechanism fix, and bundling loses the fix.

**Reading order under pressure:** when the user wants a pipeline "now", walk the table top-down — rows 1-4 are the correctness core (dual-write, semantics, volume fit, idempotence: the four that corrupt data or budgets), rows 5-8 the stream contract (lateness, event sourcing fit, schema governance, snapshot mode), rows 9-15 the operational traps. A verdict that resolves rows 1-4 and names one lateness or replay residual is honest; a verdict that discusses tooling before rows 1-4 are answered has the priorities backwards.

## Document Metadata

| Field | Value |
|---|---|
| Document ID | `SKILL-D4-001` |
| Revision | 1 |
| Effective Date | 2026-08-29 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |

## Audience

- **Primary** : Agent/engineer designing data pipelines, CDC flows, event-driven integrations, or stream/batch processing.
- **Secondary** : Maintainers editing this skill; reviewers auditing pipeline designs.
- **Expertise** : Intermediate — reader has written a cron job or a Kafka consumer, maybe both.
- **Needs to learn** : Delivery semantics triple, outbox mechanics, CDC log-based extraction, watermarks/lateness policy, consumer restart/rebalance reality, 2026 landscape (Debezium/Commonhaus, KRaft, Tableflow).
- **Common misconceptions** : "Kafka gives exactly-once" (costless — no; and it ends at the wire), "two sequential writes are fine with retries" (dual-write — divergence by construction), "we need Kafka" (at 100 events/day — no), "exactly-once means consumers can be lazy" (semantics end at the wire; consumers still dedup), "batch and stream are different systems" (dissolving — Tableflow), "ES index updates are free" (they carry a full pipeline contract), "webhooks are reliable events" (they're at-least-once over HTTP — inbox-table them).

## Purpose / Scope

**Purpose** : enforce delivery-semantics-named pipeline design with the outbox pattern and consumer idempotence. LLM training data emits "sync X to Y" advice that never names what happens on crash mid-flight; this skill forces the three-part design contract before any pipeline recommendation, and the proportionality reflex before any pipeline at all.

**Covers** : CDC patterns (Debezium 3.7/Commonhaus, PG logical decoding, outbox mandatory, Fivetran/Airbyte ELT tier), Kafka 2026 (4.3 KRaft-only, tiered storage GA, Redpanda, WarpStream, Pulsar/NATS niche), stream processing (Flink 2.3 materialized tables/changelog SQL, Kafka Streams, watermarks/lateness, Spark Structured Streaming), streaming-tables convergence (Tableflow GA, batch/stream split dissolving, DuckDB+dbt, Ray, Airflow/Dagster/Prefect), proportionality reflex, 15 anti-patterns, 3 evals.

**Does NOT cover** : Kafka cluster operations and tuning (broker configs, partition-count math, ISR/rebalancing mechanics — operational, post-design), pipeline security (mTLS, ACLs, secrets — advisory context only), datastore choice (`ddia-tradeoff-analyzer`), storage-engine internals (`ddia-storage-internals`), isolation anomalies of the source transaction (`ddia-distributed-debugger`).

**Scope-out rationale** : cluster ops/tuning is post-design operational discipline — this skill decides whether a broker is needed and what semantics the flow carries, not how to tune `linger.ms`; security is a cross-cutting practice with its own discipline — flagged as advisory, never skipped silently. Siblings' domains (see Related Skills) — referencing, not duplicating, keeps each skill under its line budget.

**Glossary dependency** : `_shared/ddia-glossary.md` Pipelines section (CDC, outbox pattern, dual-write, watermark, at-least/exactly/effective-once, streaming table) is load-bearing for sections A-D; edits there flag this Revision History.

## Definitions

| Term | Meaning |
|---|---|
| Materialized table | Flink 2.3's continuously-maintained derived state: the result of a stream query, checkpointed, upsertable, and queryable as a table via changelog SQL. |
| Tiered storage | Kafka GA feature: old log segments upload to object storage; brokers keep only the hot tail — retention decoupled from broker disk. |
| Outbox event router | Debezium connector route reading the outbox table's insert stream and publishing each row as an event — the extraction half of the outbox pattern (glossary: outbox pattern). |
| Effective-once | At-least-once wire + idempotent consumer = the 2026 pragmatic default (glossary: effective-once); distinct from Kafka transactions exactly-once. |
| Allowed lateness | Flink/event-time policy: how long past the watermark a window re-fires for late events; with drop, side-output, and re-fire as the named options (glossary: watermark). |
| Changelog SQL | SQL over streams where each result carries its row-kind (insert/update/delete) — downstream tables upsert from the changelog. |
| DLQ | Dead-letter queue for processing-failed events; a DLQ without replay tooling + metric + owner is anti-pattern row 15. |
| Inbox table | Webhook/SaaS-source landing table (PK = external event id) that dedups at-least-once third-party redelivery at the boundary — the inbound cousin of the outbox. |
| Log replay (Kappa) | Recovery/backsfill by replaying the retained log (tiered storage makes it long) into idempotent consumers — instead of maintaining a separate batch layer (Lambda). |

Common terms (CDC, outbox pattern, dual-write, watermark, at-least-once, exactly-once, effective-once, streaming table) are defined in `_shared/ddia-glossary.md` — never duplicated here. That glossary is the shared kernel across the four ddia-* skills; a term common to two or more of them belongs there, not in this table.

**Boundary rule** : when writing a local definition, check the glossary first — if the term exists there (outbox, watermark, effective-once), reference it; if it is pipeline-architect-specific (materialized table, changelog SQL, tiered storage, outbox event router, allowed lateness, DLQ, Kappa), it stays local; if it belongs to another sibling's domain (LSM, quorum, SI/SSI), it does not belong here at all. The line between local and glossary follows the two-or-more rule: watermark is load-bearing for this skill *and* the debugger's ordering reasoning → glossary; the outbox event router is Debezium-specific machinery → local, referencing the glossary's outbox pattern for the concept.

## Evals

Run these 3 pressure scenarios after any edit. Each must FAIL in the specific way described (agent refuses violation).

### Scenario 1 : dual-write-request

**Given** : the skill is loaded.
**When** user says: "J'écris dans Postgres et dans Elasticsearch en même temps — insert dans PG puis index dans ES dans le même handler, avec un try/catch au cas où."
**Expect FAIL** : Agent does not wire it. Cites Iron Law + Hard Gate + anti-pattern row 1: dual-write is divergence by construction — the second write can fail after the first commits, and try/catch converts data loss into either loss or duplicate depending on which failure shape hits. Proposes the outbox pattern **with schema**: outbox table written inside the business transaction, Debezium outbox event router extraction, ES sink upserting by key (consumer idempotence named — gate input 3), semantics named: at-least-once wire, effective-once at the index. Baseline (no skill) would confirm the handler code.

### Scenario 2 : exactly-once-assumed

**Given** : the skill is loaded.
**When** user says: "Pas besoin de gérer les doublons — Kafka me donne exactly-once."
**Expect FAIL** : Agent nuances instead of confirming. Cites section A/B + anti-pattern row 2: Kafka's exactly-once is real (transactional producer + consumer isolation, since 0.11; KRaft-era mature) but **priced** — transactional overhead, checkpoint/commit latency, throughput cost — and it ends at the pipeline boundary: exactly-once *within* Kafka and the stream app does not make a downstream HTTP call or DB write exactly-once. The 2026 pragmatic default is **effective-once**: at-least-once + idempotent consumer (upsert by key / dedup). The verdict names both the cost and the boundary — "Kafka gives exactly-once" without either is refused. Baseline would confirm the assumption.

### Scenario 3 : kafka-everything

**Given** : the skill is loaded.
**When** user says: "Je vais mettre en place Kafka pour mes 100 events par jour — c'est la bonne architecture scalable, non ?"
**Expect FAIL** : Agent does not set up Kafka. Cites anti-pattern row 3: 100 events/day is ~0.001/sec — Kafka's operational surface (broker upkeep, KRaft quorum, monitoring, connectors) is orders of magnitude beyond the load; the scalable answer for this volume is PG LISTEN/NOTIFY, a cron job, or even polling (`SELECT ... WHERE updated_at > last_check`). Names when the threshold actually crosses (persistent buffering, multiple consumers, replay, ordering at sustained rates — hundreds+/sec sustained). Baseline would confirm Kafka as "the scalable choice".

**Protocol** : manually, subagent fresh-context, with-skill vs baseline. Log to `_shared/evals/2026-08-29-ddia-pipeline-architect-eval.log` (gitignored).

Baseline capture: the baseline run (fresh subagent, no skill loaded) must be logged *before* the with-skill run on the same prompt — its failure shape (confirming the dual-write handler, confirming "Kafka = exactly-once", confirming Kafka at 100 events/day) is the regression signature; if a future edit makes the baseline fail too, the eval lost its discriminating power and the prompt needs sharpening, not the skill.

**Pass criteria** : the with-skill run must refuse/re-ask per each Expect; the baseline run must fail by wiring the dual-write (scenario 1), confirming exactly-once (scenario 2), or endorsing Kafka (scenario 3). If the with-skill run in scenario 1 proposes "write ES in the same transaction" or any retry-loop variant without the outbox, anti-pattern row 1's wording was too weak — strengthen the row, not the eval. If the with-skill run in scenario 2 confirms exactly-once with a caveat instead of naming the cost + boundary + effective-once default, section A's pricing was too soft — strengthen, not the eval. If the with-skill run in scenario 3 endorses Kafka "for future scale" without naming the operational cost at current volume, row 3 was too soft.

**Eval discipline note** : scenarios 1-3 are the minimum regression set, each targeting one gate input (scenario 1 → input 2 dual-write, scenario 2 → input 1 semantics + input 3 idempotence, scenario 3 → proportionality — the workload-profile reflex carried into pipeline design). After any edit to the Hard Gate, a section A-D rule, or an anti-pattern row, rerun all three; after a metadata-only edit (Metadata, Revision History), rerun scenario 1 only (the gate's enforcement wording is the most drift-prone surface). Log every run with timestamp and verdict per criterion — a PASS that can't cite which paragraph refused the violation is an unverified PASS.

**Sharpening rule** : the three prompts are calibrated against the baseline failure shapes (handler confirmed, exactly-once confirmed, Kafka confirmed). If a baseline run starts hedging on its own ("maybe add an outbox?"), the prompt has leaked the skill's vocabulary into general circulation — sharpen the user's conviction in the prompt (more retry logic in scenario 1, more "c'est la bonne architecture scalable, non ?" framing in scenario 3), not the skill. The eval measures the *gap*; a shrinking gap means the measurement, not the model, degraded.

## The Iron Law (reminder)

> **NO PIPELINE ADVICE WITHOUT DELIVERY SEMANTICS STATED.**

If you reached this point without the three design inputs (delivery semantics named, dual-write resolved via outbox, consumer idempotence mechanism) on your last recommendation, go back. Your training data has a favorite "sync X to Y" recipe that never says what happens on crash mid-flight — the semantics-outbox-idempotence triple is the only antidote. Sections A-D and the patterns in `references/streaming-tables.md` are ground truth.

**Modification note** : this skill consumes `_shared/ddia-glossary.md` (Task 1 product). Glossary edits require flagging this Revision History per the glossary's modification protocol. The shared Pipelines terms (CDC, outbox pattern, dual-write, watermark, at-least/exactly/effective-once, streaming table) are this skill's load-bearing vocabulary — a glossary edit to any of them is a section A-D re-audit trigger, not just a flag.

**Boundary with the siblings, stated once more where edits happen:** a pipeline design touches its source transaction (outbox write) — the isolation semantics of that transaction belong to `ddia-distributed-debugger`, referenced not duplicated; the destination table's format and compaction belong to `ddia-storage-internals`; whether the destination store should exist at all belongs to `ddia-tradeoff-analyzer`. An edit that grows this skill into any of those domains has crossed the boundary — move it back and reference the sibling. The four skills stay small by delegating, and delegation only works if the boundary holds under edit pressure.

**Modification footer / dependency** : `references/streaming-tables.md` (REF-D4-01) carries the outbox schema + Debezium config, the Tableflow flow, the idempotent consumer code, and the event-sourcing verdict — the design verdicts in sections A-D cite it; edits there flag this Revision History too.

## Revision History

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-08-29 | Initial SOTA 2026 pipeline architect: type:sub-skill + 5 contracts; Iron Law ×3; Hard Gate; Snapshot; Quick Reference projection; Related Skills typed; sections A-E (CDC Debezium 3.7/Commonhaus + outbox mandatory, Kafka 2026 KRaft-only/tiered storage/Redpanda/WarpStream, Flink 2.3 materialized tables + watermarks, Tableflow streaming-tables convergence + DuckDB/dbt/Ray orchestration, 15 anti-patterns); 3 evals; `references/streaming-tables.md` indexed. | Skills maintainer | Skills maintainer |