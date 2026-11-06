import 'package:flutter/material.dart';

import '../preview/durations.dart';
import 'player_controller.dart';

/// What ±10 s buttons jump by.
const jump = Duration(seconds: 10);

/// Where the track is: a slider to drag, and the times on each side.
class PositionSlider extends StatefulWidget {
  const PositionSlider({super.key, required this.player});

  final PlayerController player;

  @override
  State<PositionSlider> createState() => _PositionSliderState();
}

class _PositionSliderState extends State<PositionSlider> {
  /// Where the thumb is held, while dragged.
  double? _dragged;

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final total = player.duration.inMilliseconds.toDouble();
    final at = player.position.inMilliseconds.toDouble().clamp(0.0, total);
    final shown = Duration(milliseconds: (_dragged ?? at).round());
    final style = Theme.of(context).textTheme.bodySmall;
    return Column(
      children: [
        Slider(
          value: total == 0 ? 0 : (_dragged ?? at),
          max: total == 0 ? 1 : total,
          onChanged: total == 0
              ? null
              : (value) => setState(() => _dragged = value),
          onChangeEnd: (value) {
            setState(() => _dragged = null);
            player.seek(Duration(milliseconds: value.round()));
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(clock(shown), style: style),
              Text(clock(player.duration), style: style),
            ],
          ),
        ),
      ],
    );
  }
}
