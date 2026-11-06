import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'player_controller.dart';
import 'player_texts.dart';
import 'position_slider.dart';

/// A strip above the sections while something plays: title, play / pause,
/// next, close; a tap opens the whole player.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, required this.player, required this.onOpen});

  final PlayerController player;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: player,
    builder: (context, _) {
      final track = player.current;
      if (track == null) return const SizedBox.shrink();
      final l10n = AppLocalizations.of(context);
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final total = player.duration.inMilliseconds;
      final status = statusText(l10n, player);
      // Listened to from the preview, before downloading: everything here,
      // nothing else to open.
      if (track.isOnline && !track.video) {
        return Material(
          color: scheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.music_note_outlined, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (status != null)
                            Text(
                              status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: player.error == null
                                    ? scheme.onSurfaceVariant
                                    : scheme.error,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.playerBack,
                      onPressed: () => player.seekBy(-jump),
                      icon: const Icon(Icons.replay_10),
                    ),
                    PlayPauseButton(player: player),
                    IconButton(
                      tooltip: l10n.playerForward,
                      onPressed: () => player.seekBy(jump),
                      icon: const Icon(Icons.forward_10),
                    ),
                    IconButton(
                      tooltip: l10n.playerClose,
                      onPressed: player.close,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                PositionSlider(player: player),
              ],
            ),
          ),
        );
      }
      return Material(
        color: scheme.surfaceContainerLow,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              minHeight: 2,
              value: player.loading
                  ? null
                  : total == 0
                  ? 0
                  : player.position.inMilliseconds / total,
            ),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: l10n.playerOpen,
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: onOpen,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                        child: Row(
                          children: [
                            Icon(
                              track.video
                                  ? Icons.movie_outlined
                                  : Icons.music_note_outlined,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    track.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (status != null)
                                    Text(
                                      status,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: player.error == null
                                                ? scheme.onSurfaceVariant
                                                : scheme.error,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                PlayPauseButton(player: player),
                IconButton(
                  tooltip: l10n.playerNext,
                  onPressed: player.next,
                  icon: const Icon(Icons.skip_next),
                ),
                IconButton(
                  tooltip: l10n.playerClose,
                  onPressed: player.close,
                  icon: const Icon(Icons.close),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ],
        ),
      );
    },
  );
}
