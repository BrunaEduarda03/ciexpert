`timescale 1ns/1ps
module sim_decoder2x4;

  reg       clk, rstn, en;
  reg [1:0] din;
  wire [3:0] dout;

  integer errors, tests, i, ones;

  reg [3:0] expected_map [0:3];

  initial clk = 0;
  always #5 clk = ~clk;

  decoder2x4 uut (
    .clk (clk),
    .rstn(rstn),
    .en  (en),
    .din (din),
    .dout(dout)
  );

  task automatic check_dout;
    input [3:0] expected;
    begin
      @(posedge clk); #1;
      tests = tests + 1;
      if (dout !== expected) begin
        $display("[FAIL] din=%02b | exp=%04b got=%04b", din, expected, dout);
        errors = errors + 1;
      end else
        $display("[PASS] din=%02b dout=%04b", din, dout);
    end
  endtask

  initial begin
    expected_map[0] = 4'b0001;
    expected_map[1] = 4'b0010;
    expected_map[2] = 4'b0100;
    expected_map[3] = 4'b1000;

    errors = 0; tests = 0;
    rstn = 0; en = 0; din = 2'b00;
    $display("=== decoder2x4 testbench ===");
    #12 rstn = 1; en = 1;

    // Test 1: all 4 mappings
    for (i = 0; i < 4; i = i + 1) begin
      din = i[1:0];
      check_dout(expected_map[i]);
    end

    // Test 2: one-hot property ($countones equivalent)
    for (i = 0; i < 4; i = i + 1) begin
      din = i[1:0];
      @(posedge clk); #1;
      ones = dout[0] + dout[1] + dout[2] + dout[3];
      tests = tests + 1;
      if (ones !== 1) begin
        $display("[FAIL] one-hot: din=%02b dout=%04b has %0d bits set", din, dout, ones);
        errors = errors + 1;
      end else
        $display("[PASS] one-hot OK: din=%02b dout=%04b", din, dout);
    end

    // Test 3: async reset
    rstn = 0; #2;
    tests = tests + 1;
    if (dout !== 4'b0000) begin
      $display("[FAIL] async reset: got %04b", dout);
      errors = errors + 1;
    end else
      $display("[PASS] async reset: dout=0000");
    rstn = 1;

    // Test 4: en=0 holds output
    en = 0; din = 2'b10;
    @(posedge clk); #1;
    tests = tests + 1;
    if (dout !== 4'b0000) begin
      $display("[FAIL] en=0: expected hold 0000 got %04b", dout);
      errors = errors + 1;
    end else
      $display("[PASS] en=0: dout held at 0000");
    en = 1;

    #20;
    $display("=========================================");
    $display("  decoder2x4 | %0d tests | %0d error(s)", tests, errors);
    if (errors == 0) $display("  ALL TESTS PASSED");
    else             $display("  SIMULATION FAILED");
    $display("=========================================");
    $finish;
  end

  initial begin
    $dumpfile("sim/decoder2x4/sim.vcd");
    $dumpvars(0, sim_decoder2x4);
  end
endmodule
