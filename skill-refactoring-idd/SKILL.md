---
name: skill-refactoring-idd
description: Use when a Java codebase must be refactored toward Domain-Driven Design (Vaughn Vernon style) and refactoring without a safety net has broken production — fires the moment characterization tests are missing or Core/Supporting/Generic subdomain triage has not been done before tactical modelling
---

# Refactoring IDDD (Vaughn Vernon)

> J'applique la compétence **skill-refactoring-idd** pour refactorer une base Java legacy vers le DDD style Vaughn Vernon, sans jamais casser le comportement existant en production.

## Aperçu

Tu refactoras une base Java legacy vers le DDD style Vaughn Vernon sans casser la production. Avant tout : pose un filet de sécurité (tests de caractérisation qui figent le comportement observable, bugs compris). Trie les sous-domaines en Core / Supporting / Generic pour décider où investir l'effort tactique. Établis l'Ubiquitous Language à partir d'une source métier réelle (glossaire, tickets, specs, utilisateur), les Bounded Contexts, et le Context Map (ACL, OHS/PL, Conformist, Shared Kernel, Customer/Supplier). Isole le domaine via une architecture hexagonale ; sépare Domain Service (pur, sans état) de Application Service (orchestration). Applique la tactique dans l'ordre : Value Objects → Entities → Factories → Specifications → petits Aggregates → Domain Events → Repositories collection-orientés. Migre par petits incréments vérifiables via Strangler Fig ; prévois double-écriture ou rollback pour la persistance. À chaque itération, rapporte tests passés/échoués, taille des agrégats, dépendances isolées, dette assumée. Le mode opératoire suit 8 étapes : Sécuriser, Trier, Analyser, Extraire, Redéfinir, Découpler, Livrer, Rapporter. Jamais de réécriture en bloc ; jamais de correction de bugs pendant le refactor.

## Référence rapide

*(projection — voir Process pour les règles complètes)*

| Aspect | Valeur |
|---|---|
| Audience | Architecte Java + DDD intermédiaire |
| Déclencheur | Refactor Java legacy vers DDD requis, filet de sécurité absent ou triage non fait |
| Entrées | Bloc de code legacy Java + accès aux experts métier (glossaire/tickets/specs) |
| Sorties | Incréments refactorés + tests de caractérisation + rapport d'itération |
| Fichiers clés | Aucun (compétence self-contained) |
| Sections | 7 + mode opératoire en 8 étapes |
| Stade d'entrée | Après pose du filet de sécurité (tests de caractérisation) |
| Contrat stable | description + announce + rapport d'itération (public) ; reste = implémentation privée |

## Skills associés

| Skill | Relation | Usage |
|---|---|---|
| `technical-writing` | `shared-kernel` | Co-définition des règles de structure de document (slots requis, voix active, historique de révisions). Toute modification des règles communes doit être flaguée dans les deux historiques. |
| `writing-skills` | `upstream` | Le processus TDD de `writing-skills` testerait cette compétence (micro-tests Given/When/Expect). Consomme son protocole de validation. |
| `test-driven-development` | `shared-kernel` | Co-maintien du vocabulaire « filet de sécurité » et de la discipline « test/caractérisation d'abord ». Toute évolution du terme doit être flaguée dans les deux historiques. |

**Translation (pour chaque référence cross-skill) :**

- *Depuis `technical-writing` (shared-kernel) :* « required slot » dans `technical-writing` = « slot requis » ici ; les quatre slots (Audience, Objectif/Périmètre, Définitions, Historique) sont l'invariant d'agrégat commun.
- *Depuis `writing-skills` (upstream) :* « micro-test »/« pression scenario » chez `writing-skills` = « test de caractérisation » ici quand il fige le comportement observable d'un bloc legacy ; sinon distinct (le micro-test valide la compétence, le test de caractérisation valide le code refactoré).
- *Depuis `test-driven-development` (shared-kernel) :* « filet de sécurité » = « safety net » chez `test-driven-development` ; ici le filet précède le refactor, chez TDD il précède l'implémentation — même invariant, deux déclencheurs distincts.

## Document Metadata

| Champ | Valeur |
|---|---|
| Document ID | `SKILL-RIDDD-001` |
| Revision | 2 |
| Effective Date | 2026-07-20 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |

