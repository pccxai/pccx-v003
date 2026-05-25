# PCCX v003 — IP-core implementation package

> **PCCX™ v003 is an implementation branch for the July-before synthesis
> target**, not a stable RTL release or fabrication claim.

This repository is the canonical home for the next-generation PCCX™
v003 IP-core line. It mirrors the layout of the published `pccx-v002`
package (`LLM/`, `Vision/`, `Voice/`, `common/`, `compatibility/`,
`docs/`, `tests/`, `scripts/`) and exists so external consumers have
a single, predictable location to track v003 architecture and implementation
material.

## Status

- **Library implementation in progress.** Reusable common interface contracts
  live under `common/interfaces/`; integer stream logic now exists for
  attention, RoPE, sliding-window MHA, KV cache, softmax, FFN/SiLU/GELU,
  INT4xINT8 matmul,
  INT8xINT8 matmul, accumulation, RMSNorm, LayerNorm, sampling, arbitration,
  and crossbar routing. A BF16 lane slice now covers attention, RoPE, MLP, and
  RMSNorm for the smallest-target decode path.
- `hw/rtl/v003/` contains a working dispatcher/top/L2 integration path for
  AXI-Lite instruction injection and token readback smoke testing.
- Verilator smoke tops and UVM smoke checks cover the Gemma 4 E4B local text
  config constants, one-layer top-level dispatch path, and Gemma 4 E2B BF16
  decode-slice path.
- Python functional-model fixtures cover the current BF16 Attention, MLP, and
  RMSNorm lane behavior, a tiny Gemma 4-family forward path with BF16/INT4
  quantization checks, and a Verilator RTL cross-check vector package.
- The local v003 target is common RTL logic plus the smallest reviewed Gemma 4
  family row first, Verilator/xsim smoke entrypoints, and AWS F2
  out-of-context synthesis/deploy-preview setup.
- Board runtime and measured hardware performance remain separate future work.
- [`pccxai/pccx-LLM-v003`](https://github.com/pccxai/pccx-LLM-v003) was
  a historical temporary feeder for early v003 LLM planning. It is now
  superseded / retired and is no longer an active public track. Any new
  reusable v003 LLM material belongs under `LLM/` of this repository.

## What this package will hold (target shape)

| Directory | Target content |
| --- | --- |
| `LLM/` | reusable LLM RTL, sim/tb, formal harness, scripts |
| `Vision/` | reusable Vision RTL (subject to compatibility review with `pccxai/pccx-vision-v001`) |
| `Voice/` | reusable Voice RTL when a substrate is decided |
| `common/` | shared packages, interfaces, wrappers |
| `compatibility/` | `v003-contract.yaml` plus register / memory / top-interface frozen documents |
| `docs/` | per-domain READMEs and the v003 contract narrative |
| `hw/rtl/v003/` | v003 top, dispatcher, L2, ISA, and Gemma 4 constants |
| `tests/` | shared test fixtures, intake tests for absorbed material |
| `scripts/` | filelist, build, claim-scan, repo-boundary scripts |

## Current library implementation

| Directory | Current content |
| --- | --- |
| `common/interfaces/` | AXI HP, ACP, AXI-Lite command, tensor stream, and token output interfaces. |
| `common/attention/` | attention, RoPE, sliding-window MHA, softmax, and KV cache logic. |
| `common/bf16/` | BF16 lane helpers and BF16 attention/RoPE/MLP/RMSNorm slices. |
| `common/ffn/` | feed-forward, SiLU, and GELU logic. |
| `common/matmul/` | INT4/INT8 and INT8/INT8 matmul logic plus INT32 accumulation. |
| `common/normalization/` | RMSNorm and LayerNorm integer stream logic. |
| `common/sampling/` | deterministic argmax and top-k token selection logic. |
| `common/interconnect/` | tensor stream crossbar and arbiter logic. |
| `tb/` | UVM smoke checks plus standalone Verilator smoke tests and functional cross-check vectors. |
| `tests/functional/` | Python functional reference, RTL-vector generation, and functional-model unit checks. |
| `constraints/` | AWS F2 constraint anchor. |

## Boundary rule (unchanged from v002)

The model and the board consume the IP core. The IP core never
references a specific model or board name inside its `rtl/`,
`compatibility/`, or `formal/` paths. Application repositories pin
this package at a SHA that is reachable from `pccx-v003/main`.

## Canonical docs

- Project site: <https://pccx.pages.dev/en/>
- v003 pages: <https://pccx.pages.dev/en/docs/v003/>
- v002 contract narrative (reference): <https://pccx.pages.dev/en/docs/reference/v002-contract.html>

## Trackers

- v002/v003 consolidation: [pccxai/pccx#61](https://github.com/pccxai/pccx/issues/61)
- v003 implementation: [pccxai/pccx#64](https://github.com/pccxai/pccx/issues/64)
- vision-v001 absorption: [pccxai/pccx#65](https://github.com/pccxai/pccx/issues/65)

## Trademark

`PCCX™` is a mark used by the PCCX project. Korean trademark
applications are pending in Classes 09 and 42. Registration has not
been granted; do not use `PCCX®` until the central trademark policy
is updated. See the canonical policy at
[`pccxai/pccx/TRADEMARKS.md`](https://github.com/pccxai/pccx/blob/main/TRADEMARKS.md).

## License

Apache License 2.0 — see [`LICENSE`](LICENSE).
