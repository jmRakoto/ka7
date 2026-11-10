#!/usr/bin/env bash
# Installs Ka7's .rpm in a clean Fedora container with a virtual screen:
#   tool/linux/check_fedora.sh dist/ka7-<v>-1.x86_64.rpm
# KA7_FEDORA=fedora:43 for another release (default: fedora:latest).
#
# 1. dnf installs it, with the dependencies the package names.
# 2. Its libraries miss nothing on Fedora; its libmpv plays MP3, FLAC, Opus,
#    H.264 and AV1 to the end (tool/linux/play_check.py, tool/linux/media).
# 3. The app starts through /usr/bin, is still up after 15 s, with Ka7's own
#    libmpv in its memory; `ka7 --help` answers; the menu entry and icons
#    are in place.
# Sibling of check_old_linux.sh (Ubuntu and Debian: AppImage and .deb).
set -euo pipefail
rpm=$(readlink -e "${1:-}") || { echo "no such file: ${1:-}" >&2; exit 2; }
cd "$(dirname "$0")"
base=${KA7_FEDORA:-fedora:latest}

docker run --rm -i \
  -v "$rpm:/ka7.rpm:ro" \
  -v "$PWD/play_check.py:/play_check.py:ro" \
  -v "$PWD/media:/media:ro" \
  "$base" bash -s <<'SCRIPT'
set -eu
echo "== $(. /etc/os-release; echo "$PRETTY_NAME")"
dnf -y -q install /ka7.rpm >/dev/null
echo "   dnf installed $(rpm -q ka7)"
# What a desktop has beyond Ka7's own dependencies: OpenGL (Mesa), a screen
# (virtual here); python3 for the decoding check, pgrep. Not OpenGL ES
# (libglvnd-gles): the package must bring it, Flutter needs it.
dnf -y -q install mesa-libEGL mesa-libGL xorg-x11-server-Xvfb xauth \
  python3 procps-ng >/dev/null

lib=/opt/ka7/app/lib
# As the app sees them: its own folder first (plugins find Flutter there).
missing=$(for f in "$lib"/lib*.so*; do LD_LIBRARY_PATH=$lib ldd "$f" 2>/dev/null | grep "not found" || true; done | sort -u)
if [ -n "$missing" ]; then echo "FAILED: missing on this system:"; echo "$missing"; exit 1; fi
echo "   its libraries miss nothing on this system"
python3 -I /play_check.py "$lib/libmpv.so.2" /media/*

for f in /usr/share/applications/mg.rakoto.ka7.desktop \
  /usr/share/icons/hicolor/scalable/apps/mg.rakoto.ka7.svg \
  /usr/share/icons/hicolor/48x48/apps/mg.rakoto.ka7.png \
  /usr/share/icons/hicolor/512x512/apps/mg.rakoto.ka7.png; do
  [ -f "$f" ] || { echo "FAILED: $f missing"; exit 1; }
done
echo "   menu entry and icons in place"

log=/tmp/run.log
xvfb-run -a ka7-app >"$log" 2>&1 &
sleep 15
pid=$(pgrep -x 'ka7|ka7-app' | head -1 || true)
if [ -z "$pid" ] || grep -qiE "symbol lookup error|undefined symbol|error while loading shared libraries" "$log"; then
  echo "FAILED: not running after 15 s"; cat "$log"; exit 1
fi
mpv=$(grep -o '/[^ ]*libmpv\.so\.[0-9]*' "/proc/$pid/maps" | sort -u | tr '\n' ' ')
pkill -x 'ka7|ka7-app' || true
wait || true
case "$mpv" in
  */opt/ka7/app/lib/libmpv.so.2*) echo "   up for 15 s, player library: $mpv" ;;
  *) echo "FAILED: player library '$mpv', expected Ka7's"; exit 1 ;;
esac

# Usage on stderr, exit 64: it starts and loads its libraries.
if ka7 --help 2>&1 | grep -q "^Usage: ka7"; then
  echo "   ka7 --help answers"
else
  echo "FAILED: ka7 --help"; ka7 --help || true; exit 1
fi

dnf -y -q remove ka7 >/dev/null 2>&1
[ ! -e /opt/ka7 ] && [ ! -e /usr/bin/ka7 ] || { echo "FAILED: files left after removal"; exit 1; }
echo "   dnf removes it cleanly"
echo "== OK"
SCRIPT
