#!/usr/bin/env bash
# Checks on an Android device or emulator (one connected) that Ka7 plays on
# with the screen off, with its controls in the notification and the system's
# media session (lock screen, headset buttons), as a person would use them:
#   tool/android/check_background.sh
# Runs app/integration_test/android_background_test.dart, and drives it from
# outside with adb: it waits for each « KA7 … » line the test prints.
set -euo pipefail
cd "$(dirname "$0")/../../app"
adb=${ANDROID_HOME:-$HOME/Android/Sdk}/platform-tools/adb
log=$(mktemp)
trap 'rm -f "$log"; "$adb" shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1 || true' EXIT

fvm flutter test integration_test/android_background_test.dart >"$log" 2>&1 &
test_pid=$!

wait_for() { # line, seconds
  for _ in $(seq "$2"); do
    if grep -q "KA7 $1" "$log"; then
      grep -o "KA7 $1.*" "$log" | head -1 | sed 's/^/   /'
      return 0
    fi
    if ! kill -0 "$test_pid" 2>/dev/null; then break; fi
    sleep 1
  done
  echo "FAILED: no « KA7 $1 »"; tail -30 "$log"; exit 1
}
check() { # what, command
  if eval "$2"; then echo "   ✓ $1"; else echo "FAILED: $1"; exit 1; fi
}
key() { "$adb" shell input keyevent "$1"; }

echo "== playing"
wait_for PLAYING 600
session=$("$adb" shell dumpsys media_session)
check "a media session for Ka7 (lock screen, headset)" \
  'grep -q "package=mg.rakoto.ka7" <<<"$session"'
# « state=PlaybackState {state=PLAYING(3), … », « description=<title>, … ».
check "it says playing, with the title" \
  'grep -A40 "package=mg.rakoto.ka7" <<<"$session" | grep -q "state=PLAYING" &&
   grep -A40 "package=mg.rakoto.ka7" <<<"$session" | grep -q "description=Ka7 tone 440"'
check "the playback notification is up" \
  '"$adb" shell dumpsys notification --noredact | grep -q "mg.rakoto.ka7.playback"'

echo "== headset buttons"
key KEYCODE_MEDIA_PAUSE
wait_for PAUSED 20
key KEYCODE_MEDIA_PLAY
wait_for RESUMED 20

echo "== Home, then screen off; next pressed with the screen off"
key KEYCODE_HOME
sleep 3
key KEYCODE_SLEEP
sleep 2
check "the screen is off" \
  '"$adb" shell dumpsys power | grep -q "mWakefulness=Asleep\|mWakefulness=Dozing"'
sleep 10
key KEYCODE_MEDIA_NEXT
wait_for NEXT 30
wait_for "BACKGROUND OK" 60
key KEYCODE_WAKEUP

wait "$test_pid" && echo "== OK" || { echo "FAILED: the test itself"; tail -30 "$log"; exit 1; }
