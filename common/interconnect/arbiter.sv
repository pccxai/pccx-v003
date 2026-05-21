module arbiter #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_REQ0,
    tensor_stream_if.consumer S_REQ1,
    tensor_stream_if.producer M_GRANT
);
  timeunit 1ns;
  timeprecision 1ps;

  // TODO: implement tensor stream arbitration after the design phase.
endmodule
