`timescale 1ns / 1ps
`include "npu_v003_interfaces.svh"

module npu_v003_l2_uram #(
    parameter int ADDR_W = 18,
    parameter int DATA_W = 256
) (
    input logic clk_core,
    input logic rst_n_core,

    npu_v003_l2_port_if.target S_DISPATCHER_PORT,
    npu_v003_l2_port_if.target S_ENGINE_PORT
);

  localparam int ByteCount = DATA_W / 8;
  localparam int Depth = 1 << ADDR_W;

  logic [DATA_W-1:0] mem [Depth];

  logic [DATA_W-1:0] dispatcher_rsp_data_q;
  logic              dispatcher_rsp_valid_q;
  logic [DATA_W-1:0] engine_rsp_data_q;
  logic              engine_rsp_valid_q;

  wire dispatcher_accept = S_DISPATCHER_PORT.req_valid && S_DISPATCHER_PORT.req_ready;
  wire engine_accept = S_ENGINE_PORT.req_valid && S_ENGINE_PORT.req_ready;

  assign S_DISPATCHER_PORT.req_ready = !dispatcher_rsp_valid_q || S_DISPATCHER_PORT.rsp_ready;
  assign S_DISPATCHER_PORT.rsp_valid = dispatcher_rsp_valid_q;
  assign S_DISPATCHER_PORT.rsp_rdata = dispatcher_rsp_data_q;

  assign S_ENGINE_PORT.req_ready = !engine_rsp_valid_q || S_ENGINE_PORT.rsp_ready;
  assign S_ENGINE_PORT.rsp_valid = engine_rsp_valid_q;
  assign S_ENGINE_PORT.rsp_rdata = engine_rsp_data_q;

  function automatic logic [DATA_W-1:0] apply_wstrb(
      input logic [DATA_W-1:0]     old_data,
      input logic [DATA_W-1:0]     new_data,
      input logic [(DATA_W/8)-1:0] wstrb
  );
    logic [DATA_W-1:0] result;

    result = old_data;
    for (int byte_index = 0; byte_index < ByteCount; byte_index++) begin
      if (wstrb[byte_index]) begin
        result[(byte_index * 8) +: 8] = new_data[(byte_index * 8) +: 8];
      end
    end

    apply_wstrb = result;
  endfunction

  always_ff @(posedge clk_core or negedge rst_n_core) begin
    if (!rst_n_core) begin
      dispatcher_rsp_data_q <= '0;
      dispatcher_rsp_valid_q <= 1'b0;
      engine_rsp_data_q <= '0;
      engine_rsp_valid_q <= 1'b0;
    end else begin
      if (dispatcher_rsp_valid_q && S_DISPATCHER_PORT.rsp_ready) begin
        dispatcher_rsp_valid_q <= 1'b0;
      end
      if (engine_rsp_valid_q && S_ENGINE_PORT.rsp_ready) begin
        engine_rsp_valid_q <= 1'b0;
      end

      if (dispatcher_accept) begin
        if (S_DISPATCHER_PORT.req_write) begin
          mem[S_DISPATCHER_PORT.req_addr] <= apply_wstrb(
              mem[S_DISPATCHER_PORT.req_addr],
              S_DISPATCHER_PORT.req_wdata,
              S_DISPATCHER_PORT.req_wstrb
          );
          dispatcher_rsp_data_q <= S_DISPATCHER_PORT.req_wdata;
        end else begin
          dispatcher_rsp_data_q <= mem[S_DISPATCHER_PORT.req_addr];
        end
        dispatcher_rsp_valid_q <= 1'b1;
      end

      if (engine_accept) begin
        if (S_ENGINE_PORT.req_write) begin
          mem[S_ENGINE_PORT.req_addr] <= apply_wstrb(
              mem[S_ENGINE_PORT.req_addr],
              S_ENGINE_PORT.req_wdata,
              S_ENGINE_PORT.req_wstrb
          );
          engine_rsp_data_q <= S_ENGINE_PORT.req_wdata;
        end else begin
          engine_rsp_data_q <= mem[S_ENGINE_PORT.req_addr];
        end
        engine_rsp_valid_q <= 1'b1;
      end
    end
  end

endmodule
