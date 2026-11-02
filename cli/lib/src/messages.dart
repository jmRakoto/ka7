import 'package:ka7_core/ka7_core.dart';

/// What the CLI says, in French or English (system language, or `--lang`).
abstract final class Messages {
  static Messages of(String language) =>
      language.startsWith('fr') ? const _French() : const _English();

  String get usage;
  String missingFile(String path);
  String noLinks(String path);
  String readLinks(int media, int invalid, int duplicates);
  String invalid(String source, InvalidReason reason);
  String wholePlaylist(String title, int videos);
  String confirmChannel(String title, int videos);
  String leftOut(String title);
  String progress(int percent, int done, int total, double? speed);
  String unreadable(String source, FailureReason reason);
  String probed(String title, int videos, int unavailable);
  String started(int position, int total, String title);
  String succeeded(String path);
  String skipped(String title);
  String failed(String title, FailureReason reason);
  String cancelled(String title);
  String summary(RunSummary summary, int unreadable);
  String failedSaved(String path);
  String reason(FailureReason reason);
}

final class _English implements Messages {
  const _English();

  @override
  String get usage =>
      'Usage: ka7 <links.txt> [--format mp3|m4a|mp4] [--out <folder>] [--yes]\n'
      '       ka7 retry        retries the links of failed.txt';

  @override
  String missingFile(String path) => 'File not found: $path';

  @override
  String noLinks(String path) => 'No YouTube link in $path.';

  @override
  String readLinks(int media, int invalid, int duplicates) =>
      '$media links to read'
      '${invalid > 0 ? ', $invalid invalid' : ''}'
      '${duplicates > 0 ? ', $duplicates duplicates' : ''}.';

  @override
  String invalid(String source, InvalidReason reason) =>
      '  ! $source: ${switch (reason) {
        InvalidReason.notYouTube => 'not a YouTube link',
        InvalidReason.noVideoOrPlaylist => 'no video or playlist in it',
        InvalidReason.freeText => 'not a link',
      }}';

  @override
  String wholePlaylist(String title, int videos) =>
      '$title ($videos ${videos == 1 ? 'video' : 'videos'}): '
      'download the whole playlist? [y/N] ';

  @override
  String confirmChannel(String title, int videos) =>
      '$title: $videos ${videos == 1 ? 'video' : 'videos'}. '
      'Download them all? [y/N] ';

  @override
  String leftOut(String title) => '  - $title: left out';

  @override
  String progress(int percent, int done, int total, double? speed) =>
      '${'$percent'.padLeft(3)}% · $done/$total'
      '${speed == null ? '' : ' · ${_speed(speed, 'kB', 'MB')}'}';

  @override
  String unreadable(String source, FailureReason reason) =>
      '  ✗ $source: ${this.reason(reason)}';

  @override
  String probed(String title, int videos, int unavailable) =>
      '$title: $videos ${videos == 1 ? 'video' : 'videos'}'
      '${unavailable > 0 ? ' ($unavailable unavailable)' : ''}';

  @override
  String started(int position, int total, String title) =>
      '[$position/$total] $title';

  @override
  String succeeded(String path) => '  ✓ $path';

  @override
  String skipped(String title) => '  = already downloaded';

  @override
  String failed(String title, FailureReason reason) =>
      '  ✗ ${this.reason(reason)}';

  @override
  String cancelled(String title) => '  - cancelled: $title';

  @override
  String summary(RunSummary summary, int unreadable) =>
      'Summary: ${summary.succeeded.length} succeeded, '
      '${summary.skipped.length} already there, '
      '${summary.failed.length + unreadable} failed, '
      '${summary.cancelled.length} cancelled.';

  @override
  String failedSaved(String path) =>
      'Failed links saved to $path: run `ka7 retry`.';

  @override
  String reason(FailureReason reason) => switch (reason) {
    FailureReason.unavailable => 'video unavailable',
    FailureReason.private => 'private',
    FailureReason.network => 'network problem',
    FailureReason.engineMissing => 'yt-dlp is not installed',
    FailureReason.formatUnsupported => 'format not available here',
    FailureReason.unknown => 'unknown error',
  };
}

