---
name: executive-summary
description: Déclencher quand l'utilisateur cherche à rédiger l'executive summary, le résumé opérationnel, le sommaire de gestion, ou le résumé de son business plan de création d'entreprise. Produit un résumé narratif 1-2 pages en 8 paragraphes, adapté au destinataire. Mode draft (BP incomplet: placeholders narratifs qualitatifs, pas de balises techniques) ou mode final (BP complet). Détecte le mode via `bp_sections` dans `projet-state.json`.
type: sub-skill
---

# Executive summary

## Snapshot

Produit un executive summary narratif 1-2 pages en 8 paragraphes, adapté au destinataire (investisseur, banque, partenaire, incubateur). Détecte le mode via `bp_sections` dans `projet-state.json` via `state-tool.sh`: **draft** (BP incomplet → placeholders narratifs qualitatifs, pas de balises « À COMPLÉTER », pas de warning banner) ou **final** (BP complet → résumé fidèle). Suit 6 conseils de rédaction.

## Quick Reference

| Champ | Valeur |
|---|---|
| Audience | Agent accompagnant un créateur d'entreprise FR dans la rédaction de l'executive summary |
| Déclencheur | "executive summary", "résumé opérationnel", "sommaire de gestion", "résumé business plan", "/exec-summary" |
| Entrées | `bp_sections.*`, `variables.*`, `saas_metrics.*`, `scenarios.*` via state-tool |
| Sorties | `bp_sections.executive_summary` → `draft` ou `final`, livrable 1-2 pages |
| Outil état | `state-tool.sh` (jamais de JSON écrit à la main) |
| Modes | draft (narratif, placeholders qualitatifs) / final (fidèle) |

## Related Skills

| Skill | Relation | Rôle |
|---|---|---|
| `business-plan-redaction` | `upstream` | Invoque ce skill pour la section 1 du BP |
| `technical-writing` | `shared-kernel` | Co-maintient Document Metadata, Audience, Definitions |
| `previsions-financieres-demarrage` | `downstream` | En mode draft, route vers ce skill si BP incomplet |
| `plan-financement-durable` | `downstream` | En mode draft, route vers ce skill |
| `tresorerie-bfr` | `downstream` | En mode draft, route vers ce skill |
| `seuil-rentabilite` | `downstream` | En mode draft, route vers ce skill |

## Document Metadata

| Champ | Valeur |
|---|---|
| Document ID | `SKILL-ES-001` |
| Revision | 1 |
| Effective Date | 2026-08-06 |
| Owner | Skills maintainer |
| Approver | Skills maintainer |
| Doc type | Skill reference |

## Audience

- **Primary**: Agent accompagnant un créateur d'entreprise FR dans la rédaction de l'executive summary.
- **Secondary**: Maintainers of this skill.
- **Expertise level**: Intermediate — connaît pitch, proposition de valeur, destinataires BP.
- **What they already know**: Tenir une conversation de conseil en FR.
- **What they need to learn**: Détection mode draft/final via `bp_sections`, placeholders narratifs (pas punitifs), `state-tool.sh`.
- **What they will do after reading**: Produire un executive summary draft ou final, narratif et fluide.

## Purpose / Scope

**Purpose**: Produire un executive summary narratif 1-2 pages, adapté au destinataire, en mode draft ou final.

**Scope covers**:
- Détection mode via `bp_sections` (draft si incomplet, final si complet).
- 6 conseils de rédaction.
- 8 paragraphes (créateur/équipe, projet, avantages concurrentiels, clientèle, stratégie commerciale, rentabilité, financement, entreprise dans 3 ans).
- Mode draft: placeholders narratifs qualitatifs, pas de balises techniques, pas de warning banner.
- Mode final: résumé fidèle du BP.
- Adaptation destinataire (investisseur, banque, partenaire, incubateur).

**Scope does NOT cover**:
- Calculs financiers (skills 1-4), rédaction complète BP (skill 5).
- Conseil fiscal ou juridique.

## Definitions

Voir `_shared/bpifrance-finance-glossary.md`. Termes centraux: Executive summary, Business plan, MRR, CAC.

## State Contract

- **Reads** (via `state-tool.sh get`): `bp_sections.*` (pour choisir draft/final), `variables.*`, `saas_metrics.*`, `scenarios.*`.
- **Writes** (via `state-tool.sh set`): `bp_sections.executive_summary` → `draft` ou `final`.

## Mode selection

- **Draft mode** (auto si `bp_sections` a un `empty` ou `partial`): produire un **résumé narratif** basé sur la vision, avec sections chiffrées en formulation qualitative discrète — PAS de flags « À COMPLÉTER », PAS de warning banner. Le draft se lit comme un pitch fluide, pas un rapport d'erreur.
- **Final mode** (`bp_sections` tous `complete`): résumé fidèle 8 paragraphes reflétant le BP complété.

