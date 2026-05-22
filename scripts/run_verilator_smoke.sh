#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! command -v verilator >/dev/null 2>&1; then
  echo "ERROR: verilator not found on PATH" >&2
  exit 127
fi

run_top() {
  local top="$1"
  shift

  local build_dir="obj_dir/${top}"
  rm -rf "$build_dir"

  verilator \
    --binary \
    --timing \
    --Wall \
    --Wno-fatal \
    --top-module "$top" \
    --Mdir "$build_dir" \
    "$@"

  "${build_dir}/V${top}"
}

run_top v003_library_smoke_tb \
  common/pkg/npu_common_pkg.sv \
  common/interfaces/tensor_stream_if.sv \
  common/attention/attention_core.sv \
  common/ffn/ffn_core.sv \
  common/matmul/matmul_int4_int8.sv \
  common/normalization/rmsnorm_core.sv \
  tb/verilator/v003_library_smoke_tb.sv

run_top gemma4_4b_variant_smoke_tb \
  hw/rtl/v003/npu_v003_constants.sv \
  tb/verilator/gemma4_4b_variant_smoke_tb.sv
