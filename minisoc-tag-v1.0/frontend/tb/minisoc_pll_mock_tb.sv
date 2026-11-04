`timescale 1ps/1ps

module minisoc_pll_mock_tb;

  logic       i_clk_2ghz;
  logic       rst_n;
  logic       i_enable;
  logic [1:0] i_div_sel;
  logic       o_clk;
  logic       o_locked;

  minisoc_pll_mock #(
    .LOCK_MIN_CYCLES(8),
    .LOCK_MAX_CYCLES(31)
  ) dut (
    .i_clk_2ghz(i_clk_2ghz),
    .rst_n     (rst_n),
    .i_enable  (i_enable),
    .i_div_sel (i_div_sel),
    .o_clk     (o_clk),
    .o_locked  (o_locked)
  );

  // 2 GHz = 500 ps period.
  always #250 i_clk_2ghz = ~i_clk_2ghz;

  task automatic check_divider(
    input logic [1:0] div_sel,
    input time expected_period_ps
  );
    time t0;
    time t1;

    // Configure only while disabled.
    i_enable  = 1'b0;
    i_div_sel = div_sel;

    repeat (3) @(posedge i_clk_2ghz);

    if (o_locked !== 1'b0)
      $fatal(1, "PLL must be unlocked while disabled");

    if (o_clk !== 1'b0)
      $fatal(1, "System clock must be held low while PLL is disabled");

    i_enable = 1'b1;

    // Clock must remain blocked during lock acquisition.
    while (!o_locked) begin
      @(posedge i_clk_2ghz);
      #1;
      if (!o_locked && o_clk !== 1'b0)
        $fatal(1, "o_clk toggled before o_locked");
    end

    // Ignore startup edge and measure two consecutive system-clock edges.
    @(posedge o_clk);
    @(posedge o_clk);
    t0 = $time;
    @(posedge o_clk);
    t1 = $time;

    if ((t1 - t0) != expected_period_ps)
      $fatal(1,
             "Divider mismatch div_sel=%b expected_period=%0t ps measured=%0t ps",
             div_sel, expected_period_ps, (t1 - t0));

    $display("[PASS] div_sel=%b period=%0t ps", div_sel, (t1 - t0));

    i_enable = 1'b0;
    wait (o_locked == 1'b0);
    repeat (2) @(negedge i_clk_2ghz);

    if (o_clk !== 1'b0)
      $fatal(1, "o_clk must be low after disable");
  endtask

  initial begin
    i_clk_2ghz = 1'b0;
    rst_n      = 1'b0;
    i_enable   = 1'b0;
    i_div_sel  = 2'b00;

    repeat (4) @(posedge i_clk_2ghz);
    rst_n = 1'b1;

    check_divider(2'b00,  500);  // 2 GHz
    check_divider(2'b01, 1000);  // 1 GHz
    check_divider(2'b10, 2000);  // 500 MHz
    check_divider(2'b11, 4000);  // 250 MHz

    $display("[PASS] minisoc_pll_mock_tb");
    $finish;
  end

endmodule
