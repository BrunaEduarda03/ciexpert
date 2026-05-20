`timescale 1ns/1ps
module sim_arbiter;

  reg  clk, reset_n;
  reg  priority_sel, client1_req, client2_req;
  wire o_grant1, o_grant2;

  integer errors, tests, i;

  initial clk = 0;
  always #5 clk = ~clk;

  arbiter uut (
    .clk         (clk),
    .reset_n     (reset_n),
    .priority_sel(priority_sel),
    .client1_req (client1_req),
    .client2_req (client2_req),
    .o_grant1    (o_grant1),
    .o_grant2    (o_grant2)
  );

  task automatic check_grants;
    input exp_g1, exp_g2;
    begin
      tests = tests + 1;
      if (o_grant1 !== exp_g1 || o_grant2 !== exp_g2) begin
        $display("[FAIL] exp g1=%0b g2=%0b | got g1=%0b g2=%0b",
                 exp_g1, exp_g2, o_grant1, o_grant2);
        errors = errors + 1;
      end else
        $display("[PASS] grant1=%0b grant2=%0b", o_grant1, o_grant2);
    end
  endtask

  task automatic wclk;
    input integer n;
    integer k;
    begin
      for (k = 0; k < n; k = k + 1) @(posedge clk);
      #1;
    end
  endtask

  initial begin
    errors = 0; tests = 0;
    reset_n = 0; priority_sel = 0; client1_req = 0; client2_req = 0;
    $display("=== arbiter testbench ===");
    #12 reset_n = 1;
    wclk(1); check_grants(0, 0);  // IDLE

    // Scenario 1: client1 with priority
    // FSM timing: clock+1 latches req into _d; clock+2 transitions to CLINET1 → grant visible
    priority_sel = 1; client1_req = 1; client2_req = 0;
    wclk(2); check_grants(1, 0);
    client1_req = 0;
    wclk(1); check_grants(0, 0);

    // Scenario 2: client2 only
    priority_sel = 0; client2_req = 1;
    wclk(2); check_grants(0, 1);
    client2_req = 0;
    wclk(1); check_grants(0, 0);

    // Scenario 3: both, priority=1 → client1 first
    priority_sel = 1; client1_req = 1; client2_req = 1;
    wclk(2); check_grants(1, 0);
    client1_req = 0;
    wclk(1); check_grants(0, 1);  // FSM sees client2_req_d still set → CLINET2
    client2_req = 0;
    wclk(1); check_grants(0, 0);

    // Scenario 4: both, priority=0 → client2 first
    priority_sel = 0; client1_req = 1; client2_req = 1;
    wclk(2); check_grants(0, 1);
    client2_req = 0;
    wclk(1); check_grants(1, 0);  // client1_req_d still set → CLINET1
    client1_req = 0;
    wclk(1); check_grants(0, 0);

    // Scenario 5: mutual exclusion
    priority_sel = 1;
    for (i = 0; i < 20; i = i + 1) begin
      client1_req = i[0];
      client2_req = i[1];
      @(posedge clk); #1;
      tests = tests + 1;
      if (o_grant1 && o_grant2) begin
        $display("[FAIL] mutual exclusion violated at cycle %0d", i);
        errors = errors + 1;
      end
    end
    $display("[PASS] mutual exclusion: never both grants=1 (20 cycles)");
    client1_req = 0; client2_req = 0;

    #50;
    $display("=========================================");
    $display("  arbiter | %0d tests | %0d error(s)", tests, errors);
    if (errors == 0) $display("  ALL TESTS PASSED");
    else             $display("  SIMULATION FAILED");
    $display("=========================================");
    $finish;
  end

  initial begin
    $dumpfile("sim/arbiter/sim.vcd");
    $dumpvars(0, sim_arbiter);
  end
endmodule
