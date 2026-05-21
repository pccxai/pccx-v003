`timescale 1ns / 1ps
`include "npu_v003_interfaces.svh"

import isa_pkg_v003::*;

module npu_v003_top #(
    parameter int INSTRUCTION_W = V003InstructionW
) (
    input logic clk_core,
    input logic rst_n_core,
    input logic clk_ctrl,
    input logic rst_n_ctrl,
    input logic i_start,
    input logic i_clear,

    npu_v003_axil_if.slave              S_AXIL_CTRL,
    npu_v003_token_readback_if.producer M_TOKEN_READBACK
);

  // Interface-only skeleton. The v003 NPU remains self-contained at the
  // accelerator boundary; the host-facing data path is token readback only.

endmodule
