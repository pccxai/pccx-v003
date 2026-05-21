module matmul_int8_int8 #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_ACTIVATION_INT8,
    tensor_stream_if.consumer S_WEIGHT_INT8,
    tensor_stream_if.producer M_ACCUM_INT32
);
  timeunit 1ns;
  timeprecision 1ps;

  // TODO: implement pure INT8 by INT8 matmul after the design phase.
endmodule
