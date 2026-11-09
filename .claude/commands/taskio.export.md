---
description: "taskIO — exporter les tickets validés vers Linear (export/linear.json) ou les pousser dans fluent-tickets via MCP"
---
Applique les règles taskIO. Cible : `$ARGUMENTS` (`linear` ou `fluent-tickets`), sinon `adapter` de `.taskIO/config.json`.

1. Run courant = dernier avec `tickets.json`. Vérifie que les estimations sont validées (`validatedByHuman`) ; sinon signale-le et demande confirmation.

## Linear

2. `npx taskio export <run>/tickets.json --adapter linear` → `<run>/export/linear.json`.
3. Lis `unlinkedBlockers` dans `export/linear.json` (et les avertissements affichés) : si non vide, dis au dev quels tickets dépendent d'un brouillon non exporté, donc sans blocage dans Linear.
4. Rappelle que les follow-ups restent des brouillons (non exportés) tant qu'ils n'ont pas été promus en tickets.

## fluent-tickets

Le CLI se connecte lui-même à fluent-tickets (`npx taskio login`, jetons hors du dépôt) : aucun serveur MCP n'est nécessaire dans l'agent.

2. `npx taskio export <run>/tickets.json --adapter fluent-tickets` → `<run>/export/fluent-tickets.json`. Si `fluentTickets.organization` ou `fluentTickets.team` manque, fais l'étape 0 de `/taskio.init`, puis relance.
3. `npx taskio fluent check <run>` (JSON, aucune écriture). Selon le résultat :
   - erreur « pas connecté » ou « session expirée » : préviens le dev que le navigateur va s'ouvrir, `npx taskio login` (délai 10 min), puis relance `check` ;
   - `organization.actual` ≠ `expected` : la connexion vise une autre organisation ; `npx taskio login` en choisissant `expected` ;
   - `team: false` : le projet n'existe pas ou n'est pas visible ; stop (il se crée dans l'app web) ;
   - `state: false` : le statut `fluentTickets.state` n'existe pas ; demande au dev le bon nom, `npx taskio setup --ai <agents> --fluent-state "<nom>"`, puis reprends à l'étape 2 ;
   - `missingLabels` / `missingEpics` / `missingMilestones` : **demande au dev** pour chacun s'il faut le créer (noms identiques) ; pour l'epic du lot, montre son nom et son résumé, et pour les jalons leur ordre et leurs dates. Accord pour tous → `npx taskio fluent check <run> --create-missing` (crée l'epic avec son résumé et sa description, puis les jalons dans l'ordre de livraison) ; sinon annule l'export (un ticket ne peut pas porter un label, un epic ou un jalon absent). Un epic ou jalon déjà existant n'est jamais modifié.
4. Montre au dev : organisation/projet, `summary` (à créer / à mettre à jour / inchangés, plus `attachments` et `documents` à envoyer), `warnings` (estimations arrondies en demi-journées, documents ignorés), `unlinkedBlockers`, `unlinkedParents` (sous-issue dont le parent est un brouillon : créée sans parent), `orphans`. Attends son accord explicite. Si `export` échoue sur une pièce jointe introuvable, trop lourde (25 Mo) ou un document attaché à l'epic sans `fluentTickets.epic`, dis-le et propose de corriger le brouillon (`/taskio.revise`) ou la config.
5. `npx taskio push <run>` : revérifie la cible, puis envoie dans l'ordre les tickets nouveaux ou modifiés (parents et prérequis d'abord, liens ajoutés), leurs pièces jointes (fichiers lus sous `.taskIO/`), puis les documents Markdown, et enregistre chaque étape dans `export/fluent-tickets.map.json`. En cas d'erreur, montre-la au dev ; relancer `push` reprend là où ça s'est arrêté, sans rien renvoyer d'inchangé.
6. Récapitule les tickets créés et mis à jour avec leurs clés, les pièces jointes envoyées ou remplacées et les documents. Les `orphans` (retirés de taskIO, encore dans fluent-tickets) sont à traiter par le dev dans l'app. Rappelle que les follow-ups ne sont pas exportés.

Estimation : fluent-tickets prend un entier, taskIO l'envoie en **demi-journées** (1 j = 2). Une mise à jour réécrit titre, description, priorité, labels, estimation, blocages et parent, mais jamais le statut ni l'assigné posé dans l'app : les cases cochées dans la description sont perdues, préviens le dev. Le jalon d'un ticket est posé à la création et à la mise à jour ; un jalon retiré dans taskIO n'est pas détaché dans l'app. Les `links` sont en ajout seul (jamais retirés) ; un fichier modifié est renvoyé et l'ancien lien retiré des Resources ; un document modifié est réécrit en entier, donc les éditions faites dans l'app sont écrasées.
