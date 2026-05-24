#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

for tool in xvlog xelab xsim; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: $tool not found on PATH" >&2
    exit 127
  fi
done

build_dir="build/xsim/v003_bf16_decode"
snapshot="gemma4_e2b_bf16_decode_tb_sim"
rm -rf "$build_dir"
mkdir -p "$build_dir"

xvlog -sv \
  -i common/interfaces \
  -i common/bf16 \
  -i common/attention \
  -i LLM/gemma4 \
  common/bf16/bf16_lane_pkg.sv \
  common/interfaces/tensor_stream_if.sv \
  common/interfaces/token_out_if.sv \
  common/attention/kv_cache_core.sv \
  common/bf16/bf16_attention_core.sv \
  common/bf16/bf16_mlp_core.sv \
  common/bf16/bf16_rmsnorm_core.sv \
  common/bf16/bf16_rope_unit.sv \
  LLM/gemma4/gemma4_e2b_bf16_decode_slice.sv \
  tb/verilator/gemma4_e2b_bf16_decode_tb.sv \
  -log "${build_dir}/xvlog.log"

xelab gemma4_e2b_bf16_decode_tb \
  -s "$snapshot" \
  -debug typical \
  -log "${build_dir}/xelab.log"

xsim "$snapshot" \
  -R \
  -log "${build_dir}/xsim.log"
