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
  String get reasonFreeText => 'Not a link: to search, use “YouTube search”';

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
  String get runActive => 'Download in progress';

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
  String get statusQueued => 'In the queue';

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
  String get retryOne => 'Retry this one';

  @override
  String get retryAll => 'Retry all';

  @override
  String retryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos didn\'t finish',
      one: '$count video didn\'t finish',
    );
    return '$_temp0';
  }

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
  String get runRemoved => 'Run removed';

  @override
  String get removeRun => 'Remove this run';

  @override
  String get queueEarlier => 'Earlier';

  @override
  String get queueClear => 'Clear';

  @override
  String get queueClearHint => 'Remove finished runs';

  @override
  String get queueEmpty => 'Nothing downloading.';

  @override
  String get libraryTitle => 'Library';

  @override
  String get librarySearch => 'Search a title or a playlist';

  @override
  String get selectEntries => 'Select';

  @override
  String get stopSelecting => 'Stop selecting';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get removeButton => 'Remove';

  @override
  String removeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remove these $count entries from the library?',
      one: 'Remove this entry from the library?',
    );
    return '$_temp0';
  }

  @override
  String get removeBody =>
      'The files stay on the device. These videos can be downloaded again.';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get libraryEmpty => 'Nothing downloaded yet.';

  @override
  String get libraryNoMatch => 'No results.';

  @override
  String get openFolder => 'Open folder';

  @override
  String get forget => 'Forget';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsDownloads => 'Downloads';

  @override
  String get settingsFolders => 'Folders';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsConcurrencyHelp =>
      'How many videos at once, for the next runs.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutDevVersion => 'Development build';

  @override
  String get aboutEngine => 'Downloads by yt-dlp and ffmpeg.';

  @override
  String get resetFolder => 'Back to the default folder';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String filterAll(int count) {
    return 'All · $count';
  }

  @override
  String filterSucceeded(int count) {
    return 'Succeeded · $count';
  }

  @override
  String filterFailed(int count) {
    return 'Failed · $count';
  }

  @override
  String get actions => 'Actions';

  @override
  String get pasteLinks => 'Paste';

  @override
  String get addTipLines =>
      'One link per line: a YouTube video, playlist, channel or mix.';

  @override
  String get addTipShare => 'From the YouTube app: Share → Ka7.';

  @override
  String get addTipDrop => 'Drop links or a .txt file on the window.';

  @override
  String get addTipImport => 'Or import a list of links from a .txt file.';

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get clearRecent => 'Clear recent searches';

  @override
  String qualityKbps(int kbps) {
    return '$kbps kbit/s';
  }

  @override
  String get qualityBest => 'Max';

  @override
  String get qualityOriginal => 'Original audio, not re-encoded';

  @override
  String get settingsQuality => 'Quality';

  @override
  String get settingsQualityHelp =>
      'Picked in advance in the preview. Beyond 192 kbit/s, an MP3 from YouTube hardly sounds better, it only weighs more.';

  @override
  String entriesForgotten(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries forgotten',
      one: '$count entry forgotten',
    );
    return '$_temp0';
  }

  @override
  String entryForgotten(String title) {
    return '“$title” forgotten';
  }

  @override
  String get backToTop => 'Back to top';

  @override
  String get searchChannels => 'Channels';

  @override
  String get channelLabel => 'YouTube channel';

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
  String get importFile => 'Import';

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
      'Ka7 records YouTube the way we once recorded tapes: links become clean MP3 or MP4 files.';

  @override
  String get welcomeTitle2 => 'Add things any way you like';

  @override
  String get welcomeBody2 =>
      'A video, a playlist, a channel, or just a few words.';

  @override
  String get welcomeTitle3 => 'Check before you download';

  @override
  String get welcomeBody3 =>
      'The preview lists every track before anything starts.';

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
  String get loadingLink => 'Reading the link…';

  @override
  String loadingSearch(String query) {
    return 'Searching “$query”…';
  }

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

  @override
  String get welcomePoint1a =>
      'Tagged MP3s: title, artist, album, track number';

  @override
  String get welcomePoint1b => 'Sorted by playlist or by artist, well named';

  @override
  String get welcomePoint1c =>
      'Everything stays on your device: no account, no tracking';

  @override
  String get welcomePoint2a => 'Paste one or many links, even inside some text';

  @override
  String get welcomePoint2b => 'Search YouTube and tick the results';

  @override
  String get welcomePoint2c => 'Import a file of links (.txt)';

  @override
  String get welcomePoint2d => 'Drop a link or a file on the window';

  @override
  String get welcomePoint2e => 'Share from the YouTube app to Ka7';

  @override
  String get welcomePoint3a =>
      'Uncheck what you don\'t want, or everything at once';

  @override
  String get welcomePoint3b =>
      'What you already have is spotted: “Already there”';

  @override
  String get welcomePoint3c => 'MP3 or MP4, several downloads at once';

  @override
  String get welcomePoint3d => 'Cancel one track or the whole queue, anytime';

  @override
  String get welcomeTitle4 => 'Nothing gets lost';

  @override
  String get welcomeBody4 => 'Ka7 keeps track of everything that goes through.';

  @override
  String get welcomePoint4a => 'The Library finds every file and its folder';

  @override
  String get welcomePoint4b =>
      'Follow a playlist: its new tracks are offered to you';

  @override
  String get welcomePoint4c =>
      'An interrupted queue resumes at the next launch';

  @override
  String get welcomePoint4d => 'Failures retry in one click';

  @override
  String get welcomePrevious => 'Back';

  @override
  String get welcomeSetupTitle => 'Before we start';

  @override
  String get welcomeSetupBody => 'Pick your language and how Ka7 looks.';

  @override
  String get welcomeSetupLater => 'You can change this later in Settings.';

  @override
  String get welcomePoint4e =>
      'A notification tells you when everything is done';

  @override
  String get engineChecking => 'Getting the engine ready…';

  @override
  String get close => 'Close';

  @override
  String updateAvailable(String version) {
    return 'Ka7 $version is out';
  }

  @override
  String updateCurrent(String version) {
    return 'You have $version.';
  }

  @override
  String get updateDownload => 'Download the update';
}
