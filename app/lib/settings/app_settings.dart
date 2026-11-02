import 'package:flutter/foundation.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_store/ka7_store.dart';

/// The user's choices, kept in the store and applied at once.
class AppSettings extends ChangeNotifier {
  AppSettings._(
    this._store,
    this._defaultFolders,
    this._language,
    this._folders,
  );

  /// Reads the saved choices; [defaultFolders] fill what was never chosen.
  static Future<AppSettings> load(
    Ka7Store store,
    Map<MediaFormat, String> defaultFolders,
  ) async =>
      AppSettings._(store, defaultFolders, await store.setting(_languageKey), {
        for (final format in MediaFormat.values)
          format: ?await store.setting(_folderKey(format)),
      });

  final Ka7Store _store;
  final Map<MediaFormat, String> _defaultFolders;
  String? _language;
  final Map<MediaFormat, String> _folders;

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
String _folderKey(MediaFormat format) => 'folder.${format.name}';

MediaFormat _folderKind(MediaFormat format) =>
    format == MediaFormat.mp4 ? MediaFormat.mp4 : MediaFormat.mp3;
