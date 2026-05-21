`ifndef PCCX_NPU_V003_INTERFACES_SVH
`define PCCX_NPU_V003_INTERFACES_SVH

interface npu_v003_axis_if #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n
);
  logic [DATA_W-1:0]     tdata;
  logic [(DATA_W/8)-1:0] tkeep;
  logic                  tvalid;
  logic                  tready;
  logic                  tlast;

  modport sink(
      input  tdata,
      input  tkeep,
      input  tvalid,
      input  tlast,
      output tready
  );

  modport source(
      output tdata,
      output tkeep,
      output tvalid,
      output tlast,
      input  tready
  );
endinterface

interface npu_v003_axil_if #(
    parameter int ADDR_W = 16,
    parameter int DATA_W = 64
) (
    input logic clk,
    input logic rst_n
);
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

  modport slave(
      input  awaddr,
      input  awprot,
      input  awvalid,
      output awready,
      input  wdata,
      input  wstrb,
      input  wvalid,
      output wready,
      output bresp,
      output bvalid,
      input  bready,
      input  araddr,
      input  arprot,
      input  arvalid,
      output arready,
      output rdata,
      output rresp,
      output rvalid,
      input  rready
  );

  modport master(
      output awaddr,
      output awprot,
      output awvalid,
      input  awready,
      output wdata,
      output wstrb,
      output wvalid,
      input  wready,
      input  bresp,
      input  bvalid,
      output bready,
      output araddr,
      output arprot,
      output arvalid,
      input  arready,
      input  rdata,
      input  rresp,
      input  rvalid,
      output rready
  );
endinterface

interface npu_v003_l2_port_if #(
    parameter int ADDR_W = 18,
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n
);
  logic                  req_valid;
  logic                  req_ready;
  logic                  req_write;
  logic [ADDR_W-1:0]     req_addr;
  logic [DATA_W-1:0]     req_wdata;
  logic [(DATA_W/8)-1:0] req_wstrb;
  logic                  rsp_valid;
  logic                  rsp_ready;
  logic [DATA_W-1:0]     rsp_rdata;

  modport requestor(
      output req_valid,
      input  req_ready,
      output req_write,
      output req_addr,
      output req_wdata,
      output req_wstrb,
      input  rsp_valid,
      output rsp_ready,
      input  rsp_rdata
  );

  modport target(
      input  req_valid,
      output req_ready,
      input  req_write,
      input  req_addr,
      input  req_wdata,
      input  req_wstrb,
      output rsp_valid,
      input  rsp_ready,
      output rsp_rdata
  );
endinterface

interface npu_v003_token_readback_if #(
    parameter int TOKEN_W = 32
) (
    input logic clk,
    input logic rst_n
);
  logic [TOKEN_W-1:0] token;
  logic [31:0]        sequence_id;
  logic               valid;
  logic               ready;
  logic               last;

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

interface npu_v003_sparse_meta_if #(
    parameter int MASK_W = 16
) (
    input logic clk,
    input logic rst_n
);
  logic [1:0]        mode;
  logic [MASK_W-1:0] mask;
  logic              valid;
  logic              ready;

  modport producer(
      output mode,
      output mask,
      output valid,
      input  ready
  );

  modport consumer(
      input  mode,
      input  mask,
      input  valid,
      output ready
  );
endinterface

`endif  // PCCX_NPU_V003_INTERFACES_SVH
