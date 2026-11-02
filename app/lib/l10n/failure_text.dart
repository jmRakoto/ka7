import 'package:ka7_core/ka7_core.dart';

import 'app_localizations.dart';

/// Readable words for why a link or a video failed: never a code.
String failureText(AppLocalizations l10n, FailureReason reason) =>
    switch (reason) {
      FailureReason.private => l10n.probePrivate,
      FailureReason.unavailable => l10n.probeUnavailable,
      FailureReason.network => l10n.probeNetwork,
      FailureReason.engineMissing => l10n.probeEngineMissing,
      FailureReason.formatUnsupported => l10n.formatUnsupported,
      FailureReason.unknown => l10n.probeUnknown,
    };
