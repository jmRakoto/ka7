import 'package:audio_service/audio_service.dart';

import '../../l10n/app_localizations.dart';
import 'player_controller.dart';
import 'player_texts.dart';
import 'position_slider.dart';
import 'track.dart';

/// The player as the system sees it (Android): the media notification, the
/// lock screen, headset buttons. Mirrors [player], and sends their presses
/// back to it.
class PlayerSession extends BaseAudioHandler with SeekHandler {
  PlayerSession(this.player, {this.l10n, this.cover}) {
    player.addListener(_mirror);
    _mirror();
  }

  final PlayerController player;

  /// For the reason a track does not play; none in tests.
  final AppLocalizations? l10n;

  /// The picture shown with a track (notification, lock screen); null for
  /// none.
  final Uri? Function(Track track)? cover;

  /// What was last shown: a new state only when one of these moves (the
  /// system runs the clock itself between two).
  Object? _shown;

  /// [at]: where a jump lands (the real player says so only a moment later).
  void _mirror({Duration? at}) {
    final track = player.current;
    final shown = (
      track,
      player.index,
      player.playing,
      player.loading,
      player.error,
      player.duration,
    );
    if (shown == _shown && at == null) return;
    _shown = shown;
    if (track == null) {
      mediaItem.add(null);
      playbackState.add(PlaybackState());
      return;
    }
    mediaItem.add(
      MediaItem(
        id: track.path ?? track.videoId,
        title: track.title,
        album: 'Ka7',
        artUri: cover?.call(track),
        duration: player.duration > Duration.zero ? player.duration : null,
      ),
    );
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        androidCompactActionIndices: const [0, 1, 2],
        systemActions: const {
          MediaAction.seek,
          MediaAction.fastForward,
          MediaAction.rewind,
        },
        processingState: switch ((player.error, player.loading)) {
          (_?, _) => AudioProcessingState.error,
          (null, true) => AudioProcessingState.loading,
          (null, false) => AudioProcessingState.ready,
        },
        errorMessage: switch ((player.error, l10n)) {
          (_?, final l10n?) => statusText(l10n, player),
          (final error?, null) => error.name,
          _ => null,
        },
        playing: player.playing,
        updatePosition: at ?? player.position,
        queueIndex: player.index,
      ),
    );
  }

  @override
  Future<void> play() async {
    if (!player.playing) await player.toggle();
  }

  @override
  Future<void> pause() async {
    if (player.playing) await player.toggle();
  }

  @override
  Future<void> skipToNext() => player.next();

  @override
  Future<void> skipToPrevious() => player.previous();

  @override
  Future<void> seek(Duration position) async {
    await player.seek(position);
    // A jump: the system's clock starts again from there.
    _mirror(at: position);
  }

  @override
  Future<void> fastForward() => _jump(jump);

  @override
  Future<void> rewind() => _jump(-jump);

  /// Within the track, as the app's own ±10 s.
  Future<void> _jump(Duration by) {
    var to = player.position + by;
    if (to < Duration.zero) to = Duration.zero;
    if (player.duration > Duration.zero && to > player.duration) {
      to = player.duration;
    }
    return seek(to);
  }

  /// From the notification: the player goes away, and the notification.
  @override
  Future<void> stop() => player.close();

  /// Stops mirroring.
  void dispose() => player.removeListener(_mirror);
}