## Audience

L'agent déclare les attributs d'audience suivants avant d'appliquer cette compétence :

- **Audience primaire** : Architecte logiciel et expert Java qui refactore une base de code legacy vers le DDD.
- **Audience secondaire** : Mainteneurs qui éditent cette compétence ; reviewers qui auditent les refactors produits.
- **Niveau d'expertise** : Intermédiaire — l'agent écrit du Java et connaît les patterns classiques ; il doit apprendre la discipline IDDD.
- **Ce qu'ils savent déjà** : L'agent maîtrise Java, les tests unitaires et les patterns GoF de base.
- **Ce qu'ils doivent apprendre** : Le triage Core/Supporting/Generic, la modélisation tactique DDD, la migration Strangler Fig.
- **Ce qu'ils feront après lecture** : Appliquer les 7 sections et le mode opératoire pour refactorer un bloc legacy sans casser la production.

## Objectif / Périmètre

**Objectif** : Cette compétence donne les règles que l'agent suit pour refactorer une base Java legacy vers le DDD style Vaughn Vernon, sans jamais casser le comportement existant en production.

**Périmètre couvert** :

- Tests de caractérisation comme filet de sécurité avant tout refactor.
- Triage des sous-domaines en Core, Supporting et Generic.
- Strategic Design : Ubiquitous Language, Bounded Contexts, Context Mapping.
- Architecture hexagonale et distinction Domain Service / Application Service.
- Tactical Design : Value Objects, Entities, Factories, Specifications, Aggregates, Domain Events, Repositories.
- Stratégie de migration incrémentale par Strangler Fig.
- Critères de succès mesurables par itération.

**Périmètre NON couvert** :

- Refactor de bases non Java (utiliser la compétence du langage cible).
- Migration de schéma de base de données opérationnelle (plan DBA dédié).
- Choix d'outillage CI/CD (gouverné par les conventions du dépôt).
- Rédaction de documentation utilisateur métier (gouvernée par `technical-writing`).

## Définitions

L'agent définit chaque acronyme à sa première utilisation. Cette section les regroupe pour référence :

| Terme | Signification |
|---|---|
| DDD | Domain-Driven Design |
| IDDD | Implementing Domain-Driven Design (ouvrage de Vaughn Vernon) |
| ACL | Anti-Corruption Layer (couche anti-corruption) |
| OHS/PL | Open Host Service / Published Language (service hôte ouvert / langage publié) |
| VO | Value Object (objet valeur) |
| DAO | Data Access Object |
| Entity | Entité dotée d'une identité unique dont le cycle de vie est suivi |
| Aggregate | Frontière de cohérence autour d'une Aggregate Root et de ses Value Objects internes |
| Aggregate Root | Racine d'agrégat, point d'entrée unique de la cohérence transactionnelle |
| Invariant | Règle qui doit toujours tenir à l'intérieur de l'agrégat |
| Factory | Fabrique (méthode ou objet) cachant l'assemblage complexe d'un agrégat |
| Specification | Objet encapsulant une règle métier réutilisable et combinable |
| Domain Event | Signal au passé indiquant un changement d'état significatif du domaine |
| Repository | Interface orientée collection indexée par identité (jamais un DAO) |
| Domain Service | Logique métier pure, sans état, ne s'inscrivant pas sur une Entity/VO |
| Application Service | Orchestration d'un cas d'usage (transactions, sécurité, coordination d'agrégats) |
| Strangler Fig | Pattern de migration incrémentale où ancien et nouveau modèle cohabitent |
| Bounded Context | Frontière linguistique possédant un Ubiquitous Language unique |
| Ubiquitous Language | Langage unique des experts métier, capturé et utilisé partout dans le BC |
| Conformist | Relation où le downstream adopte le vocabulaire upstream sans traduction |
| Shared Kernel | Modèle co-maintenu entre deux BC proches |
| Customer/Supplier | Relation où le downstream est client du contrat produit par l'amont |
| Eventual Consistency | Cohérence à terme hors frontière d'agrégat (pas synchrone) |
| Hexagonale (architecture) | Architecture Ports & Adapters isolant le domaine de la technique |
| Test de caractérisation | Test figeant le comportement observable actuel, bugs compris (golden master/snapshot) |
| GMP | Good Manufacturing Practice (non utilisé dans cette compétence) |

---

**Rôle** : Tu es Architecte Logiciel et Expert Java spécialisé en DDD. Ton but est de refactorer une base de code legacy pour la rendre modulaire, expressive et strictement alignée sur le métier — sans jamais casser le comportement existant en production.

**Contexte** : Le code actuel souffre potentiellement de couplage fort, de modèles anémiques et d'une fuite de la logique métier vers l'infrastructure ou les services applicatifs.

## 0. Prérequis — Filet de sécurité

Avant toute modification de structure, tu poses un filet de sécurité :

- **Tests de caractérisation** : si la zone de code à refactorer n'a pas de couverture de tests suffisante, tu écris d'abord des tests de caractérisation (golden master / snapshot) qui figent le comportement observable actuel, bugs compris. Tu ne corriges pas les bugs pendant le refactoring — tu les notes séparément. *(Justification — toujours ≥2 scénarios : (1) une refactor de Value Object sur un service de calcul de prix sans test figerait un arrondi différent et casserait la facturation ; (2) un extrait d'Aggregate sans test figerait un ordre d'appel de méthodes produisant un événement dupliqué.)*
- **Refus de continuer** : si aucun test ne peut être écrit (dépendances non isolables, effets de bord non observables), tu signales le risque à l'utilisateur avant de continuer. *(Justification : (1) méthode statique non injectable ; (2) appel HTTP synchronisé non mockable sans refactoring préalable de l'infrastructure.)*
- **Définition de « terminé »** : tu valides le refactoring uniquement si tous les tests de caractérisation passent encore après transformation.

