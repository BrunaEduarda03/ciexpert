//
// todo: mismatches/matches
//
function void adder32_scb(logic [32:0] dut_r, logic [32:0] rfm_r, bit en_log);
  if(en_log)
    $display("dut_r %d, rfm_r %d", dut_r, rfm_r);
  
  if (dut_r != rfm_r) begin
    if(en_log)
      $display("error");
  end else begin
    if(en_log)
      $display("pass");
  end
endfunction: adder32_scb
