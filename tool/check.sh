#!/usr/bin/env bash
# Gate before closing a task: format, analysis, all tests.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== format"
fvm dart format --output=none --set-exit-if-changed app/lib app/test packages cli

echo "== analyze"
fvm dart analyze --fatal-infos

echo "== ka7_core tests"
(cd packages/ka7_core && fvm dart test)

echo "== ka7_engine_ytdlp tests"
(cd packages/ka7_engine_ytdlp && fvm dart test)

echo "== ka7_engine_explode tests"
(cd packages/ka7_engine_explode && fvm dart test)

echo "== ka7_store tests"
(cd packages/ka7_store && fvm dart test)

echo "== cli tests"
(cd cli && fvm dart test)

echo "== app tests"
(cd app && fvm flutter test)

echo "== all green"
