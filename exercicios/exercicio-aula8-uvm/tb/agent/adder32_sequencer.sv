// fila entre a sequence (que gera adder32_seq_item) e o driver (que consome)
class adder32_sequencer extends uvm_sequencer #(adder32_seq_item);

  `uvm_component_utils(adder32_sequencer)

  function new(string name = "adder32_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

endclass: adder32_sequencer
