import 'package:flutter/material.dart';
import 'package:ka7_core/ka7_core.dart';

import '../l10n/app_localizations.dart';

/// MP3 bitrate: 128, 192, 320 kbit/s.
class AudioQualityPicker extends StatelessWidget {
  const AudioQualityPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AudioQuality value;
  final ValueChanged<AudioQuality> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<AudioQuality>(
      showSelectedIcon: false,
      segments: [
        for (final quality in AudioQuality.values)
          ButtonSegment(
            value: quality,
            label: Text(l10n.qualityKbps(quality.kbps)),
          ),
      ],
      selected: {value},
      onSelectionChanged: (choice) => onChanged(choice.single),
    );
  }
}

/// Highest video height: 480p, 720p, 1080p, or the best there is.
class VideoQualityPicker extends StatelessWidget {
  const VideoQualityPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final VideoQuality value;
  final ValueChanged<VideoQuality> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<VideoQuality>(
      showSelectedIcon: false,
      segments: [
        for (final quality in VideoQuality.values)
          ButtonSegment(
            value: quality,
            label: Text(switch (quality.height) {
              final height? => '${height}p',
              null => l10n.qualityBest,
            }),
          ),
      ],
      selected: {value},
      onSelectionChanged: (choice) => onChanged(choice.single),
    );
  }
}
