# Gemma 4 Family Mapping

Status: placeholder mapping. Numeric model parameters absent from the linked
Google official Gemma 4 sources remain `TBD`.

Reference check used for this skeleton:

- <https://ai.google.dev/gemma/docs/get_started>
- <https://ai.google.dev/gemma/docs/core/model_card_4>
- <https://ai.google.dev/gemma/docs/releases>

## Variant Table

| Variant | hidden size | n_layers | n_heads | kv_heads | vocab_size | head_dim | context | modalities |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `GEMMA4_E2B` | TBD | 35 | TBD | TBD | 262K | TBD | 128K | text, image, audio |
| `GEMMA4_E4B` | TBD | 42 | TBD | TBD | 262K | TBD | 128K | text, image, audio |
| `GEMMA4_26B_A4B` | TBD | 30 | TBD | TBD | 262K | TBD | 256K | text, image |
| `GEMMA4_31B` | TBD | 60 | TBD | TBD | 262K | TBD | 256K | text, image |

## Mapping Rule

`hw/rtl/v003/npu_v003_constants.sv` reserves enum values and parameter anchors
for the official family rows. Values absent from the official model card stay
as `TBD`.

## Reusable Cover

The common library is model-family neutral at its RTL boundary:

- tensor data enters through `tensor_stream_if`;
- token output exits through `token_out_if`;
- sparse metadata is carried through explicit fields;
- variant-specific size selection is isolated in `npu_v003_constants`.
