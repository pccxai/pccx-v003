package npu_test_pkg;
  timeunit 1ns;
  timeprecision 1ps;

  import uvm_pkg::*;
  import npu_v003_constants::*;
  `include "uvm_macros.svh"

  `include "../env/npu_env.sv"
  `include "../sequences/token_seq.sv"
  `include "../sequences/weight_load_seq.sv"
  `include "../tests/test_basic.sv"
  `include "../tests/test_gemma4_e4b_smoke.sv"
endpackage
