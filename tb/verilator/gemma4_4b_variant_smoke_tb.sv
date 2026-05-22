module gemma4_4b_variant_smoke_tb;
  timeunit 1ns;
  timeprecision 1ps;

  import npu_v003_constants::*;

  gemma4_variant_t variant;

  initial begin
    variant = GEMMA4_E4B;

    if (variant != GEMMA4_E4B) begin
      $fatal(1, "Gemma 4 local 4B smoke did not select GEMMA4_E4B");
    end

    if (Gemma4E4BNLayers != 42) begin
      $fatal(1, "Gemma4E4BNLayers expected 42 got %0d", Gemma4E4BNLayers);
    end

    if (Gemma4E4BHiddenSize != Gemma4ParamTbd) begin
      $fatal(1, "Gemma4E4BHiddenSize must remain TBD without local source data");
    end

    if (Gemma4E4BNHeads != Gemma4ParamTbd ||
        Gemma4E4BKvHeads != Gemma4ParamTbd ||
        Gemma4E4BHeadDim != Gemma4ParamTbd ||
        Gemma4E4BVocabSize != Gemma4ParamTbd) begin
      $fatal(1, "Gemma4 E4B detailed dimensions must remain TBD without local source data");
    end

    $display(
        "Gemma 4 4B local variant smoke PASS: GEMMA4_E4B row only, missing dimensions TBD"
    );
    $finish;
  end
endmodule
