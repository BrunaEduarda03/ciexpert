/**
 * Matrix2x2 Monitor
 *
 * @ref: espelha adder2p0/tb/adder32_mon.sv. Mesmo padrao de espera (2 bordas
 *       de posedge + 3ns de folga) confirmado empiricamente no Adder32
 *       (Atividade 8): garante leitura do Res ja estavel via cb_mon, com
 *       margem de seguranca, antes da proxima transacao comecar.
 */
task matrix_mon(
  virtual matrix_if vif,
  output logic [31:0] dut_r,
  input bit en_log
);

  // wait until monitor clocking block samples the valid output
  @(posedge vif.clk);
  @(posedge vif.clk);
  #3ns;

  if (en_log)
    $display("Res = 32'h%08h", vif.cb_mon.Res);

  dut_r = vif.cb_mon.Res;

endtask: matrix_mon
