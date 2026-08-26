---
name: seuil-rentabilite
description: Déclencher quand l'utilisateur cherche le seuil de rentabilité, le point mort, la rentabilité minimale, ou veut répartir charges fixes/variables d'un projet de création d'entreprise (commerce, service, production ou SaaS/digital). Calcule le CA minimum pour ne pas faire de pertes et le traduit en objectif opérationnel concret (nb articles/jour, nb abonnés, etc.).
type: sub-skill
---

# Seuil de rentabilité

## Snapshot

Calcule le seuil de rentabilité (€) et le point mort (temps) d'un projet de création d'entreprise en répartissant les charges en fixes/variables, adapté au modèle (commerce, service, production, SaaS). Génère 3 scénarios (optimiste/nominal/pessimiste) avec paramètres spécifiques au modèle. Écrit les résultats dans `projet-state.json` via `state-tool.sh`. N'émet jamais de verdict go/no-go.

## Quick Reference

| Champ | Valeur |
|---|---|
| Audience | Agent accompagnant un créateur d'entreprise FR dans le calcul du seuil de rentabilité |
| Déclencheur | "seuil rentabilité", "point mort", "rentabilité minimale", "charges fixes variables", "/seuil-rentabilite" |
| Entrées | `projet.modele`, `variables.ca_annuel_ht` (année 1), `saas_metrics.*` (si saas) via state-tool |
| Sorties | `variables.charges_fixes[3]`, `charges_variables[3]`, `seuil_rentabilite[3]`, `point_mort_jours[3]`, `scenarios.*`, `alertes[]` |
| Outil état | `state-tool.sh` (jamais de JSON écrit à la main) |
| Modèles | commerce, service, production, saas/digital |
| Scénarios | optimiste, nominal, pessimiste (paramètres par modèle) |

## Related Skills

| Skill | Relation | Rôle |
|---|---|---|
| `previsions-financieres-demarrage` | `upstream` | Orchestrateur qui invoque ce skill pour Q3 (ventes minimales rentabilité) |
| `business-plan-redaction` | `upstream` | Invoque ce skill pour la partie financière du BP |
| `technical-writing` | `shared-kernel` | Co-maintient Document Metadata, Audience, Definitions |
| `executive-summary` | `downstream` | Consomme `seuil_rentabilite` en mode final |
| `tresorerie-bfr` | `none` | Separate Ways — pas de chevauchement direct |
| `plan-financement-durable` | `none` | Separate Ways |

## Document Metadata

| Champ | Valeur |
|---|---|
| Document ID | `SKILL-SR-001` |
| Revision | 1 |
| Effective Date | 2026-08-06 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |

## Audience

- **Primary**: Agent accompagnant un créateur d'entreprise FR dans le calcul du seuil de rentabilité.
- **Secondary**: Maintainers of this skill.
- **Expertise level**: Intermediate — connaît charges fixes/variables, marge sur coûts variables.
- **What they already know**: Tenir une conversation de conseil en FR.
- **What they need to learn**: Adaptation par modèle (SaaS: CAC variable, R&D fixe), stress-test 3 scénarios, usage de `state-tool.sh`.
- **What they will do after reading**: Calculer seuil + point mort × 3 scénarios, écrire dans le state, alerter si CA < seuil.

## Purpose / Scope

**Purpose**: Calculer le seuil de rentabilité et le point mort d'un projet, adapté au modèle économique, avec 3 scénarios.

**Scope covers**:
- Répartition charges fixes/variables (adaptée SaaS).
- Calcul marge sur coûts variables, taux de marge, seuil (€), point mort (jours).
- Interprétation opérationnelle concrète.
- Stress-test 3 scénarios avec paramètres par modèle.
- Écriture dans `projet-state.json` via `state-tool.sh`.
- Alerte `ca_sous_seuil` si CA nominal/pessimiste < seuil.

**Scope does NOT cover**:
- Plan de financement (skill 2), plan de trésorerie (skill 3), rédaction BP (skill 5).
- Conseil fiscal ou juridique.

## Definitions

Voir `_shared/bpifrance-finance-glossary.md`. Termes centraux: Seuil de rentabilité, Point mort, Charges fixes, Charges variables, Marge sur coûts variables, Taux de marge sur coûts variables, CAC, MRR.

## State Contract

