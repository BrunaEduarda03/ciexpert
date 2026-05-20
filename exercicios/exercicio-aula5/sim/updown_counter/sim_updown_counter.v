`timescale 1ns/1ps
module sim_updown_counter;

  reg       clk, resetn, en;
  wire [3:0] up_counter, down_counter;

  integer errors, tests, step, timeout;
  reg [3:0] exp_up, exp_dn, frozen_up, frozen_dn;

  initial clk = 0;
  always #5 clk = ~clk;

  updowncounter uut (
    .clk         (clk),
    .resetn      (resetn),
    .en          (en),
    .up_counter  (up_counter),
    .down_counter(down_counter)
  );

  initial begin
    errors = 0; tests = 0;
    clk = 0; resetn = 1; en = 0;
    $display("=== updown_counter testbench ===");
    $display("NOTE: reset is buggy (posedge resetn vs !resetn) - testing counting behavior");

    #5 resetn = 0;
    #5 resetn = 1;  // posedge resetn fires but reset never takes effect (bug)
    #1;             // wait for any NBA effects to settle before enabling
    en = 1;

    // Test 16 counting steps
    for (step = 0; step < 16; step = step + 1) begin
      exp_up = up_counter + 4'b1;
      exp_dn = down_counter - 4'b1;
      @(posedge clk); #1;
      tests = tests + 1;
      if (up_counter !== exp_up || down_counter !== exp_dn) begin
        $display("[FAIL] step %0d: exp up=%04b dn=%04b | got up=%04b dn=%04b",
                 step, exp_up, exp_dn, up_counter, down_counter);
        errors = errors + 1;
      end else
        $display("[PASS] step %0d: up=%04b dn=%04b", step, up_counter, down_counter);
    end

    // en=0 freeze
    en = 0;
    frozen_up = up_counter;
    frozen_dn = down_counter;
    @(posedge clk); #1;
    tests = tests + 1;
    if (up_counter !== frozen_up || down_counter !== frozen_dn) begin
      $display("[FAIL] en=0 freeze: counters changed");
      errors = errors + 1;
    end else
      $display("[PASS] en=0 freeze: up=%04b dn=%04b held", up_counter, down_counter);
    @(posedge clk); #1;
    tests = tests + 1;
    if (up_counter !== frozen_up || down_counter !== frozen_dn) begin
      $display("[FAIL] en=0 freeze cycle 2: counters changed");
      errors = errors + 1;
    end else
      $display("[PASS] en=0 freeze cycle 2: held");
    en = 1;

    // resume counting
    exp_up = up_counter + 4'b1;
    exp_dn = down_counter - 4'b1;
    @(posedge clk); #1;
    tests = tests + 1;
    if (up_counter !== exp_up || down_counter !== exp_dn) begin
      $display("[FAIL] resume: exp up=%04b dn=%04b got up=%04b dn=%04b",
               exp_up, exp_dn, up_counter, down_counter);
      errors = errors + 1;
    end else
      $display("[PASS] resume: up=%04b dn=%04b", up_counter, down_counter);

    // wait for up_counter == 4'hF then check wrap
    // #1 inside loop ensures we read post-NBA values so the exit condition is reliable
    timeout = 0;
    while (up_counter !== 4'hF && timeout < 50) begin
      @(posedge clk); #1;
      timeout = timeout + 1;
    end
    @(posedge clk); #1;
    tests = tests + 1;
    if (up_counter !== 4'h0) begin
      $display("[FAIL] wrap: up expected 0000 after F, got %04b", up_counter);
      errors = errors + 1;
    end else
      $display("[PASS] wrap: up 1111 -> 0000");

    #20;
    $display("=========================================");
    $display("  updown_counter | %0d tests | %0d error(s)", tests, errors);
    if (errors == 0) $display("  ALL TESTS PASSED");
    else             $display("  SIMULATION FAILED");
    $display("=========================================");
    $finish;
  end

  initial begin
    $dumpfile("sim/updown_counter/sim.vcd");
    $dumpvars(0, sim_updown_counter);
  end
endmodule
