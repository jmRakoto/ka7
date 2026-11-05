#!/usr/bin/env bash
# Builds the small ffmpeg that Ka7 ships on Android, instead of the 37 MB one
# of youtubedl-android (ticket 001).
#
# youtubedl-android runs `libffmpeg.so` from the app's native library folder
# (passed to yt-dlp with --ffmpeg-location; yt-dlp finds `libffprobe.so` next
# to it) and unzips `libffmpeg.zip.so` for the libraries those two load. Here
# both programs are built with everything inside them, so the zip only holds
# a note. The three files go to the app's own jniLibs, which win over the
# library's (pickFirsts in app/android/app/build.gradle.kts).
#
# Read everything, write little: Ka7 never re-encodes video (an MP4 is video
# and audio put together as they are), so no video encoder at all. It makes
# MP3 (LAME), M4A (AAC), JPG covers, tags; it reads the common audio codecs
# and files, for YouTube and for other sites later.
#
# Built for 16 KB pages, so it also replaces fix_ffmpeg_16k.sh. LGPL: no
# --enable-gpl, as the desktop ffmpeg.
#
# Run again after changing a version below. Needs the Android NDK.
set -euo pipefail
cd "$(dirname "$0")/../.."
root=$PWD

ffmpeg_version=8.1.3
ffmpeg_sha256=7138d28c96d9d3e3af4ee3d8cad72741f8ffb40da90c1112235dea3ecd3178a3
lame_version=3.100
lame_sha256=ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e
api=24
# KA7_ABIS="x86_64" builds only that one (quicker, for the emulator);
# KA7_ABIS="linux" builds the same ffmpeg for this computer.
read -ra abis <<<"${KA7_ABIS:-arm64-v8a armeabi-v7a x86_64}"

