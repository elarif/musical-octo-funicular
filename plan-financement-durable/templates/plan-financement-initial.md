# Modèle — Plan de financement initial (jour zéro)

| Besoins durables | Montant (€) | | Ressources durables | Montant (€) |
|---|---|---|---|---|
| Investissements HT (CapEx) | {INV_HT} | | Fonds propres (apports, comptes courants) | {FONDS_PROPRES} |
| Trésorerie de sécurité | {TRESO_SEC} | | Emprunts (bancaires, prêts d'honneur, microcrédit) | {EMPRUNTS} |
| BFR | {BFR} | | Aides / subventions | {AIDES} |
| **Total besoins** | {TOTAL_B} | | **Total ressources** | {TOTAL_R} |

> Règle: ressources ≥ besoins + marge sécurité. Fonds propres ≥ emprunts LMT.
> Si `tva_regime=reel`: TVA déductible sur investissements initiaux = {TVA_DED} (récupérée en mois 1).
> Si `projet.modele=saas`: distinguer CapEx (investissements durables) et OpEx (cloud, API — hors plan de financement, dans compte de résultat).