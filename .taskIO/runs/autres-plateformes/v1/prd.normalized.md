# Autres plateformes : TikTok, Instagram, Facebook, SoundCloud…

## Contexte

Ka7 refuse tout lien qui n'est pas YouTube (`InvalidReason.notYouTube` dans
`packages/ka7_core/lib/src/link_entry.dart`). Tout le cœur suppose YouTube :
identifiant de 11 caractères (`VideoEntry.videoId`), `PlaylistEntry`, URL
normalisées `youtube.com/watch?v=`, archive « Déjà là » par `videoId`,
miniatures `i.ytimg.com`, recherche `ytsearch`.

Les moteurs savent pourtant lire d'autres sites :

- **Bureau** (Linux, Windows, macOS) : binaire autonome `yt-dlp_linux` /
  `yt-dlp.exe` (`packages/ka7_engine_ytdlp`), 1 755 extracteurs, avec
  `curl_cffi` (imitation de navigateur, utile pour TikTok et Vimeo).
- **Android** : youtubedl-android 0.18.1 (yt-dlp embarqué, sans `curl_cffi`).
- **iOS** : youtube_explode seulement, YouTube seulement : hors de ce lot.

Le ticket local `tickets/004-autres-sources.md` visait SoundCloud, Vimeo,
Facebook et Bandcamp ; l'analyse ci-dessous le remplace (Vimeo demande
maintenant un compte).

## Analyse des plateformes (yt-dlp 2026.10.26, 10/11/2026)

Sondage `yt-dlp -J --flat-playlist --skip-download` sur les URL de test des
extracteurs, sans compte ni cookies, depuis une connexion résidentielle.

| Plateforme | Résultat sans compte | Audio seul | Listes | Verdict |
|---|---|---|---|---|
| **TikTok** | Vidéo publique OK (8 formats, miniature) ; une vidéo « IP bloquée » ; profil `@nom` OK (325 vidéos), profil par id numérique KO | oui | profil | **Lot 1** |
| **Instagram** | Post et Reel publics OK (miniature, auteur) ; Stories et highlights : connexion exigée ; limite de débit fréquente | non (extraire de la vidéo) | non | **Lot 1** (public seulement) |
| **Facebook** | Reel public OK ; ancien format `/videos/` et `video.php` : « Cannot parse data » | non | non | **Lot 1** (Reels ; vidéos à revérifier) |
| **SoundCloud** | Titre OK, titre privé par lien secret OK, playlist (set) OK | oui | sets, profil | **Lot 1** |
| **Bandcamp** | Titre et album OK (titres en écoute libre) | oui | albums | **Lot 1** |
| **Mixcloud** | Mix OK (1 h, audio) ; un mix supprimé | oui | profil | **Lot 1** |
| **Dailymotion** | OK (2 sur 2) | non | playlists | **Lot 1** |
| **Twitch** | Clips OK, VOD OK (4 h 46) ; VOD expirées | oui (VOD) | non | Lot 2 |
| **X / Twitter** | Tweets de test sans vidéo (supprimés) : à revérifier sur un tweet récent | non | non | Lot 2 (à vérifier) |
| **Bilibili** | OK (2 sur 2) | oui | oui | Lot 2 |
| **VK** | OK (2 sur 2) | oui | oui | Lot 2 |
| **Pinterest** | OK (2 sur 2) | non | non | Lot 2 |
| **LinkedIn** | Posts publics OK | non | non | Lot 2 |
| **Bluesky** | 1 sur 2 OK (l'autre HTTP 400) | non | non | Lot 2 |
| **Streamable** | OK (2 sur 2) | non | non | Lot 2 |
| **Odysee (LBRY)** | OK (2 sur 2) | oui | oui | Lot 2 |
| **Vimeo** | « web client only works when logged-in » ; lecteur intégré : 403 | — | — | Écarté (compte requis) |
| **Reddit** | « Account authentication is required » | — | — | Écarté (compte requis) |
| **Tumblr** | HTTP 403 | — | — | Écarté |
| **Rumble** | HTTP 403 | — | — | Écarté |
| **Snapchat Spotlight** | « Unable to extract next.js data » (extracteur cassé) | — | — | Écarté |
| **Audiomack** | « Failed to parse JSON » (extracteur cassé) | — | — | Écarté |
| **Kick** | Non testé (DNS refusé ici) | — | — | À revérifier |
| **Threads** | Aucun extracteur yt-dlp | — | — | Impossible |
| **Spotify, Deezer, Apple Music, Netflix…** | DRM : yt-dlp ne les lit pas | — | — | Hors périmètre, définitif |

Les sites sociaux (TikTok, Instagram, Facebook, X) cassent souvent : yt-dlp
publie un correctif en quelques jours, et Ka7 met déjà son yt-dlp à jour
(bureau : dernière version ; Android : `updateYoutubeDL`).

## Objectif

Accepter, en plus de YouTube, les liens des plateformes du **lot 1** (TikTok,
Instagram, Facebook, SoundCloud, Bandcamp, Mixcloud, Dailymotion), avec le
même parcours : aperçu, cocher, télécharger (audio ou vidéo), ranger, taguer,
archive « Déjà là ». Le lot 2 suit, une plateforme à la fois, une fois le cœur
générique en place.

## Exigences

- **Cœur générique** : une entrée `WebEntry(url, site)` pour un lien d'un site
  reconnu ; identifiant d'archive `extracteur:id` (`tiktok:6742501081818877190`,
  `soundcloud:123998367`) au lieu du seul `videoId`. Migration de l'archive :
  les entrées existantes deviennent `youtube:<id>`, sans perte.
