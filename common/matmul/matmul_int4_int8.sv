module matmul_int4_int8 #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    input npu_common_pkg::npu_sparse_meta_t sparse_meta,
    tensor_stream_if.consumer S_ACTIVATION_INT8,
    tensor_stream_if.consumer S_WEIGHT_INT4,
    tensor_stream_if.producer M_ACCUM_INT32
);
  timeunit 1ns;
  timeprecision 1ps;

  // TODO: implement pure INT4 weight by INT8 activation matmul after the design phase.
endmodule
