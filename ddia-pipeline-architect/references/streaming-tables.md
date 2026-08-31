# Streaming Tables — Outbox Schema, Tableflow, Idempotent Consumers, Event Sourcing Verdict

| Field | Value |
|---|---|
| Document ID | `REF-D4-01` |
| Parent | `SKILL-D4-001` (ddia-pipeline-architect) |
| Revision | 1 |
| Effective Date | 2026-08-29 |
| Applies to | Sections A-D of parent skill |

Detail for sections A-D of `ddia-pipeline-architect/SKILL.md`. The outbox schema + Debezium config, the Tableflow flow, the effective-once idempotent consumer pattern, and the 2026 event-sourcing verdict. Read order: outbox → Tableflow → idempotent consumer → event sourcing — the consumer pattern assumes the outbox's at-least-once wire, and the event-sourcing verdict assumes all three.

**Header metadata** : REF-D4-01 under SKILL-D4-001; changes here flag the parent Revision History (footer).

## Outbox pattern — schema + extraction (the anti-pattern row 1 fix)

The business row and the event commit in **one database transaction** — atomic by construction. CDC extracts the outbox rows; no dual-write window exists. Shared terms (outbox pattern, dual-write, CDC) live in `_shared/ddia-glossary.md` — never duplicated.

```sql
-- Outbox table (same Postgres DB as the business tables)
CREATE TABLE outbox (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  aggregate_id text        NOT NULL,           -- e.g. order_id — the consumer's upsert key
  event_type   text        NOT NULL,           -- 'OrderCreated', 'OrderShipped'...
  payload      jsonb       NOT NULL,           -- the event body (schema-governed, row 7)
  headers      jsonb,                          -- optional trace/correlation ids
  created_at   timestamptz NOT NULL DEFAULT now()
  -- no updated_at: rows are immutable, insert-only
);

-- The business transaction — BOTH writes commit or NEITHER does
BEGIN;
  INSERT INTO orders (id, customer_id, total, status)
    VALUES (:id, :customer_id, :total, 'created');
  INSERT INTO outbox (aggregate_id, event_type, payload)
    VALUES (:id, 'OrderCreated', :payload);
COMMIT;
-- The app NEVER publishes to Kafka/ES itself — that path is the dual-write window.
```

Extraction: **Debezium 3.7 outbox event router** tails the WAL, reads the outbox inserts, and publishes each row as an event (`aggregate_id` → topic routing + message key — ordering per aggregate preserved on the wire). Config shape (Kafka Connect YAML):

```yaml
# Debezium Postgres connector with outbox event router
name: orders-outbox-connector
config:
  connector.class: io.debezium.connector.postgresql.PostgresConnector
  database.hostname: orders-db
  database.dbname: orders
  slot.name: outbox_slot              # PG logical decoding — stable substrate
  snapshot.mode: initial               # initial + incremental; replay-safe sinks only (row 8)
  table.include.list: public.outbox
  tombstones.on.delete: "false"
  transforms: outbox
  transforms.outbox.type: io.debezium.transforms.outbox.EventRouter
  transforms.outbox.table.field.event.key: aggregate_id
  transforms.outbox.table.field.event.type: event_type
  transforms.outbox.table.field.event.payload: payload
  transforms.outbox.route.by.field: event_type   # topic per event_type (row 13)
```

Ops notes the design carries: rows accumulate → archiving job deletes published rows (Debezium emits only inserts, so deletes are invisible downstream); the replication slot holds WAL on the primary → monitor `pg_replication_slots` lag (an abandoned slot grows the WAL unbounded). These are operational consequences of the *pattern*, decided at design time.

## Tableflow — topic ↔ table sync (the section D convergence, GA)

```
Producer(s) ──▶ Kafka topic (keyed, log) ──▶ stream consumers (Flink/Kafka Streams)
                      │
                      │  Tableflow sync (GA, no separate pipeline)
                      │  - reads topic, writes Iceberg directly
                      │  - REST catalog registration (no Hive metastore cluster)
                      ▼
              Iceberg table (upsert by key, schema from topic schema registry)
                      │
                      ├──▶ warehouse SQL engines (query the table)
                      └──▶ DuckDB/Spark (read the same Parquet/Iceberg files)
```

What it is: the broker layer keeps the topic and the Iceberg table aligned by construction — one copy, one lineage, no consumer cluster to build or operate. The batch/stream split dissolves here: the topic is the stream interface, the table is the analytical interface, both views of one log.

