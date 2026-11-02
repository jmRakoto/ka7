import 'dart:async';

import 'package:flutter/services.dart';

/// Text shared to Ka7 from another app (Android's share menu), including the
/// one that launched it. Kotlin side: `MainActivity.kt`.
Stream<String> sharedLinks([
  MethodChannel channel = const MethodChannel('mg.rakoto.ka7/share'),
]) {
  final links = StreamController<String>();
  channel.setMethodCallHandler((call) async {
    if (call.method == 'shared') links.add(call.arguments as String);
  });
  links.onListen = () async {
    if (await channel.invokeMethod<String>('initial') case final text?) {
      links.add(text);
    }
  };
  return links.stream;
}
