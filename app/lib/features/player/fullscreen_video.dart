import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import 'player_controller.dart';
import 'player_texts.dart';
import 'position_slider.dart';

/// A video over the whole screen: sideways and without the system's bars
/// while [immersive] (opened by its button); a tap shows the controls.
class FullscreenVideo extends StatefulWidget {
  const FullscreenVideo({
    super.key,
    required this.player,
    this.immersive = true,
  });

  final PlayerController player;

  /// Opened by the button: turns the screen and hides the bars, until left.
  /// False when the phone itself was turned sideways: the system's own.
  final bool immersive;

  @override
  State<FullscreenVideo> createState() => _FullscreenVideoState();
}

class _FullscreenVideoState extends State<FullscreenVideo> {
  var _controls = false;

  @override
  void initState() {
    super.initState();
    widget.player.addListener(_leaveWithoutVideo);
    if (!widget.immersive) return;
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
  }

  /// The next track is a song: back to the player page.
  void _leaveWithoutVideo() {
    if (!mounted || (widget.player.current?.video ?? false)) return;
    widget.player.removeListener(_leaveWithoutVideo);
    if (widget.immersive) Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    widget.player.removeListener(_leaveWithoutVideo);
    if (widget.immersive) {
      // Any way round again, bars back.
      unawaited(SystemChrome.setPreferredOrientations(const []));
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final player = widget.player;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _controls = !_controls),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: player.backend.videoView(),
              ),
            ),
            if (_controls)
              // Light on dark, whatever the app's theme.
              Theme(
                data: ThemeData.dark(useMaterial3: true),
                child: ListenableBuilder(
                  listenable: player,
                  builder: (context, _) => ColoredBox(
                    color: Colors.black45,
                    child: SafeArea(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              if (widget.immersive)
                                IconButton(
                                  tooltip: l10n.playerExitFullscreen,
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.fullscreen_exit),
                                ),
                              Expanded(
                                child: Text(
                                  player.current?.title ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                tooltip: l10n.playerBack,
                                onPressed: () => player.seekBy(-jump),
                                icon: const Icon(Icons.replay_10),
                              ),
                              PlayPauseButton(player: player, big: true),
                              IconButton(
                                tooltip: l10n.playerForward,
                                onPressed: () => player.seekBy(jump),
                                icon: const Icon(Icons.forward_10),
                              ),
                            ],
                          ),
                          PositionSlider(player: player),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
