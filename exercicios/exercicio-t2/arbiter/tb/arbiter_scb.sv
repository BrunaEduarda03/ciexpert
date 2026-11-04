/**
 * Arbiter Scoreboard
 *
 * @ref: espelha adder2p0/tb/adder32_scb.sv (Atividade 11): contabiliza
 *       matches/mismatches/total e imprime um resumo ao final. Aqui a
 *       comparacao acontece A CADA CICLO de clock (o_grant1/o_grant2 do DUT
 *       contra o modelo de referencia em C), nao por transacao.
 */
int unsigned arbiter_scb_cycles     = 0;
int unsigned arbiter_scb_matches    = 0;
int unsigned arbiter_scb_mismatches = 0;

function void arbiter_scb(
  logic dut_g1, logic dut_g2,
  logic exp_g1, logic exp_g2,
  bit   en_log
);
  if (en_log)
    $display("dut: g1=%0b g2=%0b | exp: g1=%0b g2=%0b", dut_g1, dut_g2, exp_g1, exp_g2);

  arbiter_scb_cycles++;

  if ((dut_g1 !== exp_g1) || (dut_g2 !== exp_g2)) begin
    arbiter_scb_mismatches++;
    if (en_log)
      $display("error");
  end else begin
    arbiter_scb_matches++;
    if (en_log)
      $display("pass");
  end
endfunction: arbiter_scb

function void arbiter_scb_report();
  real pass_rate;
  pass_rate = (arbiter_scb_cycles == 0) ? 0.0 :
              100.0 * real'(arbiter_scb_matches) / real'(arbiter_scb_cycles);

  $display("==============================");
  $display("Simulation Summary");
  $display("==============================");
  $display("Cycles checked : %0d", arbiter_scb_cycles);
  $display("Matches        : %0d", arbiter_scb_matches);
  $display("Mismatches     : %0d", arbiter_scb_mismatches);
  $display("Pass Rate      : %0.1f %%", pass_rate);
  $display("==============================");
endfunction: arbiter_scb_report
