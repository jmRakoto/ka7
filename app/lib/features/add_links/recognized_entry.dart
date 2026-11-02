import 'package:ka7_core/ka7_core.dart';

import '../../l10n/app_localizations.dart';

/// How a recognized line is shown: a short label and one line of detail.
({String label, String detail}) describeEntry(
  LinkEntry entry,
  AppLocalizations l10n, {
  int mixLimit = 50,
}) => switch (entry) {
  VideoEntry() => (label: l10n.kindVideo, detail: entry.url),
  PlaylistEntry(isMix: true) => (
    label: l10n.kindMix(mixLimit),
    detail: entry.url,
  ),
  PlaylistEntry() => (label: l10n.kindPlaylist, detail: entry.url),
  VideoInPlaylistEntry() => (
    label: l10n.kindVideoInPlaylist,
    detail: l10n.detailVideoInPlaylist,
  ),
  ChannelEntry() => (label: l10n.kindChannel, detail: entry.url),
  SearchEntry(:final query) => (
    label: l10n.kindSearch,
    detail: l10n.detailSearch(query),
  ),
  DuplicateEntry() => (label: l10n.kindDuplicate, detail: l10n.detailDuplicate),
  InvalidEntry(:final reason) => (
    label: l10n.kindInvalid,
    detail: switch (reason) {
      InvalidReason.notYouTube => l10n.reasonNotYouTube,
      InvalidReason.noVideoOrPlaylist => l10n.reasonNoVideoOrPlaylist,
      InvalidReason.freeText => l10n.reasonFreeText,
    },
  ),
};
