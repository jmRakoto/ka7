# Design · Ka7

Source visuelle : `../ka7-maquette.html` (parcours, mise en page) et `../ka7-brand/` (logo, icône). Ce fichier prime sur la maquette en cas de désaccord.

## Couleurs : Nuit d'encre

Tokens à porter dans `app/lib/theme/` (`ColorScheme` Material 3 + `ThemeExtension` pour les états du bilan).

| Token | Clair | Sombre | Usage |
|---|---|---|---|
| `background` | `#F7F7FB` | `#111120` | Fond de l'app |
| `surface` | `#FFFFFF` | `#191A2C` | Cartes, panneaux |
| `surfaceMuted` | `#EEEEF6` | `#212238` | Segments, zones secondaires |
| `ink` | `#1B1B2F` | `#ECECF6` | Texte principal |
| `muted` | `#5C5C78` | `#A6A6C4` | Texte secondaire |
| `line` | `#E2E2EE` | `#2C2D46` | Bordures |
| `accent` | `#4B3FA8` | `#A79BFF` | Bouton principal, sélection, lien |
| `onAccent` | `#FFFFFF` | `#15122E` | Texte sur accent |
| `accentSoft` | `#ECEBFA` | `#25234A` | Élément de navigation actif, puces |
| `lilac` | `#9B8CF0` | `#6C5FD6` | Bobines du logo, décor |
| `ok` / `okSoft` | `#2D6B4F` / `#E0F1E8` | `#86D1AA` / `#1C3128` | Réussi |
| `warn` / `warnSoft` | `#8A5A12` / `#FBEFD6` | `#E8BF73` / `#352C1B` | Ignoré, à choisir |
| `danger` / `dangerSoft` | `#A3333F` / `#FBE5E8` | `#F2919C` / `#3A1F26` | Échoué |

- Pas de rouge vif comme couleur principale (rien qui rappelle YouTube).
- Statut jamais porté par la couleur seule : toujours un mot ou une icône avec.

## Typographie

Police système (Roboto, SF, Segoe, Cantarell). Titres d'écran 26, corps 15, secondaire 13. Chiffres en `FontFeature.tabularFigures()` pour les progressions et compteurs.

## Composants (d'après la maquette)

- Navigation : barre latérale sur bureau (Ajouter, File, Bibliothèque, Réglages), barre d'onglets en bas sur téléphone. Badge de file en attente.
- Bouton principal unique par écran, dans un pied collant (« Voir l'aperçu », « Télécharger »).
- Pastilles d'état : Vidéo, Playlist, Vidéo + playlist, Mix, Chaîne, Doublon, Ignorée ; Réussi, Ignoré, Échoué, Annulé.
- Rayon 9 (contrôles) et 12 (cartes).

## Écriture

- Mots simples dans les boutons : « Télécharger », « Réessayer », « Tout annuler ». Le clin d'œil cassette reste dans le nom et l'icône.
- Chaque échec a une raison lisible (« Vidéo privée », « Connexion coupée par YouTube »), jamais un code.
- Tutoiement en français.

## Accessibilité

WCAG 2.2 AA : contraste 4,5:1 pour le texte, focus visible au clavier, `Semantics` sur chaque contrôle, cibles tactiles de 48 px.
