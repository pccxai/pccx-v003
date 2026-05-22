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

    if (Gemma4E4BHiddenSize != 2560) begin
      $fatal(1, "Gemma4E4BHiddenSize expected 2560 got %0d", Gemma4E4BHiddenSize);
    end

    if (Gemma4E4BIntermediateSize != 10240 ||
        Gemma4E4BNHeads != 8 ||
        Gemma4E4BKvHeads != 2 ||
        Gemma4E4BHeadDim != 256 ||
        Gemma4E4BVocabSize != 262144 ||
        Gemma4E4BMaxPositionEmbeddings != 131072) begin
      $fatal(1, "Gemma4 E4B local text dimensions mismatch");
    end

    $display(
        "Gemma 4 E4B local text config smoke PASS"
    );
    $finish;
  end
endmodule
