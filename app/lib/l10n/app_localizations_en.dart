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
  String kindMix(int count) {
    return 'Mix · $count max';
  }

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

  @override
  String get summaryNone => 'Nothing recognized';

  @override
  String summaryRecognized(int count) {
    return '$count recognized';
  }

  @override
  String summarySkipped(int count) {
    return '$count skipped';
  }

  @override
  String get previewButton => 'Preview';

  @override
  String get itemPrivate => 'Private video';

  @override
  String get itemDeleted => 'Deleted video';

  @override
  String get itemUnavailable => 'Unavailable video';

  @override
  String trackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String get probePrivate => 'Private video';

  @override
  String get probeUnavailable => 'Video unavailable';

  @override
  String get probeNetwork => 'Can\'t reach YouTube';

  @override
  String get probeUnknown => 'Couldn\'t read this link';

  @override
  String get downloadButton => 'Download';

  @override
  String get probeEngineMissing => 'yt-dlp is not installed';

  @override
  String get runTitle => 'Queue';

  @override
  String get runRunning => 'Downloading';

  @override
  String get runWaiting => 'Waiting';

  @override
  String get runFinished => 'Done';

  @override
  String runCount(int done, int total) {
    return '$done / $total';
  }

  @override
  String percent(int value) {
    return '$value%';
  }

  @override
  String speed(String value) {
    return '$value MB/s';
  }

  @override
  String get cancelAll => 'Cancel all';

  @override
  String get runDone => 'Finished';

  @override
  String get statusSucceeded => 'Succeeded';

  @override
  String get statusSkipped => 'Already there';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String countSucceeded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count succeeded',
      one: '1 succeeded',
    );
    return '$_temp0';
  }

  @override
  String countSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count already there',
      one: '1 already there',
    );
    return '$_temp0';
  }

  @override
  String countFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count failed',
      one: '1 failed',
    );
    return '$_temp0';
  }

  @override
  String countCancelled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cancelled',
      one: '1 cancelled',
    );
    return '$_temp0';
  }

  @override
  String get retryButton => 'Retry';

  @override
  String get copyFailed => 'Copy failed links';

  @override
  String get copiedFailed => 'Links copied: paste them in Add to retry later.';

  @override
  String get formatMp3 => 'MP3 · audio';

  @override
  String get formatMp4 => 'MP4 · video';

  @override
  String get engineMissingBoth => 'yt-dlp and ffmpeg are missing';

  @override
  String get engineMissingYtDlp => 'yt-dlp is missing';

  @override
  String get engineMissingFfmpeg => 'ffmpeg is missing';

  @override
  String get engineMissingBody =>
      'Ka7 uses them to read YouTube and make MP3 files. It downloads them from their official sites and keeps them in its own folder.';

  @override
  String get engineInstall => 'Install';

  @override
  String engineInstalling(String tool, String percent) {
    return 'Installing $tool… $percent';
  }

  @override
  String get engineFailed =>
      'Could not install. Check your connection, then try again.';

  @override
  String get navAdd => 'Add';

  @override
  String get navQueue => 'Queue';

  @override
  String get navLibrary => 'Library';

  @override
  String get navSettings => 'Settings';

  @override
  String get queueEmpty => 'Nothing downloading.';

  @override
  String get libraryTitle => 'Library';

  @override
  String get librarySearch => 'Search a title or a playlist';

  @override
  String get libraryEmpty => 'Nothing downloaded yet.';

  @override
  String get libraryNoMatch => 'No results.';

  @override
  String get openFolder => 'Open folder';

  @override
  String get forget => 'Forget';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get folderMusic => 'Music folder (MP3)';

  @override
  String get folderVideos => 'Videos folder (MP4)';

  @override
  String get changeMusicFolder => 'Change the music folder';

  @override
  String get changeVideosFolder => 'Change the videos folder';

  @override
  String get addTitle => 'Add';

  @override
  String get addHint =>
      'Paste links, IDs or a list: one per line, or separated by spaces.';

  @override
  String get previewTitle => 'Preview';

  @override
  String get engineSize => 'About 180 MB to download, once.';

  @override
  String get formatM4a => 'M4A · original';

  @override
  String get formatUnsupported => 'Format not available on this device';

  @override
  String get notificationTitle => 'Downloading';

  @override
  String get interruptedTitle => 'Interrupted queue';

  @override
  String interruptedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks didn\'t finish last time.',
      one: '1 track didn\'t finish last time.',
    );
    return '$_temp0';
  }

  @override
  String get interruptedResume => 'Resume';

  @override
  String get interruptedDiscard => 'Discard';

  @override
  String get dropHint => 'Drop your links or a .txt file';

  @override
  String get importFile => 'Import a file';

  @override
  String get clearLinks => 'Clear';

  @override
  String get settingsConcurrency => 'Downloads at once';

  @override
  String get settingsMixLimit => 'YouTube mix: videos read';

  @override
  String get updatePlaylist => 'Update the playlist';

  @override
  String get notifyDoneTitle => 'Downloads finished';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsMixLimitHelp =>
      'A mix (a link with “list=RD”) is an endless playlist YouTube builds from one video. Ka7 only reads its first videos, this many.';

  @override
  String get selectAll => 'Select all';

  @override
  String get welcomeTitle1 => 'Welcome to Ka7';

  @override
  String get welcomeBody1 =>
      'YouTube links become clean MP3 or MP4 files: well named, tagged, sorted by playlist.';

  @override
  String get welcomeTitle2 => 'Paste, check, download';

  @override
  String get welcomeBody2 =>
      'Paste a link, a playlist or a file of links. The preview lists every track: uncheck what you don\'t want, pick the format, and go.';

  @override
  String get welcomeTitle3 => 'Everything in its place';

  @override
  String get welcomeBody3 =>
      'The Library keeps everything you downloaded. A playlist grew? Update it: only the new tracks are fetched.';

  @override
  String get welcomeSkip => 'Skip';

  @override
  String get welcomeNext => 'Next';

  @override
  String get welcomeStart => 'Get started';

  @override
  String welcomePage(int page, int count) {
    return 'Page $page of $count';
  }

  @override
  String get kindSearch => 'Search';

  @override
  String detailSearch(String query) {
    return 'YouTube results for “$query”';
  }

  @override
  String searchResults(String query) {
    return 'Search: $query';
  }

  @override
  String get settingsLayout => 'File layout';

  @override
  String get layoutPlaylist => 'By playlist';

  @override
  String get layoutArtist => 'By artist';

  @override
  String get settingsLayoutHelp =>
      'By playlist: one folder per playlist, numbered tracks. By artist: one folder per YouTube channel that published the video.';

  @override
  String get cancelOne => 'Cancel this track';

  @override
  String get modeLinks => 'Links';

  @override
  String get modeSearch => 'YouTube search';

  @override
  String get searchButton => 'Search';

  @override
  String get searchHint => 'Artist, title, album…';

  @override
  String get searchFooter => '20 results, to tick in the preview';

  @override
  String get searchAgain => 'New search';

  @override
  String get follow => 'Follow';

  @override
  String get following => 'Following';

  @override
  String get newsTitle => 'New videos';

  @override
  String get newsShow => 'Show';

  @override
  String get newsLater => 'Later';

  @override
  String newTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new tracks',
      one: '1 new track',
    );
    return '$_temp0';
  }

  @override
  String get settingsSubscriptions => 'Subscriptions';

  @override
  String get subscriptionsEmpty =>
      'No subscriptions. Follow a playlist or a channel from the preview: its new tracks will be offered at launch.';

  @override
  String get unfollow => 'Unfollow';
}
