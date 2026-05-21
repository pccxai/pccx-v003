package npu_common_pkg;
  timeunit 1ns;
  timeprecision 1ps;

  localparam int TensorDataW = 256;
  localparam int TensorUserW = 32;
  localparam int TokenW = 32;
  localparam int SequenceW = 32;
  localparam int SparseMaskW = 16;

  typedef enum logic [1:0] {
    NPU_SPARSE_DENSE      = 2'h0,
    NPU_SPARSE_STRUCTURED = 2'h1,
    NPU_SPARSE_RESERVED_2 = 2'h2,
    NPU_SPARSE_RESERVED_3 = 2'h3
  } npu_sparse_mode_e;

  typedef struct packed {
    npu_sparse_mode_e mode;
    logic [SparseMaskW-1:0] mask;
    logic [7:0] group_size;
  } npu_sparse_meta_t;
endpackage
