// Self-checking SystemVerilog testbench for encoder4x2
// RTL: rtl/encoder4x2.v
// DUT: 4-to-2 priority encoder (one-hot input → binary output)
module tb_encoder4x2;

  // ------------------------------------------------------------------ ports
  logic        clk, rstn, en;
  logic [3:0]  din;
  wire  [1:0]  dout;

  int errors = 0;
  int tests  = 0;

  // Expected mapping (one-hot input → binary code):
  // 0001 → 00, 0010 → 01, 0100 → 10, 1000 → 11
  logic [1:0] expected_map [0:3] = '{2'b00, 2'b01, 2'b10, 2'b11};
  logic [3:0] one_hot      [0:3] = '{4'b0001, 4'b0010, 4'b0100, 4'b1000};

  // ------------------------------------------------------------------ clock
  initial clk = 0;
  always  #5 clk = ~clk;

  // ------------------------------------------------------------------ DUT
  encoder4x2 dut (
    .clk  (clk),
    .rstn (rstn),
    .en   (en),
    .din  (din),
    .dout (dout)
  );

  // ------------------------------------------------------------------ task
  task automatic check_dout(input [1:0] exp, input string msg);
    @(posedge clk); #1;
    tests++;
    if (dout !== exp) begin
      $display("[FAIL] %s | din=%04b | exp=%02b got=%02b", msg, din, exp, dout);
      errors++;
    end else begin
      $display("[PASS] %s | dout=%02b", msg, dout);
    end
  endtask

  // ------------------------------------------------------------------ stimulus
  initial begin
    rstn = 0; en = 0; din = 4'b0000;
    #12 rstn = 1; en = 1;

    // --- Test 1: all four valid one-hot inputs
    for (int i = 0; i < 4; i++) begin
      din = one_hot[i];
      check_dout(expected_map[i],
                 $sformatf("one-hot din=%04b → %02b", one_hot[i], expected_map[i]));
    end

    // --- Test 2: default case (invalid input 0000 → 00)
    din = 4'b0000;
    check_dout(2'b00, "invalid din=0000 → default 00");

    // --- Test 3: async reset
    rstn = 0;
    #2;
    tests++;
    if (dout !== 2'b00) begin
      $display("[FAIL] async reset: expected 00 got %02b", dout);
      errors++;
    end else
      $display("[PASS] async reset: dout=00");
    rstn = 1;

    // --- Test 4: sweep all 4 valid inputs with enable toggle
    for (int i = 0; i < 4; i++) begin
      en  = 1;
      din = one_hot[i];
      @(posedge clk); #1; // latch result

      en  = 0;            // disable: output should freeze
      din = one_hot[(i+1)%4]; // change input while disabled
      @(posedge clk); #1;
      tests++;
      if (dout !== expected_map[i]) begin
        $display("[FAIL] en=0 freeze: expected %02b got %02b", expected_map[i], dout);
        errors++;
      end else
        $display("[PASS] en=0 freeze: dout=%02b held", dout);
    end
    en = 1;

    // ---------------------------------------------------------------- summary
    #20;
    $display("=========================================");
    $display("  encoder4x2 | %0d tests | %0d error(s)", tests, errors);
    if (errors == 0)
      $display("  ALL TESTS PASSED");
    else
      $display("  SIMULATION FAILED");
    $display("=========================================");
    $finish;
  end

  // ------------------------------------------------------------------ dump
  initial begin
    $dumpfile("tb_encoder4x2.vcd");
    $dumpvars(0, tb_encoder4x2);
  end

endmodule