- **Liste blanche** : une liste courte et testée de sites (motifs d'hôte), pas
  « tout ce que yt-dlp sait lire ». Un lien hors liste reste refusé, avec la
  raison.
- **Moteur** : `parseProbeJson` lit le JSON générique (`extractor_key`, `id`,
  `title`, `uploader`, `thumbnail`, `duration`, `entries`) ; fixtures réelles
  par site dans `test/fixtures/`.
- **Miniatures** : `thumbnail` de la réponse yt-dlp au lieu de l'URL
  `i.ytimg.com` construite.
- **Audio** : quand le site n'a pas de format audio seul (Instagram,
  Facebook, Dailymotion), extraire l'audio de la vidéo avec ffmpeg.
- **Listes** : profil TikTok, set et profil SoundCloud, album Bandcamp,
  profil Mixcloud, playlist Dailymotion donnent une liste à cocher.
- **Erreurs claires** : « contenu privé ou connexion requise », « IP bloquée
  par le site », « extracteur à mettre à jour » (proposer la mise à jour de
  yt-dlp), au lieu du texte brut de yt-dlp.
- **Écran Ajouter** : pastille par site (« TikTok », « SoundCloud »…) ; la
  recherche reste limitée à YouTube.
- **Plateformes de l'app** : bureau et Android. Sur iOS, un lien non YouTube
  est refusé avec un message (« pas encore sur iPhone »).
- **Android** : vérifier chaque site du lot 1 sur le téléphone (sans
  `curl_cffi`) ; un site qui échoue seulement sur Android est noté et refusé
  sur Android. Le petit ffmpeg d'Android n'a pas de réseau : les flux HLS
  (Dailymotion, Twitch) doivent passer par le téléchargeur interne de yt-dlp,
  ou ffmpeg doit gagner les protocoles `http`/`https`/`hls`.

## Hors périmètre

Connexion aux comptes et cookies de navigateur (Stories Instagram, Vimeo,
Reddit, contenus privés), contournement de paiement ou de DRM (Spotify,
Deezer, achats Bandcamp), recherche sur ces sites, iOS, abonnements aux
profils (ticket séparé après le lot 1).
