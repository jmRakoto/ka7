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
- `packages/ka7_core/` : cœur en Dart pur, partagé par l'app et le futur CLI.

Documentation : `../ka7-reecriture-flutter.html`, maquette : `../ka7-maquette.html`.