sdk=${ANDROID_HOME:-$HOME/Android/Sdk}
ndk=$(ls -d "$sdk"/ndk/* | sort -V | tail -1)
bin=$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin
cache=${XDG_CACHE_HOME:-$HOME/.cache}/ka7-tools
out=$root/app/android/app/src/main/jniLibs
work=$root/build/ffmpeg-small
jobs=$(nproc)
android=()
rm -rf "$work"
mkdir -p "$cache" "$work"

# Downloads $2 once into the cache as $1, and checks it.
fetch() {
  local file=$cache/$1
  [[ -f $file ]] || curl -fsSL -o "$file" "$2"
  echo "$3  $file" | sha256sum -c --quiet - ||
    { echo "$1: unexpected SHA-256" >&2; exit 1; }
  echo "$file"
}

ffmpeg_tar=$(fetch "ffmpeg-$ffmpeg_version.tar.xz" \
  "https://ffmpeg.org/releases/ffmpeg-$ffmpeg_version.tar.xz" "$ffmpeg_sha256")
lame_tar=$(fetch "lame-$lame_version.tar.gz" \
  "https://downloads.sourceforge.net/project/lame/lame/$lame_version/lame-$lame_version.tar.gz" \
  "$lame_sha256")

# What Ka7 asks of ffmpeg, through yt-dlp.
decoders=(
  # Audio, to make MP3 or M4A from it.
  aac aac_latm mp3 mp3float mp2 mp2float opus vorbis flac alac ac3 eac3
  pcm_s16le pcm_s16be pcm_s24le pcm_f32le pcm_alaw pcm_mulaw
  # Covers, converted to JPG.
  webp png mjpeg bmp
)
encoders=(libmp3lame aac mjpeg png)
muxers=(mp3 mp4 ipod mov matroska webm adts ogg opus image2 ffmetadata null)
demuxers=(
  mov matroska mp3 aac flac ogg wav flv mpegts concat ffmetadata
  image2 image_jpeg_pipe image_png_pipe image_webp_pipe image_bmp_pipe
)
filters=(
  abuffer abuffersink buffer buffersink aresample aformat anull acopy
  null copy format scale
)
protocols=(file pipe)

join() {
  local IFS=,
  echo "$*"
}

for abi in "${abis[@]}"; do
  ldflags=""
  case $abi in
    arm64-v8a)
      triple=aarch64-linux-android arch=aarch64 cpu=armv8-a
      extra=()
      ;;
    armeabi-v7a)
      triple=armv7a-linux-androideabi arch=arm cpu=armv7-a
      extra=(--enable-neon --extra-cflags=-mfpu=neon)
      ;;
    x86_64)
      # No nasm here: plain C, only for emulators and Chromebooks.
      triple=x86_64-linux-android arch=x86_64 cpu=x86-64
      extra=(--disable-x86asm)
      ;;
    linux)
      # The same recipe for this computer, to try it with the desktop app:
      # build/ffmpeg-small/linux/bin, first on the PATH.
      triple=""
      ;;
    *)
      echo "unknown ABI: $abi" >&2
      exit 2
      ;;
  esac
  build=$work/$abi
  prefix=$build/prefix
  mkdir -p "$build"
  if [[ -n $triple ]]; then
    cc=$bin/$triple$api-clang
    strip=$bin/llvm-strip
    ldflags="-Wl,-z,max-page-size=16384"
    lame_target=(--host="$triple" CC="$cc" AR="$bin/llvm-ar"
      RANLIB="$bin/llvm-ranlib")
    ffmpeg_target=(
      --enable-cross-compile --target-os=android
      --arch="$arch" --cpu="$cpu"
      --cc="$cc" --cxx="$cc++" --ld="$cc"
      --ar="$bin/llvm-ar" --nm="$bin/llvm-nm" --ranlib="$bin/llvm-ranlib"
      --strip="$strip" "${extra[@]}"
    )
  else
    strip=strip
    lame_target=()
    ffmpeg_target=(--disable-x86asm)
  fi

  echo "== $abi: LAME $lame_version"
  tar -xzf "$lame_tar" -C "$build"
  (
    cd "$build/lame-$lame_version"
    ./configure "${lame_target[@]}" LDFLAGS="$ldflags" \
      --prefix="$prefix" --enable-static --disable-shared \
      --disable-frontend --disable-decoder >/dev/null
    make -j"$jobs" >/dev/null
    make install >/dev/null
  )

  echo "== $abi: ffmpeg $ffmpeg_version"
  tar -xJf "$ffmpeg_tar" -C "$build"
  (
    cd "$build/ffmpeg-$ffmpeg_version"
    ./configure \
      --prefix="$prefix" \
      "${ffmpeg_target[@]}" --pkg-config=false \
      --extra-cflags="-I$prefix/include" \
      --extra-ldflags="-L$prefix/lib $ldflags" \
      --enable-static --disable-shared --enable-pic --enable-small \
      --disable-debug --disable-doc --disable-autodetect \
      --disable-everything --disable-network --disable-avdevice \
      --disable-ffplay --enable-ffmpeg --enable-ffprobe \
      --enable-zlib --enable-libmp3lame \
      --enable-decoder="$(join "${decoders[@]}")" \
      --enable-encoder="$(join "${encoders[@]}")" \
      --enable-muxer="$(join "${muxers[@]}")" \
      --enable-demuxer="$(join "${demuxers[@]}")" \
      --enable-filter="$(join "${filters[@]}")" \
      --enable-protocol="$(join "${protocols[@]}")" \
      --enable-parsers --enable-bsfs >"$build/configure.log"
    make -j"$jobs" >/dev/null
  )

  if [[ $abi == linux ]]; then
    mkdir -p "$build/bin"
    for program in ffmpeg ffprobe; do
      "$strip" --strip-all -o "$build/bin/$program" \
        "$build/ffmpeg-$ffmpeg_version/$program"
    done
    echo "== linux: $build/bin"
    continue
  fi
  echo "== $abi: into jniLibs"
  mkdir -p "$out/$abi"
  for program in ffmpeg ffprobe; do
    "$strip" --strip-all \
      -o "$out/$abi/lib$program.so" "$build/ffmpeg-$ffmpeg_version/$program"
  done
  android+=("$abi")
done
[[ ${#android[@]} -gt 0 ]] || exit 0

# Unzipped at each start by youtubedl-android, which reads its size to know
# whether it changed: a note, and nothing to load.
python3 -I - "$out" "${android[@]}" <<'EOF'
import sys, zipfile
out, abis = sys.argv[1], sys.argv[2:]
note = b"Ka7: ffmpeg and ffprobe are built whole, nothing to load from here.\n"
for abi in abis:
    with zipfile.ZipFile(f"{out}/{abi}/libffmpeg.zip.so", "w") as z:
        # Fixed date: the same build gives the same file.
        z.writestr(zipfile.ZipInfo("README", (1980, 1, 1, 0, 0, 0)), note)
EOF
echo "== done: $out/<abi>/lib{ffmpeg,ffprobe,ffmpeg.zip}.so"
ls -l "$out"/*/lib{ffmpeg,ffprobe}.so
