`timescale 1ns / 1ps

package isa_pkg_v003;

  localparam int V003IsaMajor = 3;
  localparam int V003IsaMinor = 0;
  localparam int V003InstructionW = 64;
  localparam int V003OpcodeW = 4;
  localparam int V003BodyW = V003InstructionW - V003OpcodeW;

  typedef logic [V003InstructionW-1:0] instruction_word_t;
  typedef logic [V003BodyW-1:0]        instruction_body_t;

  typedef enum logic [V003OpcodeW-1:0] {
    OP_V003_GEMV        = 4'h0,
    OP_V003_GEMM        = 4'h1,
    OP_V003_MEMCPY      = 4'h2,
    OP_V003_MEMSET      = 4'h3,
    OP_V003_CVO         = 4'h4,
    OP_V003_SPARSE_GEMV = 4'h5,
    OP_V003_SPARSE_GEMM = 4'h6
  } opcode_v003_e;

  typedef enum logic [1:0] {
    SPARSE_MODE_DENSE      = 2'h0,
    SPARSE_MODE_STRUCTURED = 2'h1,
    SPARSE_MODE_RESERVED_2 = 2'h2,
    SPARSE_MODE_RESERVED_3 = 2'h3
  } sparse_mode_v003_e;

  typedef struct packed {
    sparse_mode_v003_e mode;
    logic [15:0]       mask;
    logic [7:0]        group_size;
    logic [5:0]        reserved;
  } sparse_meta_v003_t;

  typedef struct packed {
    opcode_v003_e      opcode;
    instruction_body_t body;
  } instruction_v003_t;

  typedef struct packed {
    opcode_v003_e       opcode;
    sparse_meta_v003_t  sparse;
    logic               token_readback_enable;
    logic [31:0]        sequence_id;
  } dispatch_uop_v003_t;

endpackage
