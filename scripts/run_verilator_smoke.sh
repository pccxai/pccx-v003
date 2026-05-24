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
    -Ihw/rtl/v003 \
    --top-module "$top" \
    --Mdir "$build_dir" \
    "$@"

  "${build_dir}/V${top}"
}

run_top v003_library_smoke_tb \
  common/pkg/npu_common_pkg.sv \
  common/interfaces/tensor_stream_if.sv \
  common/interfaces/token_out_if.sv \
  common/attention/attention_core.sv \
  common/attention/kv_cache_core.sv \
  common/attention/mha_sliding_window_core.sv \
  common/attention/rope_unit.sv \
  common/attention/softmax_unit.sv \
  common/ffn/ffn_core.sv \
  common/ffn/gelu_unit.sv \
  common/ffn/silu_unit.sv \
  common/interconnect/arbiter.sv \
  common/interconnect/crossbar.sv \
  common/matmul/accumulator.sv \
  common/matmul/matmul_int4_int8.sv \
  common/matmul/matmul_int8_int8.sv \
  common/normalization/layernorm_core.sv \
  common/normalization/rmsnorm_core.sv \
  common/sampling/argmax_unit.sv \
  common/sampling/topk_sampler.sv \
  tb/verilator/v003_library_smoke_tb.sv

run_top gemma4_4b_variant_smoke_tb \
  hw/rtl/v003/npu_v003_constants.sv \
  tb/verilator/gemma4_4b_variant_smoke_tb.sv

run_top gemma4_e4b_one_layer_tb \
  hw/rtl/v003/isa_pkg_v003.sv \
  hw/rtl/v003/npu_v003_constants.sv \
  hw/rtl/v003/npu_v003_dispatcher.sv \
  hw/rtl/v003/npu_v003_l2_uram.sv \
  hw/rtl/v003/npu_v003_top.sv \
  tb/verilator/gemma4_e4b_one_layer_tb.sv

run_top gemma4_e2b_bf16_decode_tb \
  common/bf16/bf16_lane_pkg.sv \
  common/interfaces/tensor_stream_if.sv \
  common/interfaces/token_out_if.sv \
  common/attention/kv_cache_core.sv \
  common/bf16/bf16_attention_core.sv \
  common/bf16/bf16_mlp_core.sv \
  common/bf16/bf16_rmsnorm_core.sv \
  common/bf16/bf16_rope_unit.sv \
  LLM/gemma4/gemma4_e2b_bf16_decode_slice.sv \
  tb/verilator/gemma4_e2b_bf16_decode_tb.sv
