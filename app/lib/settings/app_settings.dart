import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_store/ka7_store.dart';

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
  );

  final Ka7Store _store;
  final Map<MediaFormat, String> _defaultFolders;
  String? _language;
  final Map<MediaFormat, String> _folders;
  int _concurrency;
  int _mixLimit;
  ThemeMode _theme;

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

  Future<void> setFolder(MediaFormat format, String folder) async {
    final kind = _folderKind(format);
    _folders[kind] = folder;
    notifyListeners();
    await _store.setSetting(_folderKey(kind), folder);
  }
}

const _languageKey = 'language';
const _concurrencyKey = 'downloads.concurrency';
const _mixLimitKey = 'mix.limit';
const _themeKey = 'theme';

/// Choices offered in Settings.
const concurrencyChoices = [1, 2, 3, 4];
const mixLimitChoices = [25, 50, 100, 200];
String _folderKey(MediaFormat format) => 'folder.${format.name}';

MediaFormat _folderKind(MediaFormat format) =>
    format == MediaFormat.mp4 ? MediaFormat.mp4 : MediaFormat.mp3;
