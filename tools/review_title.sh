#!/usr/bin/env bash
# Actual-renderer boot and title input review, always using disposable saves.
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
if [[ $# -ne 1 || "$1" != /* ]]; then echo 'Usage: ./tools/review_title.sh /absolute/output' >&2; exit 2; fi
output_dir=$(realpath -m -- "$1")
run_dir=$(mktemp -d "${TMPDIR:-/tmp}/tidesworn-title-review-XXXXXXXX")
mkdir -p "$run_dir/userdata" "$output_dir"
export XDG_DATA_HOME="$run_dir/userdata" TIDESWORN_TEST_ROOT="$run_dir" TITLE_OUTPUT="$output_dir"
set +e
timeout 150 xvfb-run -a -s '-screen 0 1920x1080x24' env LIBGL_ALWAYS_SOFTWARE=1 godot --path "$repo_dir" res://tools/title_review.tscn > "$output_dir/review.log" 2>&1
result=$?
set -e
rg -m 100 '^\[(PASS|FAIL)\]|^TITLE_REVIEW|SCRIPT ERROR|ERROR:|^Failed method|^WARNING:' "$output_dir/review.log" || true
if rg -q '\[FAIL\]|SCRIPT ERROR|ERROR:|TITLE_REVIEW FAIL|Message queue out of memory|Object was deleted while awaiting' "$output_dir/review.log"; then exit 1; fi
rg -q '^TITLE_REVIEW PASS ' "$output_dir/review.log"
exit "$result"
