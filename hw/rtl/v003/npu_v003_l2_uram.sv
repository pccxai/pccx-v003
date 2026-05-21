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

  localparam int CapacityBytes = (1 << ADDR_W) * (DATA_W / 8);

  // Interface-only skeleton. Storage primitive selection, banking,
  // arbitration, ECC, and initialization policy are intentionally deferred.

endmodule
