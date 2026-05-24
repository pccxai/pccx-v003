# v003 Library Architecture

Status: implementation pass. v003 is the reusable library line, not a full RTL
release claim. Common integer stream logic now covers attention,
RoPE, sliding-window MHA/GQA gating, KV cache, softmax, FFN/SiLU/GELU,
INT4xINT8 matmul, INT8xINT8 matmul, accumulation, RMSNorm, LayerNorm, sampling,
arbitration, and crossbar routing. A BF16 lane slice covers Attention, RoPE,
MLP, and RMSNorm for the smallest-target decode path. The v003 dispatcher, L2,
top-level token readback, UVM smoke top, xsim smoke entrypoint, and Vivado AWS
F2 synthesis/deploy-preview script coverage are present. The Python functional
model now emits checked-in RTL cross-check vectors for the BF16 Attention, MLP,
and RMSNorm slice. Board runtime and measurements remain future work.

## Directory Map

| Path | Role |
| --- | --- |
| `common/interfaces/` | SV interface and modport contracts for host, memory, tensor, and token boundaries. |
| `common/pkg/` | Shared enum, typedef, and ISA package anchors. |
| `common/attention/` | Attention, RoPE, sliding-window MHA/GQA, softmax, and KV cache logic. |
| `common/bf16/` | BF16 lane helpers and BF16 Attention/RoPE/MLP/RMSNorm slices. |
| `common/ffn/` | FFN, SiLU, and GELU logic. |
| `common/matmul/` | INT4xINT8, INT8xINT8, and INT32 accumulation logic. |
| `common/normalization/` | RMSNorm and LayerNorm logic. |
| `common/sampling/` | Deterministic argmax and top-k token selection logic. |
| `common/interconnect/` | Tensor stream crossbar and arbitration logic. |
| `hw/rtl/v003/` | v003-specific top, dispatcher, L2, ISA, and Gemma 4 constants. |
| `tb/` | UVM smoke tests plus standalone Verilator smoke tests and functional cross-check vectors. |
| `tests/functional/` | Python reference model, vector generator, and unit tests for the current BF16 slice. |
| `constraints/` | AWS F2 constraint anchor. |

## Modular Rule

Each RTL block is split into three roles:

| Role | Skeleton Rule |
| --- | --- |
| Input interface | Exposed through SV `interface` declarations and consumer/slave modports. |
| Core | Pure module signature with clock, reset, and interface modports only. |
| Output interface | Exposed through producer/master modports. |

Common cores do not expose AXI directly. External command, memory, and token
paths terminate at the v003 boundary and connect inward through the shared
interface contracts.

## Attention Slice

The current attention lane is intentionally modular:

- `rope_unit` rotates signed INT8 tensor pairs with an explicit rotation stream;
- `mha_sliding_window_core` checks causal sliding-window position and GQA
  head-to-KV-head mapping from tensor `user` metadata;
- `kv_cache_core` remains a small addressable stream cache for local smoke and
  unit-level integration checks.

The exact model-specific sliding window length stays a wrapper/config parameter
until backed by the selected model source.

## Smallest-Target BF16 Slice

The first v003 Gemma-family implementation target is the smallest reviewed
family row, currently anchored as `GEMMA4_E2B` in
`npu_v003_constants.sv`. If a reviewed nano/E1B model source becomes available,
that row can replace the target without changing the common BF16 module
boundaries.

The local BF16 decode slice is:

```text
tensor input -> BF16 RMSNorm -> BF16 RoPE -> KV-cache-backed BF16 attention
             -> BF16 MLP -> token readback
```

This is a single-model smoke path, not a full model runtime or board result.

## Functional Cross-Check Gate

`tests/functional/gemma4_smallest_reference.py` mirrors the current BF16 helper
behavior used by the RTL slice. `tests/functional/rtl_vectors.py` renders
`tb/verilator/gemma4_bf16_functional_vectors.svh`, and
`tb/verilator/gemma4_bf16_functional_crosscheck_tb.sv` compares RTL outputs
against those vectors in the Verilator smoke flow.

Run the Python side before any RTL smoke update:

```sh
bash scripts/run_functional_model_tests.sh
```

## System Boundary

The v003 NPU keeps the v002 self-contained accelerator pattern:

- command/control enters through AXI-Lite style command interfaces;
- model data and intermediate tensors stay inside accelerator-managed paths;
- host-facing generation output is token readback only;
- sparse metadata is represented as an explicit contract and is produced by the
  dispatcher for sparse opcodes.

## Target Anchor

The AWS F2 target is represented by `constraints/v003_aws_f2.xdc` and
`scripts/run_vivado_aws_f2_synth.tcl`. The Tcl script requires `AWS_F2_PART`
from the selected official shell before synthesis runs.
