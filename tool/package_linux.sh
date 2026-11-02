#!/usr/bin/env bash
# Builds Ka7 for Linux and packs it into dist/:
#   ka7_<version>_amd64.deb  app (menu entry, `ka7-app`) and CLI (`ka7`)
#   Ka7-<version>-x86_64.AppImage  app only, runs without installing
# yt-dlp and ffmpeg are not bundled: the app installs them on first launch.
set -euo pipefail
cd "$(dirname "$0")/.."
root=$PWD

id=mg.rakoto.ka7
version=$(sed -n 's/^version: \([0-9.]*\).*/\1/p' app/pubspec.yaml)
maintainer=${KA7_MAINTAINER:-"Ka7 <dev.cinco.mg@gmail.com>"}
stage=$root/build/package
dist=$root/dist
tools=${XDG_CACHE_HOME:-$HOME/.cache}/ka7-tools
rm -rf "$stage"
mkdir -p "$stage" "$dist" "$tools"

echo "== build app $version"
(cd app && fvm flutter build linux --release)
app=$root/app/build/linux/x64/release/bundle

echo "== build cli"
(cd cli && fvm dart build cli -o "$stage/cli")
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
appimage_file=$dist/Ka7-$version-x86_64.AppImage
# No FUSE needed to run the tool itself.
APPIMAGE_EXTRACT_AND_RUN=1 ARCH=x86_64 "$appimagetool" --no-appstream \
  "$appdir" "$appimage_file" >/dev/null 2>&1
echo "   $appimage_file"

echo "== done"
