# Gemma 4 Family Mapping

Status: local mapping for the current smallest-target and Gemma 4 E4B text
smoke configs. Numeric model parameters absent from local v003 materials remain
`TBD`.

## Variant Table

| Variant | hidden size | n_layers | n_heads | kv_heads | vocab_size | head_dim | context | modalities |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `GEMMA4_E2B` | TBD | 35 | TBD | TBD | 262K | TBD | 128K | text, image, audio |
| `GEMMA4_E4B` | 2560 | 42 | 8 | 2 | 262144 | 256 | 131072 | text, image, audio |
| `GEMMA4_26B_A4B` | TBD | 30 | TBD | TBD | 262K | TBD | 256K | text, image |
| `GEMMA4_31B` | TBD | 60 | TBD | TBD | 262K | TBD | 256K | text, image |

## Mapping Rule

`hw/rtl/v003/npu_v003_constants.sv` reserves enum values and parameter anchors
for the family rows. Values absent from local material stay as `TBD`.
`Gemma4V003SmallestTarget` currently points at `GEMMA4_E2B`, with separate
local smoke constants for the BF16 decode slice. Nano/E1B remains an explicit
candidate only after a reviewed source provides exact shape parameters.

## Reusable Cover

The common library is model-family neutral at its RTL boundary:

- tensor data enters through `tensor_stream_if`;
- token output exits through `token_out_if`;
- sparse metadata is carried through explicit fields;
- RoPE and sliding-window attention are parameterized common-library blocks;
- variant-specific size selection is isolated in `npu_v003_constants`.
- BF16 Attention/RoPE/MLP/RMSNorm logic is isolated under `common/bf16/`;
- the smallest-target decode wrapper is isolated under `LLM/gemma4/`.
