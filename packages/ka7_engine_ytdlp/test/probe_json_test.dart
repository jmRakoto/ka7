import 'dart:convert';
import 'dart:io';

import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';
import 'package:test/test.dart';

/// Real yt-dlp 2026.10.26 output, trimmed: first entries, no thumbnails or
/// format lists.
Map<String, Object?> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, Object?>;

void main() {
  test('reads a playlist with its videos', () {
    final probe = parseProbeJson(fixture('playlist_flat.json'));

    expect(probe.title, 'Mahaleo playlist');
    expect(probe.playlistId, 'PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy');
    expect(probe.items.map((i) => i.videoId), [
      'yXs506QBhJY',
      '9rDT9l8gtF8',
      'YW-QLSPY8Ew',
      'tXfQdfIY2qg',
      'ZeVyDTKRXpA',
      'HF_Mx_srA1Q',
    ]);
    final first = probe.items.first;
    expect(first.title, 'Tanalahy ny foko_Mahaleo');
    expect(first.duration, const Duration(minutes: 4, seconds: 56));
    expect(first.channel, 'MAFYBE61');
  });

  test('flags playlist videos listed without a title as unavailable', () {
    final probe = parseProbeJson(fixture('playlist_flat.json'));

    expect(probe.items.map((i) => i.availability), [
      Availability.available,
      Availability.unavailable,
      Availability.available,
      Availability.available,
      Availability.unavailable,
      Availability.unavailable,
    ]);
  });

  test('flags private and deleted placeholders of a playlist', () {
    final probe = parseProbeJson({
      '_type': 'playlist',
      'entries': [
        {'id': 'rS5tU7vW9xY', 'title': '[Private video]'},
        {'id': 'zA1bC3dE5fG', 'title': '[Deleted video]'},
      ],
    });

    expect(probe.items.map((i) => i.availability), [
      Availability.private,
      Availability.deleted,
    ]);
  });

  test('reads a single video as a one-item probe without playlist', () {
    final probe = parseProbeJson(fixture('video.json'));

    expect(probe.title, 'Me at the zoo');
    expect(probe.playlistId, isNull);
    expect(probe.items, hasLength(1));
    expect(probe.items.single.videoId, 'jNQXAC9IVRw');
    expect(probe.items.single.duration, const Duration(seconds: 19));
    expect(probe.items.single.channel, 'jawed');
  });

  test('reads a channel under its own name, newest videos first', () {
    final probe = parseProbeJson(fixture('channel_videos.json'));

    expect(probe.title, 'YouTube');
    expect(probe.isChannel, isTrue);
    expect(probe.playlistId, 'UCBR8-60-B28hp2BmDPdntcQ');
    expect(probe.items.first.videoId, 'Yil32mThG04');
    expect(probe.items, hasLength(3));
  });

  test('does not take a playlist for a channel', () {
    expect(parseProbeJson(fixture('playlist_flat.json')).isChannel, isFalse);
  });

  group('search with a channel', () {
    final probe = parseProbeJson(
      jsonDecode(
            File('test/fixtures/search_with_channel.json').readAsStringSync(),
          )
          as Map<String, Object?>,
    );

    test('keeps the channels it found apart from the videos', () {
      expect(probe.items.map((i) => i.videoId), ['-ieWGHvs9xQ', '7MSYzO8Avzk']);
      expect(probe.channels.single.channelId, 'UCt4quCNBZZ0Cc6xWXUSp0zQ');
      expect(probe.channels.single.name.trim(), 'Mahaleo official');
    });

    test('keeps the channel picture, the largest one', () {
      final avatar = probe.channels.single.avatar!;
      expect(avatar, startsWith('https://yt3.ggpht.com/'));
      expect(avatar, contains('s176'), reason: '176 px over 88');
    });

    test('knows the channel of each video', () {
      expect(probe.items.last.channelId, 'UCt4quCNBZZ0Cc6xWXUSp0zQ');
      expect(probe.items.first.channelId, 'UClsWET8BmyoPbIvMxRVOIDA');
    });
  });
}
