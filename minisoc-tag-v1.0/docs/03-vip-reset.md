# 03 — VIP de Reset (`tb/agents/rst/`)

Arquivos: `rst_if.sv`, `rst_cfg.sv`, `rst_driver.sv`, `rst_agent.sv`, `rst_pkg.sv`.

## `rst_if.sv`

```systemverilog
interface rst_if (input logic clk);
  logic rst_n = 1'b0;
endinterface : rst_if
```

Diferente de `clk_if`, essa interface recebe `clk` como porta — o reset
precisa saber em que clock sincronizar a liberação (ver driver abaixo).
`rst_n` é ativo em nível **baixo** e começa em `0`: o DUT já nasce em reset,
que é o estado físico real (nenhum circuito nasce fora de reset).

## `rst_cfg.sv` — duração randomizada

```systemverilog
rand int unsigned assert_cycles;
constraint c_assert_cycles { assert_cycles inside {[10:50]}; }
```

Isso implementa o requisito **ST-RST-01** do VPLAN (reset inicial ≥ 10
ciclos, aqui limitado também por cima em 50 para o teste não ficar lento).
Ser `rand` com constraint, em vez de um valor fixo, é o que torna o teste
"verificação" e não só "simulação de exemplo": cada seed roda um reset de
duração diferente, forçando o ambiente a não depender de um número mágico
específico. Quem randomiza é o teste (`minisoc_base_test.build_phase`,
chamando `env_cfg.rst.randomize()`), não o `rst_cfg` sozinho.

## `rst_driver.sv` — a parte mais sutil do marco

```systemverilog
task drive_reset(int unsigned cycles);
  in_reset  = 1'b1;
  vif.rst_n = 1'b0;                 // assert IMEDIATO
  ...
  repeat (cycles) @(posedge vif.clk);
  @(negedge vif.clk);               // release na borda de DESCIDA
  vif.rst_n = 1'b1;
  in_reset  = 1'b0;
endtask
```

Duas decisões de design, cada uma com uma razão:

- **Assert imediato** (não espera borda de clock): o reset do DUT é
  assíncrono — no hardware real, o reset pode chegar a qualquer momento,
  não só em borda de clock. O VIP imita isso.
- **Release sincronizado na borda de descida**: se `rst_n` subisse exatamente
  na borda de subida de `clk`, haveria uma corrida de simulação (race) entre
  "o flip-flop vê rst_n=1" e "o flip-flop vê a borda de clock" — o resultado
  dependeria da ordem de avaliação de eventos do simulador, não do design.
  Soltar na borda de descida dá meio ciclo de folga e elimina a ambiguidade.

`drive_reset()` é chamado duas vezes no T-SMOKE: uma pelo `run_phase` (reset
de power-on) e outra, em runtime, pelo teste via `rst_agt.apply_reset(n)` —
por isso o método já foi escrito genérico (recebe `cycles` como parâmetro),
pensando no **T-RST-RUN** que usa a mesma API.

`wait_reset_done()` só retorna quando `in_reset` vira `0` — é como o teste
sincroniza "não faça nada antes do reset inicial terminar".

## `rst_agent.sv`

Mesmo padrão do `clk_agent`: busca `rst_cfg` do config_db, valida a `vif`,
cria o driver. A diferença é que `rst_agent` expõe `apply_reset()` e
`wait_reset_done()` como métodos públicos — o teste chama
`env.rst_agt.apply_reset(runtime_cycles)` diretamente. Isso é o que
`minisoc_smoke_test.sv` usa no passo 4 (reset em runtime).

## Resumo do comportamento observado no log de 29/10

```
rst_n=0 (reset #1) por 39 ciclos de clk     ← reset inicial, valor sorteado pela seed=1
rst_n=1 (reset #1 liberado)
...
rst_n=0 (reset #2) por 27 ciclos de clk     ← reset em runtime, disparado pelo teste
rst_n=1 (reset #2 liberado)
```
Ambos dentro da faixa `[10:50]` da constraint, como esperado.
