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

- `pubspec.yaml` (racine) : workspace, membres `app`, `packages/ka7_core`, `packages/ka7_engine_ytdlp`, `packages/ka7_engine_explode`, `packages/ka7_store`, `cli`.
- `packages/ka7_core/` : cœur en Dart pur, sans Flutter (liens — une ligne faite seulement de mots libres devient une `SearchEntry`, `searchLimit` = 20 résultats ; dans une ligne mêlée de liens, les mots libres restent invalides —, sondes (`Probe.isSearch` : résultats décochés dans l'aperçu), noms de fichiers (`FolderLayout.playlist` ou `.artist` = dossier de la chaîne YouTube, repli sur la playlist si inconnue), file de téléchargement `DownloadQueue`, événements `JobEvent`, bilan, `failed.txt`). Partagé par l'app et le CLI.
- `packages/ka7_engine_ytdlp/` : moteur bureau. `EngineBinaries` (implémente `EngineSetup`) trouve yt-dlp et ffmpeg (copies de l'app d'abord, puis `PATH`) et installe les binaires officiels : yt-dlp autonome, ffmpeg en build LGPL de BtbN (vérifié : pas de `--enable-gpl`). `DailyUpdate` (décorateur d'`EngineSetup`) lance `EngineBinaries.updateYtDlp` (`yt-dlp -U`, seulement sur la copie de l'app, jamais celle du `PATH`) au plus une fois par jour, au `check()` du démarrage, délai max 1 min ; date du dernier succès dans le réglage `ytdlp.updated` (branché dans `app/lib/main.dart`). Le CLI ne met rien à jour. `YtDlpExtractor` (lecture, lanceur `RunProcess` injecté) et `YtDlpDownloader` (téléchargement, conversion MP3 / MP4, tags et pochette via ffmpeg, progression, annulation ; lanceur `StartProcess` injecté). Les fixtures de `test/fixtures/` sont de vraies sorties de yt-dlp 2026.10.26, raccourcies.
- `packages/ka7_engine_explode/` : moteur en Dart pur sur youtube_explode_dart, seul moteur d'iOS et moteur actuel d'Android. Logique dans `ExplodeEngine` (testée avec `FakeSource`), réseau dans l'adaptateur mince `YoutubeExplodeSource`. Fait M4A (audio d'origine) et MP4 muxé (360p max) ; MP3 refusé (`formatUnsupported`) faute de ffmpeg. Essai réel : `cd packages/ka7_engine_explode && fvm dart run tool/live_check.dart <dossier>`. État au 2026-10-30 : vidéo seule OK, playlists et chaînes vides (youtube_explode 3.1.0 cassé, dépôt amont inactif depuis mai 2026) ; le moteur les signale en échec au lieu de les rendre vides.
- `packages/ka7_store/` : mémoire locale drift (SQLite) : archive « déjà téléchargé », historique, réglages (clé → valeur), file en cours (`keepPending` / `dropPending` / `pending`, table `pending_downloads`). L'historique garde l'id de playlist (`HistoryItem.playlistId`, null pour une vidéo seule ou une chaîne). Abonnements : `follow` / `unfollow` / `subscriptions` (table `subscriptions`, `link` relisible par `parseEntry`). Schéma v5 ; `test/fixtures/schema_v1.sql` à `schema_v4.sql` sont de vraies bases pour tester les migrations. Code généré `lib/src/database.g.dart` : après toute modification des tables, `cd packages/ka7_store && fvm dart run build_runner build`, puis augmenter `schemaVersion` et écrire la migration.
- `cli/` : commande `ka7` (`ka7 links.txt [--format mp3|mp4] [--out dossier] [--jobs 2] [--lang fr|en] [--yes]`, `ka7 retry`). Les recherches (mots libres) y sont signalées « not a link » : rien à cocher sans écran. Pose des questions o/N (chaîne : tout télécharger ? vidéo ouverte depuis une playlist : toute la playlist ?) ; `--yes` répond oui, sans terminal la réponse est non. Barre de progression seulement si la sortie est un terminal (`stdioType`, pas `hasTerminal`, faux sans largeur de fenêtre). Logique testable dans `lib/src/ka7_cli.dart`, branchement réel dans `bin/ka7.dart`. Base partagée avec l'app : `~/.local/share/mg.rakoto.ka7/ka7.sqlite` (Linux). Binaire : `cd cli && fvm dart build cli` (embarque `libsqlite3.so`). Tester Ctrl+C sur le binaire, pas via `fvm dart run`, qui coupe la sortie.
- `app/` : app Flutter, sans logique métier testable sans Flutter (elle va dans `ka7_core`). `Ka7App` (réglages, thème, langue) → `EngineGate` (flux 0 : outils manquants, installation) → `Ka7Shell` (barre latérale, ou onglets sous 720 px ; Ajouter, File, Bibliothèque, Réglages ; tient les files en cours et écrit l'historique). Chaque titre mis en file est gardé dans le store jusqu'à sa fin (réussi, ignoré, échoué, annulé par l'utilisateur) ; fermeture ou plantage le laissent, et au lancement suivant l'app s'ouvre sur File avec la carte « File interrompue » : Reprendre (même format, même dossier) ou Abandonner (annulés dans l'historique). Composants communs dans `lib/widgets/` (`Ka7Page`, `StatusPill`, `Ka7Wordmark`, `Ka7Logo` : cassette de `../ka7-brand/ka7-mark.svg` dessinée en `CustomPainter` aux couleurs du thème, dans la barre latérale et au démarrage). Premier lancement : `OnboardingScreen` (3 pages, « Passer »), avant `EngineGate` ; réglage `onboarding.done`. Les tests d'`app_test.dart` le posent dans `setUp` ; le retirer pour tester la présentation.
- À venir, chacun avec sa première tranche testée : `packages/ka7_engine_explode`.
- Identifiant d'app : `mg.rakoto.ka7` (définitif).
- Formats : `MediaFormat.mp3`, `m4a` (audio d'origine, même dossier que MP3), `mp4`. Le bureau propose MP3/MP4, le mobile M4A/MP4 (`Ka7App.formats`).
- `app/lib/main.dart` choisit par plateforme : bureau (yt-dlp, `EngineGate`, dossiers XDG, `xdg-open`) ou mobile (`ExplodeEngine`, pas d'`EngineGate`, dossiers `Android/data/mg.rakoto.ka7/files/{Music,Movies}` ou `Documents` iOS visibles dans l'app Fichiers, pas d'ouverture de dossier).
- Android : moteur yt-dlp embarqué (youtubedl-android 0.18.1, `android/app/src/main/kotlin/mg/rakoto/ka7/YtDlpChannel.kt`), vu côté Dart comme un processus (`app/lib/platform/android_ytdlp.dart`), donc `YtDlpExtractor` et `YtDlpDownloader` servent tels quels. `AndroidEngineSetup` décompresse le moteur et met yt-dlp à jour à chaque lancement (le yt-dlp embarqué de nov. 2025 ne lit plus YouTube). Secours automatique : `FallbackExtractor` / `FallbackDownloader` (`ka7_core`) essaient yt-dlp puis youtube_explode, sauf vidéo privée ou indisponible.
- Pages de 16 Ko : le ffmpeg de youtubedl-android ne s'y charge pas (`libwebp` alignée 4 Ko, issue amont #365). `tool/android/fix_ffmpeg_16k.sh` recompile libwebp 1.6.0 avec le NDK et produit `app/android/app/src/main/jniLibs/<abi>/libffmpeg.zip.so` (ignoré par git, environ 100 Mo), qui remplace celui de la bibliothèque (`pickFirsts`). À relancer si la version de youtubedl-android change. L'émulateur `Android_17.0_API_24` est en 16 Ko.
- Réglages (`AppSettings`, clés du store) : langue, thème (`theme` : `light` / `dark`, absent = système), dossiers, téléchargements simultanés (`downloads.concurrency`, 1 à 4, défaut 2, pour les files suivantes), titres lus dans un mix (`mix.limit`, 25/50/100/200, défaut 50), rangement (`folders.layout` : `artist`, absent = par playlist). Les moteurs lisent la limite au moment de lire (`mixLimit: () => settings.mixLimit`) : `enginesFor(status, settings)`.
- Abonnements : « Suivre » sous le titre d'une playlist ou d'une chaîne dans l'aperçu (`followLinkOf` dans `ka7_core` : rien pour une vidéo, une recherche, un mix). Au lancement, `Ka7Shell` relit les abonnements en arrière-plan (`findNews` : titres disponibles absents de l'archive dans le premier format) ; s'il y en a, carte « Nouveautés » en haut d'Ajouter, « Voir » ouvre leur aperçu. Liste et « Ne plus suivre » dans Réglages (en bas : dans les tests, `scrollUntilVisible`).
- Aperçu d'une recherche : champ « Nouvelle recherche » en haut ; chaque recherche ajoute son groupe au-dessus, les titres cochés restent cochés. Tests d'`app_test.dart` : naviguer avec `_nav('Ajouter')`, le titre de l'onglet dit aussi « Ajouter ».
- Aperçu : case « Tout sélectionner » à trois états par playlist de plus d'un titre disponible (partielle → un clic coche tout). Avec `archive`, les titres déjà téléchargés dans le format choisi sont décochés et marqués « Déjà là » (recalculé au changement de format). Bibliothèque : « Mettre à jour la playlist » (lignes avec `playlistId`) ouvre l'aperçu de la playlist, seuls les nouveaux titres cochés.
- Fin de téléchargement : `RunNotifier` (`app/lib/platform/run_notifier.dart`), appelé par `Ka7Shell` quand une file se termine et que l'app n'est pas au premier plan (`lifecycleState` ≠ `resumed`). Bureau : `DesktopNotifier` (`notify-send`, silencieux s'il manque). Android : `AndroidRunNotifier` → méthode `finished` de `BackgroundChannel.kt` → `DownloadService.finished` (canal `finished`, notification qui reste après celle de progression).
- Ajouter : sélecteur « Liens / Recherche YouTube ». En mode recherche, un champ simple et « Rechercher » ouvrent l'aperçu d'une `SearchEntry` ; des liens reçus pendant ce mode (partage, dépôt) ramènent en mode Liens. File : ✕ « Annuler ce titre » sur chaque titre en cours ou en attente (`DownloadQueue.cancelOne`), les autres continuent.
- Ajouter : boutons « Importer un fichier » (`Ka7App.pickLinksFile`, sélecteur natif `.txt` dans `main.dart`, toutes plateformes ; le texte va sous le champ) et « Effacer » (vide le champ, désactivé s'il est vide).
- Glisser-déposer (bureau, `Ka7App.acceptDrops`) : `desktop_drop` autour de toute la fenêtre dans `Ka7Shell`, calque « Dépose tes liens ou un fichier .txt » pendant le survol. `droppedText` (`app/lib/platform/link_drop.dart`) garde textes et liens, lit les `.txt`, ignore les autres fichiers et les dossiers ; le résultat va sous le contenu du champ Ajouter. Sous Wayland, `desktop_drop` 0.8 ne reçoit aucun glisser (vérifié sous GNOME, 2026-11-02) : `app/linux/runner/main.cc` force `GDK_BACKEND=x11` (XWayland) sauf si la variable est déjà définie ; à retirer en passant à `desktop_drop` 0.9 (Flutter 3.47.7 minimum). Test d'écran : envoyer `updated` / `performOperation_linux` sur le canal `desktop_drop` (voir `app/test/app_test.dart`, groupe `drop`).
- Partage : « Partager → Ka7 » depuis YouTube (`MainActivity.kt`, canal `mg.rakoto.ka7/share`, `app/lib/platform/shared_links.dart`) ; seuls les liens du texte partagé sont gardés, ajoutés au champ de l'onglet Ajouter.
- Écran éteint : `DownloadService.kt` (service de premier plan `dataSync`, notification de progression, icône `res/drawable/ic_notification.xml`) piloté par `BackgroundChannel.kt` depuis `app/lib/platform/android_background.dart` ; `Ka7Shell` le garde actif tant qu'une file a des titres en cours.
- Release : R8 doit garder youtubedl-android, Jackson et Commons Compress (`android/app/proguard-rules.pro`), sinon plantage au démarrage du moteur. Toujours essayer l'APK release sur l'émulateur, pas seulement le debug.
- Fichiers sur Android : téléchargés d'abord dans le dossier de l'app, puis déplacés par `PublishingDownloader` (`app/lib/platform/media_store.dart`) et `MediaStoreChannel.kt` dans `Music/Ka7/<playlist>` ou `Movies/Ka7`, visibles par toutes les apps de musique. Android 10+ : MediaStore, sans autorisation ; Android 7 à 9 : dossiers publics avec `WRITE_EXTERNAL_STORAGE` (demandée au début des téléchargements ; refusée, le fichier reste dans le dossier de l'app). Pas de choix de dossier sur Android (`Ka7App.pickFolder` null, réglage masqué).
- Signature : clé de publication `~/.config/ka7/ka7-release.jks` (alias `ka7`, RSA 4096, valable 100 ans), mot de passe dans `~/.config/ka7/key.properties`, lu directement par Gradle (autre chemin : variable `KA7_KEY_PROPERTIES`) ; rien dans le projet. Perdre la clé empêche toute mise à jour chez ceux qui ont installé l'app : la sauvegarder hors de cette machine. Sans ce fichier, la release est signée avec la clé de debug.
- Icônes : `tool/render_icons.py` (`cd app && uv run --with cairosvg python -I ../tool/render_icons.py`) produit `app/assets/icon/` depuis `../ka7-brand/`, puis `cd app && fvm dart run flutter_launcher_icons` (réglages dans `app/pubspec.yaml`) génère Android (adaptative + monochrome), iOS, Windows et macOS. Linux : icônes de `packaging/linux/`.
- Paquets Android : `tool/package_android.sh` → `dist/Ka7-<version>-{arm64-v8a,armeabi-v7a,x86_64}.apk` (environ 55 à 65 Mo chacun, contre 257 Mo en debug universel). Signés avec la clé de publication (voir Signature).
- Java : Flutter utilise le JDK d'Android Studio (`fvm flutter config --jdk-dir=/snap/android-studio/current/jbr`), la Java du système n'a pas `javac`.
- Android : `fvm flutter build apk --debug` depuis `app/` ; émulateur `Android_17.0_API_24` (API 37, x86_64) : `~/Android/Sdk/emulator/emulator -avd Android_17.0_API_24 -no-window`. iOS : pas de build possible sous Linux (Xcode requis).
- Nouveau paquet : l'ajouter à `workspace:` dans `pubspec.yaml` et mettre `resolution: workspace` dans le sien.

## Rendu et paquets

- Captures de tous les écrans (bureau et téléphone, clair et sombre, vraies polices) : `cd app && KA7_SHOTS=/dossier fvm flutter test tool/screenshots/screenshots_test.dart`. À regarder après tout travail d'interface.
- Paquets Linux : `tool/package_linux.sh` → `dist/ka7_<version>_amd64.deb` (app `ka7-app` + CLI `ka7`) et `dist/Ka7-<version>-x86_64.AppImage` (app seule). Icônes et `.desktop` dans `packaging/linux/` (copies de `../ka7-brand/`). Version lue dans `app/pubspec.yaml`.

## Langue

- Pluriels FR : `one{{count} …}`, jamais `=1{1 …}` (le français range 0 dans « one » : avec `=1`, 0 s'affichait « 1 titre »).

- Code en anglais (obligatoire) : noms, fichiers, commentaires, noms de tests.
- Interface en français et en anglais (fichiers ARB), choix dans Réglages.
- Documents en français.

## Tests (TDD)

Skill `tdd` (rouge, vert, refactor), dans `.agents/skills/tdd/`, lié dans `.claude/skills/`. Copie du skill global `~/.agents/skills/tdd/` : modifier l'un, recopier l'autre.

| Changement | Fichier de test | Outils | Commande |
|---|---|---|---|
| Règle du cœur (liens, noms de fichiers, file, événements) | `packages/ka7_core/test/<module>_test.dart`, miroir de `lib/src/<module>.dart` | `package:test` | `cd packages/ka7_core && fvm dart test test/<fichier>` |
| Écran, widget | `app/test/<feature>/*_test.dart` | `flutter_test` (`testWidgets`, `find.bySemanticsLabel`, `find.text`) | `cd app && fvm flutter test test/<chemin>` |
| Moteur (yt-dlp, youtube_explode) | `packages/ka7_engine_*/test/` | vraies sorties dans `test/fixtures/`, `FakeYtDlp` / `FakeProcess` à la place du processus | `cd packages/ka7_engine_ytdlp && fvm dart test` |
| Archive, historique | `packages/ka7_store/test/` | `Ka7Store.inMemory()` | `cd packages/ka7_store && fvm dart test` |
| Vue d'une file (`RunView`) | `app/test/features/queue/` | `RunProgress` rempli à la main ; `ControlledDownloader` (`app/test/helpers/`) pour les parcours complets, `pumpAndSettle` après chaque ordre | `cd app && fvm flutter test test/features/queue` |
| Parcours réel bureau (réseau, vrai yt-dlp) | `app/integration_test/` | aucun double, dossier temporaire ; hors de `tool/check.sh` | `cd app && fvm flutter test integration_test -d linux` |
| Démarrage, outils manquants | `app/test/features/startup/` | `FakeEngineSetup` (`app/test/helpers/fake_engine_setup.dart`) ; `pump()` et non `pumpAndSettle()` tant que la barre est indéterminée | `cd app && fvm flutter test test/features/startup` |
| Navigation, Bibliothèque, Réglages | `app/test/app_test.dart` | `Ka7App` complet, `Ka7Store.inMemory()`, `ControlledDownloader`, `FakeEngineSetup.ready()` | `cd app && fvm flutter test test/app_test.dart` |
| Commande `ka7` | `cli/test/` | `FakeExtractor`, `FakeDownloader`, dossier temporaire, `Ka7Store.inMemory()` | `cd cli && fvm dart test` |
| Écran qui lit des liens | `app/test/features/<feature>/` | `FakeExtractor` (`app/test/helpers/fake_extractor.dart`), sondes fixes dans `app/test/helpers/probes.dart`, `pumpApp` (`app/test/helpers/pump_app.dart`) | `cd app && fvm flutter test test/features/<feature>` |

- Jamais de réseau ni de vrai yt-dlp dans les tests unitaires et d'écran : moteurs remplacés par un double. Seul `app/integration_test/` les utilise, lancé à la main.
- Dates, identifiants et durées fixes dans les tests.
- Porte avant de clore une tâche : `tool/check.sh` (format, analyse, tous les tests).

## Design (UI/UX)

- Skills d'interface (`.agents/skills/`, liés dans `.claude/skills/`, verrouillés par `skills-lock.json`) : `impeccable`, `ui-ux-pro-max` (contient des règles Flutter : `data/stacks/flutter.csv`), `design`, `design-system`. À utiliser pour tout travail d'interface. Mise à jour : `npx skills update -p`.
- `DESIGN.md` : palette Nuit d'encre, règles d'écriture et d'accessibilité. Le lire avant tout travail d'interface ; il prime sur la maquette. Aucun skill ne le réécrit sans accord.
- Ne jamais utiliser le logo, le rouge ni la marque YouTube.

## Git

- Ne jamais faire de commit ni de push : l'utilisateur les fait lui-même, manuellement.