- **Reads** (via `state-tool.sh get`): `projet.modele`, `variables.ca_annuel_ht` (index 0 pour année 1), `saas_metrics.cac`, `saas_metrics.opex_mensuel` (si `projet.modele` est `saas` ou `digital`).
- **Writes** (via `state-tool.sh set` / `patch`):
  - `variables.charges_fixes` (array [3])
  - `variables.charges_variables` (array [3])
  - `variables.seuil_rentabilite` (array [3])
  - `variables.point_mort_jours` (array [3])
  - `scenarios.optimiste`, `scenarios.nominal`, `scenarios.pessimiste` (champs ci-dessus par scénario)
  - `alertes[]` (ajout via `patch` si CA < seuil)

## Process

1. **Lire le contexte projet** via `state-tool.sh get projet.modele` et `state-tool.sh get variables.ca_annuel_ht.0`. Si le state n'existe pas, demander à l'utilisateur d'invoquer `previsions-financieres-demarrage` d'abord, ou initialiser via `state-tool.sh init` puis recueillir `projet.modele`.
2. **Répartir les charges en 2 catégories** (une question à la fois):
   - **Charges fixes (structurelles)**: loyer, salaires, assurances, honoraires — indépendantes des ventes. **Pour saas/digital: inclure R&D et salaires.**
   - **Charges variables (opérationnelles)**: approvisionnements, transport, commissions — liées au CA. **Pour saas/digital: inclure coût variable par utilisateur (API, hosting) et CAC.**
3. **Calculer la marge sur coûts variables** = ventes prévisionnelles HT - charges variables.
4. **Taux de marge sur coûts variables** = (marge / CA) × 100.
5. **Seuil de rentabilité (€)** = charges fixes / taux de marge.
6. **Point mort (jours)** = (seuil de rentabilité / CA annuel) × 365.
7. **Traduire en concret**: nb articles/jour, nb heures à facturer, **nb abonnés pour SaaS**, etc.
8. **Écrire dans le state** via `state-tool.sh set` pour chaque array [3] (N/N+1/N+2).
9. **Stress-test** (3 scénarios, paramètres par modèle — voir table ci-dessous).
10. **Alerte**: si CA nominal ou pessimiste < seuil → `state-tool.sh patch` ajoute `{type: "ca_sous_seuil", mois_ou_annee: <année>, source_skill: "seuil-rentabilite", action: "feedback → previsions-financieres-demarrage (matrice des risques)"}`.

### Stress-test parameters by model

| Scénario | commerce / production / service | saas / digital |
|---|---|---|
| Optimiste | CA +20% / coûts -10% | CA +50% / infra costs +40% / churn -30% |
| Nominal | hypothèses de base | hypothèses de base |
| Pessimiste | CA -30% 6 premiers mois / coûts +15% | **CAC x2 / churn +50% / CA -30%** (infra costs baissent avec l'usage) |

Pour SaaS pessimiste: CAC x2 augmente les charges variables, churn +50% baisse le CA récurrent — les coûts d'infra baissent avec l'usage, ne montent PAS.

## Key Principles

- Une question à la fois.
- Scénario prudent: minimiser recettes, maximiser coûts (le pessimiste formalise cela).
- Pas de verdict go/no-go — identifier les points de rupture.
- `state-tool.sh` pour tout accès état. Jamais de JSON à la main.
- Disclaimer: pédagogique, recommander validation par expert-comptable.

## Examples

### Given/When/Expect — commerce

- **Given** un créateur de boulangerie (CA HT 43 800 €, charges fixes 28 000 €, charges variables 17 500 €).
- **When** l'agent exécute le process.
- **Expect** marge = 26 300 €, taux = 60%, seuil = 46 667 €, point mort = 389 jours → alerte `ca_sous_seuil` (CA < seuil en nominal), interprétation "≈ 128 baguettes/jour minimum".

### Given/When/Expect — saas

- **Given** un créateur de SaaS (ARR 60 000 €, charges fixes 40 000 € incluant R&D, charges variables 15 000 € incluant CAC et coût API).
- **When** l'agent exécute le process avec `projet.modele=saas`.
- **Expect** marge = 45 000 €, taux = 75%, seuil = 53 333 €, interprétation "≈ 89 abonnés à 50 €/mois minimum", scénario pessimiste avec CAC x2 et churn +50%.

## Revision History

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-08-06 | Initial: seuil rentabilité multi-modèle + stress-test 3 scénarios + state-tool. | elarif | elarif |
| 2 | 2026-08-26 | Sweep typologie IDDD : ajout frontmatter type, réordonnancement Skills associés par catégorie selon _shared/SKILL-ARCH.md | Skills maintainer | Skills maintainer |