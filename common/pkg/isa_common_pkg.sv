package isa_common_pkg;
  timeunit 1ns;
  timeprecision 1ps;

  localparam int IsaMajorW = 8;
  localparam int IsaMinorW = 8;
  localparam int IsaInstructionW = 64;
  localparam int IsaOpcodeW = 6;
  localparam int IsaBodyW = IsaInstructionW - IsaOpcodeW;

  typedef logic [IsaInstructionW-1:0] isa_instruction_word_t;
  typedef logic [IsaBodyW-1:0]        isa_instruction_body_t;

  typedef enum logic [IsaOpcodeW-1:0] {
    ISA_OP_NOP         = 6'h00,
    ISA_OP_GEMV        = 6'h01,
    ISA_OP_GEMM        = 6'h02,
    ISA_OP_LOAD_TILE   = 6'h03,
    ISA_OP_STORE_TILE  = 6'h04,
    ISA_OP_RMSNORM     = 6'h05,
    ISA_OP_LAYERNORM   = 6'h06,
    ISA_OP_ATTENTION   = 6'h07,
    ISA_OP_KV_CACHE    = 6'h08,
    ISA_OP_FFN         = 6'h09,
    ISA_OP_SAMPLE      = 6'h0a,
    ISA_OP_TOKEN_OUT   = 6'h0b,
    ISA_OP_SPARSE_GEMV = 6'h0c,
    ISA_OP_SPARSE_GEMM = 6'h0d,
    ISA_OP_EXTENSION   = 6'h3f
  } isa_common_opcode_e;

  typedef struct packed {
    isa_common_opcode_e opcode;
    isa_instruction_body_t body;
  } isa_common_instruction_t;
endpackage
