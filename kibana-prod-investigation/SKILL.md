---
name: kibana-prod-investigation
description: Déclencher quand un symptôme de production est signalé (erreur 500, latence, alerte, throughput en chute) et qu'il faut produire des preuves vérifiables via Elasticsearch/Kibana en read-only strict ; évite l'investigation au hasard qui masque la cause racine et les conclusions non reproductibles.
---

# Kibana Prod Investigation

Investigue un incident de production en interrogeant Elasticsearch en **read-only strict** et produis des **preuves vérifiables** : URLs Kibana Discover (deep-links rison, sans saved object) + captures d'écran Playwright.

## Aperçu

Investigue un incident de production en interrogeant Elasticsearch en read-only strict via `es-client.sh`. Le workflow 6 phases — clarifier le symptôme → découvrir les index → requêter → corréler/traverser les traces APM → générer l'URL Kibana → capturer — produit des preuves vérifiables : URLs Discover deep-link rison + captures PNG Playwright.

Loi d'airain : pas d'accès ES hors `es-client.sh`, pas d'URL Kibana sans round-trip rison valide, pas de conclusion sans capture de vérification.

Annonce ce skill quand l'utilisateur signale un symptôme prod (erreur 500, latence, alerte) nécessitant logs/traces/métriques ES. Ne l'annonce pas pour écriture ES, dashboards saved, ou sans vault configuré.

Prérequis : `setup.sh` exécuté, `~/.config/kibana-skill/env` présent, `curl`/`jq`/`vault`/`node` ≥ 20.11. Output final : synthèse + URLs cliquables + chemins PNG + hypothèse causale + pistes de fix.

Fichiers clés : `scripts/es-client.sh`, `scripts/kibana-url.mjs`, `scripts/capture.mjs`, `reference/*.md` (voir Repository index).

## Référence rapide

*(projection — voir Process pour les règles complètes)*

| Champ | Valeur |
|---|---|
| Audience | Agent investiguant un incident prod via ES/Kibana en lecture seule |
| Déclencheur | Symptôme prod (erreur 500, latence, alerte, throughput en chute) nécessitant logs/traces/métriques ES |
| Entrées | Brief d'investigation : service, fenêtre temporelle, symptôme |
| Sorties | Synthèse + URLs Discover cliquables + captures PNG + hypothèse causale + pistes de fix |
| Fichiers clés | `scripts/es-client.sh`, `scripts/kibana-url.mjs`, `scripts/capture.mjs`, `reference/sources.md`, `reference/apm-trace-traversal.md`, `reference/rison-encoding.md`, `reference/safety.md` |
| Loi d'airain | Pas d'accès ES hors `es-client.sh` / pas d'URL sans rison valide / pas de conclusion sans capture |
| Phases | 0 Clarifier · 1 Découvrir · 2 Requêter · 3 Corréler · 4 Générer URL · 5 Capturer |

## Skills associés

| Skill | Relation | Rôle |
|---|---|---|
| `systematic-debugging` | `upstream` | Peut dispatcher ce skill quand l'investigation nécessite logs/APM/métriques ES |
| `using-superpowers` | `upstream` | Routeur qui charge ce skill à partir d'une requête utilisateur brute |
| `verification-before-completion` | `none` | Separate Ways — ne pas chaîner ; ce skill produit ses propres captures comme preuve |
| `requesting-code-review` | `none` | Pas de chevauchement |
| `test-driven-development` | `none` | Pas de chevauchement |
| `receiving-code-review` | `none` | Pas de chevauchement |

**Translation (`systematic-debugging` → ce skill)** : `systematic-debugging` émet un *symptôme à investiguer* (service + fenêtre temporelle + signe observé) ; ce skill le consomme comme **brief de Phase 0**. Aucune adoption du vocabulaire de debugging (hypothèse/expérience) — ce skill reformule en *hypothèse causale* appuyée sur preuves ES.

**Translation (`using-superpowers` → ce skill)** : `using-superpowers` fournit la requête utilisateur brute ; ce skill la **reformule en brief d'investigation** (service, timeframe, symptom) avant Phase 0. Ne pas réutiliser le vocabulaire de routage de `using-superpowers`.

## Document Metadata

| Champ | Valeur |
|---|---|
| Document ID | `SKILL-KPI-001` |
| Revision | 2 |
| Effective Date | 2026-07-20 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |

