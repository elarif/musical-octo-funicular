---
name: previsions-financieres-demarrage
description: Déclencher quand l'utilisateur cherche par où commencer ses prévisions financières, la viabilité ou la faisabilité financière d'un projet de création d'entreprise, ou ses comptes prévisionnels. Orchestrateur méthodologique: détecte le modèle (commerce, service, production, SaaS) et le régime TVA, applique la méthode 3 étapes (lister flux → répartir → plan trésorerie), route vers les 5 questions de viabilité, et consolide une matrice des risques (JAMAIS de verdict go/no-go).
---

# Prévisions financières — démarrage

## Snapshot

Orchestrateur méthodologique: détecte `projet.modele` et `projet.tva_regime`, applique la méthode 3 étapes (lister entrées/sorties en vrac → répartir plan financement/compte résultat → porter dans plan trésorerie), route vers les 5 questions de viabilité (capitaux, recettes/charges, ventes minimales, trésorerie, pérennité 3 ans) en invoquant les skills 2, 3, 4, et consolide les alertes en une **matrice des risques** (pas de go/no-go). Écrit le contexte dans `projet-state.json` via `state-tool.sh`.

## Quick Reference

| Champ | Valeur |
|---|---|
| Audience | Agent accompagnant un créateur d'entreprise FR dans le démarrage de ses prévisions financières |
| Déclencheur | "par où commencer prévisionnel", "viabilité projet", "faisabilité financière", "comptes prévisionnels", "/previsions-demarrage" |
| Entrées | Contexte projet (activité, modèle, TVA, étude marché), `alertes[]` (depuis skills 2, 3, 4) |
| Sorties | `projet.modele`, `projet.tva_regime`, `projet.marche_etude`, matrice des risques (livrable) |
| Outil état | `state-tool.sh` (jamais de JSON écrit à la main) |
| Posture | Non-prescriptive: JAMAIS de go/no-go, seulement matrice des risques |

## Related Skills

| Skill | Relation | Rôle |
|---|---|---|
| `plan-financement-durable` | `downstream` + `feedback` | Invoqué pour Q1 (capitaux) et Q5 (pérennité 3 ans) |
| `tresorerie-bfr` | `downstream` | Invoqué pour Q4 (trésorerie mensuelle) |
| `seuil-rentabilite` | `downstream` + `feedback` | Invoqué pour Q3 (ventes minimales); reçoit feedback si CA < seuil |
| `business-plan-redaction` | `upstream` | Invoque ce skill pour la partie financière du BP |
| `executive-summary` | `none` | Separate Ways |
| `technical-writing` | `shared-kernel` | Co-maintient Document Metadata, Audience, Definitions |

## Document Metadata

| Champ | Valeur |
|---|---|
| Document ID | `SKILL-PFD-DEM-001` |
| Revision | 1 |
| Effective Date | 2026-08-06 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |

## Audience

- **Primary**: Agent accompagnant un créateur d'entreprise FR dans le démarrage de ses prévisions financières.
- **Secondary**: Maintainers of this skill.
- **Expertise level**: Intermediate — connaît les 5 questions de viabilité, la méthode 3 étapes.
- **What they already know**: Tenir une conversation de conseil en FR.
- **What they need to learn**: Détection modèle + TVA, routing, matrice des risques (pas go/no-go), `state-tool.sh`.
- **What they will do after reading**: Orchestrer les skills 2, 3, 4 et produire une matrice des risques.

## Purpose / Scope

**Purpose**: Orchestrateur méthodologique pour démarrer les prévisions financières et produire une matrice des risques.

**Scope covers**:
- Détection `projet.modele` (commerce, service, production, saas, digital) et `projet.tva_regime` (franchise, réel).
- Méthode 3 étapes (lister flux → répartir → plan trésorerie).
- 5 questions de viabilité (routing vers skills 2, 3, 4).
- Consolidation des `alertes[]` en matrice des risques.
- Posture non-prescriptive (pas de go/no-go).

