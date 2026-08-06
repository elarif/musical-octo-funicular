# Modèle — Plan de trésorerie 12 mois

| Mois | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Solde début | {S0} | {S1} | {S2} | {S3} | {S4} | {S5} | {S6} | {S7} | {S8} | {S9} | {S10} | {S11} |
| Encaissements exploitation (ventes TTC) | {E1} | {E2} | {E3} | {E4} | {E5} | {E6} | {E7} | {E8} | {E9} | {E10} | {E11} | {E12} |
| Encaissements hors exploitation (apports, emprunts) | {HE1} | {HE2} | {HE3} | {HE4} | {HE5} | {HE6} | {HE7} | {HE8} | {HE9} | {HE10} | {HE11} | {HE12} |
| Décaissements exploitation (achats, salaires, charges) | {D1} | {D2} | {D3} | {D4} | {D5} | {D6} | {D7} | {D8} | {D9} | {D10} | {D11} | {D12} |
| **TVA à décaisser (M+1)** | {T1} | {T2} | {T3} | {T4} | {T5} | {T6} | {T7} | {T8} | {T9} | {T10} | {T11} | {T12} |
| Décaissements hors exploitation (investissements) | {DHE1} | {DHE2} | {DHE3} | {DHE4} | {DHE5} | {DHE6} | {DHE7} | {DHE8} | {DHE9} | {DHE10} | {DHE11} | {DHE12} |
| Solde fin de mois | {SF1} | {SF2} | {SF3} | {SF4} | {SF5} | {SF6} | {SF7} | {SF8} | {SF9} | {SF10} | {SF11} | {SF12} |
| Solde cumulé | {SC1} | {SC2} | {SC3} | {SC4} | {SC5} | {SC6} | {SC7} | {SC8} | {SC9} | {SC10} | {SC11} | {SC12} |

> Si `tva_regime=franchise`: ligne TVA à décaisser = 0 sur tous les mois.

## BFR

| Élément | Montant (€) |
|---|---|
| Stocks moyens | {STOCKS} |
| Créances clients (TTC) | {CREANCES} |
| Dettes fournisseurs (TTC) | {DETTES} |
| **BFR** | {BFR} |

## 3 scénarios (solde cumulé mois 12)

| Scénario | Solde cumulé M12 |
|---|---|
| Optimiste | {SC12_OPT} |
| Nominal | {SC12_NOM} |
| Pessimiste | {SC12_PES} |