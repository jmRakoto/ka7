# Carte « En cours de lecture » de la section Lecteur

## Contexte

En haut de la section Lecteur, la carte « En cours de lecture »
(`_NowPlaying`, `app/lib/features/player/player_hub_screen.dart`) montre ce
qui joue : icône (son ou vidéo), « En cours de lecture », titre, barre de
progression, temps écoulé / durée, et un seul bouton, lecture / pause. Toucher
la carte ouvre la page du lecteur entier (vidéo ou cassette, commandes, file de
lecture), mais rien ne le dit à l'écran : l'utilisateur ne le devine pas.

## Demandes

1. **Suivant et précédent** dans la carte, de part et d'autre de lecture /
   pause, comme dans le mini-lecteur et la page du lecteur : passer au titre
   suivant ou revenir au précédent sans ouvrir la page.
2. **Un indicateur** qui dit que la carte s'ouvre : toucher la carte montre le
   lecteur entier, avec la vidéo ou le son et la file de lecture.

## Exigences

- Mêmes règles que les autres commandes : « précédent » revient au début du
  titre après 3 s, suivant inactif en fin de file sans répétition.
- Les boutons ne déclenchent pas l'ouverture de la carte.
- Lisible en clair et en sombre, cibles tactiles de 48 px, chaque contrôle
  nommé pour les lecteurs d'écran (DESIGN.md) ; téléphone et bureau.
- Textes en français et en anglais.
