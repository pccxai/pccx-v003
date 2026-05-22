# common

Reusable v003 common library.

Current content:

- `interfaces/` contains SV `interface` declarations with modports.
- `pkg/` contains shared enum, typedef, and ISA package anchors.
- `attention/attention_core.sv`, `attention/softmax_unit.sv`,
  `attention/kv_cache_core.sv`, `ffn/ffn_core.sv`, `ffn/silu_unit.sv`,
  `ffn/gelu_unit.sv`, `matmul/matmul_int4_int8.sv`,
  `matmul/matmul_int8_int8.sv`, `matmul/accumulator.sv`,
  `normalization/rmsnorm_core.sv`, `normalization/layernorm_core.sv`,
  `sampling/argmax_unit.sv`, `sampling/topk_sampler.sv`,
  `interconnect/arbiter.sv`, and `interconnect/crossbar.sv` contain integer
  stream logic.

Runtime behavior, board integration, and measurement evidence are future work.

See [`SOURCE_MANIFEST.md`](../SOURCE_MANIFEST.md) and
[`docs/`](../docs/) for the planning narrative.
