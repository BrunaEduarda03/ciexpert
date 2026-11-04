#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include "svdpi.h"

/*
 * refmod_arbiter_step: modelo de referencia do arbiter (rtl/arbiter.v),
 * chamado via DPI-C uma vez POR CICLO DE CLOCK (nao uma vez por transacao,
 * como no Adder32/Matrix2x2), porque este DUT e sequencial: o grant de hoje
 * depende do estado interno acumulado, nao so das entradas do ciclo atual.
 *
 * O modelo mantem estado proprio (curr_state, req1_d, req2_d) em variaveis
 * estaticas de C, reproduzindo EXATAMENTE as duas maquinas de estado do RTL:
 *   1) a FSM principal (IDLE / CLIENT1 / CLIENT2);
 *   2) o "latch" de requisicao (client1_req_d / client2_req_d).
 *
 * Mesma semantica de nao-bloqueante do RTL: next_state e os proximos valores
 * de req_d sao calculados a partir do estado ANTIGO (antes da borda), e so
 * depois o estado e atualizado -- exatamente como dois always@(posedge clk)
 * separados no Verilog, que nao enxergam a atualizacao um do outro na mesma
 * borda.
 */

typedef enum { ST_IDLE = 0, ST_CLIENT1 = 1, ST_CLIENT2 = 2 } arb_state_t;

static arb_state_t curr_state = ST_IDLE;
static uint8_t req1_d = 0;
static uint8_t req2_d = 0;

void refmod_arbiter_step(
  uint8_t  reset_n,
  uint8_t  priority_sel,
  uint8_t  client1_req,
  uint8_t  client2_req,
  uint8_t *o_grant1,
  uint8_t *o_grant2
) {
  if (!reset_n) {
    curr_state = ST_IDLE;
    req1_d = 0;
    req2_d = 0;
  } else {
    arb_state_t next_state;

    /* combinational next-state logic, usa o ESTADO ANTIGO (mesma semantica
       do always@(client1_req_d, client2_req_d, curr_state, priority_sel) do RTL) */
    switch (curr_state) {
      case ST_IDLE:
        if (priority_sel && req1_d)
          next_state = ST_CLIENT1;
        else if (req2_d)
          next_state = ST_CLIENT2;
        else
          next_state = ST_IDLE;
        break;

      case ST_CLIENT1:
        next_state = req2_d ? ST_CLIENT2 : ST_IDLE;
        break;

      case ST_CLIENT2:
        next_state = req1_d ? ST_CLIENT1 : ST_IDLE;
        break;

      default:
        next_state = ST_IDLE;
        break;
    }

    /* req_d update usa o GRANT ANTIGO (derivado do curr_state ANTES desta
       borda) -- mesma semantica de race-free do RTL (2 always blocks
       separados, ambos leem o estado pre-borda) */
    uint8_t old_grant1 = (curr_state == ST_CLIENT1);
    uint8_t old_grant2 = (curr_state == ST_CLIENT2);

    uint8_t new_req1_d = req1_d;
    if (old_grant1)
      new_req1_d = 0;
    else if (client1_req)
      new_req1_d = 1;

    uint8_t new_req2_d = req2_d;
    if (old_grant2)
      new_req2_d = 0;
    else if (client2_req)
      new_req2_d = 1;

    curr_state = next_state;
    req1_d = new_req1_d;
    req2_d = new_req2_d;
  }

  *o_grant1 = (curr_state == ST_CLIENT1);
  *o_grant2 = (curr_state == ST_CLIENT2);
}
