# 5 Arbiter Project

## 5.1 Arbiter: Block Guide

**O que o módulo faz**: é um árbitro entre 2 clientes. Cada cliente pede acesso (`client1_req`, `client2_req`) e o árbitro concede (`o_grant1`, `o_grant2`) o acesso a um por vez.

**Entradas/saídas**:
- `clk`, `reset_n` — clock e reset (assíncrono, ativo baixo).
- `priority_sel` — escolhe quem tem prioridade quando os dois pedem ao mesmo tempo.
- `client1_req`, `client2_req` — pedidos dos clientes.
- `o_grant1`, `o_grant2` — concessões (nunca os dois em 1 ao mesmo tempo).

**Reset**: assíncrono, ativo baixo. Zera o estado e os pedidos guardados — `o_grant1`/`o_grant2` voltam a 0.

**Prioridade**: `priority_sel` só decide quem começa a ser atendido quando o árbitro está parado (IDLE) e os dois pedem ao mesmo tempo. `priority_sel=1` → client1 ganha. `priority_sel=0` → client2 ganha.

**Achado (lendo o RTL, não é invenção)**: se `priority_sel=0` e só o client1 pedir (client2 nunca pede), o client1 **nunca é atendido** — fica preso esperando pra sempre. Isso é porque a única forma de sair do IDLE pro client1 exige `priority_sel=1`. Confirmei isso rodando a simulação de verdade (ver `evidence/stimulus_modes/simulation_log.txt`, teste de prioridade).

**Latência**: 2 ciclos de clock entre o pedido e a concessão (1 ciclo pra guardar o pedido, mais 1 ciclo pra FSM reagir). Confirmado no waveform real.

**Estados**: 3 estados — IDLE, CLIENT1, CLIENT2 (o RTL escreve "CLINET1"/"CLINET2", com as letras trocadas, mas é só o nome interno). Sem pipeline.

---

## 5.2 Verification Plan (VP)

### Funcionalidades

| ID | Funcionalidade | Prioridade |
|---|---|---|
| F1 | Conceder acesso a um cliente que pediu | Alta |
| F2 | Nunca conceder pros dois ao mesmo tempo | Alta |
| F3 | Decidir prioridade certo quando os dois pedem | Alta |
| F4 | Reset zera tudo | Alta |
| F5 | Guardar o pedido até atender (mesmo que o sinal caia) | Média |

### Casos de teste

| ID | Caso | O que verifica |
|---|---|---|
| T1 | Nenhuma requisição | grants ficam em 0 |
| T2 | Só client1 pede | client1 é atendido, latência de 2 ciclos |
| T3 | Só client2 pede | client2 é atendido |
| T4 | Os dois pedem junto | prioridade decide quem primeiro |
| T5 | Os dois pedem sem parar | alternância entre client1/client2 |
| T6 | Prioridade = 1 | client1 ganha |
| T7 | Prioridade = 0 | client2 ganha |
| T8 | Prioridade = 0, só client1 pede | client1 nunca é atendido (starvation) |
| T9 | Reset no meio de um grant | tudo volta a 0 |
| T10 | Estímulo aleatório | regressão geral (300 ciclos) |

### Como cada caso foi verificado

| Caso | Como |
|---|---|
| T1–T5, T10 | **Scoreboard** — compara o DUT com um modelo de referência em C a cada ciclo de clock |
| T6–T8 | Scoreboard + checagem manual no log (`$display` mostrando `o_grant1` esperado) |
| T9 | Scoreboard + assertion de reset |
| Todos | **Assertions**: nunca os dois grants juntos, nunca estado ilegal, grant sempre tem causa (pedido antes) |
| Todos | **Coverage**: cobre prioridade, combinação de pedidos (nenhum/um/dois) e os 3 estados da FSM |

### Critério de aprovação

- Scoreboard sem nenhum mismatch não-esperado.
- Nenhuma assertion falhou.
- Cobertura funcional em 100%.

---

## 5.3 Arquitetura do Testbench

Mesma ideia do Adder32:

```
Sequencer → Driver → Interface → DUT → Monitor → Scoreboard
```

- **Sequencer**: gera o estímulo de 1 ciclo (`priority_sel`, `client1_req`, `client2_req`).
- **Driver**: manda esse estímulo pro DUT através da interface.
- **Interface**: conecta o testbench no DUT, com os mesmos nomes de sinal do RTL.
- **DUT**: o `arbiter` de verdade.
- **Monitor**: lê `o_grant1`/`o_grant2` do DUT a cada ciclo.
- **Scoreboard**: compara o que o DUT respondeu com o que era esperado.
- **Assertions**: checam regras que sempre têm que ser verdade (nunca os dois grants juntos, nunca estado ilegal, etc).
- **Coverage**: mostra o que já foi testado (prioridade, combinações de pedido, estados da FSM).

