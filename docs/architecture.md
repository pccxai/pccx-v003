# v003 Library Architecture

Status: interface-only skeleton. Core RTL behavior, scheduling policy,
verification stimulus, build flow, board runtime, and measurements are future
work.

## Directory Map

| Path | Role |
| --- | --- |
| `common/interfaces/` | SV interface and modport contracts for host, memory, tensor, and token boundaries. |
| `common/pkg/` | Shared enum, typedef, and ISA package skeletons. |
| `common/attention/` | Pure attention, KV cache, and softmax core signatures. |
| `common/ffn/` | Pure feed-forward and activation core signatures. |
| `common/matmul/` | Quantized matmul and accumulator core signatures. |
| `common/normalization/` | RMSNorm and LayerNorm core signatures. |
| `common/sampling/` | Token selection core signatures. |
| `common/interconnect/` | Tensor stream crossbar and arbitration signatures. |
| `hw/rtl/v003/` | v003-specific top, dispatcher, L2 placeholder, ISA, and constants. |
| `tb/` | UVM skeleton for reusable environment, sequences, and smoke tests. |
| `constraints/` | AWS F2 placeholder constraint anchor. |

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
- sparse metadata is represented as an explicit contract, with behavior left
  for the implementation phase.

## Target Anchor

The AWS F2 target is represented by `constraints/v003_aws_f2.xdc` as a
placeholder for the VU9P-class build target. Physical constraints are added
only after the shell contract is selected.
