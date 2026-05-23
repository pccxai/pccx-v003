# Gemma 4 Wrapper Slice

This directory holds reviewed Gemma-family wrapper slices for v003.

Current content:

- `gemma4_attention_slice.sv` wires query/key RoPE into parameterized
  sliding-window MHA/GQA logic through `tensor_stream_if`.

The wrapper keeps exact model dimensions as parameters. E2B/E4B/nano-specific
top wrappers should set those parameters only from reviewed source material.
Board runtime, weights, and measured performance are outside this directory.
