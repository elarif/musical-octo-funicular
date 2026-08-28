# Skills Architecture — Typologie orchestrator / sub-skill

**Effective date:** 2026-08-25
**Owner:** Skills maintainer
**Applies to:** tous les skills de `/home/elarif/.agents/skills/` hors `_shared/`.

## Ubiquitous Language

- **orchestrator** : skill qui route vers, coordonne, ou invoque d'autres skills par `name`. N'exécute pas de tâche technique précise seul. Exemple : `using-superpowers`, `brainstorming`, `writing-plans`.
- **sub-skill** : skill qui exécute une tâche technique précise et expose une "Public Interface for Composition" consommable par un orchestrateur. Ne route pas. Exemple : `writing-skills`, `test-driven-development`, `technical-writing`.
- **shared-kernel** : contenu mutualisé dans `_shared/`. Jamais un process complet. Glossaires, fragments de templates, state primitives uniquement.
- **ACL** : `Translation:` note dans Related Skills d'un skill, décrivant le mapping vocabulaire entre skill parent et sub-skill invoqué.

## Inventaire (25 skills, audit 2026-08-25)

### orchestrators (8)

| Nom | Rôle |
|---|---|
| using-superpowers | Routeur global — match trigger, charge skill |
| brainstorming | Gate créatif — spec avant implem |
| writing-plans | Spec → plan task-by-task |
| executing-plans | Plan → exécution inline |
| subagent-driven-development | Plan → dispatch subagents |
| dispatching-parallel-agents | Fan-out failures indépendants |
| business-plan-redaction | Orchestrateur métier BP France |
| previsions-financieres-demarrage | Orchestrateur finance prévisionnel |

### sub-skills (17)

| Nom | Rôle |
|---|---|
| writing-skills | Méta-skill — TDD pour skills |
| technical-writing | Règles rédaction docs techniques |
| test-driven-development | Cycle RED-GREEN-REFACTOR |
| systematic-debugging | Root cause d'abord |
| verification-before-completion | Evidence avant assertion |
| requesting-code-review | Protocole demande review |
| receiving-code-review | Protocole réception review |
| documenting-codebases | C4 + BPMN PlantUML |
| skill-refactoring-idd | Refactor Java → DDD |
| kibana-prod-investigation | Investigation prod read-only |
| using-git-worktrees | Isolation branches |
| finishing-a-development-branch | Intégration branche finie |
| executive-summary | Rédaction résumé BP |
| plan-financement-durable | Calcul plan financement |
| seuil-rentabilite | Calcul seuil |
| tresorerie-bfr | Calcul trésorerie BFR |
| opencode-clipboard-image | Clipboard → fichier timestamped |

## Invariants

1. Orchestrateur **JAMAIS** inline les règles d'un sub-skill — invoke par `name` + Translation note.
2. Sub-skill **JAMAIS** ne dispatche vers un autre skill technique — il expose sa Public Interface et remonte.
3. `_shared/` **JAMAIS** un process complet — seulement glossary / fragments / state primitives.
4. Frontmatter `type: orchestrator|sub-skill` requis sur toute entrée nouvelle.
5. Skill mixte (rare) : garde `type: orchestrator` + note Deviations (UI convenience).

## Modification

Toute modification de ce fichier nécessite revue par maintainer + flag dans Revision History de chaque skill impacté.

## Cross-repo : opencode/skills family

Les 11 skills sous `~/.config/opencode/skills/` (famille caveman + rust-idioms-reviewer) portent aussi `type:` en frontmatter depuis 2026-08-26 :
- 1 orchestrator : `cavecrew` (routing subagents caveman-style)
- 10 sub-skills : `caveman`, `caveman-commit`, `caveman-compress`, `caveman-help`, `caveman-memory`, `caveman-plan`, `caveman-review`, `caveman-stats`, `caveman-workspace`, `rust-idioms-reviewer`

**Différence de contrat :** ces skills sont minimal-by-design (12-111 lignes) et n'adoptent PAS les slots Snapshot/Related/Revision History. Le type: seul y cohabite avec leur style compact.
