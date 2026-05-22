# v003 Library Architecture

Status: implementation pass. Common integer stream logic now covers attention,
KV cache, softmax, FFN/SiLU/GELU, INT4xINT8 matmul, INT8xINT8 matmul,
accumulation, RMSNorm, LayerNorm, sampling, arbitration, and crossbar routing.
The v003 dispatcher, L2, top-level token readback, UVM smoke top, and Vivado
AWS F2 synthesis script coverage are present. Board runtime and measurements
remain future work.

## Directory Map

| Path | Role |
| --- | --- |
| `common/interfaces/` | SV interface and modport contracts for host, memory, tensor, and token boundaries. |
| `common/pkg/` | Shared enum, typedef, and ISA package anchors. |
| `common/attention/` | Attention, softmax, and KV cache logic. |
| `common/ffn/` | FFN, SiLU, and GELU logic. |
| `common/matmul/` | INT4xINT8, INT8xINT8, and INT32 accumulation logic. |
| `common/normalization/` | RMSNorm and LayerNorm logic. |
| `common/sampling/` | Deterministic argmax and top-k token selection logic. |
| `common/interconnect/` | Tensor stream crossbar and arbitration logic. |
| `hw/rtl/v003/` | v003-specific top, dispatcher, L2, ISA, and Gemma 4 constants. |
| `tb/` | UVM smoke tests plus standalone Verilator smoke tests. |
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
