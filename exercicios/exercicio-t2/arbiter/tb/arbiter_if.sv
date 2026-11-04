/**
 * Arbiter Interface
 *
 * @brief: interface do arbiter (rtl/arbiter.v). Nomes de sinais preservados
 *         exatamente como no DUT: priority_sel, client1_req, client2_req,
 *         o_grant1, o_grant2, clk, reset_n.
 * @ref  : mesmos clocking blocks e mesmo raciocinio de skew do Adder32
 *         (adder2p0/tb/adder32_if.sv), confirmado empiricamente na Atividade 8.
 */
interface arbiter_if (
    // clock and reset are provided externally, usually by the top/testbench.
    input clk,
    input reset_n
  );

  // dut signals (nomes iguais aos do DUT)
  logic priority_sel;
  logic client1_req;
  logic client2_req;
  logic o_grant1;
  logic o_grant2;

  // clocking block to drive
  clocking cb_drv @(posedge clk);
    default input #0s output #2ns;
    output priority_sel;
    output client1_req;
    output client2_req;
  endclocking

  // clocking block to monitor
  clocking cb_mon @(posedge clk);
    default input #1ns output #0ns;
    input o_grant1;
    input o_grant2;
  endclocking

endinterface: arbiter_if
