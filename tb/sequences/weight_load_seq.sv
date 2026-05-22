class weight_load_seq extends uvm_sequence;
  `uvm_object_utils(weight_load_seq)

  function new(string name = "weight_load_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "weight load smoke sequence issued", UVM_LOW)
  endtask
endclass
