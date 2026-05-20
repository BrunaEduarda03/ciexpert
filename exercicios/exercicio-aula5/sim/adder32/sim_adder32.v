`timescale 1ns/1ps
module sim_adder32;

  reg         clk, reset_n, en;
  reg  [31:0] op_a, op_b;
  wire [31:0] adder_out;
  wire        carry_out;

  integer errors, tests;

  initial clk = 0;
  always #5 clk = ~clk;

  adder uut (
    .clk      (clk),
    .reset_n  (reset_n),
    .en       (en),
    .op_a     (op_a),
    .op_b     (op_b),
    .adder_out(adder_out),
    .carry_out(carry_out)
  );

  task automatic check_adder;
    reg [32:0] ref;
    begin
      @(posedge clk); #1;
      ref = {1'b0, op_a} + {1'b0, op_b};
      tests = tests + 1;
      if ({carry_out, adder_out} !== ref) begin
        $display("[FAIL] %08h + %08h | exp carry=%b sum=%08h | got carry=%b sum=%08h",
                 op_a, op_b, ref[32], ref[31:0], carry_out, adder_out);
        errors = errors + 1;
      end else
        $display("[PASS] %08h + %08h = carry=%b %08h", op_a, op_b, carry_out, adder_out);
    end
  endtask

  initial begin
    errors = 0; tests = 0;
    reset_n = 0; en = 0; op_a = 0; op_b = 0;
    $display("=== adder32 testbench ===");
    #12 reset_n = 1; en = 1;

    op_a = 32'hAAAAAAAA; op_b = 32'hEEEEEEEE; check_adder;
    op_a = 32'h07777777; op_b = 32'h02456321; check_adder;
    op_a = 32'hCCCCCCCC; op_b = 32'h0BBBBBBB; check_adder;
    op_a = 32'h11111111; op_b = 32'h11111111; check_adder;
    op_a = 32'h00000000; op_b = 32'h00000000; check_adder;
    op_a = 32'hFFFFFFFF; op_b = 32'h00000001; check_adder;
    op_a = 32'hFFFFFFFF; op_b = 32'hFFFFFFFF; check_adder;
    op_a = 32'h12345678; op_b = 32'h87654321; check_adder;

    // async reset
    reset_n = 0; #2;
    tests = tests + 1;
    if ({carry_out, adder_out} !== 33'd0) begin
      $display("[FAIL] async reset: carry=%b sum=%08h", carry_out, adder_out);
      errors = errors + 1;
    end else
      $display("[PASS] async reset: carry=0 sum=0");
    reset_n = 1;

    // en=0 freeze
    en = 0; op_a = 32'hDEADBEEF; op_b = 32'hCAFEBABE;
    @(posedge clk); #1;
    tests = tests + 1;
    if ({carry_out, adder_out} !== 33'd0) begin
      $display("[FAIL] en=0: output changed carry=%b sum=%08h", carry_out, adder_out);
      errors = errors + 1;
    end else
      $display("[PASS] en=0: output frozen at 0");
    en = 1;

    #20;
    $display("=========================================");
    $display("  adder32 | %0d tests | %0d error(s)", tests, errors);
    if (errors == 0) $display("  ALL TESTS PASSED");
    else             $display("  SIMULATION FAILED");
    $display("=========================================");
    $finish;
  end

  initial begin
    $dumpfile("sim/adder32/sim.vcd");
    $dumpvars(0, sim_adder32);
  end
endmodule
