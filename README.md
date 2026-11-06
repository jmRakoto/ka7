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
- `packages/ka7_engine_explode/` : moteur de secours en Dart pur (youtube_explode), seul moteur d'iOS.
- `packages/ka7_store/` : archive, historique, réglages, abonnements (SQLite).
- `cli/` : commande `ka7`.

## Publier une version

Tout se lance depuis la racine de `ka7/`. Les paquets arrivent dans `dist/`.

### 1. Numéro de version

Avant chaque version, augmenter le numéro dans `app/pubspec.yaml` (et `cli/pubspec.yaml` pour la commande) :

```yaml
version: 0.2.1+3   # 0.2.1 = version affichée, +3 = numéro de build
```

Le `+N` doit augmenter à **chaque** version : sinon Android refuse d'installer la nouvelle par-dessus l'ancienne.

### 2. Linux

Prérequis : `fvm`, Docker. La construction se fait dans un conteneur Ubuntu 22.04 : les paquets marchent sur Ubuntu 22.04, Debian 12 et plus récents (construits sur une machine plus récente, ils ne démarreraient pas sur les anciennes). L'outil AppImage est téléchargé seul la première fois. Sans Docker : `KA7_NATIVE_BUILD=1` (il faut alors aussi `fakeroot` et `dpkg-deb`), paquets limités aux Linux aussi récents que la machine.

```bash
tool/package_linux.sh       # dist/ka7_<version>_amd64.deb et dist/Ka7-<version>-x86_64.AppImage
tool/linux/check_old_linux.sh dist/Ka7-*-x86_64.AppImage dist/ka7_*_amd64.deb   # démarre-t-il sur Ubuntu 22.04 ?
sudo apt install ./dist/ka7_*_amd64.deb
```

| Fichier | Contenu | Pour qui |
|---|---|---|
| `ka7_<version>_amd64.deb` | App + commande `ka7` | Ubuntu, Debian : `sudo apt install ./ka7_<version>_amd64.deb` |
| `Ka7-<version>-x86_64.AppImage` | App seule, un seul fichier | Toute distribution : `chmod +x`, puis double-clic |

Au premier lancement, l'app propose d'installer yt-dlp et ffmpeg (environ 180 Mo).

### 3. Android

Prérequis :

- La clé de publication `~/.config/ka7/ka7-release.jks` et son mot de passe dans `~/.config/ka7/key.properties` (autre emplacement : variable `KA7_KEY_PROPERTIES`). **Sans eux, l'APK est signé avec la clé de debug et ne peut pas mettre à jour les installations existantes.**
- Le SDK Android avec le NDK, la première fois seulement : le script compile un ffmpeg réduit pour Android (`tool/android/build_ffmpeg.sh`, quelques minutes).

```bash
tool/package_android.sh     # dist/Ka7-<version>-{arm64-v8a,armeabi-v7a,x86_64}.apk
```

| Fichier | Pour qui |
|---|---|
| `Ka7-<version>-arm64-v8a.apk` | Presque tous les téléphones depuis 2017 : **à donner par défaut** |
| `Ka7-<version>-armeabi-v7a.apk` | Vieux téléphones 32 bits, si l'autre affiche « app non compatible » |
| `Ka7-<version>-x86_64.apk` | Émulateurs, Chromebooks : inutile pour les utilisateurs |

### 4. Installer sur Android (côté utilisateur)

1. Ouvrir l'APK reçu (WhatsApp, Drive, lien…).
2. Android demande d'autoriser l'installation depuis cette source (Chrome, Fichiers…) : accepter.
3. Au premier lancement : langue et thème, présentation, puis autorisation des notifications.

Mise à jour : donner le nouvel APK, il s'installe par-dessus l'ancien et garde l'historique, **à condition** que le `+N` ait augmenté et qu'il soit signé avec la même clé.

Un téléphone qui a une version de développement (`flutter run`, clé de debug) doit d'abord la désinstaller.

### 5. Publier sur GitHub

Une fois la version augmentée, commitée et poussée, écrire les nouveautés dans un fichier (par exemple `notes.md`, qui commence par `## Nouveautés`), puis :

```bash
tool/release.sh --dry-run notes.md   # tout, sauf l'étiquette et l'envoi
tool/release.sh notes.md             # publie la version de app/pubspec.yaml
```

Le script refuse si des changements ne sont pas commités, si la branche n'est pas poussée, si l'étiquette existe déjà, si le `+N` n'a pas augmenté depuis la dernière release, ou si la clé de publication manque. Puis il lance `tool/check.sh`, construit tous les paquets, vérifie la signature des APK, ajoute aux notes le guide d'installation et les empreintes SHA-256 (calculées sur les fichiers envoyés), crée l'étiquette `v<version>`, publie les 4 fichiers (APK `arm64-v8a` et `armeabi-v7a`, `.deb`, AppImage) et les retélécharge pour les comparer.

Les utilisateurs téléchargent ensuite depuis `https://github.com/jmRakoto/ka7/releases`.

### 6. Windows

Flutter ne construit pas Windows depuis Linux : GitHub le fait. Dès que `tool/release.sh` a publié la version, le workflow « Windows » (`.github/workflows/windows.yml`) construit `Ka7-<version>-windows-setup.exe` (installateur) et `Ka7-<version>-windows-x64.zip`, les ajoute à la release et complète ses notes. Suivi : onglet Actions du dépôt, ou `gh run list --workflow windows.yml`. Les fichiers ne sont pas signés : Windows affiche un avertissement au premier lancement.

### La clé de publication

Elle est irremplaçable. Perdre `ka7-release.jks` ou son mot de passe oblige chaque utilisateur à désinstaller Ka7, donc à perdre son historique, pour installer une nouvelle version. **La sauvegarder hors de cette machine** (clé USB, gestionnaire de mots de passe), avec `key.properties`.

## Ligne de commande

Prérequis : `yt-dlp` et `ffmpeg` dans le `PATH`.

```bash
cd cli && fvm dart build cli          # binaire dans build/cli/…/bundle/bin/ka7
ka7 links.txt --format mp3 --out ~/Musique
ka7 retry                             # relance les liens de failed.txt
```

Documentation : `../ka7-reecriture-flutter.html`, maquette : `../ka7-maquette.html`.
