# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

One Flutter app for Linux, macOS, Windows, Android and iOS, following each OS's conventions (sidebar on desktop, bottom tabs and share sheet on mobile). No web.

## Users
- Primary: the owner, building a personal music and video library from YouTube (Malagasy music such as Mahaleo, Erick Manana, Rija Ramanantoanina; jazz, classical, instrumental covers). Works in batches: whole playlists, or a list of artists ticked off one by one.
- Secondary: a few close relatives, with the app installed directly (no store).
- Not a public service.

## Product Purpose
Turn YouTube links, IDs or whole lists into clean, well-named, tagged MP3 or MP4 files, with a clear account of what succeeded, what was skipped and what failed. Success: a library folder usable as-is in any player, and nothing lost silently.

## Positioning
Ka7 ("ka-sept" = cassette in French): the cassette you used to record the radio on, rebuilt as an app. Paste or share links, preview, download, get a clean library.

## Operating Context
- Desktop: drives the official yt-dlp and ffmpeg binaries, kept up to date by the app.
- Android: youtubedl-android (yt-dlp embedded), youtube_explode_dart as backup.
- iOS: youtube_explode_dart only; original audio (M4A) by default.
- Distribution outside stores (GitHub Releases, APK, AltStore). App Store, Google Play and Chrome Web Store refuse this kind of app.

## Capabilities and Constraints
- Formats: MP3 (128/192/320), original audio (M4A/Opus), MP4 (720p/1080p/best). Videos, playlists, bare IDs, mixes (50 max), channels.
- Flows: 0 startup, 1 add links, 2 preview and settings, 3 download, 4 summary, 5 library (see `../ka7-reecriture-flutter.html`).
- Interface in French and English, chosen in Settings. Code in English.

## Brand Commitments
- Name: Ka7. Logo and icon in `../ka7-brand/`: cassette with toothed reels, monoline "Ka7", the 7 in accent color.
- Palette: Nuit d'encre (indigo, lilac on neutral). See `DESIGN.md`.
- Never use YouTube's logo, red or branding: the product must not look affiliated with YouTube.
- Cassette wink stays in name, icon and tagline; buttons use plain words ("Télécharger", "Réessayer").

## Evidence on Hand
- Real artist lists and downloads in `../youtubeDl/back/TODO.txt` and `../youtubeDl/downloads/`. No testimonials, no user numbers: do not fabricate any.

## Product Principles
1. Nothing is lost silently: every link ends as succeeded, skipped (already there), failed with a reason, or cancelled.
2. See before you start: titles, count, duration, size before confirming.
3. Clean files: readable names, folder per playlist, ID3 tags and cover.
4. Private by default: no telemetry, no open network port.
5. One app to install, and it says what is missing.

## Accessibility & Inclusion
WCAG 2.2 AA: keyboard navigation on desktop, visible focus, labelled controls (Semantics), 48 px touch targets on mobile, contrast 4.5:1 for text.
