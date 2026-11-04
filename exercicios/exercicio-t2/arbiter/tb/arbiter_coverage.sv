/**
 * Arbiter Functional Coverage
 *
 * @ref: espelha adder2p0/tb/adder32_coverage.sv (Atividade 13). Como este
 *       DUT e uma FSM de controle, a cobertura central e sobre ESTADOS e
 *       TRANSICOES (Secao 6.1 do caderno: "Controle/FSM: transicoes de
 *       estado"), nao faixas de valor aritmetico como no Adder32/Matrix2x2.
 *       curr_state chega por referencia hierarquica (whitebox), vinda do
 *       testbench top.
 */
module arbiter_coverage (
  input logic clk,
  input logic reset_n,

  input logic priority_sel,
  input logic client1_req,
  input logic client2_req,

  input logic [1:0] curr_state
);

  // 0=none, 1=only client1, 2=only client2, 3=both -- captura diretamente
  // os casos "nenhuma / uma / duas ou mais requisicoes" pedidos no enunciado.
  function automatic bit [1:0] f_req_combo(logic c1, logic c2);
    return {c2, c1};
  endfunction: f_req_combo

  covergroup cg_arbiter @(posedge clk);
    option.per_instance = 1;
    option.name = "cg_arbiter";

    cp_priority_sel: coverpoint priority_sel {
      bins client1_priority = {1'b1};
      bins client2_priority = {1'b0};
    }

    cp_req_combo: coverpoint f_req_combo(client1_req, client2_req) {
      bins none     = {2'b00};
      bins only_c1  = {2'b01};
      bins only_c2  = {2'b10};
      bins both     = {2'b11};
    }

    cp_state: coverpoint curr_state {
      bins idle    = {2'd0};
      bins client1 = {2'd1};
      bins client2 = {2'd2};
      illegal_bins ilegal = {2'd3};
    }

    // cruzamento estado x priority_sel: mostra se ja vimos, por exemplo,
    // o arbiter em IDLE com priority_sel=0 (cenario ligado ao achado de
    // starvation do client1 -- ver docs/block_guide.md).
    cx_state_priority: cross cp_state, cp_priority_sel;

    // cruzamento estado x combinacao de requisicoes: mostra se ja vimos
    // preempcao (ex.: estado=client1 com req_combo=both).
    cx_state_reqcombo: cross cp_state, cp_req_combo;

  endgroup: cg_arbiter

  cg_arbiter cg_arbiter_inst = new();

endmodule: arbiter_coverage
