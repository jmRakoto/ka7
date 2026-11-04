import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/ka7_logo.dart';

/// While a link or a search is read: the cassette turns, [label] says what
/// is read, and pale rows shimmer where the videos will come.
class LoadingRows extends StatefulWidget {
  const LoadingRows({super.key, required this.label, this.rows = 3});

  final String label;
  final int rows;

  @override
  State<LoadingRows> createState() => _LoadingRowsState();
}

class _LoadingRowsState extends State<LoadingRows>
    with SingleTickerProviderStateMixin {
  late final _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Less motion asked: still rows, the label says enough.
    if (MediaQuery.disableAnimationsOf(context)) {
      _shine.stop();
    } else if (!_shine.isAnimating) {
      _shine.repeat();
    }
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final still = MediaQuery.disableAnimationsOf(context);
    final base = scheme.surfaceContainerHighest;
    final light = Color.lerp(base, scheme.surface, 0.7)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(child: Ka7Logo(width: 36, loading: !still)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _shine,
              builder: (context, child) => ShaderMask(
                blendMode: BlendMode.srcATop,
                // A band of light crossing the rows, left to right.
                shaderCallback: (bounds) => LinearGradient(
                  colors: [base, light, base],
                  stops: const [0.35, 0.5, 0.65],
                  begin: Alignment(-1 + 4 * _shine.value - 1.5, -0.3),
                  end: Alignment(1 + 4 * _shine.value - 1.5, 0.3),
                ).createShader(bounds),
                child: child,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < widget.rows; i++)
                    _GhostRow(color: base, width: 0.75 - 0.15 * (i % 2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The shape of a video row: picture, title, details.
class _GhostRow extends StatelessWidget {
  const _GhostRow({required this.color, required this.width});

  final Color color;

  /// Of the title, as a share of the room left.
  final double width;

  @override
  Widget build(BuildContext context) {
    Widget bar(double share, double height) => FractionallySizedBox(
      widthFactor: share,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 96,
            height: 54,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(width, 12),
                const SizedBox(height: 10),
                bar(0.3, 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Around the search field while a search runs: a violet light turns along
/// its edge, with a soft halo.
class SearchGlow extends StatefulWidget {
  const SearchGlow({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<SearchGlow> createState() => _SearchGlowState();
}

class _SearchGlowState extends State<SearchGlow>
    with SingleTickerProviderStateMixin {
  late final _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  void _follow() {
    if (widget.active && !MediaQuery.disableAnimationsOf(context)) {
      if (!_turn.isAnimating) _turn.repeat();
    } else {
      _turn.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _follow();
  }

  @override
  void didUpdateWidget(SearchGlow old) {
    super.didUpdateWidget(old);
    _follow();
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: widget.active ? 0.22 : 0),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _turn,
        builder: (context, child) => CustomPaint(
          foregroundPainter: widget.active
              ? _EdgeLight(
                  turn: _turn.value,
                  colors: [scheme.primary, scheme.secondary],
                )
              : null,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class _EdgeLight extends CustomPainter {
  _EdgeLight({required this.turn, required this.colors});

  final double turn;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final edge = RRect.fromRectAndRadius(
      rect.deflate(1),
      const Radius.circular(9),
    );
    final [first, second] = colors;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = SweepGradient(
        colors: [
          first.withValues(alpha: 0),
          first,
          second,
          second.withValues(alpha: 0),
          first.withValues(alpha: 0),
        ],
        stops: const [0, 0.25, 0.45, 0.6, 1],
        transform: GradientRotation(turn * 2 * math.pi),
      ).createShader(rect);
    canvas.drawRRect(edge, paint);
  }

  @override
  bool shouldRepaint(_EdgeLight old) => old.turn != turn;
}
