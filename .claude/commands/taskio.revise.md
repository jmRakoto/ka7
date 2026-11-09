---
description: "taskIO — retours sur 1 ou plusieurs tickets (diff, validation, révision)"
---
Applique les règles taskIO. Arguments éventuels : `<ids…> "<retour>"`.

1. Run courant = dernier `.taskIO/runs/<slug>/v<n>/` avec un `tickets.json`.
2. Sans ids : liste les tickets (titre, estimation) et demande lesquels (choix multiple), puis le retour (un pour tous, ou un par ticket).
3. `npx taskio revise <run> --new` crée `revisions/r<n>/` avec `proposal.json` (copie de l'état actuel) et `feedback.json`.
4. Modifie **uniquement les tickets ciblés** dans `proposal.json`. Un retour peut : réécrire, changer estimation/priorité/labels (dans les enums), fusionner, découper (règles de découpage), supprimer, ajouter/retirer des follow-ups.
   - Modifié → même `ref`. Fusion → garde le premier `ref`, supprime les autres et note `{ "keep": …, "remove": […] }` dans `feedback.json` → `merges` (le code remappe les références). Découpage → nouveaux `ref`.
   - Remplis `feedback.json` (validé par `npx taskio validate`) : `targets` (ids), `feedback` (`[{ "targets": [ids], "text": "…" }]`), `merges` (`[{ "keep", "remove": [ids] }]`, tableaux obligatoires), `deletes` (ids), `sets` (`[{ "id", "field": "priority|status|labels|estimate", "value" }]`). Merges, deletes et sets sont rejoués par le code après une régénération. Tout id de ticket utilisé doit figurer dans `targets` ; `$global` n'est pas un ticket : inutile de l'y mettre (toléré). Tout changement de priorité, statut, labels ou estimation doit aussi être déclaré dans `sets` (sinon le code refuse : il serait perdu à la régénération). Estimation globale : `{ "id": "$global", "field": "estimate"|"justification", "value": … }`. Un ticket retiré doit figurer dans `deletes` ou `merges`.
   - Fusion : reporte toi-même dans le ticket conservé le périmètre utile des autres ; le code avertit de ce qui n'est pas repris.
5. `npx taskio revise <run> --propose r<n>` écrit et affiche `diff.md`. Présente le diff ; les effets sur les tickets non ciblés (dépendances, références) sont listés à part.
6. Demande : tout appliquer / choisir par ticket / refuser. Pour un choix partiel, ajuste `proposal.json` puis relance `--propose`. Rien n'est appliqué avant l'accord.
7. Seule la dernière révision peut être proposée ou committée ; pour de nouveaux retours, `--new`. Accord : `npx taskio revise <run> --commit r<n>` (refusé si `proposal.json` ou `feedback.json` ont changé depuis le dernier `--propose` ; un commit consomme le diff, un nouveau `--propose` est requis pour recommitter) (valide, assemble, met à jour `tickets.json`). Le code refuse la révision si un ticket non ciblé change (hors `doneWhen`). Une estimation modifiée repasse à `validatedByHuman: false` (automatique).
