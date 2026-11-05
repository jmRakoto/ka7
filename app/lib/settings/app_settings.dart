import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_store/ka7_store.dart';

/// A folder picked in the system's picker (Android): its address, and how
/// to show it (`SD/Mozika`).
typedef Destination = ({String uri, String label});

/// The user's choices, kept in the store and applied at once.
class AppSettings extends ChangeNotifier {
  AppSettings._(
    this._store,
    this._defaultFolders,
    this._language,
    this._folders,
    this._concurrency,
    this._mixLimit,
    this._theme,
    this._onboarded,
    this._layout,
    this._destinations,
    this._quality,
  );

  /// Reads the saved choices; [defaultFolders] fill what was never chosen.
  static Future<AppSettings> load(
    Ka7Store store,
    Map<MediaFormat, String> defaultFolders,
  ) async => AppSettings._(
    store,
    defaultFolders,
    await store.setting(_languageKey),
    {
      for (final format in MediaFormat.values)
        format: ?await store.setting(_folderKey(format)),
    },
    int.tryParse(await store.setting(_concurrencyKey) ?? '') ?? 2,
    int.tryParse(await store.setting(_mixLimitKey) ?? '') ?? 50,
    ThemeMode.values.asNameMap()[await store.setting(_themeKey)] ??
        ThemeMode.system,
    await store.setting(_onboardedKey) != null,
    // By artist unless the user chose otherwise.
    FolderLayout.values.asNameMap()[await store.setting(_layoutKey)] ??
        FolderLayout.artist,
    {
      for (final format in [MediaFormat.mp3, MediaFormat.mp4])
        if ((
              await store.setting(_destinationKey(format)),
              await store.setting('${_destinationKey(format)}.label'),
            )
            case (final uri?, final label?))
          format: (uri: uri, label: label),
    },
    Quality(
      audio:
          AudioQuality.values.asNameMap()[await store.setting(_audioKey)] ??
          Quality.standard.audio,
      video:
          VideoQuality.values.asNameMap()[await store.setting(_videoKey)] ??
          Quality.standard.video,
    ),
  );

  final Ka7Store _store;
  final Map<MediaFormat, String> _defaultFolders;
  String? _language;
  final Map<MediaFormat, String> _folders;
  int _concurrency;
  int _mixLimit;
  ThemeMode _theme;
  bool _onboarded;
  FolderLayout _layout;
  final Map<MediaFormat, Destination> _destinations;
  Quality _quality;

  /// Picked at first in the preview.
  Quality get quality => _quality;

  Future<void> setAudioQuality(AudioQuality audio) async {
    _quality = Quality(audio: audio, video: _quality.video);
    notifyListeners();
    await _store.setSetting(
      _audioKey,
      audio == Quality.standard.audio ? null : audio.name,
    );
  }

  Future<void> setVideoQuality(VideoQuality video) async {
    _quality = Quality(audio: _quality.audio, video: video);
    notifyListeners();
    await _store.setSetting(
      _videoKey,
      video == Quality.standard.video ? null : video.name,
    );
  }

  /// Where files of [format] are filed in the end (Android); null for the
  /// system's default (Music/Ka7, Movies/Ka7).
  Destination? destinationFor(MediaFormat format) =>
      _destinations[_folderKind(format)];

  /// [destination] null: back to the default.
  Future<void> setDestination(
    MediaFormat format,
    Destination? destination,
  ) async {
    final kind = _folderKind(format);
    if (destination == null) {
      _destinations.remove(kind);
    } else {
      _destinations[kind] = destination;
    }
    notifyListeners();
    await _store.setSetting(_destinationKey(kind), destination?.uri);
    await _store.setSetting(
      '${_destinationKey(kind)}.label',
      destination?.label,
    );
  }

  /// Folders per artist (the default), or per playlist.
  FolderLayout get layout => _layout;

  Future<void> setLayout(FolderLayout layout) async {
    _layout = layout;
    notifyListeners();
    await _store.setSetting(_layoutKey, layout.name);
  }

  /// The welcome pages were seen (or skipped) once.
  bool get onboarded => _onboarded;

  Future<void> completeOnboarding() async {
    _onboarded = true;
    notifyListeners();
    await _store.setSetting(_onboardedKey, '1');
  }

  /// Light, dark, or following the system.
  ThemeMode get theme => _theme;

  Future<void> setTheme(ThemeMode theme) async {
    _theme = theme;
    notifyListeners();
    await _store.setSetting(
      _themeKey,
      theme == ThemeMode.system ? null : theme.name,
    );
  }

  /// Downloads running at once, for the next queues.
  int get concurrency => _concurrency;

  /// Videos of a YouTube mix read in the preview.
  int get mixLimit => _mixLimit;

  Future<void> setConcurrency(int concurrency) async {
    _concurrency = concurrency;
    notifyListeners();
    await _store.setSetting(_concurrencyKey, '$concurrency');
  }

  Future<void> setMixLimit(int limit) async {
    _mixLimit = limit;
    notifyListeners();
    await _store.setSetting(_mixLimitKey, '$limit');
  }

  /// `fr` or `en`; null follows the system.
  String? get language => _language;

  /// Audio formats share the music folder.
  String folderFor(MediaFormat format) {
    final kind = _folderKind(format);
    return _folders[kind] ?? _defaultFolders[kind]!;
  }

  Future<void> setLanguage(String? language) async {
    _language = language;
    notifyListeners();
    await _store.setSetting(_languageKey, language);
  }

  /// Whether the user picked a folder other than the default.
  bool hasOwnFolder(MediaFormat format) {
    final kind = _folderKind(format);
    return _folders[kind] != null && _folders[kind] != _defaultFolders[kind];
  }

  /// [folder] null: back to the default.
  Future<void> setFolder(MediaFormat format, String? folder) async {
    final kind = _folderKind(format);
    if (folder == null) {
      _folders.remove(kind);
    } else {
      _folders[kind] = folder;
    }
    notifyListeners();
    await _store.setSetting(_folderKey(kind), folder);
  }
}

const _languageKey = 'language';
const _concurrencyKey = 'downloads.concurrency';
const _mixLimitKey = 'mix.limit';
const _themeKey = 'theme';
const _onboardedKey = 'onboarding.done';
const _layoutKey = 'folders.layout';
const _audioKey = 'quality.audio';
const _videoKey = 'quality.video';

/// Choices offered in Settings.
const concurrencyChoices = [1, 2, 3, 4];
const mixLimitChoices = [25, 50, 100, 200];
String _folderKey(MediaFormat format) => 'folder.${format.name}';
String _destinationKey(MediaFormat format) => 'destination.${format.name}';

MediaFormat _folderKind(MediaFormat format) =>
    format == MediaFormat.mp4 ? MediaFormat.mp4 : MediaFormat.mp3;
