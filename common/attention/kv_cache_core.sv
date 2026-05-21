module kv_cache_core #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_KV_WRITE,
    tensor_stream_if.consumer S_KV_LOOKUP,
    tensor_stream_if.producer M_KV_READ
);
  timeunit 1ns;
  timeprecision 1ps;

  // TODO: implement pure KV cache core after the design phase.
endmodule
