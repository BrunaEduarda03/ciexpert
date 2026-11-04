// transacao: equivalente UVM do struct adder32_seq_item_t (adder2p0/tb/adder32_datatypes.sv)
class adder32_seq_item extends uvm_sequence_item;

  // estimulo (preenchido pela sequence / driver)
  rand bit [31:0] a;
  rand bit [31:0] b;

  // resposta do DUT (preenchido pelo monitor, antes de ir pro scoreboard)
  bit [31:0] adder_out;
  bit        carry_out;

  `uvm_object_utils_begin(adder32_seq_item)
    `uvm_field_int(a,         UVM_ALL_ON)
    `uvm_field_int(b,         UVM_ALL_ON)
    `uvm_field_int(adder_out, UVM_ALL_ON)
    `uvm_field_int(carry_out, UVM_ALL_ON)
  `uvm_object_utils_end

  // UVM_OBJECT_MUST_HAVE_CONSTRUCTOR exige esse construtor explicito
  function new(string name = "adder32_seq_item");
    super.new(name);
  endfunction: new

endclass: adder32_seq_item
