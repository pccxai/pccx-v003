# Gemma 4 Wrapper Slice

This directory holds reviewed Gemma-family wrapper slices for v003.

Current content:

- `gemma4_e2b_bf16_decode_slice.sv` is the smallest-target BF16 decode slice.
  It keeps exact external model dimensions out of the RTL until the selected
  model source is reviewed, but wires the required local path:
  RMSNorm -> RoPE -> KV-cache-backed attention -> MLP -> token readback.
- `gemma4_attention_slice.sv` wires query/key RoPE into parameterized
  sliding-window MHA/GQA logic through `tensor_stream_if`.

The wrapper keeps exact model dimensions as parameters. E2B/E4B/nano-specific
top wrappers should set those parameters only from reviewed source material.
Board runtime, weights, and measured performance are outside this directory.
