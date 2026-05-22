# v003 Library Architecture

Status: Phase 2 first logic. Attention, FFN, INT4xINT8 matmul, and RMSNorm
now have one-beat integer stream behavior. Scheduling policy, build flow,
board runtime, and measurements are future work.

## Directory Map

| Path | Role |
| --- | --- |
| `common/interfaces/` | SV interface and modport contracts for host, memory, tensor, and token boundaries. |
| `common/pkg/` | Shared enum, typedef, and ISA package skeletons. |
| `common/attention/` | First attention core logic plus KV cache and softmax signatures. |
| `common/ffn/` | First FFN core logic plus activation signatures. |
| `common/matmul/` | First INT4xINT8 matmul logic plus fallback and accumulator signatures. |
| `common/normalization/` | First RMSNorm logic plus LayerNorm signature. |
| `common/sampling/` | Token selection core signatures. |
| `common/interconnect/` | Tensor stream crossbar and arbitration signatures. |
| `hw/rtl/v003/` | v003-specific top, dispatcher, L2 placeholder, ISA, and constants. |
| `tb/` | UVM skeleton plus standalone Verilator smoke tests. |
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
