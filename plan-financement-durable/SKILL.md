---
name: plan-financement-durable
description: Déclencher quand l'utilisateur cherche le plan de financement (initial ou à 3 ans), les besoins/ressources durables, ou veut vérifier l'équilibre financier au lancement d'un projet de création d'entreprise (commerce, service, production ou SaaS/digital). Construit le tableau initial (jour zéro) et la projection 3 ans (N/N+1/N+2), distingue CapEx/OpEx pour SaaS, gère la TVA déductible sur investissements initiaux, et traite les feedback loops de trésorerie négative.
---

# Plan de financement durable

## Snapshot

Construit le plan de financement initial (jour zéro) et la projection à 3 ans (N/N+1/N+2). Distingue CapEx vs OpEx pour SaaS/digital. Calcule la TVA déductible sur investissements initiaux (mois 1) si régime réel. Traite les feedback loops issues de `tresorerie-bfr` (solde négatif → ajouter apport/emprunt). Génère 3 scénarios avec paramètres par modèle. Écrit dans `projet-state.json` via `state-tool.sh`.

## Quick Reference

| Champ | Valeur |
|---|---|
| Audience | Agent accompagnant un créateur d'entreprise FR dans la construction du plan de financement |
| Déclencheur | "plan de financement", "financement initial", "plan financement 3 ans", "besoins ressources durables", "/plan-financement" |
| Entrées | `projet.modele`, `projet.tva_regime`, `variables.bfr` (skill 3), `saas_metrics.*`, `alertes[]` (feedback) |
| Sorties | `variables.apports`, `emprunts`, `investissements_ht`, `investissements_annuels[3]`, `remboursements_emprunts_capital[3]`, `nouveaux_emprunts[3]`, `caf[3]`, `tva_deductible_mensuelle.0`, `scenarios.*` |
| Outil état | `state-tool.sh` (jamais de JSON écrit à la main) |
| Feedback | Reçoit `alertes[]` de `tresorerie-bfr` → ajoute apport/emprunt → skill 3 recalcule |

## Related Skills

| Skill | Relation | Rôle |
|---|---|---|
| `tresorerie-bfr` | `downstream` + `feedback` | Calcule le BFR consommé ici; émet les alertes de solde négatif traitées ici |
| `previsions-financieres-demarrage` | `upstream` | Orchestrateur qui invoque ce skill pour Q1 (capitaux) et Q5 (pérennité 3 ans) |
| `business-plan-redaction` | `upstream` | Invoque ce skill pour la partie financière du BP |
| `seuil-rentabilite` | `none` | Separate Ways |
| `executive-summary` | `downstream` | Consomme les données de financement en mode final |
| `technical-writing` | `shared-kernel` | Co-maintient Document Metadata, Audience, Definitions |

## Document Metadata

| Champ | Valeur |
|---|---|
| Document ID | `SKILL-PFD-001` |
| Revision | 1 |
| Effective Date | 2026-08-06 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |

## Audience

- **Primary**: Agent accompagnant un créateur d'entreprise FR dans la construction du plan de financement.
- **Secondary**: Maintainers of this skill.
- **Expertise level**: Intermediate — connaît fonds propres, emprunts, CAF, BFR.
- **What they already know**: Tenir une conversation de conseil en FR.
- **What they need to learn**: CapEx vs OpEx (SaaS), TVA déductible sur investissements initiaux, feedback loop, pluriannual [3], `state-tool.sh`.
- **What they will do after reading**: Construire plan initial + 3 ans × 3 scénarios, gérer TVA, traiter feedback loops.

## Purpose / Scope

**Purpose**: Construire le plan de financement initial et la projection 3 ans, avec gestion TVA et feedback loops.

**Scope covers**:
- Volet initial (jour zéro): besoins (investissements HT, trésorerie sécurité, BFR), ressources (fonds propres, emprunts, aides), équilibre, règles de prudence.
- Volet 3 ans: CAF, remboursements capital, nouveaux besoins/ressources, prélèvements exploitant (EI), dividendes (sociétés).
- CapEx vs OpEx pour SaaS/digital.
- TVA déductible sur investissements initiaux (mois 1) si régime réel.
- Feedback loop: alerte `tresorerie_negative` → ajouter apport/emprunt → signal skill 3.
- Stress-test 3 scénarios (paramètres par modèle).

**Scope does NOT cover**:
- Plan de trésorerie mensuel (skill 3), seuil de rentabilité (skill 4), rédaction BP (skill 5).
- Conseil fiscal ou juridique.

## Definitions

Voir `_shared/bpifrance-finance-glossary.md`. Termes centraux: Plan de financement initial, Plan de financement à 3 ans, CAF, CapEx, OpEx, TVA déductible, BFR.

## State Contract

- **Reads** (via `state-tool.sh get`): `projet.modele`, `projet.tva_regime`, `variables.bfr` (array [3] depuis skill 3), `saas_metrics.capex`, `saas_metrics.opex_mensuel` (si saas), `alertes[]` (feedback de skill 3).
- **Writes** (via `state-tool.sh set` / `patch`):
  - `variables.apports`
  - `variables.emprunts`
  - `variables.investissements_ht`
  - `variables.investissements_annuels` (array [3])
  - `variables.remboursements_emprunts_capital` (array [3])
  - `variables.nouveaux_emprunts` (array [3])
  - `variables.caf` (array [3])
  - `variables.tva_deductible_mensuelle.0` (mois 1, si `tva_regime=reel`)
  - `scenarios.*`

