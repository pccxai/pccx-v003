# Functional model

This directory contains the Python reference for the current Gemma 4 smallest
BF16 slice.

- `gemma4_smallest_reference.py` mirrors the current RTL BF16 helper behavior
  in `common/bf16/bf16_lane_pkg.sv` and models Attention, MLP, RMSNorm, RoPE,
  and the one-token smallest decode path.
- `rtl_vectors.py` emits the checked-in SystemVerilog vector package used by
  `tb/verilator/gemma4_bf16_functional_crosscheck_tb.sv`.
- `test_gemma4_smallest_reference.py` checks the Python model and the fixture
  values used by the RTL cross-check.

Run from the repository root:

```sh
scripts/run_functional_model_tests.sh
```