## Audience

Tu déclares les attributs d'audience suivants avant d'utiliser ce skill :

- **Audience primaire** : tout agent qui investigue un incident de production via Elasticsearch/Kibana en lecture seule.
- **Audience secondaire** : mainteneurs qui éditent ce skill ; relecteurs qui auditent les investigations produites.
- **Niveau d'expertise** : intermédiaire — tu connais les requêtes HTTP et la syntaxe JSON, et tu apprends le DSL Elasticsearch et le rison.
- **Ce qu'ils savent déjà** : tu maîtrises le shell, `curl`, `jq`, et tu sais lire une stack trace.
- **Ce qu'ils doivent apprendre** : le workflow 6 phases, l'usage de `es-client.sh`, l'encodage rison et la vérification par capture.
- **Ce qu'ils feront après lecture** : exécuter les 6 phases pour livrer une investigation avec URLs Kibana cliquables et captures PNG.

## Objectif / Périmètre

**Objectif** : ce skill te donne les règles pour produire une investigation dont l'utilisateur peut vérifier chaque conclusion. Chaque affirmation s'appuie sur une requête, une URL Discover et une capture d'écran.

**Périmètre couvert** :

- Interrogation read-only d'Elasticsearch via `es-client.sh`.
- Génération d'URLs Kibana Discover encodées en rison.
- Traversée de traces APM (racine, spans, logs associés).
- Captures d'écran de vérification via Playwright.

**Périmètre NON couvert** :

- Écriture ou modification de données dans Elasticsearch.
- Création de dashboards Kibana sauvegardés (saved objects).
- Configuration de vault ou de Kibana hors setup initial.
- Investigation sans vault configuré.

## Définitions

Tu définis chaque acronyme à sa première utilisation. Cette section les regroupe pour référence :

| Terme | Signification |
|---|---|
| ES | Elasticsearch — moteur de recherche et d'analyse qui stocke logs, traces et métriques. |
| APM | Application Performance Monitoring — module ES qui capture traces, spans et transactions applicatives. |
| DSL | Domain Specific Language — syntaxe de requête JSON d'Elasticsearch (`bool`, `range`, `match`, `aggs`). |
| KQL | Kibana Query Language — syntaxe de filtre utilisée dans la barre Kibana Discover. |
| rison | Encodage compact d'objets JSON pour URLs Kibana (remplace le JSON dans les query strings). |
| vault | HashiCorp Vault — coffre de secrets qui fournit `ES_USER`/`ES_PASS` au script `es-client.sh`. |
| PNG | Portable Network Graphics — format d'image que tu utilises pour les captures de vérification. |
| brief d'investigation | Service + fenêtre temporelle + symptôme, tenu en contexte dès la Phase 0. |
| hypothèse causale | Affirmation appuyée sur preuves ES reliant un nœud racine/span à un symptôme observé. |

## Quand NE PAS utiliser ce skill

Ne sers pas de ce skill dans les cas suivants :

- L'utilisateur demande une écriture ou modification ES → hors périmètre (read-only).
- L'utilisateur veut un dashboard Kibana saved → utilise l'UI Kibana, pas ce skill.
- Pas de vault configuré → lance le setup d'abord.

## Prérequis d'accès ES

Tu vérifies les prérequis suivants avant de démarrer :

- Setup fait : `bash ~/.agents/skills/kibana-prod-investigation/scripts/setup.sh`.
- `~/.config/kibana-skill/env` existe (ES_HOST, ES_USER, ES_PASS, KIBANA_BASE_URL, KIBANA_SPACE, KIBANA_VERSION, VAULT_PATH, ES_TIMEOUT).
- Outils : `curl`, `jq`, `vault`, `node` ≥ 20.11.

## Iron Law

Tu respectes la loi d'airain à chaque phase :

```
PAS D'ACCÈS ES HORS DE es-client.sh
PAS D'URL KIBANA SANS ROUND-TRIP RISON VALIDE
PAS DE CONCLUSION SANS CAPTURE DE VÉRIFICATION
```

## Workflow 6 phases

Tu DOIS compléter chaque phase avant la suivante. Ne saute pas. Motivation : (1) un symptôme 500 peut venir de traces APM ET de logs applicatifs — sauter la découverte des index fait rater la bonne source ; (2) une corrélation sans trace complète fait blâmer le point d'entrée alors que la cause est un span feuille — sauter la traversée APM fait conclure à tort.

