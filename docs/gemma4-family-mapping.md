# Gemma 4 Family Mapping

Status: local mapping for the current Gemma 4 E4B text smoke config. Numeric
model parameters absent from local v003 materials remain `TBD`.

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

## Reusable Cover

The common library is model-family neutral at its RTL boundary:

- tensor data enters through `tensor_stream_if`;
- token output exits through `token_out_if`;
- sparse metadata is carried through explicit fields;
- variant-specific size selection is isolated in `npu_v003_constants`.
