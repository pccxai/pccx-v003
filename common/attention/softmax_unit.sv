module softmax_unit #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_LOGITS,
    tensor_stream_if.producer M_PROB
);
  timeunit 1ns;
  timeprecision 1ps;

  // TODO: implement pure softmax unit after the design phase.
endmodule
