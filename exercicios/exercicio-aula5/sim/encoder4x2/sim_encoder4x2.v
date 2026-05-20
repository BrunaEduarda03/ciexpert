`timescale 1ns/1ps
module sim_encoder4x2;

  reg       clk, rstn, en;
  reg [3:0] din;
  wire [1:0] dout;

  integer errors, tests, i;

  reg [1:0] expected_map [0:3];
  reg [3:0] one_hot      [0:3];

  initial clk = 0;
  always #5 clk = ~clk;

  encoder4x2 uut (
    .clk (clk),
    .rstn(rstn),
    .en  (en),
    .din (din),
    .dout(dout)
  );

  task automatic check_dout;
    input [1:0] expected;
    begin
      @(posedge clk); #1;
      tests = tests + 1;
      if (dout !== expected) begin
        $display("[FAIL] din=%04b | exp=%02b got=%02b", din, expected, dout);
        errors = errors + 1;
      end else
        $display("[PASS] din=%04b dout=%02b", din, dout);
    end
  endtask

  initial begin
    one_hot[0] = 4'b0001; one_hot[1] = 4'b0010;
    one_hot[2] = 4'b0100; one_hot[3] = 4'b1000;
    expected_map[0] = 2'b00; expected_map[1] = 2'b01;
    expected_map[2] = 2'b10; expected_map[3] = 2'b11;

    errors = 0; tests = 0;
    rstn = 0; en = 0; din = 4'b0000;
    $display("=== encoder4x2 testbench ===");
    #12 rstn = 1; en = 1;

    // Test 1: 4 valid one-hot inputs
    for (i = 0; i < 4; i = i + 1) begin
      din = one_hot[i];
      check_dout(expected_map[i]);
    end

    // Test 2: invalid input 0000 → default 00
    din = 4'b0000;
    check_dout(2'b00);

    // Test 3: async reset
    rstn = 0; #2;
    tests = tests + 1;
    if (dout !== 2'b00) begin
      $display("[FAIL] async reset: got %02b", dout);
      errors = errors + 1;
    end else
      $display("[PASS] async reset: dout=00");
    rstn = 1;

    // Test 4: en=0 freeze sweep
    for (i = 0; i < 4; i = i + 1) begin : freeze_loop
      reg [1:0] held;
      en = 1; din = one_hot[i];
      @(posedge clk); #1;
      held = dout;
      en = 0; din = one_hot[(i+1)%4];
      @(posedge clk); #1;
      tests = tests + 1;
      if (dout !== held) begin
        $display("[FAIL] en=0 freeze: expected %02b got %02b", held, dout);
        errors = errors + 1;
      end else
        $display("[PASS] en=0 freeze: dout=%02b held", dout);
    end
    en = 1;

    #20;
    $display("=========================================");
    $display("  encoder4x2 | %0d tests | %0d error(s)", tests, errors);
    if (errors == 0) $display("  ALL TESTS PASSED");
    else             $display("  SIMULATION FAILED");
    $display("=========================================");
    $finish;
  end

  initial begin
    $dumpfile("sim/encoder4x2/sim.vcd");
    $dumpvars(0, sim_encoder4x2);
  end
endmodule
