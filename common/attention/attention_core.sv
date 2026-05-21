module attention_core #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_QUERY,
    tensor_stream_if.consumer S_KEY,
    tensor_stream_if.consumer S_VALUE,
    tensor_stream_if.producer M_CONTEXT
);
  timeunit 1ns;
  timeprecision 1ps;

  // TODO: implement pure multi-head attention core after the design phase.
endmodule
