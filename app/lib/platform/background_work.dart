/// Keeps downloads going with the screen off (Android foreground service,
/// with its progress notification).
abstract interface class BackgroundWork {
  /// Shows or updates the notification: [done] of [total] finished.
  void keep({required String title, required int done, required int total});

  /// The queue is empty: Android may stop the app again.
  void release();
}
