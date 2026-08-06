---
name: business-plan-redaction
description: Déclencher quand l'utilisateur cherche à faire ou rédiger son business plan, son plan d'affaires, ou la structure de son business plan de création d'entreprise. Structure le BP en 8 sections (executive summary, équipe, projet, économique, financière, juridique, sommaire, documentaire), adapte le ton au destinataire, invoque les skills 1-4 pour la partie financière et le skill 6 pour l'executive summary, applique les caractéristiques d'un bon BP et évite les 11 erreurs courantes.
---

# Business plan — rédaction

## Snapshot

Structure le business plan en 8 sections, adapte le ton au destinataire (investisseur, banque, partenaire, incubateur), invoque les skills 1-4 pour la partie financière et le skill 6 pour l'executive summary. Lit `alertes[]` via `state-tool.sh` et retravaille la partie financière si alertes non vides. Applique les caractéristiques d'un bon BP (soigné, concis, complet, clair, structuré, précis, vendeur mais crédible) et évite les 11 erreurs courantes.

## Quick Reference

| Champ | Valeur |
|---|---|
| Audience | Agent accompagnant un créateur d'entreprise FR dans la rédaction de son business plan |
| Déclencheur | "faire business plan", "rédiger business plan", "plan d'affaires", "structure business plan", "/business-plan" |
| Entrées | `projet.*`, `variables.*`, `saas_metrics.*`, `scenarios.*`, `alertes[]`, `bp_sections.*` via state-tool |
| Sorties | `bp_sections.economique`, `financiere`, `juridique` → `complete` |
| Outil état | `state-tool.sh` (jamais de JSON écrit à la main) |
| Sections | 8 (executive summary, équipe, projet, économique, financière, juridique, sommaire, documentaire) |

## Related Skills

| Skill | Relation | Rôle |
|---|---|---|
| `previsions-financieres-demarrage` | `downstream` + `upstream` (chaînage) | Invoqué pour la partie financière (orchestrateur); ce skill le propose en pré-check si le state est vide |
| `plan-financement-durable` | `downstream` | Invoqué pour la partie financière |
| `tresorerie-bfr` | `downstream` | Invoqué pour la partie financière |
| `seuil-rentabilite` | `downstream` | Invoqué pour la partie financière |
| `executive-summary` | `downstream` | Invoqué pour la section 1 (rédigé en dernier) |
| `technical-writing` | `shared-kernel` | Co-maintient Document Metadata, Audience, Definitions |

## Document Metadata

| Champ | Valeur |
|---|---|
| Document ID | `SKILL-BPR-001` |
| Revision | 2 |
| Effective Date | 2026-08-06 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |

## Audience

- **Primary**: Agent accompagnant un créateur d'entreprise FR dans la rédaction de son business plan.
- **Secondary**: Maintainers of this skill.
- **Expertise level**: Intermediate — connaît la structure d'un BP, les destinataires.
- **What they already know**: Tenir une conversation de conseil en FR.
- **What they need to learn**: 8 sections, adaptation destinataire, 11 erreurs, `state-tool.sh`, alertes.
- **What they will do after reading**: Produire un BP structuré 8 sections en invoquant les skills 1-4 et 6.

## Purpose / Scope

**Purpose**: Structurer et rédiger un business plan de création d'entreprise en 8 sections.

**Scope covers**:
- Définition destinataire (adapte le ton).
- 8 sections (executive summary, équipe, projet, économique, financière, juridique, sommaire, documentaire).
- Invocation skills 1-4 (partie financière) et skill 6 (executive summary).
- Lecture `alertes[]` → retravail partie financière si non vides.
- Caractéristiques d'un bon BP.
- 11 erreurs courantes à éviter.
- Timing de rédaction.

**Scope does NOT cover**:
- Calculs financiers (skills 1-4), executive summary (skill 6).
- Conseil fiscal ou juridique.

## Definitions

Voir `_shared/bpifrance-finance-glossary.md`. Termes centraux: Business plan, Executive summary, Business model, MRR, CAC.

## State Contract

