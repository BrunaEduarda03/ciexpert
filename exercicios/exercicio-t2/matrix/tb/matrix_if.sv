/**
 * Matrix2x2 Interface
 *
 * @brief: interface do matrix2x2_mult (rtl/matrixmult.v). Nomes de sinais
 *         preservados exatamente como no DUT: A, B, Res, en, clk, rstn
 *         (o DUT usa "rstn", nao "reset_n" como no Adder32).
 * @ref  : espelha adder2p0/tb/adder32_if.sv (mesmos clocking blocks e mesmo
 *         raciocinio de skew).
 */
interface matrix_if #(
    parameter int NBW = 32
  )(
    // clock and reset are provided externally, usually by the top/testbench.
    input clk,
    input rstn
  );

  // dut signals (nomes iguais aos do DUT)
  logic           en;
  logic [NBW-1:0] A;
  logic [NBW-1:0] B;
  logic [NBW-1:0] Res;

  // clocking block to drive
  // output #2ns -> mesma justificativa do Adder32 (adder2p0/tb/adder32_if.sv):
  // da folga em relacao a borda de posedge onde o DUT amostra A/B, evitando
  // race condition com o always@(posedge clk or negedge rstn) do RTL.
  clocking cb_drv @(posedge clk);
    default input #0s output #2ns; // we dont have inputs here...
    output en;
    output A;
    output B;
  endclocking

  // clocking block to monitor
  // input #1ns -> mesma justificativa do Adder32: amostra Res 1ns depois da
  // borda de posedge, dando tempo do valor registrado se propagar.
  clocking cb_mon @(posedge clk);
    default input #1ns output #0ns; // we dont have outputs here...
    input Res;
  endclocking

endinterface: matrix_if
