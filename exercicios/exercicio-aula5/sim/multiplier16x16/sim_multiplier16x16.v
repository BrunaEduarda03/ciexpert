`timescale 1ns/1ps
module sim_multiplier16x16;

  reg        clk, reset_n, en;
  reg [15:0] op_a, op_b;
  wire [31:0] multi_out;

  integer errors, tests;

  initial clk = 0;
  always #5 clk = ~clk;

  multiplier uut (
    .clk      (clk),
    .reset_n  (reset_n),
    .en       (en),
    .op_a     (op_a),
    .op_b     (op_b),
    .multi_out(multi_out)
  );

  task automatic check_mult;
    reg [31:0] expected;
    begin
      @(posedge clk); #1;
      expected = op_a * op_b;
      tests = tests + 1;
      if (multi_out !== expected) begin
        $display("[FAIL] %04h x %04h | exp=%08h got=%08h", op_a, op_b, expected, multi_out);
        errors = errors + 1;
      end else
        $display("[PASS] %04h x %04h = %08h", op_a, op_b, multi_out);
    end
  endtask

  initial begin
    errors = 0; tests = 0;
    reset_n = 0; en = 0; op_a = 0; op_b = 0;
    $display("=== multiplier16x16 testbench ===");
    #12 reset_n = 1; en = 1;

    op_a = 16'hAAAA; op_b = 16'hBBBB; check_mult;
    op_a = 16'h4444; op_b = 16'h1111; check_mult;
    op_a = 16'h0001; op_b = 16'hFFFF; check_mult;
    op_a = 16'h0000; op_b = 16'hFFFF; check_mult;
    op_a = 16'hFFFF; op_b = 16'hFFFF; check_mult;
    op_a = 16'h0010; op_b = 16'h0010; check_mult;
    op_a = 16'h0100; op_b = 16'h0100; check_mult;

    // commutativity
    begin : comm
      reg [31:0] res_ab;
      op_a = 16'h1234; op_b = 16'h5678;
      @(posedge clk); #1;
      res_ab = multi_out;
      op_a = 16'h5678; op_b = 16'h1234;
      @(posedge clk); #1;
      tests = tests + 1;
      if (multi_out !== res_ab) begin
        $display("[FAIL] commutativity: AxB=%08h BxA=%08h", res_ab, multi_out);
        errors = errors + 1;
      end else
        $display("[PASS] commutativity: AxB = BxA = %08h", multi_out);
    end

    // async reset
    reset_n = 0; #2;
    tests = tests + 1;
    if (multi_out !== 32'd0) begin
      $display("[FAIL] async reset: got %08h", multi_out);
      errors = errors + 1;
    end else
      $display("[PASS] async reset: multi_out=0");
    reset_n = 1;

    #20;
    $display("=========================================");
    $display("  multiplier16x16 | %0d tests | %0d error(s)", tests, errors);
    if (errors == 0) $display("  ALL TESTS PASSED");
    else             $display("  SIMULATION FAILED");
    $display("=========================================");
    $finish;
  end

  initial begin
    $dumpfile("sim/multiplier16x16/sim.vcd");
    $dumpvars(0, sim_multiplier16x16);
  end
endmodule
