import adder32_datatypes_pkg::*;

task adder32_drv(
  virtual adder32_if vif,
  adder32_seq_item_t seq_item,
  bit en_log
);
  // align with driver clocking block
  @(posedge vif.clk);

  vif.cb_drv.en   <= 1'b1;
  vif.cb_drv.op_a <= seq_item.a;
  vif.cb_drv.op_b <= seq_item.b;

  if(en_log)
    $display("[driver-log] ...");

endtask: adder32_drv