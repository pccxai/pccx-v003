`timescale 1ns / 1ps
`include "npu_v003_interfaces.svh"

import isa_pkg_v003::*;
import npu_v003_constants::*;

module gemma4_e4b_one_layer_tb;
  timeunit 1ns;
  timeprecision 1ps;

  logic clk;
  logic rst_n;
  logic start;
  logic clear;

  npu_v003_axil_if axil_if (
      .clk  (clk),
      .rst_n(rst_n)
  );
  npu_v003_token_readback_if token_if (
      .clk  (clk),
      .rst_n(rst_n)
  );

  npu_v003_top u_top (
      .clk_core(clk),
      .rst_n_core(rst_n),
      .clk_ctrl(clk),
      .rst_n_ctrl(rst_n),
      .i_start(start),
      .i_clear(clear),
      .S_AXIL_CTRL(axil_if),
      .M_TOKEN_READBACK(token_if)
  );

  always #5 clk = !clk;

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    start = 1'b0;
    clear = 1'b0;
    token_if.ready = 1'b1;

    axil_if.awaddr = '0;
    axil_if.awprot = '0;
    axil_if.awvalid = 1'b0;
    axil_if.wdata = '0;
    axil_if.wstrb = '0;
    axil_if.wvalid = 1'b0;
    axil_if.bready = 1'b1;
    axil_if.araddr = '0;
    axil_if.arprot = '0;
    axil_if.arvalid = 1'b0;
    axil_if.rready = 1'b1;

    if (Gemma4E4BHiddenSize != 2560 ||
        Gemma4E4BNLayers != 42 ||
        Gemma4E4BNHeads != 8 ||
        Gemma4E4BKvHeads != 2 ||
        Gemma4E4BHeadDim != 256 ||
        Gemma4E4BVocabSize != 262144) begin
      $fatal(1, "Gemma 4 E4B local text config constants are not loaded");
    end

    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    start = 1'b1;
    @(posedge clk);
    start = 1'b0;

    repeat (8) begin
      @(posedge clk);
      if (token_if.valid) begin
        if (token_if.token != {28'd0, OP_V003_GEMV}) begin
          $fatal(1, "unexpected token opcode 0x%08x", token_if.token);
        end
        if (!token_if.last) begin
          $fatal(1, "one-layer smoke token must be marked last");
        end
        $display("Gemma 4 E4B one-layer v003 top smoke PASS");
        $finish;
      end
    end

    $fatal(1, "v003 top did not emit one-layer smoke token");
  end
endmodule
