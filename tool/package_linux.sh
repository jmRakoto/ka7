#!/usr/bin/env bash
# Builds Ka7 for Linux and packs it into dist/:
#   ka7_<version>_amd64.deb  app (menu entry, `ka7-app`) and CLI (`ka7`)
#   Ka7-<version>-x86_64.AppImage  app only, runs without installing
# yt-dlp and ffmpeg are not bundled: the app installs them on first launch.
#
# Built in an Ubuntu 22.04 container (tool/linux/Dockerfile), so the packages
# run on 22.04 and newer; KA7_NATIVE_BUILD=1 builds on this machine instead
# (the packages then need a Linux as recent as this one).
# Check on an old Linux: tool/linux/check_old_linux.sh <AppImage> [<deb>].
set -euo pipefail
cd "$(dirname "$0")/.."
root=$PWD

if [[ ${KA7_IN_CONTAINER:-} != 1 && ${KA7_NATIVE_BUILD:-} != 1 ]]; then
  # The project's own Flutter (fvm) and package cache, at the same paths
  # inside: same versions, and nothing in the project points into the box.
  flutter_root=$(fvm flutter --version --machine 2>/dev/null |
    python3 -I -c 'import json,sys; print(json.load(sys.stdin)["flutterRoot"])')
  flutter_root=$(readlink -f "$flutter_root")
  pub_cache=$(readlink -f "${PUB_CACHE:-$HOME/.pub-cache}")
  tools=${XDG_CACHE_HOME:-$HOME/.cache}/ka7-tools
  mkdir -p "$tools"
  echo "== builder image (Ubuntu 22.04)"
  docker build -q -t ka7-linux-builder tool/linux >/dev/null
  docker run --rm -u "$(id -u):$(id -g)" \
    -e HOME=/tmp/home -e KA7_IN_CONTAINER=1 \
    -e FLUTTER_ROOT="$flutter_root" -e PUB_CACHE="$pub_cache" \
    -e XDG_CACHE_HOME="$(dirname "$tools")" \
    -e SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(git log -1 --format=%ct)}" \
    ${KA7_MAINTAINER:+-e KA7_MAINTAINER="$KA7_MAINTAINER"} \
    -v "$root:$root" -v "$flutter_root:$flutter_root" \
    -v "$pub_cache:$pub_cache" -v "$tools:$tools" \
    -w "$root" ka7-linux-builder tool/package_linux.sh
  exit
fi

if [[ ${KA7_IN_CONTAINER:-} == 1 ]]; then
  # A fresh home each time: no first-run usage statistics sent from here.
  flutter=("$FLUTTER_ROOT/bin/flutter" --suppress-analytics)
  dart=("$FLUTTER_ROOT/bin/dart" --suppress-analytics)
  mkdir -p "$HOME"
else
  flutter=(fvm flutter)
  dart=(fvm dart)
fi

id=mg.rakoto.ka7
version=$(sed -n 's/^version: \([0-9.]*\).*/\1/p' app/pubspec.yaml)
maintainer=${KA7_MAINTAINER:-"Ka7 <dev.cinco.mg@gmail.com>"}
stage=$root/build/package
dist=$root/dist
tools=${XDG_CACHE_HOME:-$HOME/.cache}/ka7-tools
rm -rf "$stage"
mkdir -p "$stage" "$dist" "$tools"

# Reproducible packages: every date inside them is the last commit's, so the
# same commit always gives the same files (and the same SHA-256).
export SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-$(git log -1 --format=%ct)}
same_dates() { find "$1" -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} +; }

echo "== build app $version"
# Leftovers of earlier builds would end up in the packages; objects compiled
# against this machine's libraries must not be reused in the container.
rm -rf app/build/linux/x64/release
(cd app && "${flutter[@]}" build linux --release --dart-define=KA7_VERSION="$version")
app=$root/app/build/linux/x64/release/bundle

echo "== build cli"
(cd cli && "${dart[@]}" build cli -o "$stage/cli")
cli=$stage/cli/bundle

# Desktop entry and icons, under [prefix]/share.
install_desktop_files() {
  local share=$1
  install -Dm644 packaging/linux/$id.desktop "$share/applications/$id.desktop"
  install -Dm644 packaging/linux/ka7-icon.svg \
    "$share/icons/hicolor/scalable/apps/$id.svg"
  for size in 48 512; do
    install -Dm644 "packaging/linux/ka7-icon-$size.png" \
      "$share/icons/hicolor/${size}x${size}/apps/$id.png"
  done
}

echo "== .deb"
deb=$stage/deb
mkdir -p "$deb/opt/ka7" "$deb/usr/bin" "$deb/DEBIAN"
cp -r "$app" "$deb/opt/ka7/app"
cp -r "$cli" "$deb/opt/ka7/cli"
ln -s /opt/ka7/app/ka7 "$deb/usr/bin/ka7-app"
ln -s /opt/ka7/cli/bin/ka7 "$deb/usr/bin/ka7"
install_desktop_files "$deb/usr/share"
cat > "$deb/DEBIAN/control" <<EOF
Package: ka7
Version: $version
Section: sound
Priority: optional
Architecture: amd64
Maintainer: $maintainer
Depends: libgtk-3-0t64 | libgtk-3-0, xz-utils, xdg-utils, zenity | kdialog
Installed-Size: $(du -sk "$deb/opt" | cut -f1)
Homepage: https://rakoto.mg
Description: YouTube links to clean, tagged MP3 or MP4 files
 Paste links, IDs or whole playlists, preview them, then download them as
 tagged MP3 or MP4 files, tidied in one folder per playlist. Downloads and
 updates the official yt-dlp and ffmpeg (LGPL build) on first launch.
EOF
deb_file=$dist/ka7_${version}_amd64.deb
same_dates "$deb"
fakeroot dpkg-deb --build --root-owner-group "$deb" "$deb_file" >/dev/null
echo "   $deb_file"

echo "== .AppImage"
appimagetool=$tools/appimagetool-x86_64.AppImage
if [[ ! -x $appimagetool ]]; then
  curl -fsSL -o "$appimagetool.part" \
    https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x "$appimagetool.part"
  mv "$appimagetool.part" "$appimagetool"
fi
appdir=$stage/Ka7.AppDir
mkdir -p "$appdir/usr/lib"
cp -r "$app" "$appdir/usr/lib/ka7"
install_desktop_files "$appdir/usr/share"
cp packaging/linux/$id.desktop "$appdir/$id.desktop"
cp packaging/linux/ka7-icon-512.png "$appdir/$id.png"
cat > "$appdir/AppRun" <<'EOF'
#!/bin/sh
here="$(dirname "$(readlink -f "$0")")"
exec "$here/usr/lib/ka7/ka7" "$@"
EOF
chmod +x "$appdir/AppRun"
same_dates "$appdir"
appimage_file=$dist/Ka7-$version-x86_64.AppImage
# No FUSE needed to run the tool itself.
APPIMAGE_EXTRACT_AND_RUN=1 ARCH=x86_64 "$appimagetool" --no-appstream \
  "$appdir" "$appimage_file" >/dev/null 2>&1
echo "   $appimage_file"

echo "== done"
