# 003 · Lecteur audio / vidéo, avant et après téléchargement

- **État** : En cours
- **Taille** : grosse
- **Plateformes** : Android et Linux (iOS plus tard)

## Contexte

Ka7 télécharge mais ne lit pas : pour écouter, il faut une autre app. Le document de conception mettait le lecteur « hors périmètre » ; ce ticket revient sur cette décision. NewPipe montre que c'est l'attente des utilisateurs.

## Objectif

1. **Avant téléchargement (en ligne)** : depuis l'aperçu, écouter ou regarder un titre pour vérifier que c'est le bon, sans le télécharger.
2. **Après téléchargement (hors ligne)** : depuis la Bibliothèque, lire les fichiers téléchargés.
3. **Commandes** : comme un lecteur classique : lecture, pause, stop, suivant, précédent, avance et recul (±10 s), barre de progression déplaçable.
4. **Listes de lecture** : créer ses propres listes avec les fichiers téléchargés (ajouter, retirer, réordonner, renommer, supprimer) et les lire hors ligne ; file d'attente « lire ensuite » ; modes répétition et aléatoire.
5. **Arrière-plan** : l'audio continue écran éteint ou app en arrière-plan, avec les commandes dans la notification et l'écran de verrouillage (lecture, pause, stop, suivant, précédent).

## À faire

- **Choix de la bibliothèque** : `just_audio` + `audio_service` (audio, arrière-plan, notification), `media_kit` (audio et vidéo, Linux et Android). À trancher par un essai court.
- **Lecture en ligne** : URL du flux par yt-dlp (`-g`) ou youtube_explode ; les URL de YouTube expirent (quelques heures) : les demander au moment de lire.
- **Lecture hors ligne** : chemin du fichier, déjà dans l'historique (`HistoryItem.path`) ; sur Android, URI MediaStore (`Music/Ka7`).
- **Arrière-plan Android** : service de premier plan de type `mediaPlayback` (le `DownloadService` existant est `dataSync`), permission et notification média.
- **Interface** : mini-lecteur en bas (au-dessus de la barre d'onglets), écran plein pour la vidéo ; bouton ▶ sur les lignes de l'aperçu et de la Bibliothèque.
- **File de lecture** : lire une playlist téléchargée dans l'ordre ; « lire ensuite » et « ajouter à la file » depuis la Bibliothèque.
- **Listes de lecture utilisateur** : modèle `UserPlaylist` (nom, liste ordonnée d'entrées de l'historique) dans le cœur, stockage local à côté de l'historique ; écran de gestion (créer, renommer, supprimer, glisser pour réordonner) ; « Ajouter à une liste » sur les lignes de la Bibliothèque. Un fichier supprimé du disque est signalé et sauté, pas un plantage.
- **Commandes** : stop (arrête et revient au début, ferme la notification), avance/recul ±10 s, seek par la barre, répétition (aucune / une / toutes), aléatoire.

## Critères d'acceptation

- [ ] ▶ dans l'aperçu lit le titre en ligne en moins de 5 s sur une connexion correcte.
- [ ] ▶ dans la Bibliothèque lit le fichier sans réseau (mode avion).
- [x] L'audio continue écran éteint ; pause/suivant marchent depuis la notification et l'écran de verrouillage (vérifié sur émulateur, `tool/android/check_background.sh`).
- [ ] Lecture, pause, stop, suivant, précédent, ±10 s et seek marchent dans l'app, sur l'audio comme sur la vidéo.
- [ ] Je crée une liste, y ajoute des titres téléchargés, la réordonne, la lis hors ligne de bout en bout ; elle survit au redémarrage de l'app.
- [ ] Répétition et aléatoire marchent sur une liste.
- [x] La vidéo se lit en plein écran, rotation comprise (bouton plein écran : paysage et sans barres ; téléphone tourné sur une vidéo : plein écran ; tests d'écran).
- [x] Un téléchargement en cours ne coupe pas la lecture, et l'inverse (test d'app ; pas encore essayé sur téléphone).

## Ajouté en cours de route

- [x] Focus audio (Android) : pause pendant un appel puis reprise à la fin, pause pour une autre app (sans reprise), volume baissé sous un son de notification, pause quand on débranche le casque. Vérifié sur émulateur avec un vrai appel simulé (`adb emu gsm call`).
- [x] Image du titre dans la notification et sur l'écran verrouillé (image YouTube ; aucune pour les fichiers d'un dossier).

## Risques

- **Taille** : un lecteur vidéo ajoute plusieurs Mo (à mettre en regard du ticket 001).
- **Juridique** : lire YouTube hors de YouTube, sans publicité, est contre leurs conditions, comme le téléchargement ; même position que NewPipe.
- **Deux services Android** (téléchargement et lecture) à faire cohabiter.
