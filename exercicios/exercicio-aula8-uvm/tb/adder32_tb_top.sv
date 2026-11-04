import uvm_pkg::*;
`include "uvm_macros.svh"
import adder32_pkg::*;

module adder32_tb_top();

  //
  // clk/rst gen (igual tb_adder32.sv)
  //
  localparam int CLK_PERIOD = 10ns;
  logic clk = 0;
  logic reset_n;

  always #(CLK_PERIOD/2) clk = ~clk;

  //
  // interface + DUT
  //
  adder32_if #(
    .NBW(32)
  ) uu_adder32_if (
    .clk    (clk),
    .reset_n(reset_n)
  );

  adder uu_adder (
    .clk       (clk),
    .reset_n   (reset_n),

    .en        (uu_adder32_if.en),
    .op_a      (uu_adder32_if.op_a),
    .op_b      (uu_adder32_if.op_b),

    .adder_out (uu_adder32_if.adder_out),
    .carry_out (uu_adder32_if.carry_out)
  );

  initial begin: MAIN
    repeat(70) $write("-");
    $display("\n\n[dbg] adder32_tb_top started\n");
    repeat(70) $write("-");
    $display("");

    // publica a virtual interface pro driver/monitor pegarem no build_phase
    uvm_config_db#(virtual adder32_if)::set(null, "*", "vif", uu_adder32_if);

    // reset sequence
    reset_n = 1'bx;
    #(CLK_PERIOD);
    reset_n = 1'b0;
    #(CLK_PERIOD);
    reset_n = 1'b1;

    run_test(); // +UVM_TESTNAME=baseline (default no Makefile) escolhe a classe "baseline"
  end: MAIN

endmodule