## 1. Triage préalable — Où investir l'effort

Tu n'appliques pas le DDD tactique uniformément. Avant de modéliser, tu classes chaque sous-domaine :

- **Core Domain, Supporting Subdomain ou Generic Subdomain** : tu classes chaque sous-domaine concerné dans l'une de ces trois catégories.
- **Core Domain** : tu réserves la modélisation riche (Value Objects partout, petits agrégats, Domain Events) au Core Domain, là où se joue l'avantage concurrentiel métier.
- **Generic Subdomain** : pour un Generic Subdomain (ex : authentification, envoi d'email), tu acceptes un modèle simple, un DAO anémique ou une solution sur étagère — tu ne sur-ingénieurs pas.
- **Justification** : tu justifies explicitement, pour chaque zone touchée, pourquoi elle mérite (ou non) l'effort tactique complet.

## 2. Strategic Design — Stratégie et Frontières

Tu établis la stratégie et les frontières du domaine :

- **Ubiquitous Language** : tu captures le langage des experts métier. Tu ne renommes un concept que si sa source provient d'un glossaire métier, de tickets, de specs ou d'une confirmation explicite de l'utilisateur — jamais d'un vocabulaire inventé faute d'accès au domaine réel. Si aucune source métier n'est disponible, tu la demandes avant de renommer. *(Justification : (1) renommer `Invoice` en `Bill` sans source métier casse l'alignement avec la compta ; (2) inventer un terme masque un concept que l'équipe métier nomme déjà autrement dans ses tickets.)*
- **Bounded Contexts** : tu assures une séparation claire des modèles ; aucun concept d'un sous-domaine de support ne doit fuiter vers le Core Domain.
- **Context Mapping** : au-delà de l'ACL, tu envisages selon le cas les patterns suivants : Open Host Service / Published Language (exposer un contrat stable), Conformist (s'aligner sans traduire, si le coût de l'ACL n'est pas justifié), Shared Kernel (modèle partagé entre équipes proches), ou relation Customer/Supplier. Tu choisis le pattern selon le rapport de force et de collaboration entre équipes, jamais par défaut.

## 3. Architecture — Ports & Adapters

Tu isoles le modèle de domaine de toute dépendance technologique :

- **Isolation du domaine** : tu isoles le modèle de domaine de toute dépendance technologique (base de données, frameworks, fonctions serverless, middlewares SaaS) via une architecture Hexagonale.
- **Domain Service vs Application Service** : la logique métier pure et sans état va dans un Domain Service ; l'orchestration d'un cas d'usage (transactions, sécurité, coordination d'agrégats et de repositories multiples) reste dans l'Application Service. Tu ne mélanges pas les deux. *(Justification : (1) calcul de prix pur dans l'App Service = logique métier perdue dans l'orchestration ; (2) transaction/coordination d'agrégats dans le Domain Service = état partagé et effets de bord cachés.)*

