// Derived from tests/functional/rtl_vectors.py.
// Checked in so RTL smoke tests can compare against the Python reference.
`ifndef GEMMA4_BF16_FUNCTIONAL_VECTORS_SVH
`define GEMMA4_BF16_FUNCTIONAL_VECTORS_SVH

package gemma4_bf16_functional_vectors_pkg;
  localparam int FuncDataW = 64;
  localparam int FuncKeepW = FuncDataW / 8;

  localparam logic [FuncDataW-1:0] FUNC_RMS_INPUT_DATA = 64'h3f00bf8040003f80;
  localparam logic [FuncKeepW-1:0] FUNC_RMS_INPUT_KEEP = 8'hff;
  localparam logic [31:0] FUNC_RMS_INPUT_USER = 32'h00001001;
  localparam logic FUNC_RMS_INPUT_LAST = 1'b1;

  localparam logic [FuncDataW-1:0] FUNC_RMS_WEIGHT_DATA = 64'h4000bf803f003f80;
  localparam logic [FuncKeepW-1:0] FUNC_RMS_WEIGHT_KEEP = 8'hff;
  localparam logic [31:0] FUNC_RMS_WEIGHT_USER = 32'h00001002;
  localparam logic FUNC_RMS_WEIGHT_LAST = 1'b1;

  localparam logic [FuncDataW-1:0] FUNC_RMS_EXPECTED_DATA = 64'h3f803f803f803f80;
  localparam logic [FuncKeepW-1:0] FUNC_RMS_EXPECTED_KEEP = 8'hff;
  localparam logic [31:0] FUNC_RMS_EXPECTED_USER = 32'h00001001;
  localparam logic FUNC_RMS_EXPECTED_LAST = 1'b1;

  localparam logic [FuncDataW-1:0] FUNC_ATTN_QUERY_DATA = 64'h3f00bf8040003f80;
  localparam logic [FuncKeepW-1:0] FUNC_ATTN_QUERY_KEEP = 8'hff;
  localparam logic [31:0] FUNC_ATTN_QUERY_USER = 32'h00002001;
  localparam logic FUNC_ATTN_QUERY_LAST = 1'b1;

  localparam logic [FuncDataW-1:0] FUNC_ATTN_KEY_DATA = 64'h4000bf803f003f80;
  localparam logic [FuncKeepW-1:0] FUNC_ATTN_KEY_KEEP = 8'hff;
  localparam logic [31:0] FUNC_ATTN_KEY_USER = 32'h00002002;
  localparam logic FUNC_ATTN_KEY_LAST = 1'b1;

  localparam logic [FuncDataW-1:0] FUNC_ATTN_VALUE_DATA = 64'h3f803f00bf804000;
  localparam logic [FuncKeepW-1:0] FUNC_ATTN_VALUE_KEEP = 8'hff;
  localparam logic [31:0] FUNC_ATTN_VALUE_USER = 32'h00002003;
  localparam logic FUNC_ATTN_VALUE_LAST = 1'b1;

  localparam logic [FuncDataW-1:0] FUNC_ATTN_EXPECTED_DATA = 64'h3f803f00bf804000;
  localparam logic [FuncKeepW-1:0] FUNC_ATTN_EXPECTED_KEEP = 8'hff;
  localparam logic [31:0] FUNC_ATTN_EXPECTED_USER = 32'h00002001;
  localparam logic FUNC_ATTN_EXPECTED_LAST = 1'b1;

  localparam logic [FuncDataW-1:0] FUNC_MLP_ACTIVATION_DATA = 64'hbf003f00c0004000;
  localparam logic [FuncKeepW-1:0] FUNC_MLP_ACTIVATION_KEEP = 8'hff;
  localparam logic [31:0] FUNC_MLP_ACTIVATION_USER = 32'h00003001;
  localparam logic FUNC_MLP_ACTIVATION_LAST = 1'b1;

  localparam logic [FuncDataW-1:0] FUNC_MLP_WEIGHT_DATA = 64'h400040003f003f00;
  localparam logic [FuncKeepW-1:0] FUNC_MLP_WEIGHT_KEEP = 8'hff;
  localparam logic [31:0] FUNC_MLP_WEIGHT_USER = 32'h00003002;
  localparam logic FUNC_MLP_WEIGHT_LAST = 1'b1;

  localparam logic [FuncDataW-1:0] FUNC_MLP_EXPECTED_DATA = 64'h00003f8000003f80;
  localparam logic [FuncKeepW-1:0] FUNC_MLP_EXPECTED_KEEP = 8'hff;
  localparam logic [31:0] FUNC_MLP_EXPECTED_USER = 32'h00003001;
  localparam logic FUNC_MLP_EXPECTED_LAST = 1'b1;

endpackage

`endif
