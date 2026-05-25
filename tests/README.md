# tests

Shared test fixtures live here as the v003 compatibility contract and common
library mature. The reusable UVM skeleton for this library starts under
[`../tb/`](../tb/).

`functional/` contains the Python reference for the current Gemma 4 smallest
BF16 Attention, MLP, and RMSNorm lane behavior, a tiny Gemma 4-family forward
fixture with BF16/INT4 quantization checks, and the generator that keeps the
Verilator cross-check vectors in sync.

See [`SOURCE_MANIFEST.md`](../SOURCE_MANIFEST.md) and
[`docs/`](../docs/) for the planning narrative.