Design conditions (from parent section D):
- **Keyed upserts**: table sync lands by key — the topic must carry keys (row 4 again — idempotence is structural).
- **Schema lineage**: the topic's schema registry still governs — compatibility enforced upstream (row 7); the table inherits.
- **Scope**: analytical destinations. Operational sinks (ES, Redis) remain connector + idempotent sink territory.
- **Alternative when not on Confluent**: self-managed Kafka Connect + Iceberg sink connectors exist, but now you operate the pipeline Tableflow removes — name that trade-off.

## Effective-once idempotent consumer pattern (the gate input 3 mechanism)

At-least-once wire (the default) + this consumer = effective-once (glossary: effective-once). The pattern has two halves — **upsert by key** for state, **dedup** for side effects:

```sql
-- 1. UPSERT BY KEY: state merges instead of duplicating
--    (ES sink, Flink materialized table, Iceberg table — same shape)
INSERT INTO order_summary (order_id, total, status, updated_at)
VALUES (:order_id, :total, :status, :event_ts)
ON CONFLICT (order_id) DO UPDATE
  SET total = EXCLUDED.total, status = EXCLUDED.status,
      updated_at = EXCLUDED.updated_at
WHERE EXCLUDED.updated_at > order_summary.updated_at;  -- last-write-wins by event ts (from the log)
```

```sql
-- 2. DEDUP WINDOW for side effects (emails, charges, HTTP calls)
CREATE TABLE processed_events (
  event_id    uuid PRIMARY KEY,
  processed_at timestamptz NOT NULL DEFAULT now()
);
-- Consumer loop, per message:
--   BEGIN;
--     INSERT INTO processed_events (event_id) VALUES (:event_id);  -- PK conflict = redelivery → skip
--     ... perform side effect with idempotency key = :event_id ...
--   COMMIT;
-- Cleanup: DELETE FROM processed_events WHERE processed_at < now() - interval '7 days';
-- window ≥ max redelivery interval (Kafka consumer restarts, rebalances)
```

Why both: upsert alone doesn't dedup side effects (a redelivered OrderCreated that upserts cleanly still fires the email twice); dedup alone doesn't fix state (the row exists — the second arrival skips the work but state was overwritten by the rebalance-time duplicate already). State = upsert, effects = dedup window, idempotency key = the event's identity (`event_id`) or business key. **Effective-once verdict format:** "at-least-once wire; consumer upserts by `aggregate_id` + dedups `event_id` over a 7-day window → effective-once. Exactly-once transactions not needed — priced out (row 2)." That verdict is gate-input-3 satisfied; "we process each message once" is not.

## Event sourcing verdict 2026 — alive, niche, never for simple CRUD

Event sourcing (persist domain events as the system of record; state = replay) is alive in 2026: the **Axon ecosystem** (Axon Framework + Axon Server) carries the pattern for JVM teams; **Kafka-native microservices** (state in Kafka topics, state stores as materialized views) are its streaming-native cousin — Flink materialized tables (parent section C) are the infrastructure layer that finally makes state-from-stream mainstream.

Verdict shape: ES pays its way when **the event history itself is a product** — audit as first-class requirement, temporal queries ("what did we know at T"), event replay as recovery, domain experts who read the event log. It costs: versioning the event schemas forever (every consumer must replay old events — row 7 squared), snapshots + replay infra, aggregate design discipline. For **simple CRUD** the machinery is all cost and no yield — plain tables + outbox events where events are needed gives the integration benefits without the sourcing commitment (parent anti-pattern row 6).

**Decision:**
| Need | Answer |
|---|---|
| CRUD with integration events | Plain tables + outbox (this file § 1) — NOT event sourcing |
| Audit trail as a product, temporal queries | Event sourcing (Axon ecosystem) — price the versioning discipline |
| State rebuilt from stream | Kafka-native materialized tables (Flink 2.3 / Kafka Streams state stores) |

**DDIA 2017: event streams as the source of truth sketched as an idea. SOTA 2026: alive and niche — real infrastructure (Axon, Flink materialized state), but a decision paid in versioning + replay discipline, not a default.**

---

**Modification footer** : any change to this file requires flagging the parent skill's Revision History (SKILL-D4-001) — see ddia-glossary.md modification protocol.

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-08-29 | Initial: outbox schema + Debezium 3.7 outbox event router config, Tableflow flow diagram + design conditions, effective-once idempotent consumer pattern (upsert by key + dedup window), event sourcing 2026 verdict (alive-niche, Axon ecosystem, never for simple CRUD). | Skills maintainer | Skills maintainer |