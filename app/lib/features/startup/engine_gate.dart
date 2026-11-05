import 'package:flutter/material.dart';
import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/ka7_logo.dart';
import '../../widgets/ka7_splash.dart';
import '../../widgets/ka7_wordmark.dart';

/// Flow 0: makes sure yt-dlp and ffmpeg are there before the app opens.
class EngineGate extends StatefulWidget {
  const EngineGate({super.key, required this.setup, required this.builder});

  final EngineSetup setup;

  /// The app, once every tool is found.
  final Widget Function(BuildContext context, EngineStatus status) builder;

  @override
  State<EngineGate> createState() => _EngineGateState();
}

class _EngineGateState extends State<EngineGate> {
  EngineStatus? _status;
  EngineTool? _installing;
  double? _fraction;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final status = await widget.setup.check();
    if (mounted) setState(() => _status = status);
  }

  Future<void> _install() async {
    setState(() => _failed = false);
    try {
      for (final tool in _status!.missing) {
        setState(() {
          _installing = tool;
          _fraction = null;
        });
        await for (final fraction in widget.setup.install(tool)) {
          if (mounted) setState(() => _fraction = fraction);
        }
      }
    } on InstallFailure {
      if (mounted) setState(() => _failed = true);
    }
    if (!mounted) return;
    setState(() => _installing = null);
    await _check();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null) {
      return Ka7Splash(message: AppLocalizations.of(context).engineChecking);
    }
    if (status.isReady) return widget.builder(context, status);

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final installing = _installing;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Ka7Logo(width: 48),
                    SizedBox(width: 12),
                    ExcludeSemantics(child: Ka7Wordmark()),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.engineMissingTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.engineMissingBody,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.engineSize,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                if (installing != null) ...[
                  Text(
                    l10n
                        .engineInstalling(
                          _fraction == null
                              ? ''
                              : l10n.percent((_fraction! * 100).round()),
                        )
                        .trimRight(),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _fraction),
                ] else ...[
                  if (_failed) ...[
                    Text(
                      l10n.engineFailed,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton(
                    onPressed: _install,
                    child: Text(
                      _failed ? l10n.retryButton : l10n.engineInstall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
