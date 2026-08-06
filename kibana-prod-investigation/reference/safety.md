# Safety read-only

`es-client.sh` est la seule porte d'accès à ES. Read-only par construction.

## Whitelist d'endpoints

- `^/_search$`, `^/_async_search$`, `^/_count$` — recherche (GET ou POST).
- `^/_field_caps$`, `^/[^/]+/_field_caps$` — découverte de champs (GET).
- `^/[^/]+/_mapping$` — schéma d'index (GET).
- `^/_cat/indices(/.*)?$`, `^/_cat/aliases(/.*)?$` — métadonnées index (GET).
- `^/_cluster/health(/[^/]+)?$` — santé cluster (GET).
- `^/[^/]+/(_search|_count|_field_caps|_mapping)$` — variantes par index.

Tout autre path → refus (exit 1), même si l'agent demande.

## Méthodes

- `GET` ou `POST` autorisés sur `_search`/`_async_search`/`_count` (POST nécessaire pour bodies > 4096 chars).
- `GET` seul sur le reste.
- `PUT`, `DELETE`, `PATCH` → toujours rejetés.

## Vérifications structurelles (parse du DSL JSON)

- `"script": { "source": ... }` avec `ctx._source` / `ctx._index` / `params._type` → bloqué (scripts côté serveur peuvent écrire).
- `"aggs"` avec `script` → bloqué (trop risqué à valider). Pré-filtrer côté client si besoin.
- Index cible en wildcard `*` ou `_all` → autorisé mais avertit (peut être coûteux).
- Index commençant par `.` (index système) → bloqué.

## Refresh credentials

Si curl renvoie 401/403, le script appelle `fetch-creds.sh` (lit Vault, réécrit `env`), puis réessaie une fois. Au 2e échec → exit 1 "auth failed after vault refresh". Jamais de boucle.

## Logging

Chaque appel est loggé dans `~/.config/kibana-skill/es-calls.log` (timestamp, endpoint, méthode, nb hits, durée). Pas de body loggé (données sensibles).

## Timeouts

`--max-time 30` par défaut, configurable via `ES_TIMEOUT`. Requêtes longues → `_async_search` + polling.