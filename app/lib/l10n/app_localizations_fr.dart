// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Ka7';

  @override
  String get kindVideo => 'Vidéo';

  @override
  String get kindPlaylist => 'Playlist';

  @override
  String kindMix(int count) {
    return 'Mix · $count max';
  }

  @override
  String get kindVideoInPlaylist => 'Vidéo + playlist';

  @override
  String get kindChannel => 'Chaîne';

  @override
  String get kindDuplicate => 'Doublon';

  @override
  String get kindInvalid => 'Ignorée';

  @override
  String get reasonNotYouTube => 'Seul YouTube est pris en charge';

  @override
  String get reasonNoVideoOrPlaylist => 'Lien YouTube sans vidéo ni playlist';

  @override
  String get reasonFreeText =>
      'Pas un lien : pour chercher, passe par « Recherche YouTube »';

  @override
  String get detailDuplicate => 'Déjà présent plus haut';

  @override
  String get detailVideoInPlaylist =>
      'Choix à l\'aperçu : cette vidéo ou toute la playlist';

  @override
  String get summaryNone => 'Aucune entrée reconnue';

  @override
  String summaryRecognized(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrées reconnues',
      one: '$count entrée reconnue',
    );
    return '$_temp0';
  }

  @override
  String summarySkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ignorées',
      one: '$count ignorée',
    );
    return '$_temp0';
  }

  @override
  String get previewButton => 'Voir l\'aperçu';

  @override
  String get itemPrivate => 'Vidéo privée';

  @override
  String get itemDeleted => 'Vidéo supprimée';

  @override
  String get itemUnavailable => 'Vidéo indisponible';

  @override
  String trackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres',
      one: '$count titre',
    );
    return '$_temp0';
  }

  @override
  String get probePrivate => 'Vidéo privée';

  @override
  String get probeUnavailable => 'Vidéo indisponible';

  @override
  String get probeNetwork => 'Pas de connexion à YouTube';

  @override
  String get probeUnknown => 'Lecture impossible';

  @override
  String get downloadButton => 'Télécharger';

  @override
  String get probeEngineMissing => 'yt-dlp n\'est pas installé';

  @override
  String get runTitle => 'File d\'attente';

  @override
  String get runActive => 'Téléchargement en cours';

  @override
  String get runRunning => 'En cours';

  @override
  String get runWaiting => 'En attente';

  @override
  String get runFinished => 'Traités';

  @override
  String runCount(int done, int total) {
    return '$done / $total';
  }

  @override
  String percent(int value) {
    return '$value %';
  }

  @override
  String speed(String value) {
    return '$value Mo/s';
  }

  @override
  String get cancelAll => 'Tout annuler';

  @override
  String get runDone => 'Terminé';

  @override
  String get statusSucceeded => 'Réussi';

  @override
  String get statusSkipped => 'Déjà là';

  @override
  String get statusQueued => 'Dans la file';

  @override
  String get statusFailed => 'Échoué';

  @override
  String get statusCancelled => 'Annulé';

  @override
  String countSucceeded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count réussis',
      one: '$count réussi',
    );
    return '$_temp0';
  }

  @override
  String countSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count déjà là',
      one: '$count déjà là',
    );
    return '$_temp0';
  }

  @override
  String countFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count échoués',
      one: '$count échoué',
    );
    return '$_temp0';
  }

  @override
  String countCancelled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count annulés',
      one: '$count annulé',
    );
    return '$_temp0';
  }

  @override
  String get retryButton => 'Réessayer';

  @override
  String get retryOne => 'Réessayer ce titre';

  @override
  String get retryAll => 'Tout réessayer';

  @override
  String retryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres n\'ont pas abouti',
      one: '$count titre n\'a pas abouti',
    );
    return '$_temp0';
  }

  @override
  String get copyFailed => 'Copier les liens échoués';

  @override
  String get copiedFailed =>
      'Liens copiés : colle-les dans Ajouter pour réessayer plus tard.';

  @override
  String get formatMp3 => 'MP3 · audio';

  @override
  String get formatMp4 => 'MP4 · vidéo';

  @override
  String get engineMissingTitle => 'Une dernière étape';

  @override
  String get engineMissingBody =>
      'Ka7 a besoin de quelques compléments pour lire YouTube et créer tes MP3. Il les télécharge et les range dans son propre dossier.';

  @override
  String get engineInstall => 'Installer';

  @override
  String engineInstalling(String percent) {
    return 'Téléchargement des compléments… $percent';
  }

  @override
  String get engineFailed =>
      'Installation impossible. Vérifie ta connexion, puis réessaie.';

  @override
  String get navAdd => 'Ajouter';

  @override
  String get navQueue => 'File';

  @override
  String get navLibrary => 'Bibliothèque';

  @override
  String get navSettings => 'Réglages';

  @override
  String get runRemoved => 'File retirée';

  @override
  String get removeRun => 'Retirer cette file';

  @override
  String get queueEarlier => 'Plus tôt';

  @override
  String get queueClear => 'Effacer';

  @override
  String get queueClearHint => 'Retirer les files terminées';

  @override
  String get queueEmpty => 'Aucun téléchargement en cours.';

  @override
  String get libraryTitle => 'Bibliothèque';

  @override
  String get librarySearch => 'Chercher un titre ou une playlist';

  @override
  String get selectEntries => 'Sélectionner';

  @override
  String get stopSelecting => 'Arrêter la sélection';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnés',
      one: '$count sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get removeButton => 'Retirer';

  @override
  String removeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Retirer ces $count titres de la bibliothèque ?',
      one: 'Retirer ce titre de la bibliothèque ?',
    );
    return '$_temp0';
  }

  @override
  String get removeBody =>
      'Les fichiers restent sur l\'appareil. Ces titres pourront être téléchargés de nouveau.';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get libraryEmpty => 'Rien n\'a encore été téléchargé.';

  @override
  String get libraryNoMatch => 'Aucun résultat.';

  @override
  String get openFolder => 'Ouvrir le dossier';

  @override
  String get forget => 'Oublier';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsDownloads => 'Téléchargements';

  @override
  String get settingsFolders => 'Dossiers';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsConcurrencyHelp =>
      'Combien de titres à la fois, pour les prochaines files.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutDevVersion => 'Version de développement';

  @override
  String get aboutTitle => 'À propos de Ka7';

  @override
  String get aboutMadeBy => 'Développé par Rakoto Ketrika';

  @override
  String get aboutTagline =>
      'Tes vidéos et ta musique, en fichiers propres que tu gardes.';

  @override
  String get aboutPrivate =>
      'Tout reste sur ton appareil : aucun compte, aucune publicité, aucun suivi.';

  @override
  String get aboutDescription =>
      'Ka7 transforme des vidéos YouTube en fichiers MP3, M4A ou MP4 que tu gardes pour toujours, même sans connexion. Une vidéo, une playlist entière ou toute une chaîne : tu colles, tu vérifies, Ka7 s\'occupe du reste.';

  @override
  String get aboutFeatures => 'Ce que fait Ka7';

  @override
  String get featureAddTitle => 'Ajoute de toutes les façons';

  @override
  String get featureAddBody =>
      'Colle un ou plusieurs liens (vidéo, playlist, chaîne, mix), cherche directement sur YouTube, importe un fichier .txt, glisse un lien sur la fenêtre ou partage-le depuis l\'app YouTube.';

  @override
  String get featurePreviewTitle => 'Vérifie avant de télécharger';

  @override
  String get featurePreviewBody =>
      'L\'aperçu montre chaque titre avec sa miniature, sa durée et sa date. Coche ce que tu veux, filtre une longue liste, et ce que tu as déjà est marqué « Déjà là ».';

  @override
  String get featureFormatTitle => 'Choisis le format et la qualité';

  @override
  String get featureFormatBody =>
      'MP3 pour la musique, M4A pour le son d\'origine, MP4 pour la vidéo. Qualité au choix : de 128 à 320 kbit/s, de 480p à la meilleure image.';

  @override
  String get featureFilesTitle => 'Des fichiers propres et rangés';

  @override
  String get featureFilesBody =>
      'Titre, artiste, album, numéro de piste et pochette dans chaque MP3. Rangés par playlist ou par artiste, dans le dossier de ton choix.';

  @override
  String get featureQueueTitle => 'Suis la file';

  @override
  String get featureQueueBody =>
      'Plusieurs titres à la fois, avec la progression et la vitesse. Annule ou réessaie un titre, reprends une file interrompue, et reçois une notification à la fin.';

  @override
  String get featureLibraryTitle => 'Retrouve tout dans la Bibliothèque';

  @override
  String get featureLibraryBody =>
      'L\'historique jour par jour, avec recherche et filtres. Ouvre le dossier d\'un titre ou mets une playlist à jour avec ses nouveaux titres.';

  @override
  String get featureFollowTitle => 'Suis tes playlists et tes chaînes';

  @override
  String get featureFollowBody =>
      'Abonne-toi depuis l\'aperçu : au démarrage, Ka7 te propose leurs nouveaux titres. Il te prévient aussi quand une nouvelle version de Ka7 sort.';

  @override
  String get aboutOpen => 'Plus d\'infos sur Ka7';

  @override
  String get resetFolder => 'Revenir au dossier par défaut';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String filterAll(int count) {
    return 'Tout · $count';
  }

  @override
  String filterSucceeded(int count) {
    return 'Réussis · $count';
  }

  @override
  String filterFailed(int count) {
    return 'Échoués · $count';
  }

  @override
  String get actions => 'Actions';

  @override
  String get pasteLinks => 'Coller';

  @override
  String get addTipLines =>
      'Un lien par ligne : vidéo, playlist, chaîne ou mix YouTube.';

  @override
  String get addTipShare => 'Depuis l\'app YouTube : Partager → Ka7.';

  @override
  String get addTipDrop =>
      'Glisse des liens ou un fichier .txt sur la fenêtre.';

  @override
  String get addTipImport =>
      'Ou importe une liste de liens depuis un fichier .txt.';

  @override
  String get recentSearches => 'Recherches récentes';

  @override
  String get clearRecent => 'Effacer les recherches récentes';

  @override
  String qualityKbps(int kbps) {
    return '$kbps kbit/s';
  }

  @override
  String get qualityBest => 'Max';

  @override
  String get qualityOriginal => 'Audio d\'origine, sans réencodage';

  @override
  String get settingsQuality => 'Qualité';

  @override
  String get settingsQualityHelp =>
      'Choisie d\'avance dans l\'aperçu. Au-delà de 192 kbit/s, un MP3 tiré de YouTube ne sonne guère mieux, il pèse juste plus lourd.';

  @override
  String entriesForgotten(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres oubliés',
      one: '$count titre oublié',
    );
    return '$_temp0';
  }

  @override
  String entryForgotten(String title) {
    return '« $title » oublié';
  }

  @override
  String get backToTop => 'Revenir en haut';

  @override
  String get searchChannels => 'Chaînes';

  @override
  String get channelLabel => 'Chaîne YouTube';

  @override
  String get openOnYouTube => 'Ouvrir sur YouTube';

  @override
  String get filterTitles => 'Filtrer les titres…';

  @override
  String filterCount(int shown, int total) {
    return '$shown sur $total';
  }

  @override
  String get filterNoMatch => 'Aucun titre ne correspond.';

  @override
  String channelCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chaîne YouTube · $count titres',
      one: 'Chaîne YouTube · $count titre',
    );
    return '$_temp0';
  }

  @override
  String get ageToday => 'aujourd\'hui';

  @override
  String ageDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'il y a $count jour',
    );
    return '$_temp0';
  }

  @override
  String ageWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count semaines',
      one: 'il y a $count semaine',
    );
    return '$_temp0';
  }

  @override
  String ageMonths(int count) {
    return 'il y a $count mois';
  }

  @override
  String ageYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count ans',
      one: 'il y a $count an',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get languageSystem => 'Système';

  @override
  String get folderMusic => 'Dossier de la musique (MP3)';

  @override
  String get folderVideos => 'Dossier des vidéos (MP4)';

  @override
  String get changeMusicFolder => 'Changer le dossier de la musique';

  @override
  String get changeVideosFolder => 'Changer le dossier des vidéos';

  @override
  String get addTitle => 'Ajouter';

  @override
  String get addHint =>
      'Colle des liens, des ID ou une liste : un par ligne, ou séparés par des espaces.';

  @override
  String get previewTitle => 'Aperçu';

  @override
  String get engineSize => 'Environ 180 Mo à télécharger, une seule fois.';

  @override
  String get formatM4a => 'M4A · d\'origine';

  @override
  String get formatUnsupported => 'Format impossible sur cet appareil';

  @override
  String get notificationTitle => 'Téléchargement';

  @override
  String get interruptedTitle => 'File interrompue';

  @override
  String interruptedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres n\'ont pas fini la dernière fois.',
      one: '$count titre n\'a pas fini la dernière fois.',
    );
    return '$_temp0';
  }

  @override
  String get interruptedResume => 'Reprendre';

  @override
  String get interruptedDiscard => 'Abandonner';

  @override
  String get dropHint => 'Dépose tes liens ou un fichier .txt';

  @override
  String get importFile => 'Importer';

  @override
  String get clearLinks => 'Effacer';

  @override
  String get settingsConcurrency => 'Téléchargements simultanés';

  @override
  String get settingsMixLimit => 'Mix YouTube : titres lus';

  @override
  String get updatePlaylist => 'Mettre à jour la playlist';

  @override
  String get notifyDoneTitle => 'Téléchargements terminés';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get settingsMixLimitHelp =>
      'Un mix (lien qui contient « list=RD ») est une playlist sans fin que YouTube compose à partir d\'une vidéo. Ka7 n\'en lit que les premiers titres, ce nombre-ci.';

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get welcomeTitle1 => 'Bienvenue dans Ka7';

  @override
  String get welcomeBody1 =>
      'Ka7 enregistre YouTube comme on enregistrait une cassette : des liens deviennent des fichiers MP3 ou MP4 propres.';

  @override
  String get welcomeTitle2 => 'Ajoute de toutes les façons';

  @override
  String get welcomeBody2 =>
      'Une vidéo, une playlist, une chaîne, ou juste quelques mots.';

  @override
  String get welcomeTitle3 => 'Vérifie avant de télécharger';

  @override
  String get welcomeBody3 =>
      'L\'aperçu montre chaque titre avant que rien ne parte.';

  @override
  String get welcomeSkip => 'Passer';

  @override
  String get welcomeNext => 'Suivant';

  @override
  String get welcomeStart => 'Commencer';

  @override
  String welcomePage(int page, int count) {
    return 'Page $page sur $count';
  }

  @override
  String get kindSearch => 'Recherche';

  @override
  String detailSearch(String query) {
    return 'Résultats YouTube pour « $query »';
  }

  @override
  String searchResults(String query) {
    return 'Recherche : $query';
  }

  @override
  String get settingsLayout => 'Rangement des fichiers';

  @override
  String get layoutPlaylist => 'Par playlist';

  @override
  String get layoutArtist => 'Par artiste';

  @override
  String get settingsLayoutHelp =>
      'Par playlist : un dossier par playlist, titres numérotés. Par artiste : un dossier par chaîne YouTube qui a publié la vidéo.';

  @override
  String get cancelOne => 'Annuler ce titre';

  @override
  String get modeLinks => 'Liens';

  @override
  String get modeSearch => 'Recherche YouTube';

  @override
  String get searchButton => 'Rechercher';

  @override
  String get searchHint => 'Artiste, titre, album…';

  @override
  String get searchFooter => '20 résultats, à cocher dans l\'aperçu';

  @override
  String get loadingLink => 'Lecture du lien…';

  @override
  String loadingSearch(String query) {
    return 'Recherche de « $query »…';
  }

  @override
  String get searchAgain => 'Nouvelle recherche';

  @override
  String get follow => 'Suivre';

  @override
  String get following => 'Suivi';

  @override
  String get newsTitle => 'Nouveautés';

  @override
  String get newsShow => 'Voir';

  @override
  String get newsLater => 'Plus tard';

  @override
  String newTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouveaux titres',
      one: '$count nouveau titre',
    );
    return '$_temp0';
  }

  @override
  String get settingsSubscriptions => 'Abonnements';

  @override
  String get subscriptionsEmpty =>
      'Aucun abonnement. Suis une playlist ou une chaîne depuis l\'aperçu : ses nouveaux titres te seront proposés au démarrage.';

  @override
  String get unfollow => 'Ne plus suivre';

  @override
  String get welcomePoint1a =>
      'MP3 tagués : titre, artiste, album, numéro de piste';

  @override
  String get welcomePoint1b =>
      'Rangés par playlist ou par artiste, bien nommés';

  @override
  String get welcomePoint1c =>
      'Tout reste sur ton appareil : aucun compte, aucun suivi';

  @override
  String get welcomePoint2a =>
      'Colle un ou plusieurs liens, même au milieu d\'un texte';

  @override
  String get welcomePoint2b => 'Cherche sur YouTube et coche les résultats';

  @override
  String get welcomePoint2c => 'Importe un fichier de liens (.txt)';

  @override
  String get welcomePoint2d => 'Glisse un lien ou un fichier sur la fenêtre';

  @override
  String get welcomePoint2e => 'Partage depuis l\'app YouTube vers Ka7';

  @override
  String get welcomePoint3a =>
      'Décoche ce que tu ne veux pas, ou tout d\'un coup';

  @override
  String get welcomePoint3b => 'Ce que tu as déjà est repéré : « Déjà là »';

  @override
  String get welcomePoint3c =>
      'MP3 ou MP4, plusieurs téléchargements à la fois';

  @override
  String get welcomePoint3d =>
      'Annule un titre ou toute la file, à tout moment';

  @override
  String get welcomeTitle4 => 'Rien ne se perd';

  @override
  String get welcomeBody4 => 'Ka7 garde la trace de tout ce qui passe.';

  @override
  String get welcomePoint4a =>
      'La Bibliothèque retrouve chaque fichier et son dossier';

  @override
  String get welcomePoint4b =>
      'Suis une playlist : ses nouveautés te sont proposées';

  @override
  String get welcomePoint4c => 'Une file coupée reprend au lancement suivant';

  @override
  String get welcomePoint4d => 'Les échecs se relancent en un clic';

  @override
  String get welcomePrevious => 'Précédent';

  @override
  String get welcomeSetupTitle => 'Avant de commencer';

  @override
  String get welcomeSetupBody => 'Choisis ta langue et l\'apparence de Ka7.';

  @override
  String get welcomeSetupLater =>
      'Tu pourras changer ça plus tard dans Réglages.';

  @override
  String get welcomePoint4e =>
      'Une notification te prévient quand tout est fini';

  @override
  String get engineChecking => 'Préparation du moteur…';

  @override
  String get close => 'Fermer';

  @override
  String updateAvailable(String version) {
    return 'Ka7 $version est disponible';
  }

  @override
  String updateCurrent(String version) {
    return 'Tu as la $version.';
  }

  @override
  String get updateDownload => 'Télécharger la mise à jour';

  @override
  String get playerPlay => 'Lire';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerStop => 'Arrêter';

  @override
  String get playerNext => 'Suivant';

  @override
  String get playerPrevious => 'Précédent';

  @override
  String get playerForward => 'Avancer de 10 s';

  @override
  String get playerBack => 'Reculer de 10 s';

  @override
  String get playerRepeatOff => 'Répéter : non';

  @override
  String get playerRepeatAll => 'Répéter la liste';

  @override
  String get playerRepeatOne => 'Répéter ce titre';

  @override
  String get playerShuffle => 'Lecture aléatoire';

  @override
  String get playerClose => 'Fermer le lecteur';

  @override
  String get playerOpen => 'Ouvrir le lecteur';

  @override
  String get playerQueue => 'File de lecture';

  @override
  String get playerNowPlaying => 'En cours de lecture';

  @override
  String get playerRemoveFromQueue => 'Retirer de la file de lecture';

  @override
  String get playerMissingFile => 'Fichier introuvable : déplacé ou supprimé';

  @override
  String get playerOffline => 'Lecture en ligne impossible : pas de réseau';

  @override
  String get playerUnavailable => 'Ce titre ne peut pas être lu';

  @override
  String get playerLoading => 'Chargement…';

  @override
  String get playerMissingBadge => 'Introuvable';

  @override
  String get playNext => 'Lire ensuite';

  @override
  String get enqueue => 'Ajouter à la file de lecture';

  @override
  String get addToPlaylist => 'Ajouter à une liste…';

  @override
  String get playAll => 'Tout lire';

  @override
  String get shuffleAll => 'Lecture aléatoire';

  @override
  String get playlistsTitle => 'Listes de lecture';

  @override
  String get playlistsOpen => 'Mes listes';

  @override
  String get newPlaylist => 'Nouvelle liste';

  @override
  String get playlistName => 'Nom de la liste';

  @override
  String get createButton => 'Créer';

  @override
  String get saveButton => 'Enregistrer';

  @override
  String get renamePlaylist => 'Renommer';

  @override
  String get deletePlaylist => 'Supprimer la liste';

  @override
  String deletePlaylistTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get deletePlaylistBody =>
      'Seule la liste disparaît : les fichiers restent.';

  @override
  String get playlistsEmpty =>
      'Aucune liste pour l\'instant. Crée-en une, puis ajoute-y des titres depuis la Bibliothèque.';

  @override
  String get playlistEmpty =>
      'Liste vide : ajoute des titres depuis la Bibliothèque, menu ⋮ « Ajouter à une liste… ».';

  @override
  String addedToPlaylist(String name) {
    return 'Ajouté à « $name »';
  }

  @override
  String get removeFromPlaylist => 'Retirer de la liste';

  @override
  String get playlistActions => 'Actions de la liste';

  @override
  String get listenOnline => 'Écouter avant de télécharger';

  @override
  String get watchOnline => 'Regarder avant de télécharger';

  @override
  String get navPlayer => 'Lecteur';

  @override
  String playerTitles(int count) {
    return 'Titres · $count';
  }

  @override
  String playerLists(int count) {
    return 'Listes · $count';
  }

  @override
  String get playerEmpty =>
      'Rien à écouter pour l\'instant : les titres téléchargés arrivent ici, prêts à lire sans réseau.';

  @override
  String get playerSearch => 'Chercher un titre';

  @override
  String get playerNoMatch => 'Aucun titre ne correspond.';

  @override
  String get addFolder => 'Ajouter un dossier';

  @override
  String get folderEmpty =>
      'Aucun fichier à lire dans ce dossier : vide, déplacé, ou plus accessible.';

  @override
  String get playerNotificationChannel => 'Lecture';
}
