import 'dart:math';

import 'package:flutter/material.dart';

/// The cassette of the Ka7 logo (`../ka7-brand/ka7-mark.svg`), drawn in the
/// theme's colours: light and dark logos come out of the same drawing.
class Ka7Logo extends StatefulWidget {
  const Ka7Logo({
    super.key,
    this.width = 48,
    this.spin = false,
    this.loading = false,
  });

  final double width;

  /// The reels turn, then slow down to a stop, as a tape being wound.
  final bool spin;

  /// The reels keep turning, as a tape playing, until the widget goes.
  final bool loading;

  @override
  State<Ka7Logo> createState() => _Ka7LogoState();
}

class _Ka7LogoState extends State<Ka7Logo> with SingleTickerProviderStateMixin {
  late final _wind = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) return;
    if (widget.loading) {
      _wind.repeat();
    } else if (widget.spin) {
      _wind.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _wind.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final turns = widget.loading
        ? _wind
        : CurvedAnimation(parent: _wind, curve: Curves.easeOutCubic);
    return Semantics(
      label: 'Ka7',
      image: true,
      child: AnimatedBuilder(
        animation: turns,
        builder: (context, _) => CustomPaint(
          size: Size(
            widget.width,
            widget.width * _viewBox.height / _viewBox.width,
          ),
          painter: _CassettePainter(
            body: scheme.primary,
            window: scheme.surface,
            reels: scheme.secondary,
            angle: turns.value * (widget.loading ? 2 : 4) * pi,
          ),
        ),
      ),
    );
  }
}

const _viewBox = Size(160, 120);

class _CassettePainter extends CustomPainter {
  _CassettePainter({
    required this.body,
    required this.window,
    required this.reels,
    this.angle = 0,
  });

  final Color body;
  final Color window;
  final Color reels;

  /// How far the reels have turned, in radians.
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _viewBox.width);
    Paint fill(Color color) => Paint()..color = color;

    canvas
      ..drawRRect(
        RRect.fromLTRBR(4, 4, 156, 116, const Radius.circular(16)),
        fill(body),
      )
      ..drawRRect(
        RRect.fromLTRBR(18, 18, 142, 74, const Radius.circular(10)),
        fill(window),
      );
    for (final x in [52.0, 108.0]) {
      final center = Offset(x, 44);
      canvas
        ..drawCircle(center, 17, fill(reels))
        ..drawCircle(center, 4.5, fill(body));
      // Teeth of the reel: a dashed ring.
      final teeth = Paint()
        ..color = body
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      const radius = 8.5;
      const dash = 3.6 / radius;
      const gap = 5.3 / radius;
      for (var a = 0.0; a < 2 * pi - dash; a += dash + gap) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          a + angle,
          dash,
          false,
          teeth,
        );
      }
    }
    canvas
      ..drawPath(
        Path()
          ..moveTo(38, 116)
          ..lineTo(47, 90)
          ..lineTo(113, 90)
          ..lineTo(122, 116)
          ..close(),
        fill(window),
      )
      ..drawCircle(const Offset(64, 104), 4.5, fill(body))
      ..drawCircle(const Offset(96, 104), 4.5, fill(body));
  }

  @override
  bool shouldRepaint(_CassettePainter old) =>
      old.body != body ||
      old.window != window ||
      old.reels != reels ||
      old.angle != angle;
}
