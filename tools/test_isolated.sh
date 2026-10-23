#!/usr/bin/env bash
# Linux test entrypoint: never shares Godot user:// with the player's game.
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
run_dir=$(mktemp -d "${TMPDIR:-/tmp}/tidesworn-tests-XXXXXXXX")
export XDG_DATA_HOME="$run_dir/userdata"
export TIDESWORN_TEST_ROOT="$run_dir"
mkdir -p "$XDG_DATA_HOME"
printf 'Isolated test artifacts: %s\n' "$run_dir"
set +e
timeout 600 godot --headless --path "$repo_dir" res://tools/tide_test.tscn 2>&1 | tee "$run_dir/test.log"
result=${PIPESTATUS[0]}
set -e
if rg -q '\[FAIL\]|SCRIPT ERROR|ERROR:' "$run_dir/test.log"; then
	exit 1
fi
if ! rg -q '^--- tide test: [0-9]+ checks, PASS ---$' "$run_dir/test.log"; then
	printf 'Acceptance summary missing or incomplete.\n' >&2
	exit 1
fi
exit "$result"
