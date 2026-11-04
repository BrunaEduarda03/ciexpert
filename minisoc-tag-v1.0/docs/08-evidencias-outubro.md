# 08 — Evidências de 29/10 (quinta), linha a linha

Executado neste servidor (`srv-microeletronica3`), VCS X-2025.06-SP2,
UVM-1.2, seed=1, teste `minisoc_smoke_test`.

Arquivos salvos em `verif/doc/evidencias/outubro/`:
- `minisoc_smoke_test_1.log` — log completo do run (cópia do log oficial, não regenerado)
- `waves.fsdb` — waveform FSDB (abrir com `make verdi` ou direto no Verdi)

## Compilação (`make compile`)

```
CPU time: 13.829 seconds to compile + .605 seconds to elab + 1.841 seconds to link
Verdi KDB elaboration done and the database successfully generated
```
Nenhum `Error-[...]`. Um único warning esperado (`INTFDV`, dump de VCD em
interface não suportado — não afeta o FSDB, que é outro mecanismo).

## Execução (`make run WAVES=fsdb`), explicada por trecho

```
UVM_INFO ... [minisoc_smoke_test] Configuracao: ref_clk=500 ps | mem_clk=10000 ps | reset inicial=39 ciclos
```
`env_cfg.convert2string()` — confirma que a seed=1 sorteou **39 ciclos** de
reset inicial (dentro de `[10:50]`, ver [03](03-vip-reset.md)).

```
UVM_INFO ... [clk_driver] Gerando clock: periodo=10000 ps (100.0 MHz), duty=50%, atraso=0 ps
UVM_INFO ... [clk_driver] Gerando clock: periodo=500 ps (2000.0 MHz), duty=50%, atraso=0 ps
```
Os dois `clk_agent` (mem_clk_agt e ref_clk_agt) iniciando — confirma os
períodos configurados em `minisoc_env_cfg` ([04](04-probe-env.md)).

```
UVM_INFO ... [rst_driver] rst_n=0 (reset #1) por 39 ciclos de clk     @ 0
UVM_INFO ... [rst_driver] rst_n=1 (reset #1 liberado)                 @ 20000
```
Reset inicial: assert em `t=0` (imediato, como projetado), libera em
`t=20000 ps` = 39 ciclos × 500 ps + meio ciclo de folga da borda de descida.
Bate com o cálculo esperado.

```
UVM_INFO ... [SMOKE_CLK] clk (referencia): periodo medido 500.0 ps (2000.0 MHz) - OK
UVM_INFO ... [SMOKE_CLK] mem_clk: periodo medido 10000.0 ps (100.0 MHz) - OK
```
`measure_clock()` confirmando os dois períodos com precisão exata (tolerância
configurada era ±0.5 ps e a medição bateu em cheio).

```
UVM_INFO ... [rst_driver] rst_n=0 (reset #2) por 27 ciclos de clk    @ 69000
UVM_INFO ... [rst_driver] rst_n=1 (reset #2 liberado)                @ 83000
```
Reset em runtime, disparado pelo passo 4 do T-SMOKE — outra duração sorteada
(27, dentro de `[10:30]` como o teste pede).

```
UVM_INFO ... [SMOKE] Checagens: 57 executadas, 0 falhas
UVM_INFO ... [RESULT] *** TEST PASSED: minisoc_smoke_test ***
```
Resultado final do teste — ver a quebra de 57 checks em [05](05-testes.md).

```
UVM_ERROR :    0
UVM_FATAL :    0
```
Resumo oficial do UVM report server — é essa contagem que
`minisoc_base_test.report_phase()` usa para decidir PASS/FAIL.

```
"top_assertions.sv", 48: top_tb.dut.u_sva.C01_reset_release, 185 attempts, 2 match
"top_assertions.sv", 49: top_tb.dut.u_sva.C01_reset_runtime, 185 attempts, 1 match
```
As duas `cover property` dispararam (ver [06](06-assertions-sva.md)) — prova
de que A-01/A-02a/A-03 foram exercitadas de verdade, não passaram
vacuamente.

```
==> PASS: minisoc_smoke_test seed=1  log: .../sim/logs/minisoc_smoke_test_1.log
```
Linha final impressa pelo próprio `Makefile` (`make run`), que faz o
`grep "TEST PASSED"` e decide o exit code.

## Problema encontrado e corrigido durante a execução de hoje

`make run WAVES=fsdb` **não gerava** `waves.fsdb` na primeira tentativa —
o simulador terminava normalmente (PASS), mas nenhum arquivo de waveform
aparecia, sem nenhum erro no log. Investigação (detalhada em
[07](07-makefile-vcs.md)): o `Makefile` dependia de um "auto-dump" via
plusarg (`+vcs+fsdbon`) que esta instalação do VCS não dispara sozinho; era
necessário chamar `$fsdbDumpfile`/`$fsdbDumpvars` explicitamente dentro do
`top_tb.sv`, chamada que nunca tinha sido escrita (só havia um comentário
dizendo para usar `WAVES=fsdb`). Corrigido em `top_tb.sv` e `Makefile`,
testado isoladamente com um módulo mínimo antes de aplicar no projeto real,
depois confirmado end-to-end: `waves.fsdb` gerado (17958 bytes) e Verdi
abrindo sem erro de licença.

## O que ainda falta (seu lado)

Abrir o Verdi de verdade e tirar o print mostrando `clk`, `mem_clk` e
`rst_n` com zoom em volta da liberação do reset inicial — isso só você
consegue fazer, porque precisa escolher sinais e dar zoom interativamente:

```bash
source /Tools/synopsys-scripts/snps.sh
cd minisoc-tag-v1.0/verif
make verdi
```
Dentro do Verdi: arraste `rst_n`, `ref_clk_if.clk` e `mem_clk_if.clk` (estão
em `top_tb` na árvore de hierarquia) para a janela de waveform, dê zoom em
torno de `t=20000 ps` (liberação do reset #1) e tire o print.
