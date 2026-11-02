import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../settings/app_settings.dart';
import '../../widgets/ka7_logo.dart';

/// Shown on first launch, before anything else: language and theme, then
/// four pages about Ka7.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onDone,
    required this.settings,
    this.canDrop = false,
    this.canShare = false,
  });

  /// Skipped or finished: the app opens.
  final VoidCallback onDone;

  /// Language and theme, chosen on the first page and applied at once.
  final AppSettings settings;

  /// Desktop: links and files can be dropped on the window.
  final bool canDrop;

  /// Mobile: links come from YouTube's share menu.
  final bool canShare;

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

  void _go(int page) => _pages.animateToPage(
    page,
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeOutCubic,
  );

  List<_Page> _content(AppLocalizations l10n) => [
    _Page(
      art: const Ka7Logo(width: 140, spin: true),
      title: l10n.welcomeSetupTitle,
      body: l10n.welcomeSetupBody,
      points: const [],
      extra: _Setup(settings: widget.settings),
    ),
    _Page(
      art: const _Badge(icon: Icons.graphic_eq),
      title: l10n.welcomeTitle1,
      body: l10n.welcomeBody1,
      points: [
        (Icons.music_note_outlined, l10n.welcomePoint1a),
        (Icons.folder_outlined, l10n.welcomePoint1b),
        (Icons.lock_outline, l10n.welcomePoint1c),
      ],
    ),
    _Page(
      art: const _Badge(icon: Icons.add_link),
      title: l10n.welcomeTitle2,
      body: l10n.welcomeBody2,
      points: [
        (Icons.content_paste, l10n.welcomePoint2a),
        (Icons.search, l10n.welcomePoint2b),
        (Icons.upload_file, l10n.welcomePoint2c),
        if (widget.canDrop) (Icons.pan_tool_alt_outlined, l10n.welcomePoint2d),
        if (widget.canShare) (Icons.share_outlined, l10n.welcomePoint2e),
      ],
    ),
    _Page(
      art: const _Badge(icon: Icons.playlist_add_check),
      title: l10n.welcomeTitle3,
      body: l10n.welcomeBody3,
      points: [
        (Icons.check_box_outlined, l10n.welcomePoint3a),
        (Icons.inventory_2_outlined, l10n.welcomePoint3b),
        (Icons.tune, l10n.welcomePoint3c),
        (Icons.close, l10n.welcomePoint3d),
      ],
    ),
    _Page(
      art: const _Badge(icon: Icons.library_music_outlined),
      title: l10n.welcomeTitle4,
      body: l10n.welcomeBody4,
      points: [
        (Icons.manage_search, l10n.welcomePoint4a),
        (Icons.notifications_active_outlined, l10n.welcomePoint4b),
        (Icons.history, l10n.welcomePoint4c),
        (Icons.refresh, l10n.welcomePoint4d),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pages = _content(l10n);
    final last = _page == pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
                        for (final (i, page) in pages.indexed)
                          _PageView(page: page, active: i == _page),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Semantics(
                        label: l10n.welcomePage(_page + 1, pages.length),
                        child: ExcludeSemantics(
                          child: Row(
                            children: [
                              for (var i = 0; i < pages.length; i++)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  margin: const EdgeInsets.only(right: 6),
                                  width: i == _page ? 24 : 8,
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
                      if (_page > 0) ...[
                        TextButton(
                          onPressed: () => _go(_page - 1),
                          child: Text(l10n.welcomePrevious),
                        ),
                        const SizedBox(width: 8),
                      ],
                      FilledButton(
                        onPressed: last ? widget.onDone : () => _go(_page + 1),
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

final class _Page {
  const _Page({
    required this.art,
    required this.title,
    required this.body,
    required this.points,
    this.extra,
  });

  final Widget art;
  final String title;
  final String body;
  final List<(IconData, String)> points;

  /// Shown under the text, revealed like the points.
  final Widget? extra;
}

/// First page: language and theme, before reading anything else.
class _Setup extends StatelessWidget {
  const _Setup({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: theme.textTheme.titleSmall),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        label(l10n.settingsLanguage),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'fr', label: Text('Français')),
            ButtonSegment(value: 'en', label: Text('English')),
          ],
          selected: {
            settings.language ?? Localizations.localeOf(context).languageCode,
          },
          onSelectionChanged: (choice) => settings.setLanguage(choice.single),
        ),
        const SizedBox(height: 20),
        label(l10n.settingsTheme),
        SegmentedButton<ThemeMode>(
          segments: [
            ButtonSegment(
              value: ThemeMode.system,
              icon: const Icon(Icons.brightness_auto_outlined),
              label: Text(l10n.themeSystem),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              icon: const Icon(Icons.light_mode_outlined),
              label: Text(l10n.themeLight),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: const Icon(Icons.dark_mode_outlined),
              label: Text(l10n.themeDark),
            ),
          ],
          selected: {settings.theme},
          onSelectionChanged: (choice) => settings.setTheme(choice.single),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.welcomeSetupLater,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// One page: its picture pops in, then its points slide in one by one,
/// each time the page comes into view.
class _PageView extends StatefulWidget {
  const _PageView({required this.page, required this.active});

  final _Page page;
  final bool active;

  @override
  State<_PageView> createState() => _PageViewState();
}

class _PageViewState extends State<_PageView>
    with SingleTickerProviderStateMixin {
  late final _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _reveal.value = 1;
    } else if (widget.active && _reveal.value == 0) {
      _reveal.forward();
    }
  }

  @override
  void didUpdateWidget(_PageView old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      MediaQuery.disableAnimationsOf(context)
          ? _reveal.value = 1
          : _reveal.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  /// From 0 to 1 over its own slice of the reveal.
  Animation<double> _step(double start, double length) => CurvedAnimation(
    parent: _reveal,
    curve: Interval(start, (start + length).clamp(0, 1), curve: Curves.easeOut),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = widget.page;
    final art = _step(0, 0.45);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            ScaleTransition(
              scale: Tween(begin: 0.8, end: 1.0).animate(art),
              child: FadeTransition(opacity: art, child: page.art),
            ),
            const SizedBox(height: 28),
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              page.body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (page.extra case final extra?)
              FadeTransition(opacity: _step(0.25, 0.5), child: extra),
            for (final (i, (icon, text)) in page.points.indexed)
              _Point(
                icon: icon,
                text: text,
                reveal: _step(0.25 + i * 0.12, 0.4),
              ),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text, required this.reveal});

  final IconData icon;
  final String text;
  final Animation<double> reveal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: reveal,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(reveal),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 20, color: scheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(text)),
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
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.secondary.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Icon(icon, size: 52, color: scheme.primary),
    );
  }
}