## Process

### Volet initial (jour zéro)

1. Évaluer besoins: investissements (HT) — **CapEx vs OpEx distinction if `projet.modele` is saas/digital**, trésorerie sécurité, BFR (renvoie skill 3 pour calcul via `state-tool.sh get variables.bfr.0`).
2. Lister ressources: fonds propres (apports, comptes courants), emprunts (bancaires, prêts d'honneur, microcrédit), aides/subventions.
3. Vérifier équilibre: ressources ≥ besoins + marge sécurité.
4. Règle prudence: fonds propres ≥ emprunts LMT; éviter financer durable par court terme.
5. **TVA déductible sur investissements initiaux**: si `projet.tva_regime == "reel"`, calculer la TVA déductible sur les investissements du mois 1 et écrire `state-tool.sh set variables.tva_deductible_mensuelle.0 <valeur>`. Cette TVA est récupérée et améliore la trésorerie du mois 1.

### Volet 3 ans

1. Année 1: reprendre initial + remboursement capital emprunt + (prélèvements exploitant si EI) | ressources: CAF (bénéfices après impôts + dotations amortissements).
2. Années 2-3: nouveaux besoins (investissements, ↑BFR, remboursements, dividendes) | nouvelles ressources (augmentations capital, CAF, nouveaux emprunts, subventions).
3. Vérifier ressources > besoins de 15-20% CAF année 1, s'accentuant ensuite.

### feedback-loop handling

Quand invoqué depuis une feedback loop (alerte `tresorerie_negative` de skill 3):
1. Lire `alertes[]` via `state-tool.sh patch` ou `get alertes`.
2. Re-entrer à l'étape pertinente (ajouter apport ou emprunt).
3. Mettre à jour `variables.apports` ou `variables.emprunts` via `state-tool.sh set`.
4. Signaler à skill 3 de recalculer (le state est mis à jour, skill 3 relit).

### Stress-test (paramètres par modèle)

| Scénario | commerce / production / service | saas / digital |
|---|---|---|
| Optimiste | CA +20% / coûts -10% | CA +50% / infra costs +40% / churn -30% |
| Nominal | hypothèses de base | hypothèses de base |
| Pessimiste | CA -30% 6 premiers mois / coûts +15% | **CAC x2 / churn +50% / CA -30%** (infra costs baissent avec l'usage) |

Persister dans `scenarios.*` via `state-tool.sh`. Arrays pluriannuels [3] calculés pour chaque scénario.

## Key Principles

- Une question à la fois.
- Scénario prudent: minimiser recettes, maximiser coûts.
- CapEx vs OpEx: ne pas confondre pour SaaS.
- Feedback loop: solde négatif → retravailler, pas ignorer.
- `state-tool.sh` pour tout accès état. Jamais de JSON à la main.
- Disclaimer: pédagogique, recommander validation par expert-comptable.

## Erreurs fréquentes (flag)

- Oublier le BFR ou le confondre avec la trésorerie de sécurité.
- Financer un besoin durable uniquement avec une ressource de court terme.
- Inscrire une subvention ou un prêt avant d'avoir vérifié les conditions.
- Sous-estimer le stock, les travaux, la communication de lancement ou les frais annexes.
- Construire le plan sans devis ni hypothèses vérifiables.
- Ne pas répercuter une modification dans le compte de résultat et le plan de trésorerie.
- Présenter un tableau équilibré sans vérifier la capacité réelle de remboursement.
- Figer les prévisions après le lancement alors que l'activité évolue.
- **Confondre CapEx et OpEx pour SaaS.**
- **Ne pas distinguer abonnement annuel (ressource différée) et mensuel.**

## Examples

### Given/When/Expect — initial avec TVA réel

- **Given** un créateur (investissements 25 000 € HT, TVA 20%, `tva_regime=reel`).
- **When** l'agent exécute le volet initial.
- **Expect** TVA déductible mois 1 = 5 000 € écrite via `state-tool.sh set variables.tva_deductible_mensuelle.0 5000`, améliorant la trésorerie du mois 1.

### Given/When/Expect — feedback loop

- **Given** une alerte `tresorerie_negative` mois 4 dans le state.
- **When** l'agent traite la feedback loop.
- **Expect** l'agent propose d'ajouter un apport de 3 000 €, met à jour `variables.apports` via `state-tool.sh set`, et signale à skill 3 de recalculer le plan de trésorerie.

### Given/When/Expect — saas CapEx/OpEx

- **Given** un SaaS (développement initial 30 000 € CapEx, cloud 500 €/mois OpEx).
- **When** l'agent évalue les besoins avec `projet.modele=saas`.
- **Expect** CapEx 30 000 € dans `investissements_ht`, OpEx 500 €/mois dans `saas_metrics.opex_mensuel`, distinction claire dans le tableau.

## Revision History

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-08-06 | Initial: plan financement initial + 3 ans + CapEx/OpEx SaaS + TVA déductible + feedback loop + state-tool. | elarif | elarif |