module argmax_unit #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_LOGITS,
    token_out_if.producer M_TOKEN
);
  timeunit 1ns;
  timeprecision 1ps;

  // TODO: implement deterministic argmax unit after the design phase.
endmodule
