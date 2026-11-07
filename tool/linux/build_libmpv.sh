#!/usr/bin/env bash
# Builds Ka7's own player library for Linux: libmpv + FFmpeg, LGPL only (no
# GPL part: Ubuntu's libmpv is built GPL, Ka7 cannot ship it), into
#   app/linux/libmpv/{include,lib}   (ignored by git)
# Run inside the Ubuntu 22.04 builder (tool/linux/Dockerfile): what is built
# here runs on 22.04 and newer. tool/package_linux.sh runs it when missing.
#
# Sources pinned: FFmpeg by SHA-256 (same release as Android's), dav1d,
# libplacebo and mpv by git commit. dav1d (AV1, BSD) is linked into FFmpeg:
# Ubuntu releases ship incompatible versions of it.
# libass (subtitles, ISC) is shipped too, Ubuntu 22.04's: GTK does not bring
# it, and without it Ka7 does not start at all.
# Only libraries every desktop has stay outside: PulseAudio, ALSA, GnuTLS
# (online streams), zlib, the fonts libraries GTK uses (freetype, fribidi,
# harfbuzz, fontconfig), OpenGL (from the app's own context). No hardware
# decoding: no libva/vdpau to depend on.
set -euo pipefail
cd "$(dirname "$0")/../.."
root=$PWD

ffmpeg_version=8.1.3
ffmpeg_sha256=7138d28c96d9d3e3af4ee3d8cad72741f8ffb40da90c1112235dea3ecd3178a3
dav1d_version=1.5.3
dav1d_commit=b546257f770768b2c88258c533da38b91a06f737
libplacebo_version=7.360.1
libplacebo_commit=cee9b076f2c63104ccfd497fa79c39a867293ec4
mpv_version=0.41.0
mpv_commit=41f6a645068483470267271e1d09966ca3b9f413

out=$root/app/linux/libmpv
libass_version=$(dpkg-query -W -f='${Version}' libass9)
stamp="ffmpeg $ffmpeg_version, dav1d $dav1d_version, libplacebo $libplacebo_version, mpv $mpv_version, libass $libass_version"
if [[ -f $out/VERSIONS && $(head -1 "$out/VERSIONS") == "$stamp" ]]; then
  echo "   already built: $stamp"
  exit 0
fi

work=${KA7_LIBMPV_WORK:-$root/build/libmpv}
sources=${XDG_CACHE_HOME:-$HOME/.cache}/ka7-tools/sources
prefix=$work/prefix
rm -rf "$work" "$out"
mkdir -p "$work" "$sources" "$prefix"
jobs=$(nproc)
export PKG_CONFIG_PATH=$prefix/lib/pkgconfig
# Each library finds the others beside it, wherever the app is installed.
export LDFLAGS="-Wl,-rpath,\$ORIGIN -Wl,-z,origin"

fetch() { # url sha256 file
  local file=$sources/$3
  if [[ ! -f $file ]]; then
    curl -fsSL -o "$file.part" "$1"
    mv "$file.part" "$file"
  fi
  echo "$2  $file" | sha256sum -c --quiet - || { echo "bad checksum: $3" >&2; exit 1; }
}
# Long tools' output kept in a log, shown when they fail.
quiet() { "$@" >"$work/last.log" 2>&1 || { tail -40 "$work/last.log" >&2; exit 1; }; }
# Kept in the cache between runs, the pinned commit only, its submodules
# without their history (libplacebo's Vulkan-Headers took 15 min in full).
clone() { # url commit dir
  local cache=$sources/$3-$2
  if [[ ! -d $cache ]]; then
    rm -rf "$cache.part"
    git init -q "$cache.part"
    git -C "$cache.part" fetch -q --depth 1 "$1" "$2"
    git -C "$cache.part" checkout -q FETCH_HEAD
    git -C "$cache.part" submodule -q update --init --recursive --depth 1
    mv "$cache.part" "$cache"
  fi
  [[ $(git -C "$cache" rev-parse HEAD) == "$2" ]] || { echo "bad commit: $3" >&2; exit 1; }
  cp -r "$cache" "$work/$3"
}

echo "== dav1d $dav1d_version (AV1, BSD, inside FFmpeg)"
clone https://code.videolan.org/videolan/dav1d.git "$dav1d_commit" dav1d
quiet meson setup "$work/dav1d/build" "$work/dav1d" --prefix="$prefix" --libdir=lib \
  --buildtype=release --default-library=static -Denable_tools=false -Denable_tests=false
quiet ninja -C "$work/dav1d/build" install

echo "== FFmpeg $ffmpeg_version (LGPL)"
fetch "https://ffmpeg.org/releases/ffmpeg-$ffmpeg_version.tar.xz" "$ffmpeg_sha256" "ffmpeg-$ffmpeg_version.tar.xz"
tar -xJf "$sources/ffmpeg-$ffmpeg_version.tar.xz" -C "$work"
(
  cd "$work/ffmpeg-$ffmpeg_version"
  # Read everything, write nothing: decoders, demuxers, parsers, network.
  ./configure --prefix="$prefix" --libdir="$prefix/lib" \
    --enable-shared --disable-static --enable-pic \
    --disable-autodetect --disable-programs --disable-doc \
    --disable-avdevice --disable-encoders --disable-muxers \
    --enable-libdav1d --enable-gnutls --enable-zlib >"$work/last.log" 2>&1 ||
    { tail -40 "$work/last.log" "$work/ffmpeg-$ffmpeg_version/ffbuild/config.log" >&2; exit 1; }
  quiet make -j"$jobs"
  quiet make install
)