**Diferença em relação ao Adder32**: o Adder32 é um bloco de conta (soma), então dava pra testar "uma operação por vez". O arbiter é uma FSM — o resultado de agora depende do que aconteceu antes. Por isso o "modelo de referência" (que no Adder32 era só uma soma em C) aqui é uma **FSM em C** que roda 1 vez por ciclo de clock, junto com o DUT, e o scoreboard compara os dois a cada ciclo (não só no final da operação).

---

## 5.4 Definition of Done (DoD)

- [x] RTL analisado (`rtl/arbiter.v`, sem alterar nada)
- [x] Testbench criado (`tb/`, `dpi/`, `cmd/`, seguindo a organização do Adder32)
- [x] Compilação realizada (`make clean && make all`, sem erro)
- [x] Simulação executada (VCS X-2025.06-SP2, `$finish` sem travar)
- [x] Testes básicos aprovados (nenhuma / uma / duas requisições — ver `evidence/stimulus_modes/simulation_log.txt`)
- [x] Prioridade validada (client1 ganha com `priority_sel=1`, client2 ganha com `priority_sel=0`, e o caso de starvation confirmado)
- [x] Reset validado (grants voltam a 0 durante o reset)
- [x] Scoreboard funcionando (294/294 ciclos comparados, 100% de acerto)
- [x] Assertions executadas (0 erros; todas com pelo menos 1 `cover` batido, ou seja, foram realmente testadas)
- [x] Coverage gerada (100% de cobertura **funcional** — ver print `verdi_coverage_groups_100pct.png`, aba **Groups**: `SCORE 100.00`, `Variables 9/9`, `Crosses 18/18`)
- [x] Waveforms salvas (`evidence/stimulus_modes/arbiter.fsdb` + `fsdbreport_transitions.txt`)
- [x] Evidências organizadas na pasta `evidence/` (log, fsdb, coverage report, screenshots do Verdi)

### Screenshots (em `evidence/stimulus_modes/screenshots/`)

- `verdi_waveform_overview.png` — waveform completa do Verdi, com `priority_sel`/`client1_req`/`client2_req`/`o_grant1`/`o_grant2`/`curr_state` e o código parado no `$finish`.
- `verdi_coverage_gui.png` — GUI de cobertura do Verdi na aba **Hierarchy** (abre nessa aba por padrão). Essa aba mostra **cobertura de código** (`Line`/`Toggle`/`Branch`/`Condition`), **não** é a cobertura funcional — por isso aparece bem abaixo de 100% ali (nesta execução: `Total SCORE=78.11`, `LINE=89.59`, `COND=81.82`, `TOGGLE=2.65`, `BRANCH=72.73`; já `FSM=100.00` e `ASSERT=100.00`). Isso é esperado, não é um problema (ver "Cobertura de código", abaixo).
- `verdi_coverage_groups_100pct.png` — relatório `urgReport/grp0.html` aberto no navegador, na aba **Groups** (cobertura funcional). Mostra `cg_arbiter SCORE=100.00`, `Variables 9/9`, `Crosses 18/18`, com contagem real por bin (ex.: `cp_req_combo`: `both=65`, `only_c1=78`, `only_c2=55`, `none=100`). **Esta é a evidência do 100% de cobertura funcional citado neste documento.**

### Cobertura de código (não é o mesmo que cobertura funcional)

A GUI do Verdi tem duas telas de cobertura diferentes: **Hierarchy** (cobertura de código: quantas linhas/branches/toggles do RTL rodaram) e **Groups** (cobertura funcional: os covergroups que eu escrevi). São métricas diferentes. Neste projeto, o VP usa a cobertura **funcional** como critério de fechamento (por isso "100%" no checklist acima se refere a ela), e ela fechou 100%. A cobertura de código ficou parcial (principalmente `TOGGLE=2.65%`, porque o RTL do arbiter é pequeno e boa parte dos bits nunca alterna sozinha) — isso é esperado e não faz parte do critério de aprovação deste VP.

### Bugs que encontrei e corrigi no meu próprio testbench (não no RTL)

1. **Desliguei o "checker" durante o reset**, achando que reset assíncrono não fazia parte do modelo. Errado: o modelo em C já sabe tratar reset sozinho, e desligá-lo fez ele "congelar" e dessincronizar do DUT (182 ciclos errados de uma vez). Corrigido deixando o checker sempre ligado.
2. **Monitor lendo o grant do clocking block 1 ciclo atrasado.** Descobri comparando com o `curr_state` real do DUT (lido direto, por hierarquia) e vi que o valor que eu lia sempre era o do ciclo anterior. Corrigido lendo o sinal da interface direto, sem passar pelo clocking block.
3. **Reset trocado exatamente em cima de uma borda de clock**, causando 1 comparação errada por causa de uma corrida (race) entre o meu código e o clock. Corrigido com um pequeno atraso (`#1ns`) antes de mudar o `reset_n`.

Depois desses 3 ajustes, a simulação fechou 294/294 (100%) sem nenhum erro de assertion.
