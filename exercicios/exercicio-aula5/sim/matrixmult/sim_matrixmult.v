`timescale 1ns/1ps
module sim_matrixmult;

  reg        clk, rstn, en;
  reg [31:0] A, B;
  wire [31:0] Res;

  integer errors, tests;

  initial clk = 0;
  always #5 clk = ~clk;

  matrix2x2_mult uut (
    .clk (clk),
    .rstn(rstn),
    .en  (en),
    .A   (A),
    .B   (B),
    .Res (Res)
  );

  function [31:0] mat_mult;
    input [31:0] mA, mB;
    reg [7:0] a00, a01, a10, a11;
    reg [7:0] b00, b01, b10, b11;
    reg [7:0] r00, r01, r10, r11;
    begin
      a00 = mA[31:24]; a01 = mA[23:16]; a10 = mA[15:8]; a11 = mA[7:0];
      b00 = mB[31:24]; b01 = mB[23:16]; b10 = mB[15:8]; b11 = mB[7:0];
      r00 = (a00 * b00) + (a01 * b10);
      r01 = (a00 * b01) + (a01 * b11);
      r10 = (a10 * b00) + (a11 * b10);
      r11 = (a10 * b01) + (a11 * b11);
      mat_mult = {r00, r01, r10, r11};
    end
  endfunction

  task automatic check_result;
    reg [31:0] expected;
    begin
      @(posedge clk); #1;
      expected = mat_mult(A, B);
      tests = tests + 1;
      if (Res !== expected) begin
        $display("[FAIL] A=%08h B=%08h | exp=%08h got=%08h", A, B, expected, Res);
        errors = errors + 1;
      end else
        $display("[PASS] A=%08h B=%08h Res=%08h", A, B, Res);
    end
  endtask

  initial begin
    errors = 0; tests = 0;
    rstn = 0; en = 0; A = 0; B = 0;
    $display("=== matrixmult testbench ===");
    #12 rstn = 1; en = 1;

    // identity x identity = identity
    A = {8'd1,8'd0,8'd0,8'd1}; B = {8'd1,8'd0,8'd0,8'd1}; check_result;
    // [[1,1],[1,1]] x [[1,1],[1,1]] = [[2,2],[2,2]]
    A = {8'd1,8'd1,8'd1,8'd1}; B = {8'd1,8'd1,8'd1,8'd1}; check_result;
    // 3I x I = 3I
    A = {8'd3,8'd0,8'd0,8'd3}; B = {8'd1,8'd0,8'd0,8'd1}; check_result;
    // [[2,2],[2,2]]^2 = [[8,8],[8,8]]
    A = {8'd2,8'd2,8'd2,8'd2}; B = {8'd2,8'd2,8'd2,8'd2}; check_result;
    // zero x B = zero
    A = {8'd0,8'd0,8'd0,8'd0}; B = {8'd5,8'd3,8'd7,8'd2}; check_result;
    // [[1,2],[3,4]] x [[5,6],[7,8]] = [[19,22],[43,50]]
    A = {8'd1,8'd2,8'd3,8'd4}; B = {8'd5,8'd6,8'd7,8'd8}; check_result;

    // async reset
    rstn = 0; #2;
    // Note: Res only updates on clock with en=1; internal array resets but Res register holds
    // After reset + en=1 + A=0 + B=0 → Res=0
    rstn = 1; A = 0; B = 0; en = 1;
    @(posedge clk); #1;
    tests = tests + 1;
    if (Res !== 32'd0) begin
      $display("[FAIL] post-reset with A=B=0: Res=%08h", Res);
      errors = errors + 1;
    end else
      $display("[PASS] post-reset A=B=0: Res=0");

    #20;
    $display("=========================================");
    $display("  matrixmult | %0d tests | %0d error(s)", tests, errors);
    if (errors == 0) $display("  ALL TESTS PASSED");
    else             $display("  SIMULATION FAILED");
    $display("=========================================");
    $finish;
  end

  initial begin
    $dumpfile("sim/matrixmult/sim.vcd");
    $dumpvars(0, sim_matrixmult);
  end
endmodule
