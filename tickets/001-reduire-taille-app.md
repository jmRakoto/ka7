# 001 · Réduire la taille de l'app

- **État** : À faire
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

- [ ] APK `arm64-v8a` sous 35 Mo (mesuré par `tool/package_android.sh`).
- [ ] MP3 tagué avec pochette, M4A et MP4 marchent sur le Samsung M36 (pages 4 Ko) et l'émulateur 16 Ko.
- [ ] Mise à jour depuis la 0.2.0 sans perte d'historique.
- [ ] La taille de chaque APK figure dans les notes de release.

## Risques

- Un ffmpeg trop allégé casse un cas rare (une vidéo dans un codec oublié) : garder une liste des formats testés.
- La piste 2 ajoute un point de panne (téléchargement de ffmpeg hors ligne) : prévoir le même écran que `EngineGate` sur bureau.
