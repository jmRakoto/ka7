import 'package:ka7_core/ka7_core.dart';

/// Reads yt-dlp's error message; it has no error codes.
FailureReason failureReasonOf(String message) => switch (message) {
  _ when message.contains('Private video') => FailureReason.private,
  _ when message.contains('Video unavailable') => FailureReason.unavailable,
  _
      when message.contains('Unable to download') ||
          message.contains('urlopen error') =>
    FailureReason.network,
  _ => FailureReason.unknown,
};
