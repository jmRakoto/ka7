---
name: taskio
description: "Règles taskIO : transformer un PRD validé en tickets JSON (découpage, format, déterminisme). À appliquer pour toute commande /taskio.*"
---
# taskIO — règles

taskIO intervient **après** la validation du PRD. Il ne réécrit jamais le PRD. Tu es le LLM : tu écris uniquement du **contenu** ; `npx taskio …` fait tout ce qui est déterministe (parse, validate, assemble, export). Ne fabrique ni n'édite jamais le JSON final à la main (y compris `validatedByHuman` : utilise `npx taskio approve`).

Langue : français (PRD, questions, tickets).

## Fichiers (chemins fixes)

`.taskIO/config.json` (enums, seuils) · `.taskIO/prd/` · `.taskIO/templates/` · `.taskIO/runs/<slug>/v<n>/` : `prd.normalized.md`, `meta.json`, `questions.json`, `answers.json`, `tickets.draft.json`, `tickets.json`, `revisions/r<n>/{feedback.json,proposal.json,diff.md,tickets.json}`, `export/linear.json`, `export/fluent-tickets.json` (plan MCP) et `export/fluent-tickets.map.json` (clés, fichiers et documents poussés, écrit par `npx taskio push` uniquement).

Lis toujours `.taskIO/config.json` : les valeurs de `status`, `priority`, `labels`, `methodology` viennent **exclusivement** de ses listes.

## Découpage : le moins de tickets possible

- Un ticket = un résultat livrable et vérifiable, jamais une micro-tâche.
- Si le travail tient dans 1-2 tickets, il tient dans 1-2 tickets.
- Infra / initialisation : 1 ticket, 2 maximum (elle bloque tout).
- Fusionne ce qui se fait dans le même contexte, par la même personne, sans validation intermédiaire. Pas de ticket « tests », « doc » ou « revue » séparé : ce sont des étapes.
- Dépendance (`doneWhen`) uniquement si vraiment bloquante ; préfère des tickets parallélisables.
- Dans le doute, moins de tickets ; le reste devient un **follow-up** (brouillon, non exporté).
- Follow-up ≠ hors périmètre : c'est un à-faire connu que le dev pourra promouvoir.

## Contenu d'un ticket (voir `.taskIO/templates/ticket.md`)

`origin`, `contexte`, `perimetre` (puces précises : endpoints, variables, limites…), `etapes` (cases à cocher, adaptées à la méthode choisie), `doneWhen` (refs des prérequis), `followUps`, plus `status`, `priority`, `assignee`, `labels`, `project`, `estimate.value` (jours, ton jugement). « Hors périmètre » et « Ensuite » sont produits par le code : ne les écris pas.

Méthode : TDD → première étape « Tests rouges » ; BDD → scénarios d'abord ; spec-driven → spec/contrat d'abord ; tests-after → implémentation puis tests ; prototype-first → prototype jetable puis version propre. La méthode est un choix du dev, pas une règle fixe.

## Lot cohérent : epic et jalons

- **Epic** (`epic`) : un seul par PRD, nommé d'après l'objectif du PRD (`E01 — …`), avec un résumé d'une phrase (255 caractères max) et une description Markdown courte (objectif, périmètre, hors périmètre global). Tous les tickets en font partie : laisse `project` à `null` sur les tickets, sauf exception voulue. `null` seulement si le dev ne veut pas d'epic.
- **Jalons** (`milestones`) : seulement s'ils aident à livrer par étapes, avec deux jalons au minimum (un seul n'organise rien). Chaque jalon est un état livrable et vérifiable (« socle déployé », « API utilisable »), pas une catégorie technique. Écris-les **dans l'ordre de livraison** : un ticket ne peut dépendre que de tickets du même jalon ou d'un jalon précédent. Chaque jalon contient au moins un ticket ; place chaque ticket dans un jalon (`milestone`), les sous-issues dans celui de leur parent. Pas de `targetDate` sans date dans le PRD.
- Petit projet (≈ 3 tickets ou moins) : un epic, pas de jalons.
- Le code refuse un jalon vide ou inconnu, un prérequis dans un jalon plus tardif, un ticket avec jalon et `project`, des jalons sans epic ; `validate` avertit des tickets sans jalon.

## Fonctions fluent-tickets (sous-issues, liens, pièces jointes, documents)

Ces champs sont toujours présents (`null` / `[]` si vides) et n'ont d'effet que dans l'export fluent-tickets.

- **Sous-issues** (`parent`) : seulement quand un livrable fait réellement partie d'un autre. Le découpage minimal prime : ne crée pas de sous-ticket pour une simple étape (elle va dans `etapes`).
- **Liens** (`links`) et **pièces jointes** (`attachments`) : uniquement ce que le PRD ou `.taskIO/prd/` fournit et qui sert au ticket ; vérifie que le fichier existe, n'invente jamais de chemin ni d'URL.
- **Assets du PRD** : `parse` extrait captures, gabarits HTML et PDF images dans `assets/` du run et liste le tout dans `assets.json` (`id`, `kind` image|html|figma, `path` ou `url`, `section`, `context`). Un ticket reçoit seulement les assets de sa fonctionnalité, aucun s'il n'y en a pas : images et HTML en `attachments` (`path` tel quel, titre parlant), lien Figma en `links` (jamais téléchargé). `validate` refuse un `path` d'asset ou un lien Figma absent du manifeste.
- **Documents** (`documents`) : du Markdown de référence qui ne tient pas dans un ticket (contrat d'API, glossaire, décisions). Pas de doublon avec le contenu des tickets ; n'y copie pas le PRD.

## Estimations

Jugement approximatif en jours. L'estimation globale (`estimate.value` + `justification`) est ton avis, pas la somme. Un humain les valide ensuite.

## Boucle de validation

Après avoir écrit un fichier, lance `npx taskio validate <fichier>`. En cas d'erreur, corrige et relance, `validate` compte les échecs (`validateMaxAttempts`, 3 par défaut) et renvoie le code 3 à la limite : arrête-toi alors et montre les erreurs au dev. Les avertissements de granularité : corrige ou justifie.

## Points de validation humaine

Récapitulatif des réponses avant génération ; revue des tickets et estimations avant export ; diff avant d'appliquer un retour. N'avance jamais sans accord explicite.
