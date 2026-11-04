import matrix_datatypes_pkg::*;

/**
 * Matrix2x2 Driver
 *
 * @ref: espelha adder2p0/tb/adder32_drv.sv (Atividade 10), com o mesmo
 *       controle de en_mode (EN_RANDOM / EN_BURST / EN_DISABLE).
 */
task matrix_drv(
  virtual matrix_if vif,
  matrix_seq_item_t seq_item,
  en_mode_t          en_mode,
  bit                en_log
);
  logic en_val;

  // align with driver clocking block
  @(posedge vif.clk);

  case (en_mode)
    EN_RANDOM:  en_val = $urandom_range(1, 0);
    EN_BURST:   en_val = 1'b1;
    EN_DISABLE: en_val = 1'b0;
    default:    en_val = 1'b1;
  endcase

  vif.cb_drv.en <= en_val;
  vif.cb_drv.A  <= seq_item.a;
  vif.cb_drv.B  <= seq_item.b;

  if (en_log)
    $display("[driver-log] en_mode=%s en=%b A=32'h%08h B=32'h%08h", en_mode.name(), en_val, seq_item.a, seq_item.b);

endtask: matrix_drv