final class _French implements Messages {
  const _French();

  @override
  String get usage =>
      'Usage : ka7 <links.txt> [--format mp3|m4a|mp4] [--out <dossier>] [--yes]\n'
      '        ka7 retry        relance les liens de failed.txt';

  @override
  String missingFile(String path) => 'Fichier introuvable : $path';

  @override
  String noLinks(String path) => 'Aucun lien YouTube dans $path.';

  @override
  String readLinks(int media, int invalid, int duplicates) =>
      '$media ${media == 1 ? 'lien' : 'liens'} à lire'
      '${invalid > 0 ? ', $invalid ${invalid == 1 ? 'invalide' : 'invalides'}' : ''}'
      '${duplicates > 0 ? ', $duplicates en double' : ''}.';

  @override
  String invalid(String source, InvalidReason reason) =>
      '  ! $source : ${switch (reason) {
        InvalidReason.notYouTube => "ce n'est pas un lien YouTube",
        InvalidReason.noVideoOrPlaylist => 'ni vidéo ni playlist',
        InvalidReason.freeText => "ce n'est pas un lien",
      }}';

  @override
  String wholePlaylist(String title, int videos) =>
      '$title ($videos ${videos == 1 ? 'vidéo' : 'vidéos'}) : '
      'télécharger toute la playlist ? [o/N] ';

  @override
  String confirmChannel(String title, int videos) =>
      '$title : $videos ${videos == 1 ? 'vidéo' : 'vidéos'}. '
      'Tout télécharger ? [o/N] ';

  @override
  String leftOut(String title) => '  - $title : laissée de côté';

  @override
  String progress(int percent, int done, int total, double? speed) =>
      '${'$percent'.padLeft(3)} % · $done/$total'
      '${speed == null ? '' : ' · ${_speed(speed, 'ko', 'Mo').replaceAll('.', ',')}'}';

  @override
  String unreadable(String source, FailureReason reason) =>
      '  ✗ $source : ${this.reason(reason)}';

  @override
  String probed(String title, int videos, int unavailable) =>
      '$title : $videos ${videos == 1 ? 'vidéo' : 'vidéos'}'
      '${unavailable > 0 ? ' ($unavailable indisponibles)' : ''}';

  @override
  String started(int position, int total, String title) =>
      '[$position/$total] $title';

  @override
  String succeeded(String path) => '  ✓ $path';

  @override
  String skipped(String title) => '  = déjà téléchargé';

  @override
  String failed(String title, FailureReason reason) =>
      '  ✗ ${this.reason(reason)}';

  @override
  String cancelled(String title) => '  - annulé : $title';

  @override
  String summary(RunSummary summary, int unreadable) =>
      'Bilan : ${summary.succeeded.length} réussis, '
      '${summary.skipped.length} déjà là, '
      '${summary.failed.length + unreadable} échoués, '
      '${summary.cancelled.length} annulés.';

  @override
  String failedSaved(String path) =>
      'Liens échoués enregistrés dans $path : lancez `ka7 retry`.';

  @override
  String reason(FailureReason reason) => switch (reason) {
    FailureReason.unavailable => 'vidéo indisponible',
    FailureReason.private => 'vidéo privée',
    FailureReason.network => 'problème de réseau',
    FailureReason.engineMissing => "yt-dlp n'est pas installé",
    FailureReason.formatUnsupported => 'format impossible ici',
    FailureReason.unknown => 'erreur inconnue',
  };
}

/// Bytes per second in kilo or mega units.
String _speed(double bytesPerSecond, String kilo, String mega) =>
    bytesPerSecond >= 1e6
    ? '${(bytesPerSecond / 1e6).toStringAsFixed(1)} $mega/s'
    : '${(bytesPerSecond / 1e3).round()} $kilo/s';
