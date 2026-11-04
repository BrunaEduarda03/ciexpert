/**
 * Arbiter datatypes package
 *
 * @brief : espelha a filosofia de adder32_datatypes_pkg (adder2p0), adaptada
 *          para o DUT arbiter (rtl/arbiter.v). Diferente do Adder32/Matrix2x2,
 *          o arbiter e um bloco de CONTROLE (FSM): cada "transacao" aqui e o
 *          estimulo de UM ciclo de clock (priority_sel/client1_req/client2_req),
 *          nao uma operacao aritmetica completa.
 */
package arbiter_datatypes_pkg;

  // Transacao: estimulo de 1 ciclo aplicado as entradas do arbiter.
  typedef struct packed {
    logic priority_sel;
    logic client1_req;
    logic client2_req;
  } arbiter_seq_item_t;

  // Modos de estimulo do sequencer, cobrindo os casos pedidos no enunciado:
  //   NONE     -> nenhuma requisicao
  //   ONE_C1   -> apenas uma requisicao (client1)
  //   ONE_C2   -> apenas uma requisicao (client2)
  //   BOTH     -> duas requisicoes ao mesmo tempo
  //   RANDOM   -> estimulo aleatorio
  typedef enum {
    NONE,
    ONE_C1,
    ONE_C2,
    BOTH,
    RANDOM
  } stimulus_mode_t;

endpackage: arbiter_datatypes_pkg
