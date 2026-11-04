/**
 * Matrix2x2 Functional Coverage
 *
 * @ref: espelha adder2p0/tb/adder32_coverage.sv (Atividade 13). Os
 *       coverpoints cp_A/cp_B reaproveitam exatamente as mesmas faixas
 *       (zero/low/mid/high/max) do Adder32. cp_carry (Adder32) nao se
 *       aplica aqui (nao ha carry_out neste DUT) -- foi substituido por
 *       cp_overflow, que observa se ALGUM dos 4 elementos de Res estourou
 *       8 bits na multiplicacao (derivado de A/B, ja que o DUT nao expoe
 *       um sinal de overflow).
 */
module matrix_coverage #(
  parameter int NBW = 32
)(
  input logic           clk,
  input logic           rstn,
  input logic           en,

  input logic [NBW-1:0] A,
  input logic [NBW-1:0] B
);

  // Deteccao de overflow por elemento (apenas para fins de cobertura --
  // nao influencia o DUT). Mesma aritmetica de matrix_assertion.sv::f_expected_res,
  // mas retornando se algum produto-soma de 8 bits ultrapassou 255.
  function automatic bit f_overflow(logic [NBW-1:0] a, logic [NBW-1:0] b);
    byte unsigned a00, a01, a10, a11;
    byte unsigned b00, b01, b10, b11;
    int unsigned  p00, p01, p10, p11;

    a00 = a[31:24]; a01 = a[23:16]; a10 = a[15:8]; a11 = a[7:0];
    b00 = b[31:24]; b01 = b[23:16]; b10 = b[15:8]; b11 = b[7:0];

    p00 = (a00 * b00) + (a01 * b10);
    p01 = (a00 * b01) + (a01 * b11);
    p10 = (a10 * b00) + (a11 * b10);
    p11 = (a10 * b01) + (a11 * b11);

    return (p00 > 255) || (p01 > 255) || (p10 > 255) || (p11 > 255);
  endfunction: f_overflow

  covergroup cg_matrix @(posedge clk);
    option.per_instance = 1;
    option.name = "cg_matrix";

    // faixa de valor de A (mesmas faixas do Adder32 cp_op_a)
    cp_A: coverpoint A {
      bins zero = {32'h0000_0000};
      bins low  = {[32'h0000_0001 : 32'h0000_00FF]};
      bins mid  = {[32'h0000_0100 : 32'h7FFF_FFFF]};
      bins high = {[32'h8000_0000 : 32'hFFFF_FFFE]};
      bins max  = {32'hFFFF_FFFF};
    }

    // faixa de valor de B (mesmas faixas do Adder32 cp_op_b)
    cp_B: coverpoint B {
      bins zero = {32'h0000_0000};
      bins low  = {[32'h0000_0001 : 32'h0000_00FF]};
      bins mid  = {[32'h0000_0100 : 32'h7FFF_FFFF]};
      bins high = {[32'h8000_0000 : 32'hFFFF_FFFE]};
      bins max  = {32'hFFFF_FFFF};
    }

    // overflow por elemento (substitui cp_carry do Adder32)
    cp_overflow: coverpoint f_overflow(A, B) {
      bins no_overflow = {1'b0};
      bins overflow    = {1'b1};
    }

    // en (enable)
    cp_en: coverpoint en {
      bins disabled = {1'b0};
      bins enabled  = {1'b1};
    }

    // rstn
    cp_reset: coverpoint rstn {
      bins in_reset     = {1'b0};
      bins not_in_reset = {1'b1};
    }

    // cruzamento overflow x en (equivalente ao cx_carry_en do Adder32)
    cx_overflow_en: cross cp_overflow, cp_en;

    // cruzamento rstn x en (equivalente ao cx_reset_en do Adder32)
    cx_reset_en: cross cp_reset, cp_en;

  endgroup: cg_matrix

  cg_matrix cg_matrix_inst = new();

endmodule: matrix_coverage
