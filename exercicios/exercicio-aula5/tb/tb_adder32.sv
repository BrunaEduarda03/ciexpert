// Self-checking SystemVerilog testbench for adder (32-bit)
// RTL: rtl/adder32.v
// DUT: 32-bit adder with carry out, registered output, active-low reset
module tb_adder32;

  // ------------------------------------------------------------------ ports
  logic         clk, reset_n, en;
  logic [31:0]  op_a, op_b;
  wire  [31:0]  adder_out;
  wire          carry_out;

  int errors = 0;
  int tests  = 0;

  // Reference model
  logic [32:0] ref_sum;

  // ------------------------------------------------------------------ clock
  initial clk = 0;
  always  #5 clk = ~clk;

  // ------------------------------------------------------------------ DUT
  adder dut (
    .clk       (clk),
    .reset_n   (reset_n),
    .en        (en),
    .op_a      (op_a),
    .op_b      (op_b),
    .adder_out (adder_out),
    .carry_out (carry_out)
  );

  // ------------------------------------------------------------------ task
  task automatic check_result(input string msg);
    @(posedge clk); #1;
    ref_sum = {1'b0, op_a} + {1'b0, op_b};
    tests++;
    if ({carry_out, adder_out} !== ref_sum) begin
      $display("[FAIL] %s | A=%08h B=%08h | exp carry=%0b sum=%08h | got carry=%0b sum=%08h",
               msg, op_a, op_b, ref_sum[32], ref_sum[31:0], carry_out, adder_out);
      errors++;
    end else begin
      $display("[PASS] %s | %08h + %08h = carry=%0b %08h",
               msg, op_a, op_b, carry_out, adder_out);
    end
  endtask

  // ------------------------------------------------------------------ stimulus
  initial begin
    reset_n = 0; en = 0; op_a = 0; op_b = 0;
    #12 reset_n = 1; en = 1;

    // --- Test 1: basic addition cases from original TB
    op_a = 32'hAAAAAAAA; op_b = 32'hEEEEEEEE;
    check_result("0xAAAA + 0xEEEE (overflow expected)");

    op_a = 32'h07777777; op_b = 32'h02456321;
    check_result("0x0777 + 0x0245");

    op_a = 32'hCCCCCCCC; op_b = 32'h0BBBBBBB;
    check_result("0xCCCC + 0x0BBB");

    op_a = 32'h11111111; op_b = 32'h11111111;
    check_result("0x1111 + 0x1111");

    // --- Test 2: zero cases
    op_a = 32'h00000000; op_b = 32'h00000000;
    check_result("0 + 0 = 0");

    op_a = 32'hFFFFFFFF; op_b = 32'h00000001;
    check_result("0xFFFF + 1 → carry=1 sum=0");

    // --- Test 3: max + max
    op_a = 32'hFFFFFFFF; op_b = 32'hFFFFFFFF;
    check_result("0xFFFF + 0xFFFF → max carry");

    // --- Test 4: symmetric operands
    op_a = 32'h12345678; op_b = 32'h87654321;
    check_result("0x1234 + 0x8765");

    // --- Test 5: reset clears output
    reset_n = 0;
    #2;
    tests++;
    if ({carry_out, adder_out} !== 33'd0) begin
      $display("[FAIL] async reset: expected carry=0 sum=0, got carry=%0b sum=%08h",
               carry_out, adder_out);
      errors++;
    end else
      $display("[PASS] async reset: carry=0 sum=0x00000000");
    reset_n = 1;

    // --- Test 6: en=0 freezes output (holds reset value = 0)
    en = 0;
    op_a = 32'hDEADBEEF; op_b = 32'hCAFEBABE;
    @(posedge clk); #1;
    tests++;
    if ({carry_out, adder_out} !== 33'd0) begin
      $display("[FAIL] en=0: output changed unexpectedly carry=%0b sum=%08h", carry_out, adder_out);
      errors++;
    end else
      $display("[PASS] en=0: output frozen at 0");
    en = 1;

    // ---------------------------------------------------------------- summary
    #20;
    $display("=========================================");
    $display("  adder32 | %0d tests | %0d error(s)", tests, errors);
    if (errors == 0)
      $display("  ALL TESTS PASSED");
    else
      $display("  SIMULATION FAILED");
    $display("=========================================");
    $finish;
  end

  // ------------------------------------------------------------------ dump
  initial begin
    $dumpfile("tb_adder32.vcd");
    $dumpvars(0, tb_adder32);
  end

endmodule
