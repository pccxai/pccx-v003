class weight_load_seq extends uvm_sequence;
  `uvm_object_utils(weight_load_seq)

  function new(string name = "weight_load_seq");
    super.new(name);
  endfunction

  virtual task body();
    // TODO: add weight load stimulus after the design phase.
  endtask
endclass
