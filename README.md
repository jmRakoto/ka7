# Ka7

Liens YouTube → fichiers MP3 / MP4 propres, tagués et rangés. Une app Flutter pour Linux, macOS, Windows, Android et iOS.

## Démarrer

Prérequis : [fvm](https://fvm.app). La version de Flutter est fixée dans `.fvmrc`.

```bash
fvm install                 # installe la version de Flutter du projet
fvm dart pub get            # dépendances de tout le workspace
cd app && fvm flutter run -d linux
```

## Vérifier

```bash
tool/check.sh               # format, analyse, tous les tests
```

## Structure

- `app/` : app Flutter.
- `packages/ka7_core/` : cœur en Dart pur, partagé par l'app et le CLI.
- `packages/ka7_engine_ytdlp/` : moteur bureau (yt-dlp + ffmpeg).
- `packages/ka7_store/` : archive et historique (SQLite).
- `cli/` : commande `ka7`.

## Paquets Linux

```bash
tool/package_linux.sh       # dist/ka7_<version>_amd64.deb et dist/Ka7-<version>-x86_64.AppImage
sudo apt install ./dist/ka7_*_amd64.deb
```

Au premier lancement, l'app propose d'installer yt-dlp et ffmpeg (environ 180 Mo).

## Ligne de commande

Prérequis : `yt-dlp` et `ffmpeg` dans le `PATH`.

```bash
cd cli && fvm dart build cli          # binaire dans build/cli/…/bundle/bin/ka7
ka7 links.txt --format mp3 --out ~/Musique
ka7 retry                             # relance les liens de failed.txt
```

Documentation : `../ka7-reecriture-flutter.html`, maquette : `../ka7-maquette.html`.
