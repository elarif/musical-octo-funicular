# DDIA Glossary — Shared Kernel

**Effective date:** 2026-08-29
**Owner:** Skills maintainer
**Applies to:** ddia-tradeoff-analyzer, ddia-storage-internals, ddia-distributed-debugger, ddia-pipeline-architect. Ces skills référencent ce fichier ; ne dupliquent jamais les définitions.

## Storage

- **LSM-tree** — Log-Structured Merge tree. Writes → memtable → SSTables immuables. Compaction merge. Gagne en writes.
- **SSTable** — Sorted String Table. Fichier trié immuable écrit par memtable flush.
- **Memtable** — Buffer trié en mémoire. Flush → SSTable.
- **B-tree** — Pages fixes équilibrées, in-place update, WAL requis. Gagne en reads.
- **WAL** — Write-Ahead Log. Journal append-only avant page write. Crash recovery.
- **Compaction** — Merge SSTables pour limiter read-amp. Stratégies : STCS (size-tiered), LCS (leveled), ICS (incremental — time-series TTL).
- **Write/read/space amplification** — Triangle : écritures multiples vs lectures multiples vs espace disque surplus. Tuning = arbitrage.

## Distributed

- **Quorum** — W + R > N (lecture/écriture majoritaires). Tolère (N-W) writes lost, (N-R) nodes down.
- **HLC** — Hybrid Logical Clock. Horloge logique + timestamp physique. Ordering sans TrueTime.
- **TrueTime** — API Spanner avec bornes d'incertité garanties (hardware GPS/atomic).
- **SI** — Snapshot Isolation. Lecture cohérente d'un snapshot. Autorise write skew.
- **SSI** — Serializable SI. Détecte write skew par tracking dépendances. Retry SQLSTATE 40001.
- **Write skew** — 2 transactions lisent des conditions disjointes puis écrivent sur l'ensemble. SI ne prévient pas. Fix : contrainte explicite ou SELECT FOR SHARE ou SSI.
- **Split-brain** — 2 nœuds croient être leader. Fix : quorum/consensus (Raft).
- **Leader lease** — Bail temporel du leader au lieu d'horloge physique pour failover.

## Pipelines

- **CDC** — Change Data Capture. Log transactionnel → stream. Debezium dominant.
- **Outbox pattern** — Écrire event dans table outbox DANS la transaction métier. CDC extrait. Élimine dual-write.
- **Dual-write** — Écrire 2 stores sans transaction distribuée. Anti-pattern : divergence silencieuse.
- **Watermark** — Borne temporelle de complétude d'un stream. Gère lateness.
- **At-least-once** — Redelivery possible. Idempotence requise côté consommateur.
- **Exactly-once** — Kafka transactions + checkpointing. Réel mais coûteux (latence, throughput).
- **Effective-once** — At-least-once + idempotent consumers. Pragmatique 2026.
- **Streaming table** — Topic Kafka ↔ table Iceberg synchronisée (Tableflow). Batch/stream split dissolving.

## Modification

Toute modification nécessite flag dans Revision History des 4 skills ddia-*.