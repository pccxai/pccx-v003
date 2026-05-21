interface tensor_stream_if #(
    parameter int DATA_W = 256,
    parameter int USER_W = 32
) (
    input logic clk,
    input logic rst_n
);
  timeunit 1ns;
  timeprecision 1ps;

  logic [DATA_W-1:0]     data;
  logic [(DATA_W/8)-1:0] keep;
  logic [USER_W-1:0]     user;
  logic                  valid;
  logic                  ready;
  logic                  last;

  modport producer(
      output data,
      output keep,
      output user,
      output valid,
      input  ready,
      output last
  );

  modport consumer(
      input  data,
      input  keep,
      input  user,
      input  valid,
      output ready,
      input  last
  );
endinterface
