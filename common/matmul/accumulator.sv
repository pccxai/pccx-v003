module accumulator #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_PARTIAL_INT32,
    tensor_stream_if.producer M_SUM_INT32
);
  timeunit 1ns;
  timeprecision 1ps;

  // TODO: implement pure INT32 accumulator after the design phase.
endmodule
