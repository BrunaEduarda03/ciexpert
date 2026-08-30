/**
 * Adder Interface
 *
 * @brief: interface definition of adder32
 * @author: gvillanovanm
 */
interface adder32_if #(
    parameter int NBW = 32
  )(
    // clock and reset are provided externally, usually by the top/testbench..
    input clk,
    input reset_n
  );

  // dut signals
  logic           en;
  logic [NBW-1:0] op_a;
  logic [NBW-1:0] op_b;
  logic [NBW-1:0] adder_out;
  logic           carry_out;

  // modport are used to define inputs/outputs...
  // ...

  // clocking blocks... useful in top-module, defines when data will be drive/monitor related to clk
  // SKEW modeling...
  // input  #0ns -> input signals would be sampled 0ns before the posedge clock
  // output #2ns -> output signals are routed 2ns after the posedge clock

  // clocking block to drive
  clocking cb_drv @(posedge clk);
		default input #0s output #2ns; // we dont have inputs here...
		output en;
    output op_a;
    output op_b;
	endclocking

  // clocking block to monitor
  clocking cb_mon @(posedge clk);
		default input #1ns output #0ns; // we dont have outputs here...
		input adder_out;
    input carry_out;
	endclocking

endinterface: adder32_if
