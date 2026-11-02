import 'package:ka7_core/ka7_core.dart';

/// Fixed probes for screen tests.
const ericMananaPlaylist = Probe(
  title: 'Erick Manana · Sélection',
  playlistId: 'PLe7rK2mErickManana01',
  items: [
    ProbeItem(
      videoId: 'aB3dE5fG7hI',
      title: "Tsara Ny Hiran' Ny Taniko",
      duration: Duration(minutes: 4, seconds: 12),
    ),
    ProbeItem(
      videoId: 'jK9lM1nO3pQ',
      title: 'Tsy Ferana',
      duration: Duration(minutes: 5, seconds: 41),
    ),
    ProbeItem(
      videoId: 'rS5tU7vW9xY',
      title: '[Private video]',
      availability: Availability.private,
    ),
    ProbeItem(
      videoId: 'zA1bC3dE5fG',
      title: '',
      availability: Availability.unavailable,
    ),
  ],
);

const hafatraVideo = Probe(
  title: 'Hafatra',
  items: [
    ProbeItem(
      videoId: 'Qm7tR2vLx9A',
      title: 'Hafatra',
      duration: Duration(minutes: 3, seconds: 12),
    ),
  ],
);
