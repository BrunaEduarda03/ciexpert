// Self-checking SystemVerilog testbench for decoder2x4
// RTL: rtl/decoder2x4.v
// DUT: 2-to-4 binary decoder with registered one-hot output
module tb_decoder2x4;

  // ------------------------------------------------------------------ ports
  logic        clk, rstn, en;
  logic [1:0]  din;
  wire  [3:0]  dout;

  int errors = 0;
  int tests  = 0;

  // Expected one-hot mapping: din → dout
  // 00 → 0001, 01 → 0010, 10 → 0100, 11 → 1000
  logic [3:0] expected_map [0:3] = '{4'b0001, 4'b0010, 4'b0100, 4'b1000};

  // ------------------------------------------------------------------ clock
  initial clk = 0;
  always  #5 clk = ~clk;

  // ------------------------------------------------------------------ DUT
  decoder2x4 dut (
    .clk  (clk),
    .rstn (rstn),
    .en   (en),
    .din  (din),
    .dout (dout)
  );

  // ------------------------------------------------------------------ task
  task automatic check_dout(input [3:0] exp, input string msg);
    @(posedge clk); #1;
    tests++;
    if (dout !== exp) begin
      $display("[FAIL] %s | din=%02b | exp=%04b got=%04b", msg, din, exp, dout);
      errors++;
    end else begin
      $display("[PASS] %s | dout=%04b", msg, dout);
    end
  endtask

  // ------------------------------------------------------------------ stimulus
  initial begin
    rstn = 0; en = 0; din = 2'b00;
    #12 rstn = 1; en = 1;

    // --- Test 1: all four 2-bit inputs produce correct one-hot output
    for (int i = 0; i < 4; i++) begin
      din = i[1:0];
      check_dout(expected_map[i], $sformatf("din=%02b → one-hot[%0d]", din, i));
    end

    // --- Test 2: verify only ONE bit is high at any time (one-hot property)
    for (int i = 0; i < 4; i++) begin
      din = i[1:0];
      @(posedge clk); #1;
      tests++;
      if ($countones(dout) !== 1) begin
        $display("[FAIL] one-hot check: din=%02b got dout=%04b (%0d bits set)",
                 din, dout, $countones(dout));
        errors++;
      end else
        $display("[PASS] one-hot OK: din=%02b dout=%04b", din, dout);
    end

    // --- Test 3: reset forces dout=0000
    rstn = 0;
    #2;
    tests++;
    if (dout !== 4'b0000) begin
      $display("[FAIL] async reset: expected 0000 got %04b", dout);
      errors++;
    end else
      $display("[PASS] async reset: dout=0000");
    rstn = 1;

    // --- Test 4: enable=0 — output holds last latched value
    en = 0;
    din = 2'b10; // would give 0100 if en=1
    @(posedge clk); #1;
    tests++;
    if (dout !== 4'b0000) begin // should hold reset value
      $display("[FAIL] en=0 after reset: expected hold 0000 got %04b", dout);
      errors++;
    end else
      $display("[PASS] en=0 after reset: dout held at 0000");
    en = 1;

    // ---------------------------------------------------------------- summary
    #20;
    $display("=========================================");
    $display("  decoder2x4 | %0d tests | %0d error(s)", tests, errors);
    if (errors == 0)
      $display("  ALL TESTS PASSED");
    else
      $display("  SIMULATION FAILED");
    $display("=========================================");
    $finish;
  end

  // ------------------------------------------------------------------ dump
  initial begin
    $dumpfile("tb_decoder2x4.vcd");
    $dumpvars(0, tb_decoder2x4);
  end

endmodule
