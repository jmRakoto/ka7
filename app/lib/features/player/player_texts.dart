import 'package:flutter/material.dart';
import 'package:ka7_core/ka7_core.dart';

import '../../l10n/app_localizations.dart';
import 'player_controller.dart';

/// Why it does not play, or that it is loading; null while all is well.
String? statusText(AppLocalizations l10n, PlayerController player) =>
    switch (player.error) {
      PlayerError.missingFile => l10n.playerMissingFile,
      PlayerError.offline => l10n.playerOffline,
      PlayerError.unavailable => l10n.playerUnavailable,
      null => player.loading ? l10n.playerLoading : null,
    };

/// Play while paused, pause while playing.
class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({super.key, required this.player, this.big = false});

  final PlayerController player;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final playing = player.playing;
    final icon = Icon(playing ? Icons.pause : Icons.play_arrow);
    final tooltip = playing ? l10n.playerPause : l10n.playerPlay;
    if (!big) {
      return IconButton(tooltip: tooltip, onPressed: player.toggle, icon: icon);
    }
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: player.toggle,
      iconSize: 36,
      padding: const EdgeInsets.all(14),
      icon: icon,
    );
  }
}

/// The next repeat mode, and the words for the current one.
(Repeat next, String label, IconData icon) repeatStep(
  AppLocalizations l10n,
  Repeat repeat,
) => switch (repeat) {
  Repeat.off => (Repeat.all, l10n.playerRepeatOff, Icons.repeat),
  Repeat.all => (Repeat.one, l10n.playerRepeatAll, Icons.repeat),
  Repeat.one => (Repeat.off, l10n.playerRepeatOne, Icons.repeat_one),
};
