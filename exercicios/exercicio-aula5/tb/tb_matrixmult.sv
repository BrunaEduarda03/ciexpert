// Self-checking SystemVerilog testbench for matrix2x2_mult
// RTL: rtl/matrixmult.v
// DUT: 2×2 matrix multiplier — inputs packed as 32-bit (4 × 8-bit elements)
//
// Packing convention (from RTL):
//   A[31:24]=A[0][0], A[23:16]=A[0][1], A[15:8]=A[1][0], A[7:0]=A[1][1]
//   Same for B and Res
module tb_matrixmult;

  // ------------------------------------------------------------------ ports
  logic        clk, rstn, en;
  logic [31:0] A, B;
  wire  [31:0] Res;

  int errors = 0;
  int tests  = 0;

  // ------------------------------------------------------------------ clock
  initial clk = 0;
  always  #5 clk = ~clk;

  // ------------------------------------------------------------------ DUT
  matrix2x2_mult dut (
    .clk  (clk),
    .rstn (rstn),
    .en   (en),
    .A    (A),
    .B    (B),
    .Res  (Res)
  );

  // ------------------------------------------------------------------ reference model (pure function)
  function automatic logic [31:0] mat_mult(input logic [31:0] mA, mB);
    logic [7:0] a00, a01, a10, a11;
    logic [7:0] b00, b01, b10, b11;
    logic [7:0] r00, r01, r10, r11;
    {a00, a01, a10, a11} = mA;
    {b00, b01, b10, b11} = mB;
    r00 = (a00 * b00) + (a01 * b10);
    r01 = (a00 * b01) + (a01 * b11);
    r10 = (a10 * b00) + (a11 * b10);
    r11 = (a10 * b01) + (a11 * b11);
    return {r00, r01, r10, r11};
  endfunction

  // ------------------------------------------------------------------ task
  task automatic check_result(input string msg);
    logic [31:0] expected;
    // Wait for registered output (clocked computation)
    @(posedge clk); #1;
    expected = mat_mult(A, B);
    tests++;
    if (Res !== expected) begin
      $display("[FAIL] %s | A=%08h B=%08h | exp=%08h got=%08h",
               msg, A, B, expected, Res);
      errors++;
    end else begin
      $display("[PASS] %s | Res=%08h", msg, Res);
    end
  endtask

  // ------------------------------------------------------------------ helper: pack matrix
  // pack(a00, a01, a10, a11) → 32-bit word
  function automatic logic [31:0] pack(
    input logic [7:0] m00, m01, m10, m11
  );
    return {m00, m01, m10, m11};
  endfunction

  // ------------------------------------------------------------------ stimulus
  initial begin
    rstn = 0; en = 0; A = 0; B = 0;
    #12 rstn = 1; en = 1;

    // --- Test 1: identity × identity = identity
    // I = [[1,0],[0,1]]
    A = pack(1, 0, 0, 1);
    B = pack(1, 0, 0, 1);
    check_result("I × I = I");

    // --- Test 2: all-ones matrix (from original TB: each element=1)
    A = 32'b00000001_00000001_00000001_00000001;
    B = 32'b00000001_00000001_00000001_00000001;
    // [[1,1],[1,1]] × [[1,1],[1,1]] = [[2,2],[2,2]]
    check_result("all-1s: [[1,1],[1,1]] × [[1,1],[1,1]] = [[2,2],[2,2]]");

    // --- Test 3: scalar × identity
    A = pack(3, 0, 0, 3);  // 3I
    B = pack(1, 0, 0, 1);  // I
    check_result("3I × I = 3I");

    // --- Test 4: [[2,2],[2,2]] from original TB
    A = 32'b00000010_00000010_00000010_00000010;
    B = 32'b00000010_00000010_00000010_00000010;
    check_result("all-2s: [[2,2],[2,2]] × [[2,2],[2,2]] = [[8,8],[8,8]]");

    // --- Test 5: zero matrix
    A = pack(0, 0, 0, 0);
    B = pack(5, 3, 7, 2);
    check_result("0 × B = 0");

    // --- Test 6: non-trivial case
    A = pack(1, 2, 3, 4);
    B = pack(5, 6, 7, 8);
    // [[1,2],[3,4]] × [[5,6],[7,8]] = [[19,22],[43,50]]
    check_result("[[1,2],[3,4]] × [[5,6],[7,8]] = [[19,22],[43,50]]");

    // --- Test 7: async reset
    rstn = 0;
    #2;
    tests++;
    if (Res !== 32'd0) begin
      $display("[FAIL] async reset: expected 0 got %08h", Res);
      errors++;
    end else
      $display("[PASS] async reset: Res=0x00000000");
    rstn = 1;

    // ---------------------------------------------------------------- summary
    #20;
    $display("=========================================");
    $display("  matrixmult | %0d tests | %0d error(s)", tests, errors);
    if (errors == 0)
      $display("  ALL TESTS PASSED");
    else
      $display("  SIMULATION FAILED");
    $display("=========================================");
    $finish;
  end

  // ------------------------------------------------------------------ dump
  initial begin
    $dumpfile("tb_matrixmult.vcd");
    $dumpvars(0, tb_matrixmult);
  end

endmodule