### Phase 0 — Clarifier le symptôme

Tu reformules le problème prod en termes actionnables : service, fenêtre temporelle, symptôme (erreur 500, latence, throughput en chute, alerte déclenchée). Si l'utilisateur reste vague, tu poses 1 à 2 questions ciblées puis tu continues.

**Output** : un brief d'investigation (service, timeframe, symptom) tenu en contexte.

### Phase 1 — Découvrir les index

Tu lances `es-client.sh discover-indices` pour lister les index candidats (`*apm*`, `*log*`, `*metric*`, `*audit*`). Pour chaque index pertinent, tu lances `es-client.sh field-caps <index>` pour découvrir les champs clés.

Tu mappes le symptôme aux index pertinents :

- Erreur 500 / latence → `traces-apm-*` + `apm-*-error` + `logs-*` du service.
- Pic CPU / mémoire → `metricbeat-*`.
- Connexion suspecte → `auditbeat-*` / `.security-*`.

**Output** : liste d'index + champs clés (`@timestamp`, `service.name`, `trace.id`, `parent.id`, `transaction.id`, `error.message`, etc.).

### Phase 2 — Requêter ciblée

Tu construis une requête DSL (`bool`/`range`/`match`/`aggs`) adaptée au type de source (voir `reference/sources.md` — protocole de mapping symptôme → index → DSL). Tu écris le DSL dans un fichier temporaire et tu lances `es-client.sh search <index> <dsl-file>`.

Tu itères si bruit avec les actions suivantes :

- Fenêtre plus courte.
- Filtre plus strict.
- `terms` aggs pour grouper.

**Output** : agrégats + documents clés (top erreurs, traces lentes, pics).

### Phase 3 — Corréler & traverser les traces APM

Si APM trouve une trace intéressante, tu récupères son arbre complet (voir `reference/apm-trace-traversal.md` — protocole de traversée racine → spans → logs) :

1. `es-client.sh trace-root <trace.id>` — remonte au document racine.
2. `es-client.sh trace-tree <trace.id>` — récupère tous les spans/transactions.
3. `es-client.sh trace-logs <trace.id>` — récupère les logs associés.

Tu reconstitues l'arbre mental (racine → enfants → spans feuilles, avec durée, statut, service.name). L'hypothèse causale cible le nœud racine ou le span le plus coûteux ou erroné, pas seulement le point d'entrée.

**Output** : hypothèse causale (ex : "latence DB sur span X → erreurs 500 sur le service Y").

### Phase 4 — Générer l'URL Kibana

Pour chaque requête pertinente, tu génères une URL Discover :

```bash
node ~/.agents/skills/kibana-prod-investigation/scripts/kibana-url.mjs \
  --index '<pattern>' \
  --query '<kql>' \
  --from <iso> --to <iso> \
  --columns '<csv>'
```

L'encodeur fait un round-trip rison et refuse toute URL cassée. Voir `reference/rison-encoding.md` — règles d'encodage et de validation rison.

**Output** : 1 à N URLs Kibana cliquables selon le nombre de requêtes pertinentes.

### Phase 5 — Vérifier par capture

Pour chaque URL, tu lances une capture :

```bash
node ~/.agents/skills/kibana-prod-investigation/scripts/capture.mjs '<url>' '<slug>'
```

Playwright ouvre l'URL (session persistante), attend le rendu Discover, capture un PNG dans `~/.config/kibana-skill/screenshots/`. Tu lis l'image pour confirmer que les données attendues sont visibles.

#### Traiter les échecs de capture

Tu gères les échecs de capture selon leur cause :

- Login expiré → ouvre le navigateur, auth manuelle, reprend.
- Discover affiche une erreur → URL probablement mal encodée → régénère avec le fallback.
- 0 résultats inattendus → réexamine la requête DSL (Phase 2).

**Output final** : synthèse d'investigation + URLs Kibana (cliquables) + chemins des captures PNG + hypothèse causale + pistes de fix.

## Safety

Tu respectes les règles de sécurité à chaque exécution :

