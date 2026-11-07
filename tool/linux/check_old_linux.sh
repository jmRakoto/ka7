#!/usr/bin/env bash
# Starts Ka7's Linux packages in a clean container with a virtual screen, on
# the oldest Linux they promise to run on (Ubuntu 22.04, GLib 2.72):
#   tool/linux/check_old_linux.sh dist/Ka7-<v>-x86_64.AppImage [dist/ka7_<v>_amd64.deb]
# KA7_OLD_LINUX=ubuntu:24.04 (or debian:12) for another system.
#
# 1. AppImage on a bare desktop: starts, loads Ka7's own libmpv (read in the
#    running app's memory map); its libraries miss nothing on the system;
#    that libmpv plays MP3, FLAC, Opus, H.264 and AV1 to the end
#    (tool/linux/play_check.py, test files in tool/linux/media).
# 2. Same, with the system's own (GPL) libmpv installed: still Ka7's.
# 3. .deb: installs, loads its own libmpv; `ka7 --help` answers.
set -euo pipefail
cd "$(dirname "$0")"
base=${KA7_OLD_LINUX:-ubuntu:22.04}
appimage=$(readlink -f "$1")
deb=${2:+$(readlink -f "$2")}

docker run --rm -i \
  -v "$appimage:/ka7.AppImage:ro" \
  ${deb:+-v "$deb:/ka7.deb:ro"} \
  -v "$PWD/play_check.py:/play_check.py:ro" \
  -v "$PWD/media:/media:ro" \
  "$base" bash -s <<'SCRIPT'
set -eu
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null
# What a desktop has: GTK 3, OpenGL (Mesa), sound client libraries, a screen
# (virtual here); python3 for the decoding check.
apt-get install -y -qq libgtk-3-0 libegl1 libgl1 libgles2 libpulse0 \
  libasound2 xvfb xauth python3-minimal >/dev/null 2>&1 ||
  apt-get install -y -qq libgtk-3-0t64 libegl1 libgl1 libgles2 libpulse0 \
    libasound2t64 xvfb xauth python3-minimal >/dev/null
echo "== $(. /etc/os-release; echo "$PRETTY_NAME"), GLib $(dpkg-query -W -f='${Version}' 'libglib2.0-0*' | head -1)"

# Starts "$@" on a virtual screen; after 15 s it must still run, and its
# memory must hold a libmpv whose path contains $want.
up_with() {
  local want=$1
  shift
  local log=/tmp/run.log
  xvfb-run -a "$@" >"$log" 2>&1 &
  sleep 15
  local pid
  # « ka7 », or « ka7-app » when started through /usr/bin (.deb).
  pid=$(pgrep -x 'ka7|ka7-app' | head -1 || true)
  if [ -z "$pid" ] || grep -qiE "symbol lookup error|undefined symbol|error while loading shared libraries" "$log"; then
    echo "FAILED: not running after 15 s"; cat "$log"; return 1
  fi
  local mpv
  mpv=$(grep -o '/[^ ]*libmpv\.so\.[0-9]*' "/proc/$pid/maps" | sort -u | tr '\n' ' ')
  pkill -x 'ka7|ka7-app' || true
  wait || true
  case "$mpv" in
    *$want*) echo "   up for 15 s, player library: $mpv" ;;
    *) echo "FAILED: player library '$mpv', expected $want"; return 1 ;;
  esac
}

echo "== AppImage, bare desktop"
APPIMAGE_EXTRACT_AND_RUN=1 up_with /usr/lib/ka7/lib/libmpv.so.2 /ka7.AppImage
cd /tmp && /ka7.AppImage --appimage-extract >/dev/null && lib=/tmp/squashfs-root/usr/lib/ka7/lib
# As the app sees them: its own folder first (plugins find Flutter there).
missing=$(for f in "$lib"/lib*.so*; do LD_LIBRARY_PATH=$lib ldd "$f" | grep "not found"; done | sort -u)
if [ -n "$missing" ]; then echo "FAILED: missing on this system:"; echo "$missing"; exit 1; fi
echo "   its libraries miss nothing on this system"
python3 -I /play_check.py "$lib/libmpv.so.2" /media/*

echo "== AppImage, with the system's own libmpv installed too"
apt-get install -y -qq libmpv2 >/dev/null 2>&1 || apt-get install -y -qq libmpv1 >/dev/null
APPIMAGE_EXTRACT_AND_RUN=1 up_with /usr/lib/ka7/lib/libmpv.so.2 /ka7.AppImage
apt-get remove -y -qq 'libmpv*' >/dev/null

if [ -f /ka7.deb ]; then
  echo "== .deb"
  apt-get install -y -qq /ka7.deb >/dev/null
  up_with /opt/ka7/app/lib/libmpv.so.2 ka7-app
  # Usage on stderr, exit 64: it starts and loads its libraries.
  if ka7 --help 2>&1 | grep -q "^Usage: ka7"; then
    echo "   ka7 --help answers"
  else
    echo "FAILED: ka7 --help"; ka7 --help || true; exit 1
  fi
fi
echo "== OK"
SCRIPT
