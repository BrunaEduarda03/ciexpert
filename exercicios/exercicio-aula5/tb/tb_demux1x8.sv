// Self-checking SystemVerilog testbench for demux1x8
// RTL: rtl/1x8demux.v
// DUT: 1-to-8 demultiplexer with registered output, active-low reset, active-high enable
module tb_demux1x8;

  // ------------------------------------------------------------------ ports
  logic        clk, rstn, en, din;
  logic [2:0]  sel;
  wire  [7:0]  dout;

  int errors = 0;
  int tests  = 0;

  // ------------------------------------------------------------------ clock
  initial clk = 0;
  always  #5 clk = ~clk;

  // ------------------------------------------------------------------ DUT
  demux1x8 dut (
    .clk  (clk),
    .rstn (rstn),
    .en   (en),
    .sel  (sel),
    .din  (din),
    .dout (dout)
  );

  // ------------------------------------------------------------------ task
  task automatic check_dout(input [7:0] expected, input string msg);
    @(posedge clk); #1;
    tests++;
    if (dout !== expected) begin
      $display("[FAIL] %s | sel=%0b din=%0b | exp=%08b got=%08b",
               msg, sel, din, expected, dout);
      errors++;
    end else begin
      $display("[PASS] %s | dout=%08b", msg, dout);
    end
  endtask

  // ------------------------------------------------------------------ stimulus
  initial begin
    rstn = 0; en = 0; din = 0; sel = 0;
    #12 rstn = 1; en = 1;

    // --- Test 1: each sel routes din=1 to the correct output bit
    for (int i = 0; i < 8; i++) begin
      sel = i[2:0];
      din = 1'b1;
      check_dout(8'(8'd1 << i), $sformatf("sel=%0d din=1 → dout[%0d]=1", i, i));
    end

    // --- Test 2: din=0 forces all outputs to 0 regardless of sel
    sel = 3'b011; din = 1'b0;
    check_dout(8'h00, "sel=3 din=0 → dout=0x00");

    sel = 3'b101; din = 1'b0;
    check_dout(8'h00, "sel=5 din=0 → dout=0x00");

    // --- Test 3: disable (en=0) — output should hold previous value
    // (no new latch on negedge rstn, just no update)
    // enable was 1, dout holds last value; disable doesn't matter for
    // registered output (output keeps last latched value)
    en = 0;
    sel = 3'b000; din = 1'b1;
    @(posedge clk); #1;
    tests++;
    // dout should NOT change (en=0 means case statement not entered)
    if (dout !== 8'h00) begin
      $display("[FAIL] en=0: output changed unexpectedly to %08b", dout);
      errors++;
    end else
      $display("[PASS] en=0: dout held at %08b", dout);
    en = 1;

    // --- Test 4: async reset clears all outputs
    rstn = 0;
    #2; // negedge rstn → async reset, no clock edge needed
    tests++;
    if (dout !== 8'h00) begin
      $display("[FAIL] async reset: expected 0x00 got %08b", dout);
      errors++;
    end else
      $display("[PASS] async reset: dout=0x00");
    rstn = 1;

    // ---------------------------------------------------------------- summary
    #20;
    $display("=========================================");
    $display("  demux1x8 | %0d tests | %0d error(s)", tests, errors);
    if (errors == 0)
      $display("  ALL TESTS PASSED");
    else
      $display("  SIMULATION FAILED");
    $display("=========================================");
    $finish;
  end

  // ------------------------------------------------------------------ dump
  initial begin
    $dumpfile("tb_demux1x8.vcd");
    $dumpvars(0, tb_demux1x8);
  end

endmodule
