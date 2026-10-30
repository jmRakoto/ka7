// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ka7';

  @override
  String get kindVideo => 'Video';

  @override
  String get kindPlaylist => 'Playlist';

  @override
  String get kindMix => 'Mix · 50 max';

  @override
  String get kindVideoInPlaylist => 'Video + playlist';

  @override
  String get kindChannel => 'Channel';

  @override
  String get kindDuplicate => 'Duplicate';

  @override
  String get kindInvalid => 'Skipped';

  @override
  String get reasonNotYouTube => 'Only YouTube is supported';

  @override
  String get reasonNoVideoOrPlaylist =>
      'YouTube link without a video or playlist';

  @override
  String get reasonFreeText => 'Free text: search is not available yet';

  @override
  String get detailDuplicate => 'Already listed above';

  @override
  String get detailVideoInPlaylist =>
      'Choose in preview: this video or the whole playlist';
}
