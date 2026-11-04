/**
 * Arbiter Assertions
 *
 * @ref: espelha adder2p0/tb/adder32_assertion.sv (Atividade 15: reset,
 *       causalidade/latencia). Este DUT e um bloco de CONTROLE (FSM), entao
 *       assertions de estado ilegal e de transicao entram no lugar das
 *       assertions aritmeticas do Adder32 (ver Secao 6.1 do caderno:
 *       "Controle/FSM: transicoes de estado, deadlock/livelock, estados
 *       ilegais (assertions)").
 *
 * Duas assertions usam referencia hierarquica direta a sinais internos do
 * DUT (uu_arbiter.curr_state / uu_arbiter.client1_req_d / client2_req_d).
 * Isso e proposital (tecnica whitebox comum em verificacao): o estado da FSM
 * e a requisicao "travada" (req_d) nao aparecem em nenhuma porta do DUT, e
 * sem enxergar esses sinais nao da para checar "estado ilegal" nem provar
 * causalidade direta do grant.
 */
module arbiter_assertion (
  input logic clk,
  input logic reset_n,

  input logic priority_sel,
  input logic client1_req,
  input logic client2_req,

  input logic o_grant1,
  input logic o_grant2,

  // referencia hierarquica (whitebox) vinda do testbench top
  input logic [1:0] curr_state,
  input logic       client1_req_d,
  input logic       client2_req_d
);

  // Durante o reset, os grants devem estar em 0 (aqui, ao contrario do
  // Matrix2x2, o reset realmente zera a saida -- ver docs/block_guide.md).
  property p_reset_grants_zero;
    @(posedge clk)
      (reset_n === 1'b0) |-> (!o_grant1 && !o_grant2);
  endproperty

  a_reset_grants_zero: assert property (p_reset_grants_zero)
    else $error("[ASSERTION] Reset failure: o_grant1=%0b o_grant2=%0b durante reset_n=0", o_grant1, o_grant2);

  cov_reset_grants_zero: cover property (p_reset_grants_zero);

  // Mutua exclusao: os dois grants nunca podem estar altos ao mesmo tempo
  // (o DUT tem um unico registrador de estado, entao isso deveria ser
  // impossivel por construcao -- a assertion prova isso na pratica).
  property p_mutual_exclusion;
    @(posedge clk) disable iff (reset_n !== 1'b1)
      !(o_grant1 && o_grant2);
  endproperty

  a_mutual_exclusion: assert property (p_mutual_exclusion)
    else $error("[ASSERTION] Mutual exclusion failure: o_grant1 e o_grant2 altos ao mesmo tempo");

  cov_mutual_exclusion: cover property (p_mutual_exclusion);

  // Estado ilegal: a FSM so deveria assumir os valores 0 (IDLE), 1 (CLIENT1)
  // ou 2 (CLIENT2). O estado 3 nunca e atribuido no RTL, mas o registrador
  // tem 2 bits -- essa assertion prova que o estado 3 nunca e alcancado.
  property p_no_illegal_state;
    @(posedge clk) disable iff (reset_n !== 1'b1)
      curr_state inside {2'd0, 2'd1, 2'd2};
  endproperty

  a_no_illegal_state: assert property (p_no_illegal_state)
    else $error("[ASSERTION] Illegal state: curr_state=%0d", curr_state);

  cov_no_illegal_state: cover property (p_no_illegal_state);

  // Causalidade do grant1: o_grant1 so pode estar alto num ciclo se
  // client1_req_d estava setado ANTES desse ciclo (prova que o grant nao
  // "aparece do nada").
  property p_grant1_causality;
    @(posedge clk) disable iff (reset_n !== 1'b1)
      o_grant1 |-> $past(client1_req_d);
  endproperty

  a_grant1_causality: assert property (p_grant1_causality)
    else $error("[ASSERTION] Grant1 causality failure: o_grant1=1 sem client1_req_d no ciclo anterior");

  cov_grant1_causality: cover property (p_grant1_causality);

  // Causalidade do grant2 (simetrico ao grant1).
  property p_grant2_causality;
    @(posedge clk) disable iff (reset_n !== 1'b1)
      o_grant2 |-> $past(client2_req_d);
  endproperty

  a_grant2_causality: assert property (p_grant2_causality)
    else $error("[ASSERTION] Grant2 causality failure: o_grant2=1 sem client2_req_d no ciclo anterior");

  cov_grant2_causality: cover property (p_grant2_causality);

  // Preempcao: enquanto client1 esta sendo servido (o_grant1), se
  // client2_req_d chegar a 1, o proximo ciclo tem que preemptar para
  // client2, INDEPENDENTE de priority_sel (achado do Block Guide: a
  // preempcao durante o atendimento ignora priority_sel).
  property p_preempt_c1_to_c2;
    @(posedge clk) disable iff (reset_n !== 1'b1)
      (o_grant1 && client2_req_d) |=> o_grant2;
  endproperty

  a_preempt_c1_to_c2: assert property (p_preempt_c1_to_c2)
    else $error("[ASSERTION] Preemption failure: client2 nao preemptou client1 apesar de client2_req_d=1");

  cov_preempt_c1_to_c2: cover property (p_preempt_c1_to_c2);

endmodule: arbiter_assertion
