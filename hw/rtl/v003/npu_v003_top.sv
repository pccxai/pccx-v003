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

  localparam logic [7:0] AxilAddrControl = 8'h00;
  localparam logic [7:0] AxilAddrInstruction = 8'h08;
  localparam logic [7:0] AxilAddrStatus = 8'h10;

  logic                    instruction_valid_q;
  logic [INSTRUCTION_W-1:0] instruction_word_q;
  logic                    instruction_ready;

  logic [63:0] axil_rdata_q;
  logic        axil_rvalid_q;
  logic        axil_bvalid_q;

  npu_v003_l2_port_if dispatcher_l2_if (
      .clk  (clk_core),
      .rst_n(rst_n_core)
  );
  npu_v003_l2_port_if engine_l2_if (
      .clk  (clk_core),
      .rst_n(rst_n_core)
  );
  npu_v003_sparse_meta_if sparse_meta_if (
      .clk  (clk_core),
      .rst_n(rst_n_core)
  );

  wire axil_write_fire = S_AXIL_CTRL.awvalid && S_AXIL_CTRL.awready &&
                         S_AXIL_CTRL.wvalid && S_AXIL_CTRL.wready;
  wire axil_read_fire = S_AXIL_CTRL.arvalid && S_AXIL_CTRL.arready;

  assign S_AXIL_CTRL.awready = !axil_bvalid_q;
  assign S_AXIL_CTRL.wready = !axil_bvalid_q;
  assign S_AXIL_CTRL.bresp = 2'b00;
  assign S_AXIL_CTRL.bvalid = axil_bvalid_q;

  assign S_AXIL_CTRL.arready = !axil_rvalid_q;
  assign S_AXIL_CTRL.rdata = axil_rdata_q;
  assign S_AXIL_CTRL.rresp = 2'b00;
  assign S_AXIL_CTRL.rvalid = axil_rvalid_q;

  assign engine_l2_if.req_valid = 1'b0;
  assign engine_l2_if.req_write = 1'b0;
  assign engine_l2_if.req_addr = '0;
  assign engine_l2_if.req_wdata = '0;
  assign engine_l2_if.req_wstrb = '0;
  assign engine_l2_if.rsp_ready = 1'b1;

  assign sparse_meta_if.ready = 1'b1;

  npu_v003_dispatcher #(
      .INSTRUCTION_W(INSTRUCTION_W)
  ) u_dispatcher (
      .clk_core(clk_core),
      .rst_n_core(rst_n_core),
      .instruction_valid(instruction_valid_q),
      .instruction_ready(instruction_ready),
      .instruction_word(instruction_word_q),
      .M_L2_PORT(dispatcher_l2_if),
      .M_SPARSE_META(sparse_meta_if),
      .M_TOKEN_READBACK(M_TOKEN_READBACK)
  );

  npu_v003_l2_uram u_l2_uram (
      .clk_core(clk_core),
      .rst_n_core(rst_n_core),
      .S_DISPATCHER_PORT(dispatcher_l2_if),
      .S_ENGINE_PORT(engine_l2_if)
  );

  function automatic logic [INSTRUCTION_W-1:0] default_start_instruction();
    default_start_instruction = {OP_V003_GEMV, {V003BodyW{1'b0}}};
  endfunction

  function automatic logic [63:0] read_register(input logic [7:0] addr);
    case (addr)
      AxilAddrControl: read_register = {62'd0, instruction_valid_q, i_start};
      AxilAddrInstruction: read_register = instruction_word_q;
      AxilAddrStatus: read_register = {62'd0, instruction_ready, instruction_valid_q};
      default: read_register = 64'd0;
    endcase
  endfunction

  always_ff @(posedge clk_core or negedge rst_n_core) begin
    if (!rst_n_core) begin
      instruction_valid_q <= 1'b0;
      instruction_word_q <= '0;
      axil_rdata_q <= '0;
      axil_rvalid_q <= 1'b0;
      axil_bvalid_q <= 1'b0;
    end else begin
      if (instruction_valid_q && instruction_ready) begin
        instruction_valid_q <= 1'b0;
      end

      if (i_clear) begin
        instruction_valid_q <= 1'b0;
      end else if (i_start && (!instruction_valid_q || instruction_ready)) begin
        instruction_word_q <= default_start_instruction();
        instruction_valid_q <= 1'b1;
      end

      if (axil_write_fire) begin
        if (S_AXIL_CTRL.awaddr[7:0] == AxilAddrInstruction) begin
          instruction_word_q <= S_AXIL_CTRL.wdata[INSTRUCTION_W-1:0];
          instruction_valid_q <= 1'b1;
        end else if (S_AXIL_CTRL.awaddr[7:0] == AxilAddrControl && S_AXIL_CTRL.wdata[0]) begin
          instruction_word_q <= default_start_instruction();
          instruction_valid_q <= 1'b1;
        end
        axil_bvalid_q <= 1'b1;
      end else if (axil_bvalid_q && S_AXIL_CTRL.bready) begin
        axil_bvalid_q <= 1'b0;
      end

      if (axil_read_fire) begin
        axil_rdata_q <= read_register(S_AXIL_CTRL.araddr[7:0]);
        axil_rvalid_q <= 1'b1;
      end else if (axil_rvalid_q && S_AXIL_CTRL.rready) begin
        axil_rvalid_q <= 1'b0;
      end
    end
  end

endmodule
