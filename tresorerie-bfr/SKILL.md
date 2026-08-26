---
name: tresorerie-bfr
description: Déclencher quand l'utilisateur cherche le plan de trésorerie, le BFR (besoin en fonds de roulement), la trésorerie mensuelle, ou veut analyser un décalage de paiement d'un projet de création d'entreprise (commerce, service, production ou SaaS/digital). Calcule le BFR selon le modèle, construit le plan de trésorerie 12 mois avec TVA à décaisser en M+1, détecte les soldes négatifs et déclenche une feedback loop vers le plan de financement.
type: sub-skill
---

# Trésorerie et BFR

## Snapshot

Calcule le BFR (formule multi-modèle: commerce, service, SaaS) et construit le plan de trésorerie mensuel sur 12 mois en intégrant la TVA à décaisser (régime réel: imputée en mois M+1; franchise: zéro). Détecte les soldes négatifs et émet une alerte dans `projet-state.json` via `state-tool.sh` pour déclencher une feedback loop vers `plan-financement-durable`. Génère 3 scénarios avec paramètres par modèle.

## Quick Reference

| Champ | Valeur |
|---|---|
| Audience | Agent accompagnant un créateur d'entreprise FR dans le calcul du BFR et du plan de trésorerie |
| Déclencheur | "plan trésorerie", "BFR", "besoin fonds roulement", "trésorerie mensuelle", "décalage paiement", "/tresorerie-bfr" |
| Entrées | `projet.modele`, `projet.tva_regime`, `variables.apports`, `variables.emprunts`, `variables.ca_mensuel`, `variables.tva_deductible_mensuelle` (mois 1), `saas_metrics.*` |
| Sorties | `variables.bfr[3]`, `tresorerie_solde[12]`, `tresorerie_cumul[12]`, `tva_*_mensuelle[12]`, `alertes[]`, `scenarios.*` |
| Outil état | `state-tool.sh` (jamais de JSON écrit à la main) |
| Feedback loop | Solde négatif → alerte → `plan-financement-durable` (ajouter apport/emprunt) → recalcul |

## Related Skills

| Skill | Relation | Rôle |
|---|---|---|
| `previsions-financieres-demarrage` | `upstream` | Orchestrateur qui invoque ce skill pour Q4 (trésorerie mensuelle) |
| `business-plan-redaction` | `upstream` | Invoque ce skill pour la partie financière du BP |
| `technical-writing` | `shared-kernel` | Co-maintient Document Metadata, Audience, Definitions |
| `plan-financement-durable` | `downstream` + `feedback` | Reçoit le BFR calculé ici; reçoit les feedback loops (solde négatif → ajouter apport/emprunt) |
| `executive-summary` | `downstream` | Consomme les données de trésorerie en mode final |
| `seuil-rentabilite` | `none` | Separate Ways |

## Document Metadata

| Champ | Valeur |
|---|---|
| Document ID | `SKILL-TB-001` |
| Revision | 1 |
| Effective Date | 2026-08-06 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |

## Audience

- **Primary**: Agent accompagnant un créateur d'entreprise FR dans le calcul du BFR et du plan de trésorerie.
- **Secondary**: Maintainers of this skill.
- **Expertise level**: Intermediate — connaît BFR, créances/dettes, TVA.
- **What they already know**: Tenir une conversation de conseil en FR.
- **What they need to learn**: BFR multi-modèle (SaaS: revenus différés), TVA à décaisser en M+1, feedback loop, `state-tool.sh`.
- **What they will do after reading**: Calculer BFR + plan trésorerie 12 mois × 3 scénarios, gérer la TVA, émettre alertes.

## Purpose / Scope

**Purpose**: Calculer le BFR (multi-modèle) et construire le plan de trésorerie 12 mois avec TVA, détecter les soldes négatifs, déclencher une feedback loop.

