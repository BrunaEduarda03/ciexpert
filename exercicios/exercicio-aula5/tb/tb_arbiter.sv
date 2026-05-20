// Self-checking SystemVerilog testbench for arbiter
// RTL: rtl/arbiter.v
// DUT: 2-client fixed-priority arbiter (FSM: IDLE → CLIENT1 / CLIENT2)
//
// Arbiter logic (from RTL):
//   IDLE:
//     priority_sel=1 AND client1_req → CLINET1
//     else client2_req              → CLINET2
//     else                          → IDLE
//   CLINET1: client2_req → CLINET2, else → IDLE
//   CLINET2: client1_req → CLINET1, else → IDLE
//
//   o_grant1 = (state == CLINET1)
//   o_grant2 = (state == CLINET2)
//
// NOTE: requests are internally registered (client*_req_d), so they must be
// held for at least one clock cycle to be seen by the FSM next-state logic.
module tb_arbiter;

  // ------------------------------------------------------------------ ports
  logic clk, reset_n;
  logic priority_sel, client1_req, client2_req;
  wire  o_grant1, o_grant2;

  int errors = 0;
  int tests  = 0;

  // ------------------------------------------------------------------ clock
  initial clk = 0;
  always  #5 clk = ~clk;

  // ------------------------------------------------------------------ DUT
  arbiter dut (
    .clk         (clk),
    .reset_n     (reset_n),
    .priority_sel(priority_sel),
    .client1_req (client1_req),
    .client2_req (client2_req),
    .o_grant1    (o_grant1),
    .o_grant2    (o_grant2)
  );

  // ------------------------------------------------------------------ tasks
  task automatic check_grants(
    input logic exp_g1, exp_g2,
    input string msg
  );
    tests++;
    if (o_grant1 !== exp_g1 || o_grant2 !== exp_g2) begin
      $display("[FAIL] %s | exp g1=%0b g2=%0b | got g1=%0b g2=%0b",
               msg, exp_g1, exp_g2, o_grant1, o_grant2);
      errors++;
    end else
      $display("[PASS] %s | grant1=%0b grant2=%0b", msg, o_grant1, o_grant2);
  endtask

  task automatic wait_clk(input int n = 1);
    repeat(n) @(posedge clk);
    #1;
  endtask

  // ------------------------------------------------------------------ stimulus
  initial begin
    reset_n = 0; priority_sel = 0; client1_req = 0; client2_req = 0;
    #12 reset_n = 1;
    wait_clk(1);
    check_grants(0, 0, "after reset: both grants=0 (IDLE)");

    // === Scenario 1: client1 with priority_sel=1 ===
    priority_sel = 1'b1;
    client1_req  = 1'b1;
    client2_req  = 1'b0;
    wait_clk(2); // req registered internally, then FSM transitions
    check_grants(1, 0, "priority=1 req1=1: grant1 asserted");

    // client1 req served (grant1 clears client1_req_d), no more requests → IDLE
    client1_req = 1'b0;
    wait_clk(2);
    check_grants(0, 0, "after req1 cleared: back to IDLE");

    // === Scenario 2: client2 only (priority_sel=0) ===
    priority_sel = 1'b0;
    client2_req  = 1'b1;
    wait_clk(2);
    check_grants(0, 1, "priority=0 req2=1: grant2 asserted");

    client2_req = 1'b0;
    wait_clk(2);
    check_grants(0, 0, "after req2 cleared: IDLE");

    // === Scenario 3: both request, priority_sel=1 → client1 first ===
    priority_sel = 1'b1;
    client1_req  = 1'b1;
    client2_req  = 1'b1;
    wait_clk(2);
    check_grants(1, 0, "both req priority=1: grant1 first");

    // client1 served, client2 still pending → grant2 next
    client1_req = 1'b0;
    wait_clk(2);
    check_grants(0, 1, "after c1 served: grant2 for pending c2");

    client2_req = 1'b0;
    wait_clk(2);
    check_grants(0, 0, "after c2 served: IDLE");

    // === Scenario 4: both request, priority_sel=0 → client2 first ===
    priority_sel = 1'b0;
    client1_req  = 1'b1;
    client2_req  = 1'b1;
    wait_clk(2);
    check_grants(0, 1, "both req priority=0: grant2 first");

    client2_req = 1'b0;
    wait_clk(2);
    check_grants(1, 0, "after c2 served: grant1 for pending c1");

    client1_req = 1'b0;
    wait_clk(2);
    check_grants(0, 0, "after c1 served: IDLE");

    // === Scenario 5: mutual exclusion — never both grants high ===
    // Run 20 random-ish cycles and verify grants are never both=1
    priority_sel = 1'b1;
    for (int i = 0; i < 20; i++) begin
      client1_req = i[0];
      client2_req = i[1];
      @(posedge clk); #1;
      tests++;
      if (o_grant1 && o_grant2) begin
        $display("[FAIL] mutual exclusion violated: both grants=1 at cycle %0d", i);
        errors++;
      end
    end
    $display("[PASS] mutual exclusion: never both grants=1 across 20 cycles");

    client1_req = 0; client2_req = 0;

    // ---------------------------------------------------------------- summary
    #50;
    $display("=========================================");
    $display("  arbiter | %0d tests | %0d error(s)", tests, errors);
    if (errors == 0)
      $display("  ALL TESTS PASSED");
    else
      $display("  SIMULATION FAILED");
    $display("=========================================");
    $finish;
  end

  // ------------------------------------------------------------------ dump
  initial begin
    $dumpfile("tb_arbiter.vcd");
    $dumpvars(0, tb_arbiter);
  end

endmodule
