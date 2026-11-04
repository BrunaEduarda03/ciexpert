import adder32_datatypes_pkg::*;

task adder32_drv(
  virtual adder32_if vif,
  adder32_seq_item_t seq_item,
  en_mode_t           en_mode,
  bit                 en_log
);
  // controlado pelo modo selecionado (Atividade 10)
  logic en_value;

  // align with driver clocking block
  @(posedge vif.clk);

  case (en_mode)
    EN_RANDOM:  en_value = 1'($urandom_range(1, 0));
    EN_BURST:   en_value = 1'b1;
    EN_DISABLE: en_value = 1'b0;
    default:    en_value = 1'b1;
  endcase

  vif.cb_drv.en   <= en_value;
  vif.cb_drv.op_a <= seq_item.a;
  vif.cb_drv.op_b <= seq_item.b;

  if(en_log)
    $display("[driver-log] en_mode=%s en=%0b op_a=32'h%08h op_b=32'h%08h",
              en_mode.name(), en_value, seq_item.a, seq_item.b);

endtask: adder32_drv
