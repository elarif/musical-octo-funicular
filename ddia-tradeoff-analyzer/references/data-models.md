# Data Model Arbitrage — Relational vs Document vs Graph

| Field | Value |
|---|---|
| Document ID | `REF-D1-01` |
| Parent | `SKILL-D1-001` (ddia-tradeoff-analyzer) |
| Revision | 1 |
| Effective Date | 2026-08-29 |
| Applies to | Section A of parent skill |

Detail for section A of `ddia-tradeoff-analyzer/SKILL.md`. Decision tree summary, then per-model deep dive, then workload examples, then the Postgres-first 2026 rationale.

## Decision tree (detail)

1. **Queries join across entities / integrity matters / schema known at design time** → relational. Postgres default.
2. **Data is a self-contained aggregate, loaded/stored whole, schema varies per record** → document. Postgres `jsonb` first; MongoDB only at proven scale limits or write-pattern mismatch.
3. **Access pattern is dominated by variable-depth recursive traversal** → graph. Apache AGE on Postgres for depths 1-3; Neo4j/Memgraph for heavy recursive traversal as the core workload.

## Relational

**Shape** : tuples, normalization, foreign keys, joins at query time. Schema enforced before write.

**Strengths** : arbitrary ad-hoc queries (the killer feature — you cannot predict future queries, relational lets you ask them anyway); ACID across entities; constraint-declared integrity; forty years of tooling; every cloud runs it managed.

**Weaknesses** : impedance mismatch with object graphs (ORM pain); schema migrations on huge tables can lock; sharding is manual (Citus, or leave for distributed SQL).

**Choose when** : relationships between entities are the domain (orders↔customers↔products), queries evolve post-launch, integrity beats write throughput.

**Postgres specifics** : declarative partitioning (range/list/hash) for append-heavy tables; partial + expression indexes for selective queries; `INSERT … ON CONFLICT` for upsert idioms; logical replication for selective table copies; `pg_stat_statements` to ground the workload profile in measured access patterns rather than guesses.

## Document

**Shape** : self-contained JSON-like aggregates, no joins across documents, schema per record.

**Strengths** : aggregate load/store in one I/O; schema flexibility without migrations; locality for whole-document reads.

**Weaknesses** : no cross-document joins (in-DB); denormalization drift (update author name in 10k posts); multi-document transactions historically weak (Mongo improved, but the model still fights them).

**Choose when** : the aggregate boundary is stable and real (user profile, CMS content, catalog item); reads are whole-document; writes stay within one document.

**Aggregate boundary test** (before committing to document model): (a) does any read need data from two aggregates? → joins in app code forever; (b) does any fact live in two aggregates? → denormalization drift + invalidation logic; (c) can the aggregate outgrow a sensible size (post + unbounded comments)? → split or rethink. Failing any leg pushes the workload back to relational.

**Document store exit costs** (what "leaving later" actually means): rebuilding aggregate boundaries under live traffic; dual-writing during migration (dual-write is an anti-pattern — see glossary); re-implementing every app-side join as SQL. Deciding document vs relational is a 10-minute exercise with the boundary test; undoing a wrong call is a quarter of engineering.

**2026 reality** : `jsonb` gives Postgres document storage with GIN indexing. The remaining MongoDB cases: write throughput beyond a single primary, driver-ecosystem lock-in, horizontal sharding as a first-class need.

**jsonb usage discipline** (the difference between document-in-Postgres and JSON soup):

- Index the access path, not the document: GIN on the whole column for containment (`@>`) or expression index on the queried keys.
- `jsonb` not `json` — binary form, indexable; `json` stores text and re-parses per query.
- Partial indexes on document predicates (`WHERE (doc->>'type') = 'post'`) keep index size proportionate.
- CHECK constraints can enforce per-type schema invariants inside the document — schema discipline without full relational normalization.

## Graph

**Shape** : nodes + edges, traversal cost independent of total dataset size (index-free adjacency).

**Strengths** : variable-depth traversal (friend-of-friend depth 4+) at constant-ish cost where SQL recursive CTEs degrade; pattern matching (fraud rings, dependency chains) expressed naturally.

**Weaknesses** : OLTP transactions across the whole graph are harder; ops expertise rare; most "graph" problems are 1-2 hops = SQL/AGE territory.

**Choose when** : recursive multi-hop traversal is the dominant access pattern — social graph analysis, fraud detection rings, knowledge graphs with deep queries, bill-of-materials with unbounded depth.

**Query-shape tell:** the requirement text contains "all paths between", "upstream dependencies of any depth", "shortest path", or "connected components" — graph shapes. "Report by customer" is not a graph shape no matter how many foreign keys the schema has.

**Neo4j/Memgraph** : Cypher/openCypher, mature visualization, ops story. **Apache AGE** : openCypher inside Postgres — graph queries over relational tables, one engine, no new ops surface.

**Depth heuristic (when to exit SQL):** depth ≤ 2 and bounded — plain joins; depth 3 with modest fan-out — recursive CTE, measure first; depth 4+ or unbounded with fan-out — graph engine. The cost driver is not depth per se but fan-out^depth (rows touched per traversal). A depth-4 traversal on a sparse graph (avg 2 edges/node) is 16 rows — SQL handles it fine. The same depth on a social graph (avg 100 edges/node) is 10^8 — graph engine or bust. Name the fan-out when justifying the exit.

## Workload examples (canonical mappings)

Mapping table — each row is the input to the parent skill's section E questions, not a shortcut around them:

