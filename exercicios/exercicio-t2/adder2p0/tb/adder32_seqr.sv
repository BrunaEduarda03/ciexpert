function automatic adder32_datatypes_pkg::adder32_seq_item_t adder32_seqr(bit en_log);
  // data
  logic [31:0] a;
  logic [31:0] b;

  adder32_datatypes_pkg::adder32_seq_item_t item;

  if (!randomize(a, b)) begin
    $fatal(1, "Randomization failed in adder32_seqr()");
  end

  if(en_log) begin
    $display("# ---------------------------");
    $display("# sequence generated");
    $display("# ---------------------------");
  end
  item.a = a;
  item.b = b;

  //
  // TODO: criar  uma coleção de estimulos (a e b: random, pequeno, grande, min/max, etc e controlar isso)
  //

  return item;

endfunction: adder32_seqr