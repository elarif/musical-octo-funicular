# Encodage rison pour URLs Kibana Discover

## Pourquoi rison
Kibana Discover encode l'état de la vue (index, query, filtres, timeRange, colonnes) dans le hash de l'URL (`#/view?_a=<rison>`). Rison est un format compact conçu pour les URLs.

## Pièges connus (corrigés par kibana-url.mjs)

1. **Rison écrit à la main** → erreurs d'échappement (`(`, `)`, `,`, `:` mal gérés). Solution : utiliser la lib `rison` npm, jamais de concaténation manuelle.
2. **Caractère `#` dans le rison** → casse le hash URL. L'encodeur valide l'absence de `#` et rejette si présent.
3. **Round-trip** : l'encodeur décode le rison produit pour vérifier qu'il redonne l'état attendu. Si le round-trip échoue, erreur au lieu d'URL cassée.

## Schéma d'état Discover (Kibana 8.x)

```js
{
  indexPattern: { title: 'apm-*' },
  query: { query: 'service.name: "svc" AND event.outcome: failure', language: 'kuery' },
  filters: [],
  timeRange: { from: '2026-07-18T10:00:00.000Z', to: '2026-07-18T11:00:00.000Z' },
  columns: ['trace.id', 'service.name', 'transaction.duration.us', 'event.outcome']
}
```

## Fallback

Si l'encodage échoue, `kibana-url.mjs` renvoie une URL Discover avec seulement le timeRange (`?_g=(time:(from,to))`) + la requête KQL en clair sur stderr, pour collage manuel. Mieux vaut une URL partielle correcte qu'une URL complète cassée.

## Validation

La capture Playwright (Phase 5) est le test de vérité : si Discover affiche les bons résultats, l'URL est correcte. Si la capture montre une erreur Kibana ou 0 résultats inattendus, l'encodeur est suspecté → régénérer avec le fallback.