# Source manifest

> This branch extends the local implementation RTL for the v003 common library.
> These files are written in this repository, not imported from an external
> source.

| domain | source repo | source SHA | source path | dest path | status |
| --- | --- | --- | --- | --- | --- |
| RTL integration | n/a | n/a | n/a | `hw/rtl/v003/` | dispatcher, L2, top, ISA, and constants |
| Common interfaces | n/a | n/a | n/a | `common/interfaces/` | SV interface/modport contracts |
| Common core logic | n/a | n/a | n/a | `common/{attention,bf16,ffn,matmul,normalization,sampling,interconnect}/` | local integer stream logic plus BF16 attention/RoPE/MLP/RMSNorm slices |
| UVM and simulation tests | n/a | n/a | n/a | `tb/`, `scripts/run_verilator_full_sim.sh`, `scripts/run_xsim_smoke.sh` | UVM smoke top plus standalone Verilator and xsim smoke entrypoints |
| AWS F2 synthesis | n/a | n/a | n/a | `constraints/v003_aws_f2.xdc`, `scripts/run_vivado_aws_f2_synth.tcl`, `scripts/aws_f2_deploy_preview.sh` | synthesis script requires official `AWS_F2_PART`; deploy preview is local preflight only |
| LLM | n/a | n/a | n/a | `LLM/gemma4/` | local Gemma-family attention wrapper and smallest-target BF16 decode slices |
| Vision | `pccxai/pccx-vision-v001` (compatibility track) | TBD | TBD | `Vision/...` | planning intake (compatibility review pending) |
| Voice | n/a | n/a | n/a | `Voice/...` | placeholder |
| common | n/a | n/a | n/a | `common/...` | local v003 common logic |

The table is a local implementation manifest. Rows that still say `TBD` remain
open until the relevant source has been reviewed against the v003 compatibility
contract and merged.
