import 'package:flutter/services.dart';

/// Android: opens [url] in the browser. Kotlin side: `MainActivity.kt`,
/// channel `mg.rakoto.ka7/open`.
void openUrlOnAndroid(String url) => const MethodChannel(
  'mg.rakoto.ka7/open',
).invokeMethod<void>('url', {'url': url});
