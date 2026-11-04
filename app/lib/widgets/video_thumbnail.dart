import 'package:flutter/material.dart';

/// A video's picture, 16:9, with a neutral tile while it loads or when it
/// cannot.
class VideoThumbnail extends StatelessWidget {
  const VideoThumbnail({
    super.key,
    required this.image,
    this.width = 96,
    this.onLongPress,
  });

  final ImageProvider image;
  final double width;

  /// Opens a larger view; a tap still goes to the row.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_video_outlined,
        color: scheme.onSurfaceVariant,
        size: width / 4,
      ),
    );
    return GestureDetector(
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: width,
          height: width * 9 / 16,
          child: Image(
            image: image,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            frameBuilder: (context, child, frame, _) =>
                frame == null ? placeholder : child,
            errorBuilder: (context, _, _) => placeholder,
          ),
        ),
      ),
    );
  }
}
