module ffn_core #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_ACTIVATION,
    tensor_stream_if.consumer S_WEIGHT,
    tensor_stream_if.producer M_ACTIVATION
);
  timeunit 1ns;
  timeprecision 1ps;

  // TODO: implement pure feed-forward core after the design phase.
endmodule
