/**
 * Matrix2x2 Scoreboard
 *
 * @ref: espelha adder2p0/tb/adder32_scb.sv (Atividade 11): contabiliza
 *       matches/mismatches/total de transacoes e imprime um resumo ao final.
 */
int unsigned matrix_scb_transactions = 0;
int unsigned matrix_scb_matches      = 0;
int unsigned matrix_scb_mismatches   = 0;

function void matrix_scb(logic [31:0] dut_r, logic [31:0] rfm_r, bit en_log);
  if (en_log)
    $display("dut_r 32'h%08h, rfm_r 32'h%08h", dut_r, rfm_r);

  matrix_scb_transactions++;

  if (dut_r !== rfm_r) begin
    matrix_scb_mismatches++;
    if (en_log)
      $display("error");
  end else begin
    matrix_scb_matches++;
    if (en_log)
      $display("pass");
  end
endfunction: matrix_scb

// resumo final (chamado uma vez, ao termino de todas as transacoes)
function void matrix_scb_report();
  real pass_rate;
  pass_rate = (matrix_scb_transactions == 0) ? 0.0 :
              100.0 * real'(matrix_scb_matches) / real'(matrix_scb_transactions);

  $display("==============================");
  $display("Simulation Summary");
  $display("==============================");
  $display("Transactions : %0d", matrix_scb_transactions);
  $display("Matches      : %0d", matrix_scb_matches);
  $display("Mismatches   : %0d", matrix_scb_mismatches);
  $display("Pass Rate    : %0.1f %%", pass_rate);
  $display("==============================");
endfunction: matrix_scb_report
