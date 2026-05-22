# common

Reusable v003 common library.

Current content:

- `interfaces/` contains SV `interface` declarations with modports.
- `pkg/` contains shared enum, typedef, and ISA package anchors.
- `attention/attention_core.sv`, `ffn/ffn_core.sv`,
  `matmul/matmul_int4_int8.sv`, and `normalization/rmsnorm_core.sv` contain
  first-pass integer stream logic.
- Remaining compute modules are still pure core signatures only.

Runtime behavior, board integration, and measurement evidence are future work.

See [`SOURCE_MANIFEST.md`](../SOURCE_MANIFEST.md) and
[`docs/`](../docs/) for the planning narrative.
