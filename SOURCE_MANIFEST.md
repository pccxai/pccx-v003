# Source manifest

> Phase 2 starts local implementation RTL for selected common cores. These
> files are written in this repository, not imported from an external source.

| domain | source repo | source SHA | source path | dest path | status |
| --- | --- | --- | --- | --- | --- |
| RTL skeleton | n/a | n/a | n/a | `hw/rtl/v003/` | interface-only skeleton |
| Common interfaces | n/a | n/a | n/a | `common/interfaces/` | interface-only skeleton |
| Common core logic | n/a | n/a | n/a | `common/{attention,ffn,matmul,normalization}/` | first local integer stream logic for selected cores |
| Common core signatures | n/a | n/a | n/a | `common/{attention,ffn,matmul,normalization,sampling,interconnect}/` | remaining signature-only skeletons |
| UVM and smoke tests | n/a | n/a | n/a | `tb/` | UVM placeholders plus standalone Verilator smoke |
| AWS F2 constraints | n/a | n/a | n/a | `constraints/v003_aws_f2.xdc` | placeholder |
| LLM | `pccxai/pccx-LLM-v003` (temporary planning line) | TBD | TBD | `LLM/...` | planning intake |
| Vision | `pccxai/pccx-vision-v001` (compatibility track) | TBD | TBD | `Vision/...` | planning intake (compatibility review pending) |
| Voice | n/a | n/a | n/a | `Voice/...` | placeholder |
| common | shared with `pccxai/pccx-v002/common/` (reference) | TBD | TBD | `common/...` | planning intake |

The table is a *planning* manifest only. Real intake rows are added
once a piece of source has been reviewed against the v003
compatibility contract and merged.
