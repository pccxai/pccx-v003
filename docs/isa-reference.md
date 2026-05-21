# v003 ISA Reference

Status: skeleton reference. Encoding fields are anchors for review; execution
semantics are future work.

## Common Opcode Package

`common/pkg/isa_common_pkg.sv` defines shared instruction widths and common
opcode names used by reusable blocks.

| Opcode | Purpose |
| --- | --- |
| `ISA_OP_NOP` | Reserved idle instruction anchor. |
| `ISA_OP_GEMV` | Matrix-vector operation anchor. |
| `ISA_OP_GEMM` | Matrix-matrix operation anchor. |
| `ISA_OP_LOAD_TILE` | Tile load operation anchor. |
| `ISA_OP_STORE_TILE` | Tile store operation anchor. |
| `ISA_OP_RMSNORM` | RMSNorm operation anchor. |
| `ISA_OP_LAYERNORM` | LayerNorm operation anchor. |
| `ISA_OP_ATTENTION` | Attention operation anchor. |
| `ISA_OP_KV_CACHE` | KV cache operation anchor. |
| `ISA_OP_FFN` | Feed-forward operation anchor. |
| `ISA_OP_SAMPLE` | Sampling operation anchor. |
| `ISA_OP_TOKEN_OUT` | Token readback operation anchor. |
| `ISA_OP_SPARSE_GEMV` | Sparse matrix-vector operation anchor. |
| `ISA_OP_SPARSE_GEMM` | Sparse matrix-matrix operation anchor. |
| `ISA_OP_EXTENSION` | v003-specific extension anchor. |

## v003 Package

`hw/rtl/v003/isa_pkg_v003.sv` remains the v003-specific ISA package in this
repository. It currently anchors:

| Opcode | Purpose |
| --- | --- |
| `OP_V003_GEMV` | v003 matrix-vector operation anchor. |
| `OP_V003_GEMM` | v003 matrix-matrix operation anchor. |
| `OP_V003_MEMCPY` | v003 memory copy operation anchor. |
| `OP_V003_MEMSET` | v003 memory set operation anchor. |
| `OP_V003_CVO` | v003 control/vector operation anchor. |
| `OP_V003_SPARSE_GEMV` | v003 sparse matrix-vector operation anchor. |
| `OP_V003_SPARSE_GEMM` | v003 sparse matrix-matrix operation anchor. |

## Deferred Work

- Instruction field layout review.
- Dispatcher decode and scheduling behavior.
- Sparse metadata semantics.
- Token readback sequencing rules.
- UVM sequence coverage.
