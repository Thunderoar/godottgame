#!/usr/bin/env bash
# Real GL renderer, fixed viewport, independent user data. Explicit output directory.
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
if [[ $# -ne 1 ]]; then echo 'Usage: ./tools/review_monsoon.sh /absolute/output/directory' >&2; exit 2; fi
output_dir=$(realpath -m -- "$1")
run_dir=$(mktemp -d "${TMPDIR:-/tmp}/tidesworn-monsoon-XXXXXXXX")
mkdir -p "$run_dir/userdata" "$output_dir"
export XDG_DATA_HOME="$run_dir/userdata" TIDESWORN_TEST_ROOT="$run_dir" MONSOON_OUTPUT="$output_dir"
set +e
timeout 180 xvfb-run -a -s '-screen 0 1280x720x24' env LIBGL_ALWAYS_SOFTWARE=1 godot --path "$repo_dir" res://tools/monsoon_review.tscn > "$output_dir/review.log" 2>&1
result=$?
set -e
cat "$output_dir/review.log"
if rg -q '\[FAIL\]|SCRIPT ERROR|ERROR:' "$output_dir/review.log"; then exit 1; fi
rg -q '^MONSOON_REVIEW PASS ' "$output_dir/review.log"
exit "$result"
