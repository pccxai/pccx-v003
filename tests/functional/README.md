# Functional model

This directory contains Python references for the current Gemma 4 smallest BF16
slice and the local tiny functional-model fixture.

- `gemma4_smallest_reference.py` mirrors the current RTL BF16 helper behavior
  in `common/bf16/bf16_lane_pkg.sv` and models Attention, MLP, RMSNorm, RoPE,
  and the one-token smallest decode path.
- `gemma4_functional_model.py` provides a deterministic tiny Gemma 4-family
  forward model for software-side shape and quantization checks.
- `gemma4_quantization.py` covers BF16 fake-quantization plus symmetric INT4
  quantize, dequantize, and pack/unpack helpers.
- `rtl_vectors.py` emits the checked-in SystemVerilog vector package used by
  `tb/verilator/gemma4_bf16_functional_crosscheck_tb.sv`.
- `test_gemma4_smallest_reference.py` checks the Python model and the fixture
  values used by the RTL cross-check.
- `test_gemma4_functional_model.py` checks the tiny forward path and BF16/INT4
  quantization helpers.

Run from the repository root:

```sh
scripts/run_functional_model_tests.sh
```
