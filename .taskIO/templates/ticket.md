# Gabarit d'un ticket (champs de tickets.draft.json)

Les clés sont fixes et toutes présentes (`null` / `[]` si vide). Ne rien ajouter.

```json
{
  "ref": "api-lancer-suivre-sse",
  "title": "API publique v1 : lancer, suivre (SSE), rapport",
  "origin": "PRD · section Fonctionnalités",
  "contexte": "Pourquoi ce ticket existe.",
  "perimetre": ["POST /v1/campaigns (Idempotency-Key)."],
  "etapes": ["Tests rouges : …", "Implémenter …", "Vérifier / déployer."],
  "doneWhen": ["ref-d-un-autre-ticket"],
  "followUps": [{ "ref": "api-webhooks", "title": "Webhooks sortants" }],
  "status": "todo",
  "priority": "high",
  "assignee": null,
  "labels": ["api"],
  "project": "API publique v1",
  "estimate": { "value": 3 },
  "parent": null,
  "links": [{ "url": "https://www.figma.com/design/…", "title": "Maquette" }],
  "attachments": [{ "path": "prd/maquette.png", "title": "Maquette écran liste" }],
  "milestone": "m1-socle"
}
```

- `parent` : `ref` d'un autre ticket pour une sous-issue (un livrable qui fait partie d'un plus gros), sinon `null`. Ce n'est pas une dépendance : ajoute `doneWhen` si l'ordre compte aussi.
- `links` : URLs citées par le PRD (maquette, doc externe) utiles à ce ticket.
- `milestone` : `ref` d'un jalon de `milestones` (voir plus bas), sinon `null`. Un ticket avec jalon a `project: null` : il appartient à l'epic du lot.
- `attachments` : fichiers du dossier `.taskIO/` (ex. `prd/…`) utiles à ce ticket ; `path` relatif à `.taskIO/`, sans `..`. Ne cite que des fichiers qui existent.

Fichier complet :

```json
{
  "schemaVersion": "1.1",
  "methodology": "tdd",
  "estimate": { "value": 12, "justification": "Une phrase." },
  "epic": { "name": "E01 — API publique v1", "summary": "Une phrase (255 car. max).", "description": "# Objectif\n…" },
  "milestones": [
    { "ref": "m1-socle", "name": "M1 — Socle", "description": "Ce qui est livré à ce jalon.", "targetDate": null },
    { "ref": "m2-api", "name": "M2 — API", "description": "…", "targetDate": null }
  ],
  "tickets": [ ],
  "documents": [
    { "ref": "contrat-api", "title": "Contrat d'API", "content": "# Markdown…", "attachTo": "ticket:api-lancer-suivre-sse" }
  ]
}
```

`epic` : l'epic du lot (un par PRD, créé dans fluent-tickets s'il manque), `null` pour n'en créer aucun. `milestones` : jalons **dans l'ordre de livraison** (`[]` si inutiles), chacun avec au moins un ticket ; `targetDate` `AAAA-MM-JJ` ou `null` (ne jamais inventer une date que le PRD ne donne pas).

`documents` (`[]` si aucun) : texte Markdown de référence qui ne tient pas dans un ticket (contrat d'API, glossaire, décisions). `attachTo` : `"ticket:<ref>"`, `"epic"` (l'epic de `config.json`) ou `"project"`.