**Scope does NOT cover**:
- Calculs chiffrés (délégués aux skills 2, 3, 4).
- Rédaction BP (skill 5), executive summary (skill 6).
- Conseil fiscal ou juridique.

## Definitions

Voir `_shared/bpifrance-finance-glossary.md`. Termes centraux: Matrice des risques, state-tool.sh, TVA, franchise en base.

## State Contract

- **Reads** (via `state-tool.sh get`): `projet.*`, `alertes[]` (consolidées depuis skills 2, 3, 4).
- **Writes** (via `state-tool.sh set`):
  - `projet.nom`
  - `projet.activite`
  - `projet.modele`
  - `projet.tva_regime`
  - `projet.marche_etude`

## Process

1. **Recueillir contexte projet** (une question à la fois): activité, **détection `projet.modele`** (commerce / service / production / saas / digital), **détection `projet.tva_regime`** (franchise ou réel), étude marché faite?.
2. **Écrire le contexte** via `state-tool.sh set` (projet.nom, projet.activite, projet.modele, projet.tva_regime, projet.marche_etude).
3. **Méthode 3 étapes** (article "par où commencer"):
   - Étape A: lister entrées/sorties argent en vrac (sans classer).
   - Étape B: répartir → plan financement (besoins durables) OU compte résultat (charges).
   - Étape C: porter dans plan trésorerie (décalages mensuels).
4. **Q1 capitaux lancement** → invoque skill 2 (`plan-financement-durable`, volet initial).
5. **Q2 recettes vs charges** → oriente vers compte de résultat (hors scope; indique prérequis, renvoie vers expert-comptable ou outil Bpifrance).
6. **Q3 ventes minimales rentabilité** → invoque skill 4 (`seuil-rentabilite`).
7. **Q4 trésorerie mensuelle** → invoque skill 3 (`tresorerie-bfr`).
8. **Q5 pérennité 3 ans** → invoque skill 2 (`plan-financement-durable`, volet 3 ans).
9. **Consolider `alertes[]`** issues des skills 2, 3, 4 (lectures du state via `state-tool.sh get alertes`).
10. **Produire la matrice des risques** — JAMAIS de go/no-go:
    - Pour chaque scénario (optimiste/nominal/pessimiste) et chaque question Q1-Q5, identifier: zone fragile, point de rupture, hypothèse à valider.
    - Output: tableau `risque | scénario(s) concerné(s) | gravité | action de retravail recommandée`.
    - Posture: l'agent identifie, l'entrepreneur décide. Aucun verdict binaire.

## Key Principles

- Une question à la fois.
- Scénario prudent: minimiser recettes, maximiser coûts (le pessimiste formalise cela).
- Démarche itérative: feedback loops via `alertes` dans le state JSON.
- **Non-prescription**: l'agent ne donne jamais un verdict go/no-go; il cartographie les risques et points de rupture.
- `state-tool.sh` pour tout accès état. Jamais de JSON à la main.
- Disclaimer: pédagogique, recommander validation par expert-comptable.

## Examples

### Given/When/Expect — orchestration complète

- **Given** un créateur de SaaS B2B (modèle saas, TVA réel, étude marché faite).
- **When** l'agent exécute le process.
- **Expect** `projet.modele=saas` et `projet.tva_regime=reel` écrits via `state-tool.sh`, routing vers skills 2, 3, 4, matrice des risques produite (pas de go/no-go).

### Given/When/Expect — matrice des risques avec alerte

- **Given** skill 3 a émis une alerte `tresorerie_negative` mois 4 et skill 4 une alerte `ca_sous_seuil` année 1.
- **When** l'agent consolide.
- **Expect** matrice des risques avec 2 lignes: "Trésorerie négative mois 4 | pessimiste | grave | retravailler le financement (skill 2)" et "CA sous seuil année 1 | nominal, pessimiste | grave | valider hypothèses de marché".

## Revision History

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-08-06 | Initial: orchestrateur + détection modèle/TVA + 5 questions + matrice des risques (no go/no-go) + state-tool. | elarif | elarif |