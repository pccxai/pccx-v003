class test_gemma4_e4b_smoke extends test_basic;
  `uvm_component_utils(test_gemma4_e4b_smoke)

  function new(string name = "test_gemma4_e4b_smoke", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    // TODO: add Gemma 4 E4B smoke sequence after official parameters are set.
    phase.drop_objection(this);
  endtask
endclass
