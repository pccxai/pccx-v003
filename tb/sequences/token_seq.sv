class token_seq extends uvm_sequence;
  `uvm_object_utils(token_seq)

  function new(string name = "token_seq");
    super.new(name);
  endfunction

  virtual task body();
    // TODO: add token readback stimulus after the design phase.
  endtask
endclass