- Accès ES **uniquement** via `es-client.sh` (whitelist read-only, voir `reference/safety.md` — whitelist des commandes read-only et gestion des credentials).
- Jamais de credentials dans ton contexte — ils vivent dans `~/.config/kibana-skill/env` (chmod 600).
- Si `es-client.sh` renvoie "auth failed after vault refresh", tu alertes l'utilisateur — ne tente pas de contourner.

## Repository index

Ce skill indexe ses fichiers de référence et scripts par chemin (Repository collection-oriented). Lis-les à la demande ; ne les inline pas.

**`reference/`**

| Fichier | Rôle |
|---|---|
| `reference/sources.md` | Mapping symptôme → index ES (logs/apm/metrics/audit) et DSL adapté à chaque type de source. |
| `reference/apm-trace-traversal.md` | Protocole de traversée de trace APM : racine → spans → logs associés. |
| `reference/rison-encoding.md` | Règles d'encodage rison et de validation par round-trip pour URLs Kibana. |
| `reference/safety.md` | Whitelist read-only de `es-client.sh` et règles de gestion des credentials. |

**`scripts/`**

| Fichier | Rôle |
|---|---|
| `scripts/setup.sh` | Installe les dépendances, configure vault, génère `~/.config/kibana-skill/env`. |
| `scripts/es-client.sh` | Client ES read-only : `discover-indices`, `field-caps`, `search`, `trace-root`, `trace-tree`, `trace-logs`. |
| `scripts/kibana-url.mjs` | Encodeur d'URL Discover avec round-trip rison ; refuse toute URL cassée. |
| `scripts/capture.mjs` | Capture Playwright PNG de vérification (session persistante). |

## Environment adapter

Si `AGENTS.md` spécifie des conventions d'investigation (host ES, space Kibana, timeout, commandes d'accès), les utiliser ; sinon, utiliser ces valeurs par défaut (`~/.config/kibana-skill/env`, `es-client.sh`, `kibana-url.mjs`, `capture.mjs`).

## Idempotence

Ré-annoncer ce skill dans la même session est un no-op (ou une re-entry délibérée avec un nouveau brief d'investigation) — ne pas relancer le setup ni régénérer des URLs/captures déjà produites sans nouveau contexte.

## Exemples

### Exemple — trace APM lente (Given/When/Expect)

**Given** un symptôme "latence sur le service `payments-api` entre 14:00 et 14:15 UTC", **When** tu annonces `kibana-prod-investigation` et exécutes les 6 phases, **Expect** : un brief d'investigation tenu en contexte, une liste d'index (`traces-apm-*`, `logs-*`) avec champs clés, une requête DSL sur `service.name:payments-api` + `range @timestamp`, une trace APM traversée (root → span DB lent), une URL Discover cliquable encodée rison, et un PNG dans `~/.config/kibana-skill/screenshots/` montrant le span fautif — hypothèse causale "latence DB sur span X → erreurs 500 sur payments-api".

### Exemple — requête DSL (VO pur)

```json
{
  "query": {
    "bool": {
      "filter": [
        { "term": { "service.name": "payments-api" } },
        { "range": { "@timestamp": { "gte": "2026-07-20T14:00:00Z", "lte": "2026-07-20T14:15:00Z" } } }
      ]
    }
  },
  "aggs": { "by_trace": { "terms": { "field": "trace.id", "size": 20 } } }
}
```

## Déviations

Aucune déviation structurelle. Les fichiers de référence et scripts sont indexés par chemin (Repository collection-oriented) plutôt qu'inlinés — conformité à L12.1/L12.3. Les fichiers ne sont pas inlinés car le skill s'exécute dans un contexte agent qui peut lire le système de fichiers.

## Historique des révisions

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-07-19 | Mise en conformité technical-writing : ajout de Document Metadata, Audience, Objectif/Périmètre, Définitions, voix active, phrase d'introduction avant chaque liste, Historique des révisions. | Skills maintainer | Skills maintainer |
| 2 | 2026-07-20 | Couche IDDD : Aperçu (snapshot), Référence rapide (projection), Skills associés avec relations typées + Translation, Repository index (reference/ + scripts/), Environment adapter, Idempotence, Exemples Given/When/Expect, éclatement Phase 5 (capture vs échecs), renommage headings en langue ubiquitaire, description en Domain Event nommant le failure mode, motivation ≥2 scénarios sur la règle de séquence des phases. Aucune déviation. | Skills maintainer | Skills maintainer |