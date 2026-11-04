import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_store/ka7_store.dart';
import 'package:test/test.dart';

const _song = ProbeItem(videoId: 'yXs506QBhJY', title: 'Tanalahy ny foko');
const _video = Probe(title: 'Tanalahy ny foko', items: [_song]);
const _download = PlannedDownload(source: _video, item: _song, index: 1);
final _monday = DateTime.utc(2026, 10, 26, 9);
final _friday = DateTime.utc(2026, 10, 30, 18);

void main() {
  late Ka7Store store;
  late Set<String> files;
  late VerifiedArchive archive;
  setUp(() {
    store = Ka7Store.inMemory();
    files = {};
    archive = VerifiedArchive(
      store,
      exists: (path, format) async => files.contains(path),
    );
  });
  tearDown(() => store.close());

  Future<void> downloaded(String path, {DateTime? at}) async {
    await store.add('yXs506QBhJY', MediaFormat.mp3);
    await store.record(
      JobSucceeded(_download, path),
      MediaFormat.mp3,
      at ?? _monday,
    );
  }

  test('holds a video while its file is there', () async {
    await downloaded('/music/a.mp3');
    files.add('/music/a.mp3');

    expect(await archive.contains('yXs506QBhJY', MediaFormat.mp3), isTrue);
  });

  test('forgets a video whose file was deleted, in that format only', () async {
    await downloaded('/music/a.mp3');
    await store.add('yXs506QBhJY', MediaFormat.mp4);

    expect(await archive.contains('yXs506QBhJY', MediaFormat.mp3), isFalse);
    expect(await store.contains('yXs506QBhJY', MediaFormat.mp3), isFalse);
    expect(await store.contains('yXs506QBhJY', MediaFormat.mp4), isTrue);
    expect(
      (await store.history()).single.status,
      HistoryStatus.succeeded,
      reason: 'the history tells what happened, it stays',
    );
  });

  test('looks at the file of the latest download', () async {
    await downloaded('/music/old.mp3');
    await downloaded('/music/new.mp3', at: _friday);
    files.add('/music/new.mp3');

    expect(await archive.contains('yXs506QBhJY', MediaFormat.mp3), isTrue);
  });

  test('trusts the archive where no file is known', () async {
    await store.add('yXs506QBhJY', MediaFormat.mp3);

    expect(await archive.contains('yXs506QBhJY', MediaFormat.mp3), isTrue);
  });

  test('holds nothing the store does not', () async {
    expect(await archive.contains('yXs506QBhJY', MediaFormat.mp3), isFalse);
  });

  test('adds to the store', () async {
    await archive.add('yXs506QBhJY', MediaFormat.mp3);

    expect(await store.contains('yXs506QBhJY', MediaFormat.mp3), isTrue);
  });
}
