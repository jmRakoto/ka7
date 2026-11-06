#!/usr/bin/env bash
# Starts Ka7's Linux packages on the oldest Linux they promise to run on
# (Ubuntu 22.04, GLib 2.72), in a clean container with a virtual screen:
#   tool/linux/check_old_linux.sh dist/Ka7-<v>-x86_64.AppImage [dist/ka7_<v>_amd64.deb]
# Fails when the app does not stay up for 15 s (« symbol lookup error »…),
# or the CLI does not answer.
set -euo pipefail
base=${KA7_OLD_LINUX:-ubuntu:22.04}
appimage=$(readlink -f "$1")
deb=${2:+$(readlink -f "$2")}

run() {
  docker run --rm -i \
    -v "$appimage:/ka7.AppImage:ro" \
    ${deb:+-v "$deb:/ka7.deb:ro"} \
    "$base" bash -s
}

run <<'SCRIPT'
set -eu
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null
# What a desktop has: GTK 3, OpenGL (Mesa), a screen (virtual here).
apt-get install -y -qq libgtk-3-0 libegl1 libgl1 libgles2 xvfb xauth >/dev/null
echo "== $(. /etc/os-release; echo "$PRETTY_NAME"), GLib $(dpkg-query -W -f='${Version}' libglib2.0-0)"

up_for_15s() {
  local log=/tmp/run.log
  xvfb-run -a timeout 15 "$@" >"$log" 2>&1 && status=0 || status=$?
  if grep -qiE "symbol lookup error|undefined symbol|error while loading shared libraries|not found \(required" "$log" \
      || [ "$status" != 124 ]; then
    echo "FAILED (exit $status):"; cat "$log"; return 1
  fi
  echo "   up for 15 s"
}

echo "== AppImage"
APPIMAGE_EXTRACT_AND_RUN=1 up_for_15s /ka7.AppImage

if [ -f /ka7.deb ]; then
  echo "== .deb"
  apt-get install -y -qq /ka7.deb >/dev/null
  up_for_15s ka7-app
  # Usage on stderr, exit 64: it starts and loads its libraries.
  if ka7 --help 2>&1 | grep -q "^Usage: ka7"; then
    echo "   ka7 --help answers"
  else
    echo "FAILED: ka7 --help"; ka7 --help || true; exit 1
  fi
fi
echo "== OK"
SCRIPT
