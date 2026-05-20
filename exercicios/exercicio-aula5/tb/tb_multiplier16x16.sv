// Self-checking SystemVerilog testbench for multiplier (16x16)
// RTL: rtl/multiplier16x16.v
// DUT: 16-bit × 16-bit = 32-bit registered multiplier
module tb_multiplier16x16;

  // ------------------------------------------------------------------ ports
  logic         clk, reset_n, en;
  logic [15:0]  op_a, op_b;
  wire  [31:0]  multi_out;

  int errors = 0;
  int tests  = 0;

  // ------------------------------------------------------------------ clock
  initial clk = 0;
  always  #5 clk = ~clk;

  // ------------------------------------------------------------------ DUT
  multiplier dut (
    .clk       (clk),
    .reset_n   (reset_n),
    .en        (en),
    .op_a      (op_a),
    .op_b      (op_b),
    .multi_out (multi_out)
  );

  // ------------------------------------------------------------------ task
  task automatic check_result(input string msg);
    logic [31:0] expected;
    @(posedge clk); #1;
    expected = op_a * op_b;
    tests++;
    if (multi_out !== expected) begin
      $display("[FAIL] %s | %04h × %04h | exp=%08h got=%08h",
               msg, op_a, op_b, expected, multi_out);
      errors++;
    end else begin
      $display("[PASS] %s | %04h × %04h = %08h", msg, op_a, op_b, multi_out);
    end
  endtask

  // ------------------------------------------------------------------ stimulus
  initial begin
    reset_n = 0; en = 0; op_a = 0; op_b = 0;
    #12 reset_n = 1; en = 1;

    // --- Test 1: cases from original TB
    op_a = 16'hAAAA; op_b = 16'hBBBB;
    check_result("0xAAAA × 0xBBBB");

    op_a = 16'h4444; op_b = 16'h1111;
    check_result("0x4444 × 0x1111");

    // --- Test 2: boundary cases
    op_a = 16'h0001; op_b = 16'hFFFF;
    check_result("1 × 0xFFFF (max)");

    op_a = 16'h0000; op_b = 16'hFFFF;
    check_result("0 × max = 0");

    op_a = 16'hFFFF; op_b = 16'hFFFF;
    check_result("max × max = 0xFFFE0001");

    // --- Test 3: powers of two
    op_a = 16'h0010; op_b = 16'h0010; // 16 × 16 = 256
    check_result("16 × 16 = 256");

    op_a = 16'h0100; op_b = 16'h0100; // 256 × 256 = 65536
    check_result("256 × 256 = 65536");

    // --- Test 4: commutativity check
    op_a = 16'h1234; op_b = 16'h5678;
    @(posedge clk); #1;
    begin
      logic [31:0] res_ab = multi_out;
      op_a = 16'h5678; op_b = 16'h1234;
      @(posedge clk); #1;
      tests++;
      if (multi_out !== res_ab) begin
        $display("[FAIL] commutativity: A×B=%08h ≠ B×A=%08h", res_ab, multi_out);
        errors++;
      end else
        $display("[PASS] commutativity: A×B = B×A = %08h", multi_out);
    end

    // --- Test 5: async reset
    reset_n = 0;
    #2;
    tests++;
    if (multi_out !== 32'd0) begin
      $display("[FAIL] async reset: expected 0 got %08h", multi_out);
      errors++;
    end else
      $display("[PASS] async reset: multi_out=0x00000000");
    reset_n = 1;

    // ---------------------------------------------------------------- summary
    #20;
    $display("=========================================");
    $display("  multiplier16x16 | %0d tests | %0d error(s)", tests, errors);
    if (errors == 0)
      $display("  ALL TESTS PASSED");
    else
      $display("  SIMULATION FAILED");
    $display("=========================================");
    $finish;
  end

  // ------------------------------------------------------------------ dump
  initial begin
    $dumpfile("tb_multiplier16x16.vcd");
    $dumpvars(0, tb_multiplier16x16);
  end

endmodule
