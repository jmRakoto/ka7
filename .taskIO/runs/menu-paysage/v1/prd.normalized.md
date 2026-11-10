# Menu en mode paysage sur téléphone

## Constat

Sur un téléphone tenu à l'horizontale (Galaxy M36 : environ 780 × 360 px
logiques), l'écran dépasse 720 px de large : Ka7 montre la barre latérale
(`NavigationRail` de `Ka7Shell`, `app/lib/features/shell/ka7_shell.dart`) au
lieu des onglets du bas. Avec le logo et ses cinq entrées (Ajouter, File,
Bibliothèque, Lecteur, Réglages), elle est plus haute que l'écran : Réglages
sort de l'écran (vers 373–389 px pour 360) et la barre ne défile pas. Flutter
signale un débordement de 41 px. Le mini-lecteur, en bas pendant une lecture,
réduit encore la hauteur.

## Demande

Le menu doit se faire défiler quand il ne tient pas : chaque entrée reste
atteignable en mode paysage.

## Exigences

- Garder la barre latérale (choix du dev) ; elle défile quand elle ne tient
  pas, logo compris, et ne bouge pas quand tout tient (bureau, tablette).
- Plus aucun débordement à 780 × 360, avec et sans mini-lecteur.
- L'entrée choisie reste visible et le badge de la File (titres en attente)
  reste lisible.
- Cibles tactiles de 48 px, rien d'autre ne change en portrait ni sur bureau.
