#!/usr/bin/env bash
# Headless run of the playable-slice test.
#
# --fixed-fps 60 keeps the run deterministic and fast; the test itself counts
# physics ticks, so it also passes on an uncapped headless run.
#
#   ./game/tests/run.sh
#   GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot ./game/tests/run.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GODOT="${GODOT_BIN:-godot}"
exec "$GODOT" --headless --path "$ROOT/game" --fixed-fps 60 \
  --script res://tests/playable_slice_test.gd "$@"
