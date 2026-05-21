module crossbar #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_PORT0,
    tensor_stream_if.consumer S_PORT1,
    tensor_stream_if.producer M_PORT0,
    tensor_stream_if.producer M_PORT1
);
  timeunit 1ns;
  timeprecision 1ps;

  // TODO: implement tensor stream crossbar after the design phase.
endmodule
