# 004 · Autres sources : SoundCloud, Vimeo, Facebook…

- **État** : Abandonné — remplacé par KA-5 à KA-8 (Fluent Tickets, `.taskIO/prd/autres-plateformes.md`) : Vimeo demande maintenant un compte, lot réduit à TikTok, Instagram, Facebook
- **Taille** : grosse
- **Plateformes** : toutes celles qui ont yt-dlp (bureau, Android) ; pas iOS (youtube_explode ne lit que YouTube)

## Contexte

Ka7 refuse tout lien qui n'est pas YouTube : `InvalidReason.notYouTube` dans `packages/ka7_core/lib/src/link_entry.dart`. Pourtant yt-dlp lit des centaines de sites ; Seal en profite.

Tout le cœur suppose YouTube : identifiant vidéo de 11 caractères (`VideoEntry.videoId`), `PlaylistEntry`, URL normalisées `youtube.com/watch?v=`, archive par `videoId`, miniatures `i.ytimg.com`, recherche `ytsearch`.

## Objectif

Accepter, en plus de YouTube, au moins **SoundCloud, Vimeo, Facebook, Bandcamp**, avec le même parcours : aperçu, cocher, télécharger, ranger, taguer, archive « Déjà là ».

## À faire

- **Cœur** : une entrée générique `WebEntry(url)` pour un lien d'un site reconnu ; identifiant d'archive `extractor:id` (`soundcloud:123456`) au lieu du seul `videoId`. Migration de l'archive (les entrées existantes deviennent `youtube:<id>`).
- **Liste des sites** : une liste courte et testée plutôt que « tout ce que yt-dlp sait lire » (certains sites demandent un compte, d'autres cassent souvent).
- **Moteur yt-dlp** : `parseProbeJson` lit déjà le JSON générique (`extractor_key`, `id`, `title`, `uploader`, `thumbnail`) ; vérifier sur une vraie sortie par site (fixtures dans `test/fixtures/`).
- **Miniatures** : prendre `thumbnail` dans la réponse de yt-dlp au lieu de construire l'URL `i.ytimg.com`.
- **Repli** : pas de youtube_explode pour ces sites ; message clair si yt-dlp échoue.
- **Écran Ajouter** : pastille par site (« SoundCloud », « Vimeo »…), recherche toujours limitée à YouTube.
- **Abonnements** : playlists SoundCloud et chaînes Vimeo suivables si yt-dlp les liste.

## Critères d'acceptation

- [ ] Un titre SoundCloud, une playlist SoundCloud, une vidéo Vimeo, une vidéo Facebook publique et un album Bandcamp donnent des fichiers tagués et rangés.
- [ ] « Déjà là » marche pour ces sites, et l'archive YouTube existante est gardée après migration.
- [ ] Un lien d'un site non pris en charge reste refusé avec la raison.
- [ ] Fixtures réelles par site, tests en TDD.

## Risques

- **Facebook, Instagram** : souvent derrière une connexion ; ne viser que le contenu public, sans gestion de comptes.
- **Droits** : SoundCloud et Bandcamp vendent de la musique ; Bandcamp ne donne en général qu'un extrait aux non-acheteurs. Ne jamais contourner un paiement (hors périmètre du document de conception).
- **Ampleur** : toucher `videoId` partout est un gros refactor ; écrire d'abord des tests de caractérisation.
