class npu_env extends uvm_env;
  `uvm_component_utils(npu_env)

  function new(string name = "npu_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // TODO: add reusable NPU verification components after the design phase.
  endfunction
endclass
