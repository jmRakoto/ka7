import 'dart:convert';
import 'dart:io';

/// A published version of Ka7 (a GitHub release).
final class AppRelease {
  const AppRelease({required this.version, required this.url});

  /// `0.3.0`, without the `v` of its tag.
  final String version;

  /// Its page, with the files to download.
  final String url;
}

/// Reads GitHub's `releases/latest` answer; null for a draft, a pre-release
/// or an answer that is not a release.
AppRelease? parseRelease(Map<String, Object?> json) {
  final tag = json['tag_name'];
  final url = json['html_url'];
  if (tag is! String || url is! String) return null;
  if (json['draft'] == true || json['prerelease'] == true) return null;
  return AppRelease(
    version: tag.startsWith('v') ? tag.substring(1) : tag,
    url: url,
  );
}

/// Whether [candidate] (`0.10.0`) comes after [current] (`0.9.1`).
bool isNewer(String candidate, String current) {
  final a = _numbers(candidate);
  final b = _numbers(current);
  if (a == null || b == null) return false;
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i] > b[i];
  }
  return false;
}

/// `1.2.3` → [1, 2, 3]; `0.3` → [0, 3, 0]; null when not a version.
List<int>? _numbers(String version) {
  final parts = version.split('.');
  if (parts.isEmpty || parts.length > 3) return null;
  final numbers = [for (final part in parts) int.tryParse(part)];
  if (numbers.contains(null)) return null;
  return [...numbers.cast<int>(), ...List.filled(3 - numbers.length, 0)];
}

/// Where Ka7 is published.
const releasesApi = 'https://api.github.com/repos/jmRakoto/ka7/releases/latest';

/// Asks GitHub for the latest Ka7; null when there is none to offer. Throws
/// when GitHub cannot be reached.
Future<AppRelease?> fetchLatestRelease({String api = releasesApi}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.getUrl(Uri.parse(api));
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
      ..set(HttpHeaders.userAgentHeader, 'Ka7');
    final response = await request.close().timeout(const Duration(seconds: 15));
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != HttpStatus.ok) return null;
    return parseRelease(jsonDecode(body) as Map<String, Object?>);
  } finally {
    client.close();
  }
}
