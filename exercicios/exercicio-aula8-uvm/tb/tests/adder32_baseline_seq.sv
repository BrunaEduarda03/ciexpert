// equivalente UVM do loop "repeat(NUM_OF_SEQUENCES) adder32_seqr(...)" (tb_adder32.sv)
class adder32_baseline_seq extends uvm_sequence #(adder32_seq_item);

  `uvm_object_utils(adder32_baseline_seq)

  int unsigned num_items = 2; // mesmo NUM_OF_SEQUENCES do tb_adder32.sv

  function new(string name = "adder32_baseline_seq");
    super.new(name);
  endfunction: new

  task body();
    adder32_seq_item item;

    repeat (num_items) begin
      item = adder32_seq_item::type_id::create("item");

      start_item(item);
      if (!item.randomize())
        `uvm_fatal("SEQ", "randomize() falhou em adder32_baseline_seq")
      finish_item(item);
    end
  endtask: body

endclass: adder32_baseline_seq
