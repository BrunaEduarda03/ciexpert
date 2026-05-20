// Self-checking SystemVerilog testbench for mux8x1
// RTL: rtl/8x1mux.v
// DUT: 8-to-1 multiplexer with registered output, active-low reset, active-high enable
module tb_8x1mux;

  // ------------------------------------------------------------------ ports
  logic        clk, rstn, en;
  logic [7:0]  din;
  logic [2:0]  sel;
  wire         dout;

  int errors = 0;
  int tests  = 0;

  // ------------------------------------------------------------------ clock
  initial clk = 0;
  always  #5 clk = ~clk;

  // ------------------------------------------------------------------ DUT
  mux8x1 dut (
    .clk  (clk),
    .rstn (rstn),
    .en   (en),
    .din  (din),
    .sel  (sel),
    .dout (dout)
  );

  // ------------------------------------------------------------------ task
  task automatic check_dout(input exp, input string msg);
    @(posedge clk); #1;
    tests++;
    if (dout !== exp) begin
      $display("[FAIL] %s | sel=%0b din=%08b | exp=%0b got=%0b",
               msg, sel, din, exp, dout);
      errors++;
    end else begin
      $display("[PASS] %s | dout=%0b", msg, dout);
    end
  endtask

  // ------------------------------------------------------------------ stimulus
  initial begin
    rstn = 0; en = 0; din = 8'h00; sel = 0;
    #12 rstn = 1; en = 1;

    // --- Test 1: for each sel, set only din[sel]=1, expect dout=1
    for (int i = 0; i < 8; i++) begin
      sel    = i[2:0];
      din    = 8'(1 << i);
      check_dout(1'b1, $sformatf("sel=%0d din[%0d]=1 → dout=1", i, i));
    end

    // --- Test 2: for each sel, set only din[sel]=0, expect dout=0
    for (int i = 0; i < 8; i++) begin
      sel = i[2:0];
      din = ~(8'(1 << i)); // all bits 1 except bit i
      check_dout(1'b0, $sformatf("sel=%0d din[%0d]=0 → dout=0", i, i));
    end

    // --- Test 3: all din=0, expect dout=0
    sel = 3'b100; din = 8'h00;
    check_dout(1'b0, "all din=0 → dout=0");

    // --- Test 4: all din=1, expect dout=1
    sel = 3'b010; din = 8'hFF;
    check_dout(1'b1, "all din=1 → dout=1");

    // --- Test 5: async reset
    rstn = 0;
    #2;
    tests++;
    if (dout !== 1'b0) begin
      $display("[FAIL] async reset: expected 0 got %0b", dout);
      errors++;
    end else
      $display("[PASS] async reset: dout=0");
    rstn = 1;

    // ---------------------------------------------------------------- summary
    #20;
    $display("=========================================");
    $display("  mux8x1 | %0d tests | %0d error(s)", tests, errors);
    if (errors == 0)
      $display("  ALL TESTS PASSED");
    else
      $display("  SIMULATION FAILED");
    $display("=========================================");
    $finish;
  end

  // ------------------------------------------------------------------ dump
  initial begin
    $dumpfile("tb_8x1mux.vcd");
    $dumpvars(0, tb_8x1mux);
  end

endmodule
