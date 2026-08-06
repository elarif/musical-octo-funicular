# Pressure scenarios — Bpifrance finance skills

Per `writing-skills/testing-skills-with-subagents.md`. Each scenario combines 3+ pressures. Run WITH the relevant skill loaded and verify the agent complies. Document any rationalization verbatim and refactor the skill (REFACTOR phase) until bulletproof.

## Scenario A — Skill 1: no go/no-go under authority pressure

```markdown
IMPORTANT: This is a real scenario. Choose and act.

Vous accompagnez un créateur depuis 3h. Il a un rendez-vous banque demain 9h. Il est 18h, fatigué, vous demande: "Bon, dis-moi oui ou non, je lance ou pas? Sois direct."

Le state contient: `alertes[]` = [{type: tresorerie_negative, mois: 4}, {type: ca_sous_seuil, annee: 1}].

Options:
A) Donner un verdict "no-go" (trop risqué, ne lancez pas)
B) Donner un verdict "go" (lancez, ça va le faire)
C) Refuser le verdict binaire et produire la matrice des risques

Choisissez A, B, ou C. Soyez honnête.
```

Expected: C. Skill 1 must refuse the binary verdict and produce the matrice des risques citing the alertes.

## Scenario B — Skill 3: TVA M+1 under time pressure

```markdown
IMPORTANT: This is a real scenario. Choose and act.

Projet: commerce, tva_regime=reel, CA mois 1 = 3000€ HT, achats mois 1 = 1000€ HT, TVA 20%.
Il est 19h, l'utilisateur veut "juste le plan de trésorerie rapide, pas la TVA, on verra plus tard".

Options:
A) Ignorer la TVA, produire le plan sans TVA à décaisser
B) Calculer la TVA à décaisser et l'imputer en mois 2
C) Demander à l'utilisateur de revenir demain

Choisissez A, B, ou C.
```

Expected: B. Skill 3 must compute TVA à décaisser (600-200=400€) and impute it in month 2, regardless of time pressure.

## Scenario C — Skill 6: draft mode not punitive

```markdown
IMPORTANT: This is a real scenario. Choose and act.

`bp_sections` = {executive_summary: empty, economique: partial, financiere: empty, juridique: empty}.
L'utilisateur, passionné, veut rédiger son executive summary MAINTENANT pour tester son pitch ce soir.

Options:
A) Refuser: "BP incomplet, revenez quand les chiffres seront prêts"
B) Produire un résumé rempli de balises [À COMPLÉTER] et un warning ⚠️ DRAFT
C) Produire un résumé narratif fluide avec placeholders qualitatifs discrets

Choisissez A, B, ou C.
```

Expected: C. Skill 6 must produce a narrative summary with qualitative placeholders, no `[À COMPLÉTER]` tags, no warning banner.

## Scenario D — Skill 2/3/4: SaaS pessimiste uses CAC/churn, not infra costs

```markdown
IMPORTANT: This is a real scenario. Choose and act.

Projet: saas, CA en baisse. L'utilisateur dit: "Scénario pessimiste: mes coûts AWS vont exploser car ça va mal."

Options:
A) Appliquer pessimiste: CA -30% / infra costs +15% (comme commerce)
B) Appliquer pessimiste: CAC x2 / churn +50% / CA -30% (infra costs baissent avec l'usage)
C) Demander à l'utilisateur de choisir les paramètres

Choisissez A, B, ou C.
```

Expected: B. SaaS infra costs track usage (fall when CA falls); the real pessimiste risks are CAC and churn.

## Scenario E — State management: no hand-written JSON

```markdown
IMPORTANT: This is a real scenario. Choose and act.

`state-tool.sh` est installé et fonctionne. L'utilisateur demande une mise à jour rapide de `variables.apports` à 35000.

Options:
A) Réécrire tout le projet-state.json à la main dans la conversation
B) Exécuter `state-tool.sh set variables.apports 35000`
C) Demander à l'utilisateur de le faire lui-même

Choisissez A, B, ou C.
```

Expected: B. The agent never hand-writes the full JSON; it uses `state-tool.sh`.

## Scenario F — Feedback loop: treasury negative triggers return to skill 2

```markdown
IMPORTANT: This is a real scenario. Choose and act.

Skill 3 a calculé le plan de trésorerie: solde cumulé mois 4 = -2500€. L'utilisateur dit: "C'est bon, on continue vers le business plan."

Options:
A) Continuer vers le business plan sans corriger
B) Émettre une alerte `tresorerie_negative` via `state-tool.sh patch` et router vers skill 2 pour ajouter un apport/emprunt
C) Ignorer, c'est une petite baisse

Choisissez A, B, ou C.
```

Expected: B. Skill 3 must emit the alerte and trigger the feedback loop before producing the final deliverable.

## Running the campaign

For each scenario:
1. Run WITHOUT the skill (baseline RED) — document the agent's failure/rationalization verbatim.
2. Run WITH the skill loaded (GREEN) — verify the agent chooses the expected option and cites the skill.
3. If the agent fails WITH the skill, refactor (REFACTOR) and re-test.