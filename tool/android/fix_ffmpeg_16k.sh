#!/usr/bin/env bash
# Makes youtubedl-android's ffmpeg load on 16 KB page devices.
#
# youtubedl-android 0.18.1 ships ffmpeg's plugin libraries inside
# libffmpeg.zip.so; five of them (libwebp and friends) are aligned for 4 KB
# pages, so the linker refuses them on 16 KB devices and ffmpeg never starts
# (upstream issue yausername/youtubedl-android#365). Flipping the alignment
# field is not valid ELF: this rebuilds libwebp with 16 KB pages and splices
# the five libraries back into a copy of the zip, written to the app's own
# jniLibs, which wins over the one from the library.
#
# Run again after changing the youtubedl-android version. Needs the Android
# NDK and CMake from the SDK.
set -euo pipefail
cd "$(dirname "$0")/../.."
root=$PWD

version=0.18.1
webp=1.6.0
abis=(arm64-v8a armeabi-v7a x86_64)
sdk=${ANDROID_HOME:-$HOME/Android/Sdk}
ndk=$(ls -d "$sdk"/ndk/* | sort -V | tail -1)
cmake=$(ls -d "$sdk"/cmake/*/bin/cmake | sort -V | tail -1)
cache=${XDG_CACHE_HOME:-$HOME/.cache}/ka7-tools
out=$root/app/android/app/src/main/jniLibs
work=$root/build/ffmpeg16k
rm -rf "$work"
mkdir -p "$cache" "$work"

aar=$(find "$HOME/.gradle/caches" -name "ffmpeg-$version.aar" | head -1)
if [[ -z $aar ]]; then
  echo "ffmpeg-$version.aar not in the Gradle cache: build the app once first." >&2
  exit 1
fi

echo "== libwebp $webp sources"
src=$cache/libwebp-$webp
if [[ ! -d $src ]]; then
  curl -fsSL -o "$cache/libwebp-$webp.tar.gz" \
    "https://github.com/webmproject/libwebp/archive/refs/tags/v$webp.tar.gz"
  tar -xzf "$cache/libwebp-$webp.tar.gz" -C "$cache"
fi

unzip -q -o "$aar" 'jni/*' -d "$work/aar"
for abi in "${abis[@]}"; do
  echo "== $abi: build libwebp with 16 KB pages"
  build=$work/build-$abi
  "$cmake" -S "$src" -B "$build" -G Ninja \
    -DCMAKE_MAKE_PROGRAM="$(dirname "$cmake")/ninja" \
    -DCMAKE_TOOLCHAIN_FILE="$ndk/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI="$abi" -DANDROID_PLATFORM=android-24 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SHARED_LINKER_FLAGS="-Wl,-z,max-page-size=16384" \
    -DBUILD_SHARED_LIBS=ON \
    -DWEBP_BUILD_CWEBP=OFF -DWEBP_BUILD_DWEBP=OFF -DWEBP_BUILD_GIF2WEBP=OFF \
    -DWEBP_BUILD_IMG2WEBP=OFF -DWEBP_BUILD_VWEBP=OFF -DWEBP_BUILD_WEBPINFO=OFF \
    -DWEBP_BUILD_ANIM_UTILS=OFF -DWEBP_BUILD_EXTRAS=OFF \
    -DWEBP_BUILD_LIBWEBPMUX=ON -DWEBP_BUILD_WEBPMUX=OFF >/dev/null
  "$cmake" --build "$build" >/dev/null
  strip=$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip
  for lib in libsharpyuv libwebp libwebpdecoder libwebpdemux libwebpmux; do
    "$strip" --strip-unneeded "$build/$lib.so"
  done

  echo "== $abi: splice into libffmpeg.zip.so"
  mkdir -p "$out/$abi"
  python3 -I tool/android/splice_zip.py \
    "$work/aar/jni/$abi/libffmpeg.zip.so" "$build" "$out/$abi/libffmpeg.zip.so"
done
echo "== done: $out/<abi>/libffmpeg.zip.so"
