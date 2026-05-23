# LLM

Reviewed LLM wrapper slices live here after they pass the central v003
compatibility contract.

Current content:

- `gemma4/gemma4_attention_slice.sv` connects RoPE and parameterized
  sliding-window MHA/GQA over the shared tensor stream boundary.

Full model wrappers, runtime behavior, weights, and board evidence are future
work.

See [`SOURCE_MANIFEST.md`](../SOURCE_MANIFEST.md) and
[`docs/`](../docs/) for the implementation narrative.
