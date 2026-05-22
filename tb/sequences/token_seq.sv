class token_seq extends uvm_sequence;
  `uvm_object_utils(token_seq)

  function new(string name = "token_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "token readback smoke sequence issued", UVM_LOW)
  endtask
endclass
