import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/ka7_logo.dart';

/// Three pages shown on first launch, before anything else.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  /// Skipped or finished: the app opens.
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  var _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next(int count) {
    if (_page == count - 1) return widget.onDone();
    _pages.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pages = [
      (const Ka7Logo(width: 120), l10n.welcomeTitle1, l10n.welcomeBody1),
      (
        const _Badge(icon: Icons.playlist_add_check),
        l10n.welcomeTitle2,
        l10n.welcomeBody2,
      ),
      (
        const _Badge(icon: Icons.library_music_outlined),
        l10n.welcomeTitle3,
        l10n.welcomeBody3,
      ),
    ];
    final last = _page == pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Visibility(
                      visible: !last,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: TextButton(
                        onPressed: widget.onDone,
                        child: Text(l10n.welcomeSkip),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (page) => setState(() => _page = page),
                      children: [
                        for (final (art, title, body) in pages)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              art,
                              const SizedBox(height: 32),
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                body,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Semantics(
                        label: l10n.welcomePage(_page + 1, pages.length),
                        child: ExcludeSemantics(
                          child: Row(
                            children: [
                              for (var i = 0; i < pages.length; i++)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 6),
                                  width: i == _page ? 20 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: i == _page
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => _next(pages.length),
                        child: Text(
                          last ? l10n.welcomeStart : l10n.welcomeNext,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A large icon on the soft accent, for pages without the logo.
class _Badge extends StatelessWidget {
  const _Badge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Icon(icon, size: 56, color: scheme.primary),
    );
  }
}
