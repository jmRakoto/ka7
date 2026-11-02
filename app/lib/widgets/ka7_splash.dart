import 'package:flutter/material.dart';

import 'ka7_logo.dart';
import 'ka7_wordmark.dart';

/// What shows while Ka7 gets ready: the cassette, its reels turning.
class Ka7Splash extends StatelessWidget {
  const Ka7Splash({super.key, this.message});

  /// What is being prepared; none before the translations are loaded.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Ka7Logo(width: 120, loading: true),
            const SizedBox(height: 20),
            const ExcludeSemantics(child: Ka7Wordmark(size: 32)),
            const SizedBox(height: 28),
            SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (message case final message?) ...[
              const SizedBox(height: 12),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
