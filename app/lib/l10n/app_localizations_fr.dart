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
  String get kindMix => 'Mix · 50 max';

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
      'Texte libre : la recherche n\'est pas encore disponible';

  @override
  String get detailDuplicate => 'Déjà présent plus haut';

  @override
  String get detailVideoInPlaylist =>
      'Choix à l\'aperçu : cette vidéo ou toute la playlist';
}
