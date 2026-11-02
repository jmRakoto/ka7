import 'package:flutter/material.dart';

/// "Ka7", the 7 in accent, as on the logo.
class Ka7Wordmark extends StatelessWidget {
  const Ka7Wordmark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: scheme.onSurface,
    );
    return Semantics(
      label: 'Ka7',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            const TextSpan(text: 'Ka'),
            TextSpan(
              text: '7',
              style: TextStyle(color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
