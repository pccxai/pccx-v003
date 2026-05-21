interface axil_cmd_if #(
    parameter int ADDR_W = 16,
    parameter int DATA_W = 64
) (
    input logic clk,
    input logic rst_n
);
  timeunit 1ns;
  timeprecision 1ps;

  logic [ADDR_W-1:0]     awaddr;
  logic [2:0]            awprot;
  logic                  awvalid;
  logic                  awready;
  logic [DATA_W-1:0]     wdata;
  logic [(DATA_W/8)-1:0] wstrb;
  logic                  wvalid;
  logic                  wready;
  logic [1:0]            bresp;
  logic                  bvalid;
  logic                  bready;
  logic [ADDR_W-1:0]     araddr;
  logic [2:0]            arprot;
  logic                  arvalid;
  logic                  arready;
  logic [DATA_W-1:0]     rdata;
  logic [1:0]            rresp;
  logic                  rvalid;
  logic                  rready;

  modport master(
      output awaddr, awprot, awvalid,
      input  awready,
      output wdata, wstrb, wvalid,
      input  wready,
      input  bresp, bvalid,
      output bready,
      output araddr, arprot, arvalid,
      input  arready,
      input  rdata, rresp, rvalid,
      output rready
  );

  modport slave(
      input  awaddr, awprot, awvalid,
      output awready,
      input  wdata, wstrb, wvalid,
      output wready,
      output bresp, bvalid,
      input  bready,
      input  araddr, arprot, arvalid,
      output arready,
      output rdata, rresp, rvalid,
      input  rready
  );
endinterface
