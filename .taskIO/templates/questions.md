# Gabarit de questions.json

Générer **une seule fois**. Ne garder que les questions dont la réponse change les tickets (périmètre, découpage, étapes, estimation). Jamais de question dont le PRD donne déjà la réponse. La question `methodology` est obligatoire.

```json
{
  "schemaVersion": "1.1",
  "questions": [
    {
      "id": "methodology",
      "question": "Comment développer ?",
      "why": "Adapte les « Étapes » de chaque ticket.",
      "choices": [
        { "id": "tdd", "label": "TDD", "pros": ["Qualité, régressions évitées"], "cons": ["Plus lent au démarrage"] },
        { "id": "bdd", "label": "BDD", "pros": ["Scénarios partagés avec le produit"], "cons": ["Outillage Gherkin"] },
        { "id": "spec-driven", "label": "Spec driven", "pros": ["Contrat clair"], "cons": ["Spec à maintenir"] },
        { "id": "tests-after", "label": "Tests après le code", "pros": ["Rapide"], "cons": ["Couverture moins fiable"] },
        { "id": "prototype-first", "label": "Prototype d'abord", "pros": ["Validation rapide"], "cons": ["Code jetable"] }
      ]
    }
  ]
}
```

`id` d'une question de méthode : un des `enums.methodology` de config.json. « Autre » est proposé en plus, avec texte libre.

Réponses : `answers.json`

```json
{
  "schemaVersion": "1.1",
  "answers": [{ "questionId": "methodology", "choice": "tdd", "text": null }],
  "validatedByHuman": false
}
```
La méthode du projet = la réponse à la question `methodology` (aucun champ séparé, donc aucune contradiction possible). `choice: null` + `text` = réponse libre. Une seule réponse par question. `validatedByHuman: true` seulement après le récapitulatif.
