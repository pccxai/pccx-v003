# v003 Quickstart

Status: local full-available simulation and AWS F2 synthesis-prep flow for the
current v003 library branch.

## 1. Check the Common Library

From the repository root:

```sh
verible-verilog-syntax --printtree=false \
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
  common/sampling/topk_sampler.sv
```

## 2. Run Standalone Verilator Simulation

```sh
bash scripts/run_verilator_full_sim.sh
```

The full-sim wrapper builds the available standalone Verilator tops:

- `v003_library_smoke_tb`
- `gemma4_4b_variant_smoke_tb`
- `gemma4_e4b_one_layer_tb`

If `verilator` is not installed, the script exits before simulation and reports
the missing tool.

## 3. Run the UVM Smoke Top

The UVM package is under `tb/pkg/npu_test_pkg.sv`; the top-level smoke wrapper
is `tb/uvm/npu_v003_uvm_tb.sv`. Compile it with a simulator that provides UVM,
then run:

```sh
+UVM_TESTNAME=test_gemma4_e4b_smoke
```

## 4. Run AWS F2 Out-of-Context Synthesis

Set the selected AWS F2 shell part in the environment, then launch Vivado with
the Tcl script:

```sh
export AWS_F2_PART=<aws-f2-shell-part>
vivado -mode batch -source scripts/run_vivado_aws_f2_synth.tcl
```

The script performs out-of-context synthesis for `npu_v003_top` and writes the
synthesis checkpoint plus utilization and timing summary reports under
`build/v003_aws_f2_synth/`.

## 5. Python ISA API

The companion `pccx-python` local package exposes v003 ISA opcodes through its
Python API. Keep v003 calls limited to opcodes defined in
`hw/rtl/v003/isa_pkg_v003.sv`.