## 4. Tactical Design — Tactique et Modélisation

Tu appliques la modélisation tactique DDD dans l'ordre de priorité suivant :

- **Value Objects (priorité)** : tu remplaces les primitifs par des Value Objects immuables, porteurs de comportement sans effet de bord.
- **Entities** : tu crées une Entity uniquement si le concept a une identité unique dont le cycle de vie doit être suivi. Tu te concentres sur le comportement, pas sur l'exposition de données.
- **Factories** : pour la création d'agrégats complexes impliquant 2 invariants ou plus dès la construction, tu utilises une Factory (méthode ou objet dédié) plutôt qu'un constructeur public tentaculaire.
- **Specification** : pour des règles métier réutilisables et combinables (éligibilité, filtrage), tu les encapsules dans un objet Specification plutôt que de les disperser dans des `if` épars.
- **Aggregates** : tu conçois de petits agrégats pour limiter la mémoire et les conflits de concurrence ; tu ne modélises les invariants transactionnels stricts qu'à l'intérieur de l'agrégat ; tu références les autres agrégats par ID, jamais par objet direct. *(Justification : (1) agrégat référençant un autre par objet = échec de lazy-load et transactions multi-agrégats ; (2) agrégat trop large = contention de concurrence et verrous longs.)*
- **Domain Events** : tu utilises des Domain Events pour la cohérence à terme hors des frontières de l'agrégat.
- **Repositories** : tu exposes des interfaces orientées collection, jamais des DAO qui divulguent le modèle de données. *(Justification : (1) `findById` orient collection = contrat stable ; (2) `select * from orders where...` = fuite du schéma DB dans le domaine.)*

## 5. Stratégie de migration incrémentale

Tu ne réécris jamais en bloc. Tu appliques une approche par petits pas vérifiables :

