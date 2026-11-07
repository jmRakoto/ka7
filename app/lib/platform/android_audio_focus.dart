import 'package:audio_session/audio_session.dart';

import '../features/player/audio_focus.dart';

/// Android's audio focus, through audio_session: calls, other apps,
/// notification sounds, headphones pulled out.
class AndroidFocusEvents implements FocusEvents {
  AndroidFocusEvents(this.session);

  final AudioSession session;

  /// Music, ready to share the sound as Android expects.
  static Future<AndroidFocusEvents> start() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    return AndroidFocusEvents(session);
  }

  @override
  Stream<(bool, Interruption)> get interruptions =>
      session.interruptionEventStream.map(
        (event) => (
          event.begin,
          switch (event.type) {
            AudioInterruptionType.pause => Interruption.pause,
            AudioInterruptionType.duck => Interruption.duck,
            AudioInterruptionType.unknown => Interruption.unknown,
          },
        ),
      );

  @override
  Stream<void> get unplugged => session.becomingNoisyEventStream;

  @override
  Future<bool> request() => session.setActive(true);
}
