# Sources de données Elasticsearch

Pour chaque type, un profil : pattern d'index, champs clés, requête de base, KQL équivalent.

## 1. Logs applicatifs (`logs-*`, `filebeat-*`, `<app>-logs-*`)
- Champs : `@timestamp`, `service.name`, `log.level`, `message`, `host.name`, `container.id`, `trace.id` (si corrélation APM injectée).
- Requête : `range @timestamp` + `match service.name` + `terms log.level` (ERROR/WARN) + `match` libre sur `message`.
- KQL : `service.name: "svc" AND log.level: (ERROR OR WARN) AND message: "keyword"`.

## 2. APM traces & errors (`traces-apm-*`, `apm-*-transaction`, `apm-*-span`, `apm-*-error`)
- Champs : `trace.id`, `transaction.id`, `parent.id`, `span.id`, `service.name`, `transaction.duration.us`, `span.duration.us`, `event.outcome` (success/failure/unknown), `error.message`, `error.grouping_key`.
- Requête : `range @timestamp` + `match service.name` + `bool filter event.outcome: failure` OU `range transaction.duration.us > seuil`.
- Helpers : `trace-root`, `trace-tree`, `trace-logs` (voir apm-trace-traversal.md).
- KQL : `service.name: "svc" AND event.outcome: failure` ou `trace.id: "<id>"`.

## 3. Métriques infra/app (`metricbeat-*`, `.monitoring-*`)
- Champs : `@timestamp`, `host.name`, `metricset.name`, `metricset.module`, `system.cpu.used.pct`, `system.memory.actual.used.pct`, `kubernetes.*`.
- Requête : `range @timestamp` + `match host.name` + `avg`/`max` aggs sur le champ métrique.
- KQL : `host.name: "node1" AND metricset.module: cpu`.

## 4. Audit / security (`auditbeat-*`, `.security-*`, filebeat audit module)
- Champs : `@timestamp`, `event.action`, `event.category`, `user.name`, `source.ip`, `process.name`.
- Requête : `range @timestamp` + `match event.action` (e.g. `user_login`, `file_integrity`) + `terms user.name`.
- KQL : `event.action: "user_login" AND user.name: "admin"`.

## Détection automatique
En Phase 1, `es-client.sh discover-indices` liste les index matching `*apm*`, `*log*`, `*metric*`, `*audit*` via `_cat/indices`. L'agent n'invente pas les patterns — il découvre ce qui existe dans le cluster et adapte. Chaque profil est un guide, pas une recette figée.