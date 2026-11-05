# 001 · Réduire la taille de l'app

- **État** : Fait (2026-11-06)
- **Taille** : moyenne
- **Plateformes** : Android surtout (Linux déjà à 12-13 Mo)

## Contexte

L'APK `arm64-v8a` de la 0.2.0 fait 63 Mo (77 Mo une fois décompressé). NewPipe fait environ 10 Mo. La taille freine le téléchargement depuis la page de release, surtout sur données mobiles.

Ce qui pèse dans l'APK (`unzip -l dist/Ka7-0.2.0-arm64-v8a.apk`) :

| Fichier | Taille | Rôle |
|---|---|---|
| `libffmpeg.zip.so` | 35,5 Mo | ffmpeg de youtubedl-android (+ libwebp recompilée pour les pages de 16 Ko) |
| `libpython.zip.so` | 13,6 Mo | Python, pour faire tourner yt-dlp |
| `libflutter.so` | 11,0 Mo | moteur Flutter |
| `libapp.so` | 7,4 Mo | code Dart de Ka7 |
| `classes.dex`, `libsqlite3.so`, `libqjs.so`, ressources | ~8 Mo | Java/Kotlin, base, JavaScript pour yt-dlp |

ffmpeg et Python font 49 Mo sur 77 : c'est là que se joue l'essentiel.

## Objectif

APK `arm64-v8a` sous 35 Mo, sans perdre de fonction (MP3, tags, pochette, MP4 fusionné).

## Pistes, de la plus sûre à la plus lourde

1. **ffmpeg allégé** : recompiler ffmpeg avec seulement ce que Ka7 utilise (décodeurs Opus/AAC/VP9/H.264, encodeur MP3 `libmp3lame`, muxers mp3/mp4/m4a, filtre de pochette). On part déjà de `tool/android/fix_ffmpeg_16k.sh` qui recompile libwebp avec le NDK. Gain attendu : 20 à 25 Mo.
2. **ffmpeg téléchargé au premier lancement** : comme sur bureau, l'APK ne contient pas ffmpeg ; il est téléchargé (et vérifié par SHA-256) quand on demande un MP3 la première fois. M4A et MP4 muxé marchent sans lui. Gain : 35 Mo dans l'APK, mais un téléchargement en plus au premier MP3.
3. **Mesures de détail** : `--obfuscate --split-debug-info` pour `libapp.so`, vérifier que R8 retire bien le Java inutile, retirer les ressources non utilisées (`res/`).
4. **Android App Bundle** : inutile hors Play Store (on distribue des APK), à ne pas retenir.

## Critères d'acceptation

- [x] APK `arm64-v8a` sous 35 Mo (mesuré par `tool/package_android.sh`) : 33,3 Mo (armeabi-v7a 31,3 Mo, x86_64 33,6 Mo), contre 66 Mo en 0.3.5.
- [x] MP3 tagué avec pochette, M4A et MP4 marchent sur le Samsung M36 (pages 4 Ko) et l'émulateur 16 Ko (voir Formats vérifiés).
- [x] Mise à jour sans perte d'historique : essayée depuis la 0.1.0 sur l'émulateur (APK release, même clé), archive et fichiers gardés.
- [x] La taille de chaque APK figure dans les notes de release (`size_of` dans `tool/release.sh`).

## Risques

- Un ffmpeg trop allégé casse un cas rare (une vidéo dans un codec oublié) : garder une liste des formats testés.
- La piste 2 ajoute un point de panne (téléchargement de ffmpeg hors ligne) : prévoir le même écran que `EngineGate` sur bureau.

## Réalisation (2026-11-05)

Piste 1 retenue : ffmpeg réduit, compilé par `tool/android/build_ffmpeg.sh` (remplace `fix_ffmpeg_16k.sh` et `splice_zip.py`). Les pistes 2 (téléchargement au premier MP3 : un point de panne de plus) et 3 (`--obfuscate` : moins de 1 Mo gagné, casse ce qui dépend des noms de types, rapports de plantage illisibles) n'ont pas été faites.

youtubedl-android lance `libffmpeg.so` (dossier des bibliothèques natives, `--ffmpeg-location`) et décompresse `libffmpeg.zip.so` pour les bibliothèques qu'il charge. Ka7 fournit les trois fichiers : deux programmes complets (ffmpeg 8.1.3 + LAME 3.100 dedans, seulement libc, libm, libz du système), et un zip qui ne contient qu'une note. Au premier lancement après la mise à jour, la bibliothèque voit la taille du zip changer, efface l'ancienne copie décompressée (78 Mo sur un téléphone arm64) et décompresse la nouvelle.

Principe « lire tout, écrire peu » : Ka7 ne réencode jamais la vidéo (un MP4 est assemblé tel quel), donc aucun encodeur vidéo. Lire : décodeurs audio courants (AAC, MP3, Opus, Vorbis, FLAC, ALAC, AC-3, PCM), images (WebP, PNG, JPEG, BMP), conteneurs courants (MP4/MOV, Matroska/WebM, MP3, AAC, Ogg, FLAC, WAV, FLV, MPEG-TS, concat, ffmetadata), tous les parsers et bitstream filters. Écrire : MP3 (LAME), AAC, JPEG, PNG. Pas de réseau : si une autre source (ticket 004) fait télécharger ffmpeg lui-même, ajouter une petite bibliothèque TLS (environ 1 Mo).

Ce qui reste dans l'APK `arm64-v8a` : Python 14,1 Mo, moteur Flutter 5,4 Mo, code Dart 3,3 Mo, yt-dlp (`res/Nc`) 3,2 Mo, ffmpeg 2,3 Mo, ffprobe 2,2 Mo.

## Formats vérifiés

Émulateur `Android_17.0_API_24` (x86_64, pages de 16 Ko), 2026-11-05.

Dans l'app, vraie vidéo YouTube (dQw4w9WgXcQ), fichiers relus avec ffprobe sur le bureau :

| Demande | Résultat |
|---|---|
| MP3 192 kbit/s | MP3 192 kbit/s converti depuis Opus, pochette JPG 1280×720, titre, artiste, date, lien |
| M4A | AAC d'origine, pochette JPG, tags |
| MP4 480p | AV1 + AAC assemblés sans réencodage, pochette JPG, tags |

Avec le ffmpeg du téléphone, sur des échantillons :

| Cas | Résultat |
|---|---|
| Opus → AAC (M4A d'une vidéo sans piste AAC) | OK |
| Opus → MP3 | OK |
| VP9 + Opus → MP4 | OK |
| H.264 + AAC → MP4 | OK |
| H.265 → MP4 | OK |
| MPEG-TS AAC → MP4 (`aac_adtstoasc`) | OK |
| Pochette WebP YouTube → JPG | OK |
| MP3 + pochette JPG | OK |
| M4A + pochette JPG | OK |

Samsung M36 (`arm64-v8a`, Android 16, pages de 4 Ko), 2026-11-06, mise à jour par-dessus la 0.3.5 publiée : même vidéo, mêmes résultats que l'émulateur (MP3 192 kbit/s, M4A AAC, MP4 480p AV1 + AAC, pochette JPG 1280×720 et tags dans les trois), rangés par artiste dans `Music/Ka7/Rick Astley` et `Movies/Ka7/Rick Astley`.

Même recette compilée pour Linux (`KA7_ABIS=linux`) : MP3 et MP4 1080p (AV1) par la commande `ka7`, avec le vrai yt-dlp ; yt-dlp confirme `ffmpeg 8.1.3, ffprobe 8.1.3`.

Pas essayé : `armeabi-v7a` (aucun appareil 32 bits).
