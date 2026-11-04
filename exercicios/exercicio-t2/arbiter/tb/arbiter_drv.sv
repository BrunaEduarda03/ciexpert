import arbiter_datatypes_pkg::*;

/**
 * Arbiter Driver
 *
 * @ref: espelha adder2p0/tb/adder32_drv.sv. Dirige o estimulo de 1 ciclo
 *       (priority_sel/client1_req/client2_req) via clockvar, respeitando o
 *       output skew do clocking block (evita race com o
 *       always@(posedge clk or negedge reset_n) do DUT).
 */
task arbiter_drv(
  virtual arbiter_if vif,
  arbiter_seq_item_t seq_item,
  bit                en_log
);
  // align with driver clocking block
  @(posedge vif.clk);

  vif.cb_drv.priority_sel <= seq_item.priority_sel;
  vif.cb_drv.client1_req  <= seq_item.client1_req;
  vif.cb_drv.client2_req  <= seq_item.client2_req;

  if (en_log)
    $display("[driver-log] priority_sel=%0b client1_req=%0b client2_req=%0b",
              seq_item.priority_sel, seq_item.client1_req, seq_item.client2_req);

endtask: arbiter_drv