- **Reads** (via `state-tool.sh get`): `projet.*`, `variables.*`, `saas_metrics.*`, `scenarios.*`, `alertes[]`, `bp_sections.*`.
- **Writes** (via `state-tool.sh set`): `bp_sections.economique`, `bp_sections.financiere`, `bp_sections.juridique` → `complete` (après invocation des skills).

## Process

0. **Pré-check prévisions financières**: lire `projet.modele` via `state-tool.sh get projet.modele`. Si vide ou state inexistant (l'utilisateur arrive directement à la rédaction du BP sans avoir fait ses prévisions), proposer d'invoquer `previsions-financieres-demarrage` (skill 1) d'abord pour peupler `projet.*`, `variables.*` et résoudre les `alertes[]`. Le BP peut être rédigé en mode draft (sections chiffrées en narration qualitative) même sans prévisions complètes, mais la partie financière sera plus solide après skill 1. L'agent propose ce chaînage mais ne l'impose pas.
1. **Définir destinataire** (adapte le ton):
   - Investisseur → rentabilité, scalabilité, ROI.
   - Banque → solidité financière, capacité remboursement, gestion risques.
   - Partenaire stratégique → positionnement, synergies, développement.
   - Incubateur/jury → innovation, cohérence projet.
2. **Structurer 8 sections** (logique Bpifrance):
   - 1. Executive summary → renvoie skill 6 (rédigé en dernier; skill 6 gère draft/final selon `bp_sections`).
   - 2. Vous et votre équipe (CV, complémentarité).
   - 3. Présentation générale projet (genèse, motivations, objectifs, atouts).
   - 4. Partie économique: produits/services, étude marché, stratégie commerciale, estimation CA, moyens, business model. **Inclure `projet.modele` et métriques SaaS si applicable**.
   - 5. Partie financière → invoque skills 1-4 (plan financement, compte résultat, trésorerie, seuil rentabilité, plan financement 3 ans, annuités crédit). **Lecture du state JSON: si `alertes` non vides, retravailler avant de figer la partie financière**.
   - 6. Partie juridique (régime, répartition capital/pouvoirs).
   - 7. Sommaire.
   - 8. Partie documentaire (pièces justificatives, dossier séparé).
3. **Appliquer caractéristiques BP**:
   - Soigné, concis (10-30 pages hors annexes), complet, rédaction claire (sans jargon), structure logique, infos précises (sources citées), ton vendeur mais crédible.
4. **Éviter 11 erreurs** (checklist anti-erreurs):
   - Sous-estimer besoins financement | sous-évaluer coûts développement | pas personnaliser | omettre prévisions vente détaillées | pas plan RH | négliger différenciation | pas preuve concept | pas scénarios alternatifs | oublier PI | négliger réglementation | skip relecture.
5. **Timing**: rédiger après définition produit/marché/modèle éco, AVANT financement/immatriculation.
6. **Mettre à jour `bp_sections`** via `state-tool.sh set` après chaque section complétée.

## Key Principles

- Une question à la fois.
- Ton adapté au destinataire.
- Partie financière retravaillée si `alertes[]` non vides.
- `state-tool.sh` pour tout accès état. Jamais de JSON à la main.
- Disclaimer: pédagogique, recommander validation par expert-comptable.

## Examples

### Given/When/Expect — BP complet

- **Given** un créateur SaaS avec `projet.modele=saas`, `alertes[]` vide, `bp_sections` tous `empty`.
- **When** l'agent exécute le process.
- **Expect** 8 sections produites, skills 1-4 invoqués pour section 5, skill 6 invoqué pour section 1 (final mode car `bp_sections` complétés), `bp_sections.*` → `complete`.

### Given/When/Expect — BP avec alertes

- **Given** `alertes[]` contient une `tresorerie_negative` mois 4.
- **When** l'agent atteint la section 5 (partie financière).
- **Expect** l'agent retravaille le financement (skill 2 feedback loop) avant de figer la section 5, puis `bp_sections.financiere` → `complete`.

## Revision History

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-08-06 | Initial: business plan 8 sections + adaptation destinataire + 11 erreurs + alertes + state-tool. | elarif | elarif |
| 2 | 2026-08-06 | Pré-check (étape 0) proposant `previsions-financieres-demarrage` si state vide + Related Skills mis à jour (chaînage bidirectionnel). | elarif | elarif |