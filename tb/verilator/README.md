# Verilator smoke tests

Standalone smoke tests for the v003 common-library logic pass.

- `v003_library_smoke_tb.sv` covers one-beat integer behavior for
  attention, KV cache, FFN, GELU, INT4xINT8 matmul, accumulation, RMSNorm,
  LayerNorm, sampling, arbitration, and crossbar routing.
- `gemma4_4b_variant_smoke_tb.sv` checks the Gemma 4 E4B local text config
  constants reflected in `npu_v003_constants.sv`.
- `gemma4_e4b_one_layer_tb.sv` drives `npu_v003_top` through the one-layer
  start path and checks token readback.

Run from the repository root:

```sh
scripts/run_verilator_smoke.sh
```
