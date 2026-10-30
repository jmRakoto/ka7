#!/usr/bin/env bash
# Gate before closing a task: format, analysis, all tests.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== format"
fvm dart format --output=none --set-exit-if-changed app/lib app/test packages

echo "== analyze"
fvm dart analyze --fatal-infos

echo "== ka7_core tests"
(cd packages/ka7_core && fvm dart test)

echo "== app tests"
(cd app && fvm flutter test)

echo "== all green"
