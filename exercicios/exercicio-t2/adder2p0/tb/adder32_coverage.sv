/**
 * Adder32 Functional Coverage
 *
 * @brief: covergroup para op_a, op_b, carry_out, en e reset_n (Atividade 13),
 *         implementando os coverpoints CP1-CP9 e os crosses CP10/CP11 do
 *         mini-Verification Plan da Atividade 3.
 */
module adder32_coverage #(
  parameter int NBW = 32
)(
  input logic           clk,
  input logic           reset_n,
  input logic           en,

  input logic [NBW-1:0] op_a,
  input logic [NBW-1:0] op_b,
  input logic           carry_out
);

  covergroup cg_adder32 @(posedge clk);
    option.per_instance = 1;
    option.name = "cg_adder32";

    // CP1/CP3/CP9: faixa de valor de op_a (zero, baixo, medio, alto, maximo)
    cp_op_a: coverpoint op_a {
      bins zero   = {32'h0000_0000};
      bins low    = {[32'h0000_0001 : 32'h0000_00FF]};
      bins mid    = {[32'h0000_0100 : 32'h7FFF_FFFF]}; // "medium" e palavra reservada (trireg charge strength)
      bins high   = {[32'h8000_0000 : 32'hFFFF_FFFE]};
      bins max    = {32'hFFFF_FFFF};
    }

    // CP2/CP4/CP9: faixa de valor de op_b (zero, baixo, medio, alto, maximo)
    cp_op_b: coverpoint op_b {
      bins zero   = {32'h0000_0000};
      bins low    = {[32'h0000_0001 : 32'h0000_00FF]};
      bins mid    = {[32'h0000_0100 : 32'h7FFF_FFFF]}; // "medium" e palavra reservada (trireg charge strength)
      bins high   = {[32'h8000_0000 : 32'hFFFF_FFFE]};
      bins max    = {32'hFFFF_FFFF};
    }

    // CP5: carry_out
    cp_carry: coverpoint carry_out {
      bins no_carry = {1'b0};
      bins carry    = {1'b1};
    }

    // CP6: en (enable)
    cp_en: coverpoint en {
      bins disabled = {1'b0};
      bins enabled  = {1'b1};
    }

    // CP7: reset_n
    cp_reset: coverpoint reset_n {
      bins in_reset     = {1'b0};
      bins not_in_reset = {1'b1};
    }

    // CP10: cruzamento carry_out x en
    cx_carry_en: cross cp_carry, cp_en;

    // CP11: cruzamento reset_n x en
    cx_reset_en: cross cp_reset, cp_en;

  endgroup: cg_adder32

  cg_adder32 cg_adder32_inst = new();

endmodule: adder32_coverage