## Process

1. **Lire `bp_sections`** via `state-tool.sh get bp_sections` pour détecter le mode. L'agent n'annonce PAS le mode à l'utilisateur sauf si demandé — il produit simplement un résumé narratif cohérent.
2. **Règles de base**:
   - Max 2 pages.
   - Début du dossier BP.
   - Rédigé en dernier (final) ou avec placeholders narratifs (draft).
3. **6 conseils rédaction**:
   - Phrase d'accroche = proposition de valeur unique (marché, lacune, réponse).
   - Choisir chaque mot, exposer l'essentiel.
   - Montrer créateur préparé/maîtrise sujet.
   - Idée bien définie dès validation → clarté/précision/concision.
   - Ne pas recopier passages BP — formules concises convaincantes.
   - Adapter le plan selon interlocuteur (banquier/investisseur/incubateur).
4. **8 paragraphes** (structure proposée):
   - 1. Créateur/équipe (complémentarité, dream team ou ressources mobilisées si solo).
   - 2. Projet (vision, caractéristiques produit/service, valeurs, proposition valeur unique, bénéfices clients).
   - 3. Avantages concurrentiels (attractif, crédible, différent, positionnement match besoins).
   - 4. Clientèle (connaissance fine comportements achat, personas, adéquation produit-marché).
   - 5. Stratégie commerciale (objectifs vente atteints via moyens/actions, canaux cohérents habitudes personas).
   - 6. Rentabilité (fiable, CA réaliste - charges proportionnelles = bénéfice; **3 scénarios mentionnés**).
   - 7. Financement (investissements identifiés, apports personnels rassurent, rôles financeurs).
   - 8. Entreprise dans 3 ans (perspectives: gamme, parts marché, recrutements).
5. **Écrire le mode** dans le state: `state-tool.sh set bp_sections.executive_summary draft` ou `final`.

### Draft-mode specifics

Sections dont `bp_sections.*` n'est pas `complete` sont rédigées en **narration qualitative**, pas en flags d'erreur. Le livrable se lit comme un pitch confiant avec placeholders gracieux, pas un diagnostic de compilateur.

Exemples de phrasing qualitatif pour sections incomplètes:

- **Rentabilité (chiffrée non consolidée)**: "Notre modèle financier, en cours de consolidation, vise une rentabilité rapide à travers [proposition de valeur]. Les projections chiffrées seront intégrées après finalisation du plan financier."
- **Financement (montant non arrêté)**: "Le projet recherche un financement adapté à [postes principaux], dont la structure est en cours de définition avec nos partenaires."
- **Clientèle (étude marché partielle)**: "Nos premiers retours terrain confirment l'adéquation produit-marché; l'étude de marché est en cours d'approfondissement."

Règles draft mode:
- **Pas de warning banner** en tête du livrable (pas de `⚠️ DRAFT — …`).
- **Pas de tags « À COMPLÉTER »** dans le corps.
- L'agent n'annonce PAS le mode sauf si demandé.
- Si l'utilisateur demande "qu'est-ce qui manque?", l'agent répond séparément (PAS dans le livrable) en listant les skills à compléter, lu depuis `bp_sections`.

## Key Principles

- Une question à la fois.
- Mode draft = narratif et fluide, pas punitif.
- `state-tool.sh` pour tout accès état. Jamais de JSON à la main.
- Disclaimer: pédagogique, recommander validation par expert-comptable.

## Examples

### Given/When/Expect — draft mode narratif

- **Given** `bp_sections` = `{executive_summary: empty, economique: partial, financiere: empty, juridique: empty}`.
- **When** l'agent produit l'executive summary.
- **Expect** résumé narratif fluide, section rentabilité en phrasing qualitative ("Notre modèle financier, en cours de consolidation…"), PAS de « À COMPLÉTER », PAS de warning banner, `bp_sections.executive_summary` → `draft`.

### Given/When/Expect — final mode

- **Given** `bp_sections` tous `complete`, `variables.seuil_rentabilite.0` = 46 667.
- **When** l'agent produit l'executive summary.
- **Expect** 8 paragraphes complets, section rentabilité avec chiffres réels, `bp_sections.executive_summary` → `final`.

## Revision History

| Rev | Date | Description | Author | Approver |
|---|---|---|---|---|
| 1 | 2026-08-06 | Initial: executive summary draft/final + placeholders narratifs (pas punitifs) + state-tool. | elarif | elarif |
| 2 | 2026-08-26 | Sweep typologie IDDD : ajout frontmatter type, réordonnancement Skills associés par catégorie selon _shared/SKILL-ARCH.md | Skills maintainer | Skills maintainer |