package npu_v003_constants;
  timeunit 1ns;
  timeprecision 1ps;

  typedef enum logic [2:0] {
    GEMMA4_E2B,
    GEMMA4_E4B,
    GEMMA4_26B_A4B,
    GEMMA4_31B,
    GEMMA4_VARIANT_TBD
  } gemma4_variant_t;

  localparam int Gemma4ParamTbd = 0;

  localparam int Gemma4E2BHiddenSize = Gemma4ParamTbd;
  localparam int Gemma4E2BNLayers    = 35;
  localparam int Gemma4E2BNHeads     = Gemma4ParamTbd;
  localparam int Gemma4E2BKvHeads    = Gemma4ParamTbd;
  localparam int Gemma4E2BVocabSize  = Gemma4ParamTbd;
  localparam int Gemma4E2BHeadDim    = Gemma4ParamTbd;

  localparam int Gemma4E4BHiddenSize = Gemma4ParamTbd;
  localparam int Gemma4E4BNLayers    = 42;
  localparam int Gemma4E4BNHeads     = Gemma4ParamTbd;
  localparam int Gemma4E4BKvHeads    = Gemma4ParamTbd;
  localparam int Gemma4E4BVocabSize  = Gemma4ParamTbd;
  localparam int Gemma4E4BHeadDim    = Gemma4ParamTbd;

  localparam int Gemma4TwentySixBAFourBHiddenSize = Gemma4ParamTbd;
  localparam int Gemma4TwentySixBAFourBNLayers    = 30;
  localparam int Gemma4TwentySixBAFourBNHeads     = Gemma4ParamTbd;
  localparam int Gemma4TwentySixBAFourBKvHeads    = Gemma4ParamTbd;
  localparam int Gemma4TwentySixBAFourBVocabSize  = Gemma4ParamTbd;
  localparam int Gemma4TwentySixBAFourBHeadDim    = Gemma4ParamTbd;

  localparam int Gemma4ThirtyOneBHiddenSize = Gemma4ParamTbd;
  localparam int Gemma4ThirtyOneBNLayers    = 60;
  localparam int Gemma4ThirtyOneBNHeads     = Gemma4ParamTbd;
  localparam int Gemma4ThirtyOneBKvHeads    = Gemma4ParamTbd;
  localparam int Gemma4ThirtyOneBVocabSize  = Gemma4ParamTbd;
  localparam int Gemma4ThirtyOneBHeadDim    = Gemma4ParamTbd;
endpackage
