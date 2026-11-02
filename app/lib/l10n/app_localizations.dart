import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ka7'**
  String get appTitle;

  /// No description provided for @kindVideo.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo'**
  String get kindVideo;

  /// No description provided for @kindPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Playlist'**
  String get kindPlaylist;

  /// No description provided for @kindMix.
  ///
  /// In fr, this message translates to:
  /// **'Mix · {count} max'**
  String kindMix(int count);

  /// No description provided for @kindVideoInPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo + playlist'**
  String get kindVideoInPlaylist;

  /// No description provided for @kindChannel.
  ///
  /// In fr, this message translates to:
  /// **'Chaîne'**
  String get kindChannel;

  /// No description provided for @kindDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Doublon'**
  String get kindDuplicate;

  /// No description provided for @kindInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Ignorée'**
  String get kindInvalid;

  /// No description provided for @reasonNotYouTube.
  ///
  /// In fr, this message translates to:
  /// **'Seul YouTube est pris en charge'**
  String get reasonNotYouTube;

  /// No description provided for @reasonNoVideoOrPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Lien YouTube sans vidéo ni playlist'**
  String get reasonNoVideoOrPlaylist;

  /// No description provided for @reasonFreeText.
  ///
  /// In fr, this message translates to:
  /// **'Texte libre : la recherche n\'est pas encore disponible'**
  String get reasonFreeText;

  /// No description provided for @detailDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Déjà présent plus haut'**
  String get detailDuplicate;

  /// No description provided for @detailVideoInPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Choix à l\'aperçu : cette vidéo ou toute la playlist'**
  String get detailVideoInPlaylist;

  /// No description provided for @summaryNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune entrée reconnue'**
  String get summaryNone;

  /// No description provided for @summaryRecognized.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} entrée reconnue} other{{count} entrées reconnues}}'**
  String summaryRecognized(int count);

  /// No description provided for @summarySkipped.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} ignorée} other{{count} ignorées}}'**
  String summarySkipped(int count);

  /// No description provided for @previewButton.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'aperçu'**
  String get previewButton;

  /// No description provided for @itemPrivate.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo privée'**
  String get itemPrivate;

  /// No description provided for @itemDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo supprimée'**
  String get itemDeleted;

  /// No description provided for @itemUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo indisponible'**
  String get itemUnavailable;

  /// No description provided for @trackCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} titre} other{{count} titres}}'**
  String trackCount(int count);

  /// No description provided for @probePrivate.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo privée'**
  String get probePrivate;

  /// No description provided for @probeUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo indisponible'**
  String get probeUnavailable;

  /// No description provided for @probeNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion à YouTube'**
  String get probeNetwork;

  /// No description provided for @probeUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Lecture impossible'**
  String get probeUnknown;

  /// No description provided for @downloadButton.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger'**
  String get downloadButton;

  /// No description provided for @probeEngineMissing.
  ///
  /// In fr, this message translates to:
  /// **'yt-dlp n\'est pas installé'**
  String get probeEngineMissing;

  /// No description provided for @runTitle.
  ///
  /// In fr, this message translates to:
  /// **'File d\'attente'**
  String get runTitle;

  /// No description provided for @runRunning.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get runRunning;

  /// No description provided for @runWaiting.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get runWaiting;

  /// No description provided for @runFinished.
  ///
  /// In fr, this message translates to:
  /// **'Traités'**
  String get runFinished;

  /// No description provided for @runCount.
  ///
  /// In fr, this message translates to:
  /// **'{done} / {total}'**
  String runCount(int done, int total);

  /// No description provided for @percent.
  ///
  /// In fr, this message translates to:
  /// **'{value} %'**
  String percent(int value);

  /// No description provided for @speed.
  ///
  /// In fr, this message translates to:
  /// **'{value} Mo/s'**
  String speed(String value);

  /// No description provided for @cancelAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout annuler'**
  String get cancelAll;

  /// No description provided for @runDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get runDone;

  /// No description provided for @statusSucceeded.
  ///
  /// In fr, this message translates to:
  /// **'Réussi'**
  String get statusSucceeded;

  /// No description provided for @statusSkipped.
  ///
  /// In fr, this message translates to:
  /// **'Déjà là'**
  String get statusSkipped;

  /// No description provided for @statusFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échoué'**
  String get statusFailed;

  /// No description provided for @statusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get statusCancelled;

  /// No description provided for @countSucceeded.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} réussi} other{{count} réussis}}'**
  String countSucceeded(int count);

  /// No description provided for @countSkipped.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} déjà là} other{{count} déjà là}}'**
  String countSkipped(int count);

  /// No description provided for @countFailed.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} échoué} other{{count} échoués}}'**
  String countFailed(int count);

  /// No description provided for @countCancelled.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} annulé} other{{count} annulés}}'**
  String countCancelled(int count);

  /// No description provided for @retryButton.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retryButton;

  /// No description provided for @copyFailed.
  ///
  /// In fr, this message translates to:
  /// **'Copier les liens échoués'**
  String get copyFailed;

  /// No description provided for @copiedFailed.
  ///
  /// In fr, this message translates to:
  /// **'Liens copiés : colle-les dans Ajouter pour réessayer plus tard.'**
  String get copiedFailed;

  /// No description provided for @formatMp3.
  ///
  /// In fr, this message translates to:
  /// **'MP3 · audio'**
  String get formatMp3;

  /// No description provided for @formatMp4.
  ///
  /// In fr, this message translates to:
  /// **'MP4 · vidéo'**
  String get formatMp4;

  /// No description provided for @engineMissingBoth.
  ///
  /// In fr, this message translates to:
  /// **'Il manque yt-dlp et ffmpeg'**
  String get engineMissingBoth;

  /// No description provided for @engineMissingYtDlp.
  ///
  /// In fr, this message translates to:
  /// **'Il manque yt-dlp'**
  String get engineMissingYtDlp;

  /// No description provided for @engineMissingFfmpeg.
  ///
  /// In fr, this message translates to:
  /// **'Il manque ffmpeg'**
  String get engineMissingFfmpeg;

  /// No description provided for @engineMissingBody.
  ///
  /// In fr, this message translates to:
  /// **'Ka7 s\'en sert pour lire YouTube et créer les MP3. Il les télécharge depuis leurs sites officiels et les garde dans son propre dossier.'**
  String get engineMissingBody;

  /// No description provided for @engineInstall.
  ///
  /// In fr, this message translates to:
  /// **'Installer'**
  String get engineInstall;

  /// No description provided for @engineInstalling.
  ///
  /// In fr, this message translates to:
  /// **'Installation de {tool}… {percent}'**
  String engineInstalling(String tool, String percent);

  /// No description provided for @engineFailed.
  ///
  /// In fr, this message translates to:
  /// **'Installation impossible. Vérifie ta connexion, puis réessaie.'**
  String get engineFailed;

  /// No description provided for @navAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get navAdd;

  /// No description provided for @navQueue.
  ///
  /// In fr, this message translates to:
  /// **'File'**
  String get navQueue;

  /// No description provided for @navLibrary.
  ///
  /// In fr, this message translates to:
  /// **'Bibliothèque'**
  String get navLibrary;

  /// No description provided for @navSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get navSettings;

  /// No description provided for @queueEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun téléchargement en cours.'**
  String get queueEmpty;

  /// No description provided for @libraryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bibliothèque'**
  String get libraryTitle;

  /// No description provided for @librarySearch.
  ///
  /// In fr, this message translates to:
  /// **'Chercher un titre ou une playlist'**
  String get librarySearch;

  /// No description provided for @libraryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Rien n\'a encore été téléchargé.'**
  String get libraryEmpty;

  /// No description provided for @libraryNoMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat.'**
  String get libraryNoMatch;

  /// No description provided for @openFolder.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le dossier'**
  String get openFolder;

  /// No description provided for @forget.
  ///
  /// In fr, this message translates to:
  /// **'Oublier'**
  String get forget;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get languageSystem;

  /// No description provided for @folderMusic.
  ///
  /// In fr, this message translates to:
  /// **'Dossier de la musique (MP3)'**
  String get folderMusic;

  /// No description provided for @folderVideos.
  ///
  /// In fr, this message translates to:
  /// **'Dossier des vidéos (MP4)'**
  String get folderVideos;

  /// No description provided for @changeMusicFolder.
  ///
  /// In fr, this message translates to:
  /// **'Changer le dossier de la musique'**
  String get changeMusicFolder;

  /// No description provided for @changeVideosFolder.
  ///
  /// In fr, this message translates to:
  /// **'Changer le dossier des vidéos'**
  String get changeVideosFolder;

  /// No description provided for @addTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get addTitle;

  /// No description provided for @addHint.
  ///
  /// In fr, this message translates to:
  /// **'Colle des liens, des ID ou une liste : un par ligne, ou séparés par des espaces.'**
  String get addHint;

  /// No description provided for @previewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get previewTitle;

  /// No description provided for @engineSize.
  ///
  /// In fr, this message translates to:
  /// **'Environ 180 Mo à télécharger, une seule fois.'**
  String get engineSize;

  /// No description provided for @formatM4a.
  ///
  /// In fr, this message translates to:
  /// **'M4A · d\'origine'**
  String get formatM4a;

  /// No description provided for @formatUnsupported.
  ///
  /// In fr, this message translates to:
  /// **'Format impossible sur cet appareil'**
  String get formatUnsupported;

  /// No description provided for @notificationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement'**
  String get notificationTitle;

  /// No description provided for @interruptedTitle.
  ///
  /// In fr, this message translates to:
  /// **'File interrompue'**
  String get interruptedTitle;

  /// No description provided for @interruptedBody.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} titre n\'a pas fini la dernière fois.} other{{count} titres n\'ont pas fini la dernière fois.}}'**
  String interruptedBody(int count);

  /// No description provided for @interruptedResume.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get interruptedResume;

  /// No description provided for @interruptedDiscard.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner'**
  String get interruptedDiscard;

  /// No description provided for @dropHint.
  ///
  /// In fr, this message translates to:
  /// **'Dépose tes liens ou un fichier .txt'**
  String get dropHint;

  /// No description provided for @importFile.
  ///
  /// In fr, this message translates to:
  /// **'Importer un fichier'**
  String get importFile;

  /// No description provided for @clearLinks.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get clearLinks;

  /// No description provided for @settingsConcurrency.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargements simultanés'**
  String get settingsConcurrency;

  /// No description provided for @settingsMixLimit.
  ///
  /// In fr, this message translates to:
  /// **'Mix YouTube : titres lus'**
  String get settingsMixLimit;

  /// No description provided for @updatePlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour la playlist'**
  String get updatePlaylist;

  /// No description provided for @notifyDoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargements terminés'**
  String get notifyDoneTitle;

  /// No description provided for @settingsTheme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @settingsMixLimitHelp.
  ///
  /// In fr, this message translates to:
  /// **'Un mix (lien qui contient « list=RD ») est une playlist sans fin que YouTube compose à partir d\'une vidéo. Ka7 n\'en lit que les premiers titres, ce nombre-ci.'**
  String get settingsMixLimitHelp;

  /// No description provided for @selectAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout sélectionner'**
  String get selectAll;

  /// No description provided for @welcomeTitle1.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans Ka7'**
  String get welcomeTitle1;

  /// No description provided for @welcomeBody1.
  ///
  /// In fr, this message translates to:
  /// **'Ka7 enregistre YouTube comme on enregistrait une cassette : des liens deviennent des fichiers MP3 ou MP4 propres.'**
  String get welcomeBody1;

  /// No description provided for @welcomeTitle2.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute de toutes les façons'**
  String get welcomeTitle2;

  /// No description provided for @welcomeBody2.
  ///
  /// In fr, this message translates to:
  /// **'Une vidéo, une playlist, une chaîne, ou juste quelques mots.'**
  String get welcomeBody2;

  /// No description provided for @welcomeTitle3.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie avant de télécharger'**
  String get welcomeTitle3;

  /// No description provided for @welcomeBody3.
  ///
  /// In fr, this message translates to:
  /// **'L\'aperçu montre chaque titre avant que rien ne parte.'**
  String get welcomeBody3;

  /// No description provided for @welcomeSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get welcomeSkip;

  /// No description provided for @welcomeNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get welcomeNext;

  /// No description provided for @welcomeStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get welcomeStart;

  /// No description provided for @welcomePage.
  ///
  /// In fr, this message translates to:
  /// **'Page {page} sur {count}'**
  String welcomePage(int page, int count);

  /// No description provided for @kindSearch.
  ///
  /// In fr, this message translates to:
  /// **'Recherche'**
  String get kindSearch;

  /// No description provided for @detailSearch.
  ///
  /// In fr, this message translates to:
  /// **'Résultats YouTube pour « {query} »'**
  String detailSearch(String query);

  /// No description provided for @searchResults.
  ///
  /// In fr, this message translates to:
  /// **'Recherche : {query}'**
  String searchResults(String query);

  /// No description provided for @settingsLayout.
  ///
  /// In fr, this message translates to:
  /// **'Rangement des fichiers'**
  String get settingsLayout;

  /// No description provided for @layoutPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Par playlist'**
  String get layoutPlaylist;

  /// No description provided for @layoutArtist.
  ///
  /// In fr, this message translates to:
  /// **'Par artiste'**
  String get layoutArtist;

  /// No description provided for @settingsLayoutHelp.
  ///
  /// In fr, this message translates to:
  /// **'Par playlist : un dossier par playlist, titres numérotés. Par artiste : un dossier par chaîne YouTube qui a publié la vidéo.'**
  String get settingsLayoutHelp;

  /// No description provided for @cancelOne.
  ///
  /// In fr, this message translates to:
  /// **'Annuler ce titre'**
  String get cancelOne;

  /// No description provided for @modeLinks.
  ///
  /// In fr, this message translates to:
  /// **'Liens'**
  String get modeLinks;

  /// No description provided for @modeSearch.
  ///
  /// In fr, this message translates to:
  /// **'Recherche YouTube'**
  String get modeSearch;

  /// No description provided for @searchButton.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get searchButton;

  /// No description provided for @searchHint.
  ///
  /// In fr, this message translates to:
  /// **'Artiste, titre, album…'**
  String get searchHint;

  /// No description provided for @searchFooter.
  ///
  /// In fr, this message translates to:
  /// **'20 résultats, à cocher dans l\'aperçu'**
  String get searchFooter;

  /// No description provided for @searchAgain.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle recherche'**
  String get searchAgain;

  /// No description provided for @follow.
  ///
  /// In fr, this message translates to:
  /// **'Suivre'**
  String get follow;

  /// No description provided for @following.
  ///
  /// In fr, this message translates to:
  /// **'Suivi'**
  String get following;

  /// No description provided for @newsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveautés'**
  String get newsTitle;

  /// No description provided for @newsShow.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get newsShow;

  /// No description provided for @newsLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get newsLater;

  /// No description provided for @newTracks.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} nouveau titre} other{{count} nouveaux titres}}'**
  String newTracks(int count);

  /// No description provided for @settingsSubscriptions.
  ///
  /// In fr, this message translates to:
  /// **'Abonnements'**
  String get settingsSubscriptions;

  /// No description provided for @subscriptionsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement. Suis une playlist ou une chaîne depuis l\'aperçu : ses nouveaux titres te seront proposés au démarrage.'**
  String get subscriptionsEmpty;

  /// No description provided for @unfollow.
  ///
  /// In fr, this message translates to:
  /// **'Ne plus suivre'**
  String get unfollow;

  /// No description provided for @welcomePoint1a.
  ///
  /// In fr, this message translates to:
  /// **'MP3 tagués : titre, artiste, album, numéro de piste'**
  String get welcomePoint1a;

  /// No description provided for @welcomePoint1b.
  ///
  /// In fr, this message translates to:
  /// **'Rangés par playlist ou par artiste, bien nommés'**
  String get welcomePoint1b;

  /// No description provided for @welcomePoint1c.
  ///
  /// In fr, this message translates to:
  /// **'Tout reste sur ton appareil : aucun compte, aucun suivi'**
  String get welcomePoint1c;

  /// No description provided for @welcomePoint2a.
  ///
  /// In fr, this message translates to:
  /// **'Colle un ou plusieurs liens, même au milieu d\'un texte'**
  String get welcomePoint2a;

  /// No description provided for @welcomePoint2b.
  ///
  /// In fr, this message translates to:
  /// **'Cherche sur YouTube et coche les résultats'**
  String get welcomePoint2b;

  /// No description provided for @welcomePoint2c.
  ///
  /// In fr, this message translates to:
  /// **'Importe un fichier de liens (.txt)'**
  String get welcomePoint2c;

  /// No description provided for @welcomePoint2d.
  ///
  /// In fr, this message translates to:
  /// **'Glisse un lien ou un fichier sur la fenêtre'**
  String get welcomePoint2d;

  /// No description provided for @welcomePoint2e.
  ///
  /// In fr, this message translates to:
  /// **'Partage depuis l\'app YouTube vers Ka7'**
  String get welcomePoint2e;

  /// No description provided for @welcomePoint3a.
  ///
  /// In fr, this message translates to:
  /// **'Décoche ce que tu ne veux pas, ou tout d\'un coup'**
  String get welcomePoint3a;

  /// No description provided for @welcomePoint3b.
  ///
  /// In fr, this message translates to:
  /// **'Ce que tu as déjà est repéré : « Déjà là »'**
  String get welcomePoint3b;

  /// No description provided for @welcomePoint3c.
  ///
  /// In fr, this message translates to:
  /// **'MP3 ou MP4, plusieurs téléchargements à la fois'**
  String get welcomePoint3c;

  /// No description provided for @welcomePoint3d.
  ///
  /// In fr, this message translates to:
  /// **'Annule un titre ou toute la file, à tout moment'**
  String get welcomePoint3d;

  /// No description provided for @welcomeTitle4.
  ///
  /// In fr, this message translates to:
  /// **'Rien ne se perd'**
  String get welcomeTitle4;

  /// No description provided for @welcomeBody4.
  ///
  /// In fr, this message translates to:
  /// **'Ka7 garde la trace de tout ce qui passe.'**
  String get welcomeBody4;

  /// No description provided for @welcomePoint4a.
  ///
  /// In fr, this message translates to:
  /// **'La Bibliothèque retrouve chaque fichier et son dossier'**
  String get welcomePoint4a;

  /// No description provided for @welcomePoint4b.
  ///
  /// In fr, this message translates to:
  /// **'Suis une playlist : ses nouveautés te sont proposées'**
  String get welcomePoint4b;

  /// No description provided for @welcomePoint4c.
  ///
  /// In fr, this message translates to:
  /// **'Une file coupée reprend au lancement suivant'**
  String get welcomePoint4c;

  /// No description provided for @welcomePoint4d.
  ///
  /// In fr, this message translates to:
  /// **'Les échecs se relancent en un clic'**
  String get welcomePoint4d;

  /// No description provided for @welcomePrevious.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get welcomePrevious;

  /// No description provided for @welcomeSetupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avant de commencer'**
  String get welcomeSetupTitle;

  /// No description provided for @welcomeSetupBody.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ta langue et l\'apparence de Ka7.'**
  String get welcomeSetupBody;

  /// No description provided for @welcomeSetupLater.
  ///
  /// In fr, this message translates to:
  /// **'Tu pourras changer ça plus tard dans Réglages.'**
  String get welcomeSetupLater;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
