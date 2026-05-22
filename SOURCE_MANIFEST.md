# Source manifest

> This branch extends the local implementation RTL for the v003 common library.
> These files are written in this repository, not imported from an external
> source.

| domain | source repo | source SHA | source path | dest path | status |
| --- | --- | --- | --- | --- | --- |
| RTL integration | n/a | n/a | n/a | `hw/rtl/v003/` | dispatcher, L2, top, ISA, and constants |
| Common interfaces | n/a | n/a | n/a | `common/interfaces/` | SV interface/modport contracts |
| Common core logic | n/a | n/a | n/a | `common/{attention,ffn,matmul,normalization,sampling,interconnect}/` | local integer stream logic |
| UVM and smoke tests | n/a | n/a | n/a | `tb/` | UVM smoke top plus standalone Verilator smoke |
| AWS F2 synthesis | n/a | n/a | n/a | `constraints/v003_aws_f2.xdc`, `scripts/run_vivado_aws_f2_synth.tcl` | synthesis script requires official `AWS_F2_PART` |
| LLM | `pccxai/pccx-LLM-v003` (temporary planning line) | TBD | TBD | `LLM/...` | planning intake |
| Vision | `pccxai/pccx-vision-v001` (compatibility track) | TBD | TBD | `Vision/...` | planning intake (compatibility review pending) |
| Voice | n/a | n/a | n/a | `Voice/...` | placeholder |
| common | shared with `pccxai/pccx-v002/common/` (reference) | TBD | TBD | `common/...` | planning intake |

The table is a *planning* manifest only. Real intake rows are added
once a piece of source has been reviewed against the v003
compatibility contract and merged.
