module rmsnorm_core #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_INPUT,
    tensor_stream_if.consumer S_WEIGHT,
    tensor_stream_if.producer M_OUTPUT
);
  timeunit 1ns;
  timeprecision 1ps;

  // TODO: implement pure RMSNorm core after the design phase.
endmodule
