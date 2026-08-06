# Traversée de traces APM

Les traces APM forment une arborescence `trace.id` / `parent.id` / `transaction.id`. Une trace lente ou erronée peut avoir sa cause racine plusieurs niveaux plus haut (ex: un span DB lent sur un service amont provoque des timeouts en cascade sur les services descendants).

## Étapes

1. **Point d'entrée** : depuis un document d'erreur ou transaction lente, récupérer `trace.id` + `transaction.id` + `parent.id` du document courant.
2. **Remontée vers la racine** : tant que `parent.id` existe, requêter `traces-apm-*` / `apm-*-transaction` avec `term trace.id == <trace.id>` ET `term transaction.id == <parent.id>` (ou `term parent.id` selon schéma). On remonte jusqu'à un document dont `parent.id` est null = trace racine.
3. **Descente optionnelle** : depuis la racine, récupérer tous les spans/transactions du même `trace.id` (`term trace.id`) triés par `timestamp` asc pour reconstruire l'arbre complet.
4. **Croisement logs** : pour chaque `transaction.id` / `span.id` de l'arbre, requêter `logs-*` filtrés par `trace.id` (et `span.id` si indexé).
5. **Reconstruction** : reconstituer l'arbre mental (racine → enfants → spans feuilles, avec durée, statut, service.name à chaque nœud). L'hypothèse causale cible le nœud racine ou le span le plus coûteux/erroné, pas seulement le point d'entrée.

## Helpers es-client.sh

- `es-client.sh trace-root <trace.id>` — remonte au document racine (retourne le doc avec `parent.id` null).
- `es-client.sh trace-tree <trace.id>` — récupère tous les documents de la trace (transactions + spans), triés par `timestamp` asc.
- `es-client.sh trace-logs <trace.id>` — récupère les logs associés (cross-index `logs-*`).

## URLs Kibana

- Discover filtré sur `trace.id:<id>` avec colonnes `trace.id, parent.id, transaction.id, service.name, span.duration.us, event.outcome`.
- Si l'app APM est dispo (détecté via `_cat/indices` contenant `apm-*`), génère aussi une URL `/app/apm/traces/<trace.id>` (deep-link APM).