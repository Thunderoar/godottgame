#!/usr/bin/env bash
# Tests import/save authoring in a DISPOSABLE SOURCE COPY, never the user's project.
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
run_dir=$(mktemp -d "${TMPDIR:-/tmp}/tidesworn-studio-XXXXXXXX")
mkdir -p "$run_dir/project" "$run_dir/userdata"
rsync -a --exclude=.git --exclude=.godot --exclude=build --exclude=docs/evidence "$repo_dir/" "$run_dir/project/"
export XDG_DATA_HOME="$run_dir/userdata"
export TIDESWORN_TEST_ROOT="$run_dir"
printf 'Isolated creative editor artifacts: %s\n' "$run_dir"
timeout 120 godot --headless --path "$run_dir/project" --import > "$run_dir/import.log" 2>&1
if rg -q 'SCRIPT ERROR|ERROR:' "$run_dir/import.log"; then cat "$run_dir/import.log"; exit 1; fi
set +e
timeout 180 xvfb-run -a -s '-screen 0 1600x1000x24' godot --path "$run_dir/project" --editor -- --creative-tool-tests > "$run_dir/editor.log" 2>&1
result=$?
set -e
cat "$run_dir/editor.log"
if rg -q 'SCRIPT ERROR|ERROR:|\[TOOL FAIL\]' "$run_dir/editor.log"; then exit 1; fi
if ! rg -q '^--- creative tools: [0-9]+ checks, 0 failures ---$' "$run_dir/editor.log"; then exit 1; fi
if [[ "$result" -ne 0 ]]; then exit "$result"; fi
# A new process loads the saved registry and map and checks live collision/artwork.
timeout 60 xvfb-run -a -s '-screen 0 1280x720x24' godot --path "$run_dir/project" res://tools/creative_restart.tscn -- --map=res://data/maps/editor_workflow.tres > "$run_dir/restart.log" 2>&1
cat "$run_dir/restart.log"
if rg -q 'SCRIPT ERROR|ERROR:|--- creative restart: FAIL' "$run_dir/restart.log"; then exit 1; fi
rg -q '^--- creative restart: PASS ---$' "$run_dir/restart.log"
