# Verilator smoke tests

Standalone smoke tests for the first v003 common-library logic pass.

- `v003_library_smoke_tb.sv` covers one-beat integer behavior for
  `attention_core`, `ffn_core`, `matmul_int4_int8`, and `rmsnorm_core`.
- `gemma4_4b_variant_smoke_tb.sv` checks the local Gemma 4 E4B row used by
  this repository for the requested 4B-class smoke without inventing hidden
  size, head count, KV head count, head dimension, or exact vocab constants.

Run from the repository root:

```sh
scripts/run_verilator_smoke.sh
```
