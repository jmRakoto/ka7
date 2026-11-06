import 'package:flutter/material.dart';
import 'package:ka7_core/ka7_core.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/ka7_logo.dart';
import 'player_controller.dart';
import 'player_texts.dart';
import 'position_slider.dart';

/// The whole player: pictures or cassette, position, every control, queue.
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key, required this.player});

  final PlayerController player;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
        title: Text(l10n.playerNowPlaying),
      ),
      body: ListenableBuilder(
        listenable: player,
        builder: (context, _) {
          final track = player.current;
          if (track == null) return const SizedBox.shrink();
          final tracks = player.tracks;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverList.list(
                      children: [
                        _Picture(player: player),
                        const SizedBox(height: 20),
                        Text(
                          track.title,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (statusText(l10n, player) case final status?)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              status,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: player.error == null
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant
                                    : Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        PositionSlider(player: player),
                        _Controls(player: player),
                        const SizedBox(height: 16),
                        Semantics(
                          header: true,
                          child: Text(
                            l10n.playerQueue,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                    sliver: SliverList.builder(
                      itemCount: tracks.length,
                      itemBuilder: (context, i) {
                        final item = tracks[i];
                        final current = i == player.index;
                        final missing = player.missing.contains(item.path);
                        return ListTile(
                          key: ValueKey(('queue', i, item.videoId)),
                          selected: current,
                          leading: Icon(
                            current
                                ? Icons.graphic_eq
                                : item.video
                                ? Icons.movie_outlined
                                : Icons.music_note_outlined,
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: missing
                              ? Text(l10n.playerMissingBadge)
                              : null,
                          onTap: () => player.jumpTo(i),
                          trailing: IconButton(
                            tooltip: l10n.playerRemoveFromQueue,
                            onPressed: () => player.removeAt(i),
                            icon: const Icon(Icons.close),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A video's pictures, or the cassette whose reels follow the track.
class _Picture extends StatelessWidget {
  const _Picture({required this.player});

  final PlayerController player;

  @override
  Widget build(BuildContext context) {
    if (player.current!.video) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: RepaintBoundary(
            key: const Key('video-picture'),
            child: ColoredBox(
              color: Colors.black,
              child: player.backend.videoView(),
            ),
          ),
        ),
      );
    }
    return Center(
      child: Ka7Logo(
        width: 180,
        // One turn every 4 seconds of the track, as a tape.
        reelTurns: player.position.inMilliseconds / 4000,
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.player});

  final PlayerController player;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (nextRepeat, repeatLabel, repeatIcon) = repeatStep(
      l10n,
      player.repeat,
    );
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            IconButton(
              tooltip: l10n.playerPrevious,
              onPressed: player.previous,
              iconSize: 30,
              icon: const Icon(Icons.skip_previous),
            ),
            IconButton(
              tooltip: l10n.playerBack,
              onPressed: () => player.seekBy(-jump),
              iconSize: 28,
              icon: const Icon(Icons.replay_10),
            ),
            PlayPauseButton(player: player, big: true),
            IconButton(
              tooltip: l10n.playerForward,
              onPressed: () => player.seekBy(jump),
              iconSize: 28,
              icon: const Icon(Icons.forward_10),
            ),
            IconButton(
              tooltip: l10n.playerNext,
              onPressed: player.next,
              iconSize: 30,
              icon: const Icon(Icons.skip_next),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            IconButton(
              tooltip: l10n.playerShuffle,
              isSelected: player.shuffled,
              onPressed: () => player.setShuffle(!player.shuffled),
              color: player.shuffled ? scheme.primary : null,
              icon: const Icon(Icons.shuffle),
            ),
            IconButton(
              tooltip: l10n.playerStop,
              onPressed: player.stop,
              icon: const Icon(Icons.stop),
            ),
            IconButton(
              tooltip: repeatLabel,
              isSelected: player.repeat != Repeat.off,
              onPressed: () => player.setRepeat(nextRepeat),
              color: player.repeat != Repeat.off ? scheme.primary : null,
              icon: Icon(repeatIcon),
            ),
          ],
        ),
      ],
    );
  }
}
