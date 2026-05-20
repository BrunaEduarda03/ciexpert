`timescale 1ns/1ps
module sim_demux1x8;

  reg       clk, rstn, en, din;
  reg [2:0] sel;
  wire [7:0] dout;

  integer errors, tests, i;

  initial clk = 0;
  always #5 clk = ~clk;

  demux1x8 uut (
    .clk (clk),
    .rstn(rstn),
    .en  (en),
    .sel (sel),
    .din (din),
    .dout(dout)
  );

  task automatic check_dout;
    input [7:0] expected;
    begin
      @(posedge clk); #1;
      tests = tests + 1;
      if (dout !== expected) begin
        $display("[FAIL] sel=%0b din=%0b | exp=%08b got=%08b", sel, din, expected, dout);
        errors = errors + 1;
      end else
        $display("[PASS] sel=%0b din=%0b dout=%08b", sel, din, dout);
    end
  endtask

  initial begin
    errors = 0; tests = 0;
    rstn = 0; en = 0; din = 0; sel = 0;
    $display("=== demux1x8 testbench ===");
    #12 rstn = 1; en = 1;

    // Test 1: sel routes din=1 to correct bit
    for (i = 0; i < 8; i = i + 1) begin
      sel = i[2:0];
      din = 1'b1;
      check_dout(8'b00000001 << i);
    end

    // Test 2: din=0 forces all outputs 0
    sel = 3'b011; din = 1'b0; check_dout(8'h00);
    sel = 3'b101; din = 1'b0; check_dout(8'h00);

    // Test 3: en=0 freezes output
    en = 0; sel = 3'b000; din = 1'b1;
    @(posedge clk); #1;
    tests = tests + 1;
    if (dout !== 8'h00) begin
      $display("[FAIL] en=0: output changed to %08b", dout);
      errors = errors + 1;
    end else
      $display("[PASS] en=0: dout held at %08b", dout);
    en = 1;

    // Test 4: async reset
    rstn = 0; #2;
    tests = tests + 1;
    if (dout !== 8'h00) begin
      $display("[FAIL] async reset: got %08b", dout);
      errors = errors + 1;
    end else
      $display("[PASS] async reset: dout=0x00");
    rstn = 1;

    #20;
    $display("=========================================");
    $display("  demux1x8 | %0d tests | %0d error(s)", tests, errors);
    if (errors == 0) $display("  ALL TESTS PASSED");
    else             $display("  SIMULATION FAILED");
    $display("=========================================");
    $finish;
  end

  initial begin
    $dumpfile("sim/demux1x8/sim.vcd");
    $dumpvars(0, sim_demux1x8);
  end
endmodule
