class test_basic extends uvm_test;
  `uvm_component_utils(test_basic)

  npu_env env;

  function new(string name = "test_basic", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = npu_env::type_id::create("env", this);
  endfunction
endclass
