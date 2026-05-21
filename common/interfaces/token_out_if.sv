interface token_out_if #(
    parameter int TOKEN_W = 32,
    parameter int SEQUENCE_W = 32
) (
    input logic clk,
    input logic rst_n
);
  timeunit 1ns;
  timeprecision 1ps;

  logic [TOKEN_W-1:0]   token;
  logic [SEQUENCE_W-1:0] sequence_id;
  logic                 valid;
  logic                 ready;
  logic                 last;

  modport producer(
      output token,
      output sequence_id,
      output valid,
      input  ready,
      output last
  );

  modport consumer(
      input  token,
      input  sequence_id,
      input  valid,
      output ready,
      input  last
  );
endinterface
