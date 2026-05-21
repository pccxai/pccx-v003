`timescale 1ns / 1ps
`include "npu_v003_interfaces.svh"

import isa_pkg_v003::*;

module npu_v003_dispatcher #(
    parameter int INSTRUCTION_W = V003InstructionW
) (
    input logic clk_core,
    input logic rst_n_core,

    input  logic                    instruction_valid,
    output logic                    instruction_ready,
    input  logic [INSTRUCTION_W-1:0] instruction_word,

    npu_v003_l2_port_if.requestor        M_L2_PORT,
    npu_v003_sparse_meta_if.producer     M_SPARSE_META,
    npu_v003_token_readback_if.producer  M_TOKEN_READBACK
);

  // Interface-only skeleton. Decode, scheduling, sparse metadata routing,
  // and token sequencing are intentionally deferred to the implementation phase.

endmodule
