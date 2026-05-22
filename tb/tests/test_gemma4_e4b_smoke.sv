class test_gemma4_e4b_smoke extends test_basic;
  `uvm_component_utils(test_gemma4_e4b_smoke)

  function new(string name = "test_gemma4_e4b_smoke", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    if (Gemma4E4BHiddenSize != 2560 ||
        Gemma4E4BIntermediateSize != 10240 ||
        Gemma4E4BNLayers != 42 ||
        Gemma4E4BNHeads != 8 ||
        Gemma4E4BKvHeads != 2 ||
        Gemma4E4BHeadDim != 256 ||
        Gemma4E4BVocabSize != 262144 ||
        Gemma4E4BMaxPositionEmbeddings != 131072) begin
      `uvm_fatal(get_type_name(), "Gemma 4 E4B local text config constants mismatch")
    end
    `uvm_info(get_type_name(), "Gemma 4 E4B local text config smoke passed", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass
