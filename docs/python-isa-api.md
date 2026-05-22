# Python ISA API boundary

The `pccx` Python package should treat this repository's
`hw/rtl/v003/isa_pkg_v003.sv` file as the source of truth for v003 opcode names
and numeric values.

## Source-backed opcode surface

| Python API | SV opcode | Value |
| --- | --- | ---: |
| `pccx.isa.GEMV(target="v003")` | `OP_V003_GEMV` | `0x0` |
| `pccx.isa.GEMM(target="v003")` | `OP_V003_GEMM` | `0x1` |
| `pccx.isa.MEMCPY(target="v003")` | `OP_V003_MEMCPY` | `0x2` |
| `pccx.isa.MEMSET(target="v003")` | `OP_V003_MEMSET` | `0x3` |
| `pccx.isa.CVO(target="v003")` | `OP_V003_CVO` | `0x4` |
| `pccx.isa.SPARSE_GEMV(target="v003")` | `OP_V003_SPARSE_GEMV` | `0x5` |
| `pccx.isa.SPARSE_GEMM(target="v003")` | `OP_V003_SPARSE_GEMM` | `0x6` |

The current v003 package does not define `LOAD_WEIGHT`, `LOAD_PROMPT`,
`NEXT_TOKEN`, or `RESET_KV_CACHE`. The Python package must not invent those
v003 opcodes; calls to those helpers with `target="v003"` should fail with an
unsupported-opcode error until the SystemVerilog package adds source-backed
definitions.

## Target selection

```python
import pccx
from pccx import isa

pccx.target("v003")
cmd = isa.GEMV(body=0)
```

`pccx.target("v003")` selects the Gemma 4 family target boundary. It does not
assert hardware availability, a generated bitstream, or a stable runtime ABI.

## Sync check

From the `pccx-python` checkout:

```bash
PCCX_V003_ROOT=/path/to/pccx-v003 \
PCCX_V004_ROOT=/path/to/pccx-v004-library \
python -m unittest tests.test_sv_opcode_sync
```

That test compares the Python opcode table against this repository's
`isa_pkg_v003.sv` package.

