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

  opcode_v003_e opcode_d;
  instruction_body_t body_d;

  logic                  token_valid_q;
  logic [31:0]           token_q;
  logic [31:0]           sequence_id_q;
  logic                  token_last_q;

  logic                  sparse_valid_q;
  sparse_mode_v003_e     sparse_mode_q;
  logic [15:0]           sparse_mask_q;

  wire output_ready = !token_valid_q || M_TOKEN_READBACK.ready;
  wire instruction_fire = instruction_valid && instruction_ready;

  assign opcode_d = opcode_v003_e'(instruction_word[INSTRUCTION_W-1 -: V003OpcodeW]);
  assign body_d = instruction_word[V003BodyW-1:0];

  assign instruction_ready = output_ready;

  assign M_L2_PORT.req_valid = 1'b0;
  assign M_L2_PORT.req_write = 1'b0;
  assign M_L2_PORT.req_addr = '0;
  assign M_L2_PORT.req_wdata = '0;
  assign M_L2_PORT.req_wstrb = '0;
  assign M_L2_PORT.rsp_ready = 1'b1;

  assign M_SPARSE_META.mode = sparse_mode_q;
  assign M_SPARSE_META.mask = sparse_mask_q;
  assign M_SPARSE_META.valid = sparse_valid_q;

  assign M_TOKEN_READBACK.token = token_q;
  assign M_TOKEN_READBACK.sequence_id = sequence_id_q;
  assign M_TOKEN_READBACK.valid = token_valid_q;
  assign M_TOKEN_READBACK.last = token_last_q;

  function automatic logic opcode_uses_sparse(input opcode_v003_e opcode);
    opcode_uses_sparse = (opcode == OP_V003_SPARSE_GEMV) || (opcode == OP_V003_SPARSE_GEMM);
  endfunction

  always_ff @(posedge clk_core or negedge rst_n_core) begin
    if (!rst_n_core) begin
      token_valid_q <= 1'b0;
      token_q <= '0;
      sequence_id_q <= '0;
      token_last_q <= 1'b0;
      sparse_valid_q <= 1'b0;
      sparse_mode_q <= SPARSE_MODE_DENSE;
      sparse_mask_q <= '1;
    end else begin
      if (token_valid_q && M_TOKEN_READBACK.ready) begin
        token_valid_q <= 1'b0;
      end

      if (sparse_valid_q && M_SPARSE_META.ready) begin
        sparse_valid_q <= 1'b0;
      end

      if (instruction_fire) begin
        token_q <= {28'd0, opcode_d};
        sequence_id_q <= body_d[31:0];
        token_last_q <= 1'b1;
        token_valid_q <= 1'b1;

        sparse_mode_q <= opcode_uses_sparse(opcode_d) ? SPARSE_MODE_STRUCTURED : SPARSE_MODE_DENSE;
        sparse_mask_q <= body_d[15:0];
        sparse_valid_q <= opcode_uses_sparse(opcode_d);
      end
    end
  end

endmodule
