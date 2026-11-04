import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/platform/media_store.dart';
import 'package:ka7_core/ka7_core.dart';

final class _Engine implements Downloader {
  _Engine({this.failure});

  final DownloadFailure? failure;

  @override
  Stream<DownloadProgress> download(DownloadRequest request) async* {
    yield const DownloadProgress(fraction: 1);
    if (failure case final failure?) throw failure;
  }
}

DownloadRequest _request(MediaFormat format, String destination) =>
    DownloadRequest(
      videoId: 'jNQXAC9IVRw',
      format: format,
      destination: destination,
      tags: const TrackTags(title: 'Me at the zoo'),
    );

String _folders(MediaFormat format) => switch (format) {
  MediaFormat.mp4 => '/app/Movies',
  _ => '/app/Music',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<String> published;
  Future<void> publish(
    String path,
    String relative,
    MediaFormat format,
  ) async => published.add('$path → $relative (${format.name})');
  setUp(() => published = []);

  test('publishes each finished file under its folder path', () async {
    final downloader = PublishingDownloader(
      _Engine(),
      folders: _folders,
      publish: publish,
    );

    final progress = await downloader
        .download(
          _request(MediaFormat.mp3, '/app/Music/Mahaleo/01 - Tanalahy.mp3'),
        )
        .toList();
    await downloader
        .download(_request(MediaFormat.mp4, '/app/Movies/Me at the zoo.mp4'))
        .drain<void>();

    expect(progress.single.fraction, 1);
    expect(published, [
      '/app/Music/Mahaleo/01 - Tanalahy.mp3 → Mahaleo/01 - Tanalahy.mp3 (mp3)',
      '/app/Movies/Me at the zoo.mp4 → Me at the zoo.mp4 (mp4)',
    ]);
  });

  test('publishes nothing when the download fails', () async {
    final downloads = PublishingDownloader(
      _Engine(failure: const DownloadFailure(FailureReason.network)),
      folders: _folders,
      publish: publish,
    ).download(_request(MediaFormat.mp3, '/app/Music/a.mp3'));

    await expectLater(
      downloads,
      emitsThrough(emitsError(isA<DownloadFailure>())),
    );
    expect(published, isEmpty);
  });

  test('reports a file the library refused as a failure', () async {
    final downloads = PublishingDownloader(
      _Engine(),
      folders: _folders,
      publish: (path, relative, format) async => throw Exception('disk full'),
    ).download(_request(MediaFormat.mp3, '/app/Music/a.mp3'));

    await expectLater(
      downloads,
      emitsThrough(
        emitsError(
          isA<DownloadFailure>().having(
            (f) => f.message,
            'message',
            contains('disk full'),
          ),
        ),
      ),
    );
  });

  group('Android MediaStore', () {
    const channel = MethodChannel('mg.rakoto.ka7/media');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    late List<MethodCall> calls;
    setUp(() {
      calls = [];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        // The shared library holds only Hafatra.
        if (call.method == 'exists') {
          return (call.arguments as Map)['name'] == 'Hafatra.m4a';
        }
        return null;
      });
    });
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('files audio in Music/Ka7 and video in Movies/Ka7', () async {
      await AndroidMediaStore().publish(
        '/app/Music/Mahaleo/01 - Tanalahy.mp3',
        'Mahaleo/01 - Tanalahy.mp3',
        MediaFormat.mp3,
      );
      await AndroidMediaStore().publish(
        '/app/Music/Hafatra.m4a',
        'Hafatra.m4a',
        MediaFormat.m4a,
      );
      await AndroidMediaStore().publish(
        '/app/Movies/Me at the zoo.mp4',
        'Me at the zoo.mp4',
        MediaFormat.mp4,
      );

      expect(calls.map((c) => c.arguments), [
        {
          'path': '/app/Music/Mahaleo/01 - Tanalahy.mp3',
          'folder': 'Music/Ka7/Mahaleo',
          'name': '01 - Tanalahy.mp3',
          'mime': 'audio/mpeg',
        },
        {
          'path': '/app/Music/Hafatra.m4a',
          'folder': 'Music/Ka7',
          'name': 'Hafatra.m4a',
          'mime': 'audio/mp4',
        },
        {
          'path': '/app/Movies/Me at the zoo.mp4',
          'folder': 'Movies/Ka7',
          'name': 'Me at the zoo.mp4',
          'mime': 'video/mp4',
        },
      ]);
    });

    test('finds a file where it was filed, from where it was made', () async {
      final exists = AndroidMediaStore().existsFor(
        (format) => format == MediaFormat.mp4 ? '/app/Movies' : '/app/Music',
        stillLocal: (path) async => path == '/app/Music/Kept here.mp3',
      );

      expect(await exists('/app/Music/Hafatra.m4a', MediaFormat.m4a), isTrue);
      expect(
        await exists('/app/Music/Mahaleo/01 - Gone.mp3', MediaFormat.mp3),
        isFalse,
      );
      expect(
        await exists('/app/Music/Kept here.mp3', MediaFormat.mp3),
        isTrue,
        reason: 'not moved (storage refused): still in the app folder',
      );
      expect(calls.map((c) => c.arguments), [
        {'folder': 'Music/Ka7', 'name': 'Hafatra.m4a', 'mime': 'audio/mp4'},
        {
          'folder': 'Music/Ka7/Mahaleo',
          'name': '01 - Gone.mp3',
          'mime': 'audio/mpeg',
        },
      ]);
    });

    test('files in the folder the user chose, keeping subfolders', () async {
      await AndroidMediaStore().publish(
        '/app/Music/Mahaleo/01 - Tanalahy.mp3',
        'Mahaleo/01 - Tanalahy.mp3',
        MediaFormat.mp3,
        tree: 'content://tree/primary%3AMozika',
      );

      expect(calls.single.method, 'publishTree');
      expect(calls.single.arguments, {
        'path': '/app/Music/Mahaleo/01 - Tanalahy.mp3',
        'tree': 'content://tree/primary%3AMozika',
        'folder': 'Mahaleo',
        'name': '01 - Tanalahy.mp3',
      });
    });

    test('looks for a file in the folder the user chose', () async {
      final exists = AndroidMediaStore().existsFor(
        (format) => '/app/Music',
        stillLocal: (_) async => false,
        tree: (format) => 'content://tree/primary%3AMozika',
      );

      await exists('/app/Music/Hafatra.m4a', MediaFormat.m4a);

      expect(calls.single.method, 'existsTree');
      expect(calls.single.arguments, {
        'tree': 'content://tree/primary%3AMozika',
        'folder': '',
        'name': 'Hafatra.m4a',
      });
    });
  });
}
