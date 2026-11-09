---
description: "taskIO — régénérer les tickets depuis les réponses déjà validées"
---
Applique les règles taskIO. Sans reposer de question.

1. Choisis le run (`.taskIO/runs/<slug>/v<n>/`, dernier par défaut). Vérifie que `answers.json` existe avec `validatedByHuman: true` ; sinon renvoie vers `/taskio.init`.
2. Lis `prd.normalized.md`, `answers.json` et, s'il existe, `feedback.all.json` (retours déjà appliqués) : réapplique-les à la nouvelle génération.
3. Si `npx taskio key <run> --check` répond `fresh` (code 0), propose de garder le résultat existant.
4. Conserve les IDs existants (`ref` = ancien `id`) pour les tickets qui subsistent.
5. Écris `tickets.draft.json`, puis `npx taskio replay <run>` (rejoue par le code les fusions, suppressions et changements de champs des anciens retours ; le texte libre de `feedback.all.json` reste à appliquer par toi), puis `npx taskio validate`, `npx taskio assemble` (limite d'essais gérée par `validate`), puis `npx taskio diff <ancien tickets.json> <nouveau>` et montre le diff au dev.