**Scope covers**:
- BFR commerce/production: `stocks + créances clients (TTC) - dettes fournisseurs (TTC)`.
- BFR service: `travaux en cours + créances - acomptes clients`.
- BFR saas/digital: `revenus différés (abonnements annuels = ressource négative) + créances - dettes (incluant infra cloud prépayée)`.
- Plan de trésorerie 12 mois (TTC, imputation au mois de l'opération).
- TVA à décaisser (réel: imputée en M+1; franchise: zéro).
- Détection soldes négatifs → alerte → feedback loop vers skill 2.
- Stress-test 3 scénarios (paramètres par modèle).
- Ratios: rotation stocks, crédit clients, crédit fournisseurs.

**Scope does NOT cover**:
- Plan de financement (skill 2), seuil de rentabilité (skill 4), rédaction BP (skill 5).
- Conseil fiscal ou juridique.

## Definitions

Voir `_shared/bpifrance-finance-glossary.md`. Termes centraux: BFR, TVA collectée, TVA déductible, TVA à décaisser, Franchise en base, MRR, Churn, CapEx, OpEx.

## State Contract

- **Reads** (via `state-tool.sh get`): `projet.modele`, `projet.tva_regime`, `variables.apports`, `variables.emprunts`, `variables.ca_mensuel`, `variables.tva_deductible_mensuelle.0` (mois 1, depuis skill 2), `saas_metrics.*` (si saas).
- **Writes** (via `state-tool.sh set` / `patch`):
  - `variables.bfr` (array [3])
  - `variables.tva_collectee_mensuelle` (array [12])
  - `variables.tva_deductible_mensuelle` (mois 2-12; mois 1 déjà par skill 2)
  - `variables.tva_a_decaisser_mensuelle` (array [12])
  - `variables.tresorerie_solde` (array [12])
  - `variables.tresorerie_cumul` (array [12])
  - `scenarios.*`
  - `alertes[]` (ajout via `patch` si solde négatif)

## Process

### Volet BFR — multi-modèle

1. Lire `projet.modele` via `state-tool.sh get projet.modele`.
2. Branch:
   - **commerce/production**: `BFR = stocks + créances clients (TTC) - dettes fournisseurs (TTC)`.
   - **service**: `BFR = travaux en cours + créances - acomptes clients`.
   - **saas/digital**: pas de stocks physiques. `BFR = revenus différés (abonnements annuels payés d'avance = ressource, valeur négative) + créances clients - dettes fournisseurs (incluant infra cloud prépayée)`. Populer `saas_metrics` (MRR/ARR/CAC/LTV/churn) si non déjà fait.
3. Interpréter: BFR >0 (besoin financement) ou <0 (ressource, idéal ex: grande distrib ou SaaS avec abonnements annuels d'avance).
4. Optimiser: réduire rotation stocks (ou raccourcir cycle de vente pour SaaS), raccourcir crédit clients, allonger crédit fournisseurs.
5. Ratios: rotation stocks, crédit clients (créances/CA TTC × 365), crédit fournisseurs (dettes/consommation TTC × 365).

### Volet plan de trésorerie

1. Construire tableau 12 mois: solde début + encaissements (exploitation/hors exploitation) - décaissements (exploitation/hors exploitation) = solde fin + cumul.
2. TTC pour opérations assujetties TVA.
3. Imputer entrée/sortie au mois où elle se produit (achat janvier payable mars → mars).
4. **TVA à décaisser**: si `projet.tva_regime == "reel"`:
   - Calculer `tva_collectee_mensuelle[m]` depuis le CA TTC du mois m.
   - Calculer `tva_deductible_mensuelle[m]` depuis les achats TTC du mois m (mois 1 déjà par skill 2).
   - Calculer `tva_a_decaisser_mensuelle[m] = tva_collectee[m-1] - tva_deductible[m-1]` et **l'imputer comme décaissement du mois m** (TVA encaissée en m-1 reversée en m).
   - Si `projet.tva_regime == "franchise"`: tous les arrays TVA à zéro, pas de décaissement — mais CA et achats restent TTC dans le plan (l'entrepreneur ne récupère pas la TVA, c'est un coût réel).
5. Détecter soldes négatifs → **`state-tool.sh patch`** ajoute `{type: "tresorerie_negative", mois_ou_annee: <mois>, source_skill: "tresorerie-bfr", action: "feedback-loop → plan-financement-durable"}` → déclencher feedback loop vers skill 2 (ajouter apport/emprunt) AVANT de produire le livrable final.
6. Recalculer après résolution de l'alerte (skill 2 a mis à jour apports/emprunts via `state-tool.sh`).

### Stress-test (paramètres par modèle)

| Scénario | commerce / production / service | saas / digital |
|---|---|---|
| Optimiste | CA +20% / coûts -10% | CA +50% / infra costs +40% / churn -30% |
| Nominal | hypothèses de base | hypothèses de base |
| Pessimiste | CA -30% 6 premiers mois / coûts +15% | **CAC x2 / churn +50% / CA -30%** (infra costs baissent avec l'usage) |

Persister dans `scenarios.*` via `state-tool.sh`.

## Key Principles

- Une question à la fois.
- Scénario prudent: minimiser recettes, maximiser coûts.
- TVA à décaisser = piège mortel pour les jeunes entreprises — toujours l'imputer en M+1.
- Feedback loop: solde négatif → retravailler le financement, pas ignorer.
- `state-tool.sh` pour tout accès état. Jamais de JSON à la main.
- Disclaimer: pédagogique, recommander validation par expert-comptable.

## Examples

### Given/When/Expect — commerce avec TVA réel

- **Given** un créateur (CA mensuel 3 000 € HT mois 1, achats 1 000 € HT, TVA 20%, apport 30 000 €, emprunt 20 000 €).
- **When** l'agent exécute le process avec `projet.tva_regime=reel`.
- **Expect** TVA collectée mois 1 = 600 €, TVA déductible mois 1 = 200 € (hors investissements), TVA à décaisser mois 2 = 400 € imputée en décaissement du mois 2.

### Given/When/Expect — saas avec abonnements annuels

- **Given** un SaaS (50 abonnés à 50 €/mois, 10 abonnements annuels prépayés à 600 €).
- **When** l'agent exécute le process avec `projet.modele=saas`.
- **Expect** BFR négatif (revenus différés = ressource), `saas_metrics.mrr` = 2 500 €, interprétation "BFR négatif = ressource de financement".

### Given/When/Expect — feedback loop

- **Given** un plan de trésorerie avec solde cumulé mois 4 = -2 500 €.
- **When** l'agent détecte le solde négatif.
- **Expect** `state-tool.sh patch` ajoute une alerte `tresorerie_negative` mois 4, l'agent route vers `plan-financement-durable` pour ajouter un apport ou un emprunt, puis recalcule.

## Revision History

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-08-06 | Initial: BFR multi-modèle + plan trésorerie 12 mois + TVA M+1 + feedback loop + state-tool. | elarif | elarif |
| 2 | 2026-08-26 | Sweep typologie IDDD : ajout frontmatter type, réordonnancement Skills associés par catégorie selon _shared/SKILL-ARCH.md | Skills maintainer | Skills maintainer |