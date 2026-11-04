import 'package:flutter/services.dart';

import '../settings/app_settings.dart';

const _channel = MethodChannel('mg.rakoto.ka7/folders');

/// Android's folder picker (any folder, SD card included); Ka7 keeps the
/// right to write there. Null when closed. Kotlin side: `FolderPicker.kt`.
Future<Destination?> pickAndroidFolder() async {
  final picked = await _channel.invokeMapMethod<String, String>('pick');
  return switch (picked) {
    {'uri': final uri, 'label': final label} => (uri: uri, label: label),
    _ => null,
  };
}