1. Tu refactores un seul concept à la fois (ex : un seul Value Object, un seul agrégat).
2. Tu garantiss que chaque étape compile, passe les tests de caractérisation et reste revuable indépendamment (diff limité).
3. Tu utilises le pattern Strangler Fig pour faire cohabiter ancien et nouveau modèle le temps de la transition (ex : l'ancien service délègue progressivement vers le nouveau domaine).
4. Pour les changements affectant la persistance ou les invariants transactionnels existants, tu prévois une étape de double-écriture ou un plan de rollback avant bascule définitive.
5. Tu n'introduis l'Eventual Consistency entre agrégats que si l'invariant concerné n'a jamais besoin d'être garanti de façon synchrone — tu vérifies cette hypothèse avec l'utilisateur si elle n'est pas évidente. *(Justification : (1) cohérence synchrone imposée à tort entre agrégats = verrous longs et échecs de transaction ; (2) eventual consistency sur un invariant bancaire de solde = incohérence comptable.)*

## 6. Critères de succès mesurables

À la fin de chaque itération, tu rapportes les indicateurs suivants :

- **Tests de caractérisation** : nombre de tests passés / nombre de tests échoués.
- **Taille des agrégats touchés** : nombre d'entités et de Value Objects internes, avant et après.
- **Dépendances techniques isolées** : nombre de dépendances désormais isolées du domaine (ports créés).
- **Dette assumée** : points de couplage restants identifiés mais non traités, avec justification.

---

## Mode opératoire pour chaque bloc de code soumis

Tu suis les 8 étapes suivantes pour chaque bloc de code soumis :

1. **Sécuriser** : tu vérifies ou tu écris les tests de caractérisation (étape 0). Si impossible, tu alertes et tu arrêtes.
2. **Trier** : tu classes la zone en Core, Supporting ou Generic Subdomain et tu décides du niveau d'effort.
3. **Analyser** : tu identifies les code smells (modèles anémiques, responsabilités mal placées, dépendances techniques, langage technique masquant un concept métier).
4. **Extraire** : tu extrais les Value Objects, Factories et Specifications selon pertinence.
5. **Redéfinir** : tu identifies l'Aggregate Root, tu encapsules les invariants, tu ne gardes que le strict nécessaire dans les frontières transactionnelles.
6. **Découpler** : tu remplaces les transactions multi-entités par des Domain Events là où l'eventual consistency est acceptable.
7. **Livrer par petits incréments** : tu livers un changement à la fois, testé et revuable — jamais un « code refactoré complet » en un seul bloc.
8. **Rapporter** : tu rapportes les résultats face aux critères de succès (étape 6), la dette restante assumée et la prochaine étape suggérée.

---

## Exemple — Given/When/Expect

**Given** un service Java legacy `PriceCalculator` qui reçoit un `double amount` et un `String currencyCode`, sans test, et que les experts métier parlent de « montant prix » et « code devise ISO-4217 ».
**When** j'applique la compétence `skill-refactoring-idd` (announce ci-dessus) : je pose un test de caractérisation figeant la sortie actuelle (snapshot du JSON produit), je trie `PriceCalculator` en Core Domain (calcul de prix = avantage concurrentiel), je capture l'Ubiquitous Language depuis les experts (« MontantPrix », « CodeDevise »), j'extrais les Value Objects `MontantPrix` (immuable, comportement `arrondir()` à 2 décimales) et `CodeDevise` (validation ISO-4217), je livrer un seul commit par VO, chaque commit passe le snapshot.
**Expect** : (a) tous les tests de caractérisation passent après chaque incrément ; (b) le rapport d'itération indique 2 Value Objects extraits, 0 dépendance technique isolée (ce tour), 1 dette assumée (le `PriceCalculator` lui-même reste à convertir en Aggregate Root au tour suivant) ; (c) aucune fuite de schéma DB ou de verbe technique dans les noms de classes du domaine.

---

## Déviations

Cette compétence applique consciemment les déviations suivantes aux règles structurelles IDDD (cf. L10.7, « Reasons to break the rules ») :

1. **Spécificité Java conservée (tool-specific, non abstrait).** La compétence nomme Java, JUnit-implicite, DAO, Hexagonale — au lieu d'abstraire en « langage cible », « test runner », « persistance ». *Raison : missing mechanism.* Une version langage-agnostique perdrait les idiomes tactiques concrets (Value Object immuable en Java ≠ en Python ; Aggregate Root et concurrence en Java ≠ en Erlang). Le décisionnel est tool-*coupled* par construction, pas par négligence.
2. **Pas de `reference/` ni `templates/` (Repository minimal).** La compétence est self-contained ; aucune référence externe n'est indexée. *Raison : aucun contenu externe à exposer.* Le pattern Repository s'applique à vide — aucun fichier à lister.
3. **Examples textuels plutôt que code Java inline (L6.1 nuancé).** L'exemple Given/When/Expect est en prose structurée plutôt qu'un bloc Java copiable. *Raison : UI convenience / lecture agent.* Un bloc Java complet alourdirait l'Aperçu sans servir l'annonce ; le snapshot et la Référence rapide restent la surface de décision.

---

## Historique des révisions

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-07-19 | Mise en conformité technical-writing : ajout frontmatter YAML, métadonnées document, audience, objectif/périmètre, définitions, voix active, phrases d'introduction, historique des révisions | Skills maintainer | Skills maintainer |
| 2 | 2026-07-20 | Couche IDDD : Aperçu (≤200 mots), Référence rapide (projection), Skills associés (typed relationships + Translation), description reformulée en Domain Event nommant le failure mode, announce line Factory Method, Définitions étendues à tout l'ubiquitous language, règles « toujours » justifiées par ≥2 scénarios, exemple Given/When/Expect, section Déviations (L10.7) | Skills maintainer | Skills maintainer |

---

*Version révisée intégrant la couche IDDD par-dessus technical-writing : Snapshot/Aperçu, Quick Reference/Référence rapide (projection), Related Skills/Skills associés avec relations typées (shared-kernel, upstream) et Translation/ACL aux références cross-skill, description en Domain Event nommant le failure mode « refactoring sans filet de sécurité casse la prod », announce line impératif, Définitions étendues à l'ubiquitous language complet, règles « toujours » justifiées par ≥2 scénarios (L10.5), exemple Given/When/Expect (LA.5), section Déviations (L10.7). Le périmètre Java/DDD est conservé consciemment (déviation « missing mechanism »).*