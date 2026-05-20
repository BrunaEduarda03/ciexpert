`timescale 1ns/1ps
module sim_mux8x1;

  reg       clk, rstn, en;
  reg [7:0] din;
  reg [2:0] sel;
  wire      dout;

  integer errors, tests, i;

  initial clk = 0;
  always #5 clk = ~clk;

  mux8x1 uut (
    .clk (clk),
    .rstn(rstn),
    .en  (en),
    .din (din),
    .sel (sel),
    .dout(dout)
  );

  task automatic check_dout;
    input     exp;
    input [63:0] sel_v;
    input [63:0] din_v;
    begin
      @(posedge clk); #1;
      tests = tests + 1;
      if (dout !== exp) begin
        $display("[FAIL] sel=%0b din=%08b | exp=%0b got=%0b", sel, din, exp, dout);
        errors = errors + 1;
      end else
        $display("[PASS] sel=%0b din=%08b dout=%0b", sel, din, dout);
    end
  endtask

  initial begin
    errors = 0; tests = 0;
    rstn = 0; en = 0; din = 8'h00; sel = 0;
    $display("=== mux8x1 testbench ===");
    #12 rstn = 1; en = 1;

    // Test 1: din[sel]=1 → dout=1
    for (i = 0; i < 8; i = i + 1) begin
      sel = i[2:0];
      din = (8'b00000001 << i);
      check_dout(1'b1, i, i);
    end

    // Test 2: din[sel]=0 → dout=0
    for (i = 0; i < 8; i = i + 1) begin
      sel = i[2:0];
      din = ~(8'b00000001 << i);
      check_dout(1'b0, i, i);
    end

    // Test 3: all zeros
    sel = 3'b100; din = 8'h00;
    check_dout(1'b0, 4, 0);

    // Test 4: all ones
    sel = 3'b010; din = 8'hFF;
    check_dout(1'b1, 2, 8'hFF);

    // Test 5: async reset
    rstn = 0; #2;
    tests = tests + 1;
    if (dout !== 1'b0) begin
      $display("[FAIL] async reset: got %0b", dout);
      errors = errors + 1;
    end else
      $display("[PASS] async reset: dout=0");
    rstn = 1;

    #20;
    $display("=========================================");
    $display("  mux8x1 | %0d tests | %0d error(s)", tests, errors);
    if (errors == 0) $display("  ALL TESTS PASSED");
    else             $display("  SIMULATION FAILED");
    $display("=========================================");
    $finish;
  end

  initial begin
    $dumpfile("sim/mux8x1/sim.vcd");
    $dumpvars(0, sim_mux8x1);
  end
endmodule
