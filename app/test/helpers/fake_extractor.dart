import 'package:ka7_core/ka7_core.dart';

/// Engine double: answers each link URL with a fixed probe or failure.
class FakeExtractor implements Extractor {
  FakeExtractor(this.answers);

  /// Link URL → [Probe], or an error to throw.
  final Map<String, Object> answers;

  @override
  String get name => 'fake';

  /// URLs read, in order.
  final probed = <String>[];

  @override
  Future<Probe> probe(MediaEntry entry) async =>
      switch (answers[(probed..add(entry.url)).last]) {
        final Probe probe => probe,
        final Exception error => throw error,
        final Error error => throw error,
        _ => throw StateError('No answer for ${entry.url}'),
      };
}