echo "== libplacebo $libplacebo_version (LGPL, OpenGL only)"
clone https://github.com/haasn/libplacebo.git "$libplacebo_commit" libplacebo
quiet meson setup "$work/libplacebo/build" "$work/libplacebo" --prefix="$prefix" --libdir=lib \
  --buildtype=release -Dauto_features=disabled -Dopengl=enabled -Dgl-proc-addr=disabled \
  -Ddemos=false -Dtests=false
quiet ninja -C "$work/libplacebo/build" install

echo "== mpv $mpv_version (libmpv, LGPL)"
clone https://github.com/mpv-player/mpv.git "$mpv_commit" mpv
quiet meson setup "$work/mpv/build" "$work/mpv" --prefix="$prefix" --libdir=lib \
  --buildtype=release -Dauto_features=disabled \
  -Dgpl=false -Dlibmpv=true -Dcplayer=false -Dtests=false \
  -Dplain-gl=enabled -Dzlib=enabled \
  -Diconv=enabled -Dpulse=enabled -Dalsa=enabled
quiet ninja -C "$work/mpv/build" install

echo "== no GPL part"
config=$(strings "$prefix/lib/libavcodec.so" | grep -m1 -- '--prefix=' || true)
[[ $config != *--enable-gpl* && $config != *--enable-nonfree* ]] ||
  { echo "FFmpeg was configured GPL or nonfree" >&2; exit 1; }
python3 -I -c "import json,sys; o={x['name']:x['value'] for x in json.load(open(sys.argv[1]))}; sys.exit(0 if o['gpl'] is False else 1)" \
    "$work/mpv/build/meson-info/intro-buildoptions.json" ||
  { echo "mpv was configured GPL" >&2; exit 1; }
echo "   FFmpeg and mpv: LGPL"

mkdir -p "$out/lib"
cp -r "$prefix/include" "$out/include"
cp -P "$prefix"/lib/lib{mpv,avcodec,avformat,avutil,avfilter,swresample,swscale,placebo}.so* "$out/lib/"
cp -P /usr/lib/x86_64-linux-gnu/libass.so.9* "$out/lib/"
# Each looks beside itself, and only there. Set here, not through FFmpeg's
# Makefile, which ate « $O » (« RIGIN: », whose empty entry also meant the
# current folder).
for lib in "$out"/lib/*.so.*; do
  [[ -L $lib ]] || patchelf --set-rpath '$ORIGIN' "$lib"
done
for lib in "$out"/lib/*.so.*; do
  [[ $(patchelf --print-rpath "$lib") == '$ORIGIN' ]] ||
    { echo "bad search path in $lib: $(patchelf --print-rpath "$lib")" >&2; exit 1; }
done
# Their licences go with them, in the packages.
mkdir -p "$out/licenses"
cp "$work/ffmpeg-$ffmpeg_version/COPYING.LGPLv2.1" "$out/licenses/FFmpeg-COPYING.LGPLv2.1"
cp "$work/ffmpeg-$ffmpeg_version/LICENSE.md" "$out/licenses/FFmpeg-LICENSE.md"
cp "$work/mpv/LICENSE.LGPL" "$out/licenses/mpv-LICENSE.LGPL"
cp "$work/mpv/Copyright" "$out/licenses/mpv-Copyright"
cp "$work/libplacebo/LICENSE" "$out/licenses/libplacebo-LICENSE"
cp "$work/dav1d/COPYING" "$out/licenses/dav1d-COPYING"
cp /usr/share/doc/libass9/copyright "$out/licenses/libass-copyright"
# mpv.pc requires FFmpeg's and libplacebo's: the app's build reads them all.
mkdir -p "$out/lib/pkgconfig"
for pc in mpv libavcodec libavfilter libavformat libavutil libswresample libswscale libplacebo; do
  # Every path (FFmpeg writes libdir in full), not only « prefix= ».
  sed "s|$prefix|$out|g" "$prefix/lib/pkgconfig/$pc.pc" >"$out/lib/pkgconfig/$pc.pc"
done
{
  echo "$stamp"
  echo "FFmpeg $ffmpeg_version  https://ffmpeg.org/releases/ffmpeg-$ffmpeg_version.tar.xz  sha256 $ffmpeg_sha256  LGPL 2.1+"
  echo "dav1d $dav1d_version  https://code.videolan.org/videolan/dav1d  commit $dav1d_commit  BSD-2-Clause"
  echo "libplacebo $libplacebo_version  https://github.com/haasn/libplacebo  commit $libplacebo_commit  LGPL 2.1+"
  echo "mpv $mpv_version  https://github.com/mpv-player/mpv  commit $mpv_commit  LGPL 2.1+ (-Dgpl=false)"
  echo "libass $libass_version  Ubuntu 22.04 package libass9 (source: apt-get source libass)  ISC"
} >"$out/VERSIONS"
echo "   $out"
du -shL "$out/lib"/*.so.* | sort -h | tail -8
