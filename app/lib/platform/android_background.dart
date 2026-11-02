import 'package:flutter/services.dart';

import 'background_work.dart';
import 'run_notifier.dart';

/// Android foreground service with a progress notification. Kotlin side:
/// `DownloadService.kt`, driven by `BackgroundChannel.kt`.
class AndroidBackgroundWork implements BackgroundWork {
  AndroidBackgroundWork([
    this._channel = const MethodChannel('mg.rakoto.ka7/background'),
  ]);

  final MethodChannel _channel;
  var _kept = false;

  @override
  void keep({required String title, required int done, required int total}) {
    _kept = true;
    _channel.invokeMethod<void>('keep', {
      'title': title,
      'text': '$done/$total',
      'done': done,
      'total': total,
    });
  }

  @override
  void release() {
    if (!_kept) return;
    _kept = false;
    _channel.invokeMethod<void>('release');
  }
}

/// Android: a notification that stays once the progress one is gone. Kotlin
/// side: `BackgroundChannel.kt`, method `finished`.
class AndroidRunNotifier implements RunNotifier {
  AndroidRunNotifier([
    this._channel = const MethodChannel('mg.rakoto.ka7/background'),
  ]);

  final MethodChannel _channel;

  /// Android 13+: asks once for notifications (progress and end).
  void askPermission() => _channel.invokeMethod<void>('askNotifications');

  @override
  void finished({required String title, required String body}) =>
      _channel.invokeMethod<void>('finished', {'title': title, 'body': body});
}
