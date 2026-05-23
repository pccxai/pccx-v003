`timescale 1ns / 1ps

import uvm_pkg::*;
import npu_v003_constants::*;
import npu_test_pkg::*;

module npu_v003_uvm_tb;
  timeunit 1ns;
  timeprecision 1ps;

  initial begin
    run_test("test_gemma4_e4b_smoke");
  end
endmodule