| Workload | Model | Why |
|---|---|---|
| Fil d'actualité (feed) | Document | Post is a self-contained aggregate; read = whole-document by key; comments embedded or referenced; schema varies (media types) |
| Droits d'accès (ACL) shallow (depth ≤ 3) | Relational + FK | user→role→permission joins; constraints enforce integrity; recursive CTE handles inheritance |
| Droits d'accès deep inheritance / org trees unbounded | Graph (AGE or Neo4j) | Variable-depth traversal dominates; SQL CTE cost grows with depth per row |
| Audit bitemporal | Relational / bitemporal store | Valid-time + transaction-time queries; Postgres with `tstzrange` + exclusion constraints, or XTDB for first-class bitemporal queries |

**Bitemporal detail (the XTDB mention):** audit and compliance workloads ask two questions — "what did we believe at time T?" (transaction time) and "what was true at time T?" (valid time). Postgres answers this with append-only rows + `tstzrange` validity + exclusion constraints preventing overlaps, at the cost of manual query discipline. XTDB (bitemporal-first, SQL dialect, object-storage-native in v2) makes both axes first-class query citizens. Choose Postgres when bitemporal queries are a minority of the workload; XTDB when they are the workload (regulatory reconstruction, insurance history).
| Catalogue produits avec attributs variables | Document (`jsonb`) | Per-category attribute sets; GIN indexes on attributes; stay in one engine |
| Recommendation / similarity search | Vector (`pgvector`) | ANN over embeddings; HNSW index; dedicated vector DB only past ~10M vectors |
| Recherche full-text | Postgres `tsvector` | Integrated, adequate to mid-scale; Elasticsearch/OpenSearch when scale or relevance tuning demands |
| Catalogue produits variant-heavy | Document (`jsonb`) | Per-SKU attribute sets differ by category; containment queries via GIN |

## Postgres-first 2026 — rationale

**DDIA 2017** : relational and document models converging (Postgres JSONB, Mongo $lookup). **SOTA 2026** : convergence complete and lopsided — Postgres absorbed the other models' core use cases while keeping joins + ACID.

1. **One engine, five models** — relational rows, `jsonb` documents, AGE graph, `pgvector` vectors, `tsvector` full-text. Each departure from one engine adds: a second backup strategy, a second auth model, a second upgrade cadence, a second 3am failure mode, a second replication topology to monitor, and a data-sync mechanism between stores.
2. **Proven scale ceiling before leaving** — a single well-tuned Postgres primary sustains ~10k+ writes/sec on modest hardware, TB-scale datasets, and read replicas handle most read scale. Most "we outgrew Postgres" stories are actually missing-index or missing-partitioning stories.
3. **Leave when measurable** : sustained writes beyond single-primary ceiling → distributed SQL (CockroachDB/YugabyteDB) or leaderless (Cassandra/ScyllaDB) per parent skill section B; vector scale past ~10M → dedicated vector engine; graph depth beyond AGE comfort → Neo4j/Memgraph.

## Postgres extensions (the multi-model toolbox)

| Extension | Model | Notes |
|---|---|---|
| `jsonb` + GIN | Document | Binary JSON, indexed containment queries (`@>`), expression indexes on specific keys |
| `pgvector` | Vector | HNSW (ANN) and IVFFlat indexes; exact search fallback; `halfvec` for memory-tight large scale |
| Apache AGE | Graph | openCypher queries over tables; depth-2/3 traversal without leaving Postgres |
| `tsvector` / `tsquery` | Full-text | Built-in FTS with ranking; adequate until scale forces a search engine |
| PostGIS | Geospatial | GiST indexes, geometry types — de-facto standard |
| `pg_partman` | Time-series | Declarative partitioning automation for append-heavy tables |
| Citus | Distributed | Postgres sharding extension — the last stop before distributed SQL |
| `pg_stat_statements` | Observability | Workload profiling evidence — access patterns measurable, not guessed |
| Table access method | Extensibility | Custom index/storage methods (postgres AM API) — why Postgres keeps absorbing models |

## Spanner multi-model convergence

Google Spanner: relational SQL with interleaved tables (parent-child co-location), plus graph query (GQL) support in progress — one strongly consistent distributed engine serving multiple models. CockroachDB and YugabyteDB follow the same shape (Postgres-compatible SQL, Raft consensus). Direction of travel at the top of the market: **one strongly-consistent engine, multiple models** — not more engines glued together. Build new multi-model systems on one engine; split only on measured pain (parent skill: polyglot persistence definition).

**Migration triggers (Postgres → X, measured not vibed):**

1. Sustained primary CPU/IO saturation at P99 (not P50) across weeks after index/partition tuning — write ceiling, not query debt.
2. Replication lag chronically violating the read-your-writes SLO — read scale exhausted.
3. Dataset growth rate putting the backup/restore window beyond RTO — operational, maybe fixable with partitioning first.
4. Geo-distribution requirement appearing post-launch — consensus engine migration, not a shard-and-pray.

Each trigger names the metric, the threshold breached, and the mitigation already attempted. "It feels slow" is not a trigger.

---

**Modification footer** : any change to this file requires flagging the parent skill's Revision History (SKILL-D1-001) — see ddia-glossary.md modification protocol.

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-08-29 | Initial: relational/document/graph deep dive, 7 workload examples, Postgres-first rationale, extensions table, Spanner convergence. | Skills maintainer | Skills maintainer |