#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

synth_dir="build/v003_aws_f2_synth"
dcp_path="${synth_dir}/npu_v003_top_synth.dcp"
timing_path="${synth_dir}/timing_synth.rpt"
util_path="${synth_dir}/utilization_synth.rpt"

missing=0
for path in "$dcp_path" "$timing_path" "$util_path"; do
  if [[ ! -f "$path" ]]; then
    echo "MISSING: $path"
    missing=1
  else
    echo "FOUND: $path"
  fi
done

if [[ $missing -ne 0 ]]; then
  echo "BLOCKED: run Vivado synthesis before AWS F2 deploy preview."
  exit 2
fi

cat <<PREVIEW
AWS F2 deploy preview:
- Synth checkpoint: $dcp_path
- Timing report: $timing_path
- Utilization report: $util_path
- Next gated step: package the reviewed checkpoint for the selected AWS F2 shell.

This script does not upload artifacts, call AWS APIs, create AFIs, or mutate
cloud resources. Use a separate operator-controlled terminal for those steps.
PREVIEW
