# 002 · Choix de la qualité audio et vidéo

- **État** : À faire
- **Taille** : moyenne
- **Plateformes** : toutes (moteur yt-dlp) ; youtube_explode limité (voir Risques)

## Contexte

La qualité est fixée dans `packages/ka7_engine_ytdlp/lib/src/ytdlp_downloader.dart` :

- MP3 : `--audio-quality 192K` ;
- M4A : meilleur audio m4a disponible ;
- MP4 : meilleure vidéo mp4 + meilleur audio, sans limite de résolution (un 4K pèse lourd).

Le document de conception prévoyait déjà : « MP3 128 / 192 / 320, audio d'origine, MP4 720p / 1080p / meilleure ».

## Objectif

Choisir la qualité dans l'aperçu, à côté du format, avec un défaut retenu dans les Réglages.

- **Audio (MP3)** : 128, 192 (défaut), 320 kbit/s.
- **Vidéo (MP4)** : 480p, 720p, 1080p (défaut), meilleure disponible.
- **M4A** : pas de choix (c'est l'audio d'origine, sans réencodage).

## À faire

- `ka7_core` : type `Quality` (ou un champ dans `DownloadRequest`), avec sa valeur par défaut.
- `YtDlpDownloader` : `--audio-quality 128K|192K|320K` ; pour la vidéo, `-f 'bv*[height<=1080][ext=mp4]+ba[ext=m4a]/b[height<=1080]'` selon le choix. Tests avec `FakeProcess` sur les arguments.
- `ExplodeEngine` : prendre le flux le plus proche du choix parmi ceux disponibles.
- Aperçu : sélecteur de qualité sous le sélecteur de format, qui change selon le format.
- Réglages : qualité par défaut (`quality.audio`, `quality.video`).
- Taille estimée dans le pied de l'aperçu si yt-dlp la donne (`filesize_approx`).
- File d'attente et `pending_downloads` : garder la qualité pour une reprise après plantage (migration de la base).

## Critères d'acceptation

- [ ] Un MP3 en 320 fait bien 320 kbit/s (`ffprobe`), un MP4 en 720p a bien 720 lignes.
- [ ] Le choix par défaut des Réglages est présélectionné dans l'aperçu.
- [ ] Une file interrompue reprend avec la même qualité.
- [ ] Tests unitaires (moteur, cœur) et d'écran (aperçu, réglages) en TDD.

## Risques

- MP3 en 320 depuis une source YouTube à ~130-160 kbit/s n'améliore rien et pèse plus : l'expliquer en une phrase sous le choix.
- youtube_explode (secours Android, seul moteur iOS) n'a que du MP4 muxé en 360p : la qualité vidéo y est ignorée, à dire clairement dans l'aperçu.
