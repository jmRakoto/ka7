# Ka7

Réécriture de `../youtubeDl/` en Flutter : une seule app (Linux, macOS, Windows, Android, iOS) qui transforme des liens YouTube en fichiers MP3 / MP4 propres. Pas de version web. Pas de Rust.

## Documents (fichiers locaux, ne jamais les publier en ligne)

- `../ka7-reecriture-flutter.html` : technologies, architecture, moteurs, fonctionnalités en flux (0 à 5), étapes, risques, couleurs, nom, identité. Référence pour ce qui doit être construit.
- `../ka7-maquette.html` : maquette cliquable (bureau et téléphone, clair et sombre, FR / EN). Référence de parcours et de mise en page, pas de rendu au pixel.
- `../ka7-brand/` : logo, icône (SVG, PNG 1024 à 48), silhouette monochrome.
- `PRODUCT.md`, `DESIGN.md` : contexte produit et règles de design pour les skills d'interface.

## Outils : toujours via fvm

Flutter n'est pas installé globalement. Version fixée par `.fvmrc` (canal `stable`).

- `fvm flutter …`, `fvm dart …` : jamais `flutter` ni `dart` seuls.
- `fvm dart pub get` à la racine : installe tout le workspace.
- `fvm flutter run -d linux` depuis `app/` pour lancer l'app.

## Structure (pub workspace)

- `pubspec.yaml` (racine) : workspace, membres `app` et `packages/ka7_core`.
- `packages/ka7_core/` : cœur en Dart pur, sans Flutter (liens, jobs, événements, noms de fichiers). Partagé par l'app et le futur CLI.
- `app/` : app Flutter (écrans, état, thème, intégration système). Ne contient pas de logique métier testable sans Flutter : elle va dans `ka7_core`.
- À venir, chacun avec sa première tranche testée : `packages/ka7_engine_ytdlp`, `packages/ka7_engine_explode`, `packages/ka7_store` (drift), `cli/`.
- Nouveau paquet : l'ajouter à `workspace:` dans `pubspec.yaml` et mettre `resolution: workspace` dans le sien.

## Langue

- Code en anglais (obligatoire) : noms, fichiers, commentaires, noms de tests.
- Interface en français et en anglais (fichiers ARB), choix dans Réglages.
- Documents en français.

## Tests (TDD)

Skill `tdd` (rouge, vert, refactor), dans `.agents/skills/tdd/`, lié dans `.claude/skills/`. Copie du skill global `~/.agents/skills/tdd/` : modifier l'un, recopier l'autre.

| Changement | Fichier de test | Outils | Commande |
|---|---|---|---|
| Règle du cœur (liens, noms de fichiers, file, événements) | `packages/ka7_core/test/<module>_test.dart`, miroir de `lib/src/<module>.dart` | `package:test` | `cd packages/ka7_core && fvm dart test test/<fichier>` |
| Écran, widget | `app/test/<feature>/*_test.dart` | `flutter_test` (`testWidgets`, `find.bySemanticsLabel`, `find.text`) | `cd app && fvm flutter test test/<chemin>` |
| Moteur (yt-dlp, youtube_explode) | `packages/ka7_engine_*/test/` | sortie de yt-dlp enregistrée en fichier, processus et réseau simulés | `fvm dart test` dans le paquet |

- Jamais de réseau ni de vrai yt-dlp dans les tests : moteurs remplacés par un double.
- Dates, identifiants et durées fixes dans les tests.
- Porte avant de clore une tâche : `tool/check.sh` (format, analyse, tous les tests).

## Design (UI/UX)

- Skills d'interface (`.agents/skills/`, liés dans `.claude/skills/`, verrouillés par `skills-lock.json`) : `impeccable`, `ui-ux-pro-max` (contient des règles Flutter : `data/stacks/flutter.csv`), `design`, `design-system`. À utiliser pour tout travail d'interface. Mise à jour : `npx skills update -p`.
- `DESIGN.md` : palette Nuit d'encre, règles d'écriture et d'accessibilité. Le lire avant tout travail d'interface ; il prime sur la maquette. Aucun skill ne le réécrit sans accord.
- Ne jamais utiliser le logo, le rouge ni la marque YouTube.

## Git

- Ne jamais faire de commit ni de push : l'utilisateur les fait lui-même, manuellement.
