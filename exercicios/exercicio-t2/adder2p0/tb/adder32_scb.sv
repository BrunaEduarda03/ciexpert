// Atividade 11: contabiliza matches/mismatches/total de transacoes

int unsigned adder32_scb_transactions = 0;
int unsigned adder32_scb_matches      = 0;
int unsigned adder32_scb_mismatches   = 0;

function void adder32_scb(logic [32:0] dut_r, logic [32:0] rfm_r, bit en_log);
  if(en_log)
    $display("dut_r %d, rfm_r %d", dut_r, rfm_r);

  adder32_scb_transactions++;

  if (dut_r != rfm_r) begin
    adder32_scb_mismatches++;
    if(en_log)
      $display("error");
  end else begin
    adder32_scb_matches++;
    if(en_log)
      $display("pass");
  end
endfunction: adder32_scb

function void adder32_scb_report();
  real pass_rate;
  pass_rate = (adder32_scb_transactions == 0) ? 0.0 :
              100.0 * real'(adder32_scb_matches) / real'(adder32_scb_transactions);

  $display("==============================");
  $display("Simulation Summary");
  $display("==============================");
  $display("Transactions : %0d", adder32_scb_transactions);
  $display("Matches      : %0d", adder32_scb_matches);
  $display("Mismatches   : %0d", adder32_scb_mismatches);
  $display("Pass Rate    : %0.1f %%", pass_rate);
  $display("==============================");
endfunction: adder32_scb_report
