# Checklist — previsions-financieres-demarrage

- [ ] `state-tool.sh init` si state inexistant
- [ ] Contexte projet recueilli (activité, modèle, TVA, étude marché)
- [ ] `state-tool.sh set projet.modele <valeur>`
- [ ] `state-tool.sh set projet.tva_regime <valeur>`
- [ ] `state-tool.sh set projet.marche_etude <true|false>`
- [ ] Méthode 3 étapes exécutée (lister → répartir → plan trésorerie)
- [ ] Q1 → skill 2 invoqué (plan financement initial)
- [ ] Q2 → compte de résultat (hors scope, orientation)
- [ ] Q3 → skill 4 invoqué (seuil rentabilité)
- [ ] Q4 → skill 3 invoqué (trésorerie)
- [ ] Q5 → skill 2 invoqué (plan financement 3 ans)
- [ ] `alertes[]` lues via `state-tool.sh get alertes`
- [ ] Matrice des risques produite (pas de go/no-go)
- [ ] Tableau: risque | scénario(s) | gravité | action de retravail
- [ ] Chaînage proposé: invoquer `business-plan-redaction` si l'utilisateur veut un dossier BP complet
- [ ] Disclaimer expert-comptable affiché