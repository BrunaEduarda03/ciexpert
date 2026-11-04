# 05 — `minisoc_base_test` e `minisoc_smoke_test`

## `tb/tests/minisoc_base_test.sv` — o que todo teste herda

Responsabilidades, na ordem em que acontecem no `build_phase`:

1. Cria `env_cfg` (a config agregada, ver [04](04-probe-env.md)).
2. Busca as 4 virtual interfaces do `config_db` (`ref_clk_vif`, `mem_clk_vif`,
   `rst_vif`, `probe_vif`) — cada `get()` que falha dá `uvm_fatal` imediato,
   porque sem interface o ambiente não tem como funcionar.
3. **Randomiza o reset** (`env_cfg.rst.randomize()`) — é aqui, não dentro do
   `rst_cfg`, que a duração do reset inicial vira um número concreto para
   essa execução.
4. Chama `configure_env()` — um hook virtual vazio na base, para que testes
   derivados troquem parâmetros (ex.: um teste futuro que force
   `mem_clk.period_ps` diferente) sem reescrever o `build_phase` inteiro.
5. Publica `env_cfg` no `config_db` e cria o `env`.
6. `uvm_top.set_timeout(100us, 1)` — trava de segurança: se algo travar
   (deadlock, `wait` que nunca libera), a simulação para em 100 µs em vez de
   rodar para sempre.

`report_phase` é o que decide PASS/FAIL: conta `UVM_ERROR` + `UVM_FATAL` via
`uvm_report_server` e imprime `*** TEST PASSED ***` ou `*** TEST FAILED (N
erros) ***`. O Makefile depende exatamente dessa string (`grep "TEST
PASSED"`) para decidir o exit code — por isso nenhum teste derivado deve
sobrescrever `report_phase` sem chamar `super.report_phase()`.

## `tb/tests/minisoc_smoke_test.sv` — T-SMOKE

Estende `minisoc_base_test` e roda 4 passos no `run_phase`:

**1. Espera o reset inicial**
```systemverilog
env.rst_agt.wait_reset_done();
```

**2. Mede os dois clocks** (`measure_clock`): tira o tempo entre duas bordas
de subida consecutivas com `$realtime` e compara com `cfg.period_ps`,
tolerância de ±0.5 ps (arredondamento). Isso prova que o `clk_driver`
realmente gera o período configurado — não é um teste do RTL, é um teste do
próprio VIP.

**3. Confere os 18 defaults** (`check_defaults`), 20 ciclos depois do reset
liberar. Cada valor esperado vem do Block Guide / `minisoc_spi.sv` — por
exemplo `PLL_DIV_SEL` default é `2'b11`, não `0`, então o check reflete isso
exatamente (não é um "tudo zero" genérico).

**4. Reset em runtime**: sorteia um instante aleatório
(`$urandom_range(5,50)` ciclos de espera) e uma duração
(`$urandom_range(10,30)` ciclos), dispara `rst_agt.apply_reset()` em paralelo
com uma checagem 3 ciclos depois (`fork...join`) que confirma `rst_n==0`
*durante* o reset e que os defaults já voltaram a valer. Isso exercita a
mesma API (`apply_reset`) que o **T-RST-RUN** do VPLAN vai usar depois — o
smoke test já serve de prova de que essa API funciona.

`check_value()` compara com `!==` (não `!=`): a diferença importa porque
`!==` também pega `X`/`Z` — um sinal em `X` (não inicializado) seria
`!= 0` tanto quanto `== 0` em lógica de 2 valores, mas com `!==` um `X`
sempre falha a comparação com um valor concreto. Isso é o que garante que
"default = 0" realmente significa "é 0", não "não é X e também não é 1".

## Resultado real (log de 29/10, seed=1)

```
Checagens: 57 executadas, 0 falhas
*** TEST PASSED: minisoc_smoke_test ***
UVM_ERROR :    0
UVM_FATAL :    0
```
57 = 2 (medição de clock) + 18 (defaults após reset inicial) + 1 (rst_n
durante reset runtime) + 18 (defaults durante reset runtime) + 18 (defaults
após reset runtime) → bate exatamente com os 4 passos descritos acima.
