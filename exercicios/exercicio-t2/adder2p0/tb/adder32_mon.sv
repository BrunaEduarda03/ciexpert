task adder32_mon(
  virtual adder32_if vif,
  output logic [32:0] dut_r,
  input bit en_log
);

  // wait until monitor clocking block samples the valid output
  @(posedge vif.clk);
  @(posedge vif.clk);
  #3ns;

  if(en_log)
    $display("carry_out = %b, adder_out = %d", vif.cb_mon.carry_out, vif.cb_mon.adder_out);

  dut_r = {vif.cb_mon.carry_out, vif.cb_mon.adder_out};

endtask: adder32_mon

// diff between @(posedge clk) and @(vif.cb_mon) here:
// you are not reading the raw value of adder_out at that exact simulation time. 
// you are reading the value that the clocking block sampled according to its input skew...