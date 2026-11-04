#!/usr/bin/env bash
# Builds Ka7 for Android into dist/, one APK per processor (a single APK for
# all of them would be about 3 times bigger):
#   Ka7-<version>-arm64-v8a.apk    almost every phone since 2017
#   Ka7-<version>-armeabi-v7a.apk  older 32-bit phones
#   Ka7-<version>-x86_64.apk       emulators, Chromebooks
set -euo pipefail
cd "$(dirname "$0")/.."
root=$PWD
version=$(sed -n 's/^version: \([0-9.]*\).*/\1/p' app/pubspec.yaml)

# ffmpeg fixed for 16 KB page devices: built once, then reused.
if [[ ! -f app/android/app/src/main/jniLibs/arm64-v8a/libffmpeg.zip.so ]]; then
  tool/android/fix_ffmpeg_16k.sh
fi

(cd app && fvm flutter build apk --release --split-per-abi \
  --dart-define=KA7_VERSION="$version")
mkdir -p dist
for abi in arm64-v8a armeabi-v7a x86_64; do
  cp "app/build/app/outputs/flutter-apk/app-$abi-release.apk" \
    "dist/Ka7-$version-$abi.apk"
  echo "   dist/Ka7-$version-$abi.apk $(du -h "dist/Ka7-$version-$abi.apk" | cut -f1)"
done
