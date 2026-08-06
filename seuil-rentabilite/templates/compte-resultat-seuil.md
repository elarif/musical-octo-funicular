# Modèle — Compte de résultat et seuil de rentabilité

## Compte de résultat prévisionnel (N)

| Poste | Montant HT (€) |
|---|---|
| Chiffre d'affaires HT | {CA_HT} |
| - Charges variables | {CHARGES_VARIABLES} |
| = Marge sur coûts variables | {MARGE} |
| - Charges fixes | {CHARGES_FIXES} |
| = Résultat prévisionnel | {RESULTAT} |

## Calcul du seuil de rentabilité

| Élément | Valeur |
|---|---|
| Taux de marge sur coûts variables | {TAUX_MARGE} % |
| **Seuil de rentabilité (€)** | {SEUIL} |
| **Point mort (jours)** | {POINT_MORT} |
| Interprétation opérationnelle | {INTERPRETATION} |

## 3 scénarios

| Scénario | CA HT | Charges fixes | Charges variables | Seuil | Point mort |
|---|---|---|---|---|---|
| Optimiste | {CA_OPT} | {CF_OPT} | {CV_OPT} | {SEUIL_OPT} | {PM_OPT} |
| Nominal | {CA_NOM} | {CF_NOM} | {CV_NOM} | {SEUIL_NOM} | {PM_NOM} |
| Pessimiste | {CA_PES} | {CF_PES} | {CV_PES} | {SEUIL_PES} | {PM_PES} |