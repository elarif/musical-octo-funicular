# English Glossary — Shared Kernel

**Effective date:** 2026-08-25
**Owner:** Skills maintainer
**Applies to:** tout skill anglophone consommant ces termes. Ne pas dupliquer dans un skill — référencer ce fichier par chemin relatif.

## TDD / Testing

- **TDD** — Test-Driven Development. Cycle RED→GREEN→REFACTOR.
- **RED** — Écrire le test qui échoue + le regarder échouer. Jamais sauter cette phase.
- **GREEN** — Implémentation minimale qui fait passer le test. Rien de plus.
- **REFACTOR** — Améliorer structure sans changer comportement, tests restent verts.
- **Iron Law** — Invariant absolu sous forme "NO X WITHOUT [failing] Y FIRST". Voir `_shared/fragments/iron-law.md`.
- **Safety net** — Suite de tests qui fige comportement avant refactor.

## Skills

- **Skill** — Fichier SKILL.md + ressources associées, chargé progressive disclosure.
- **Snapshot** — Résumé ≤200 mots en tête de body, self-suffisant pour annoncer skill.
- **Quick Reference** — Table projection du Process. Labeled "projection — see X for full rules".
- **Hard Gate** — Invariant bloquant toute action implémentation avant validation. Voir `_shared/fragments/hard-gate.md`.
- **Public Interface for Composition** — Surface publique d'un sub-skill (announce line + entry points). Reste = private implementation.
- **Identity strategy** — Règle de nommage stable (descriptive name, hyphens, no rename).

## Testing skills (TDD-for-skills)

- **Pressure scenario** — Brief subagent tentant de violer une règle du skill. Run before skill exists (RED baseline) et after (GREEN compliance).
- **Micro-test** — Vérification Given/When/Expect wording in-memory, no tool call.
- **In-memory micro-test recipe** — Protocole 5+ reps fresh-contexts, chaque flagged match lu manuellement.
- **Given/When/Expect** — Format exemple canonique. Voir `_shared/fragments/given-when-expect.md`.
- **Rationalization table** — Table Excuse|Reality capturant excuses récurrentes agent + contre-vérité.
- **Evals** — Suite prompt + expected output + assertions gradées. Run with-skill vs baseline.

## Cross-skill relationships

- **upstream** — Skill parent qui charge/invoque ce skill.
- **downstream** — Skill enfant invoqué par ce skill.
- **shared-kernel** — Co-maintenance vocabulaire, modifications flaggées dans Revision History des deux côtés.
- **conformist** — Sub-skill adopte vocabulaire parent sans traduction.
- **Translation (ACL)** — Note décrivant mapping vocabulaire skill parent ↔ skill invoqué.

## Structure

- **Bounded Context (BC)** — 1 skill = 1 BC. Frontière linguistique Ubiquitous Language unique.
- **Shared Kernel** — `_shared/` directory. Ne contient JAMAIS process complet.
- **orchestrator** — Skill type router/coordinator. Voir `_shared/SKILL-ARCH.md`.
- **sub-skill** — Skill type executor avec Public Interface. Voir `_shared/SKILL-ARCH.md`.

## Modification

Toute modification d'un terme nécessite flag dans Revision History de chaque skill listant ce terme dans ses Definitions ou Process.
