# Atividade 12

## Alterações realizadas no Makefile

O `Makefile` original não tinha nenhuma flag de cobertura. A análise mostrou uma pista importante: o `vcs_clean` **já** listava `simv.vdb` e `vdCovLog` entre os artefatos a remover — ou seja, o autor original já previa cobertura usando os nomes padrão do VCS, mesmo sem nunca ter ligado a flag. Por isso, em vez de inventar um diretório de cobertura customizado (`-cm_dir`), a correção usa o default do VCS (`./simv.vdb`), mantendo essa convenção já existente.

Diff conceitual (nada foi removido, apenas adicionado/ajustado):

```makefile
# Atividade 12: cobertura de codigo (line/toggle/branch/condition/fsm).
# Sem -cm_dir: usa o default do VCS (./simv.vdb), que o vcs_clean abaixo ja limpava.
VCS_COV_METRICS = line+cond+fsm+branch+tgl
VCS_COV_FLAGS   = -cm $(VCS_COV_METRICS)

all: vcs run

vcs:
	vcs $(VCS_FLAGS) $(VCS_COV_FLAGS) $(PKG_FILES) $(C_FILES) $(IF_FILES) $(RTL_FILES) $(ASSERT_FILES) $(TB_FILES)

run:
	./simv +FSDB=$(BLOCK).fsdb $(VCS_COV_FLAGS)

# Atividade 12: gera o relatorio textual/HTML de cobertura (Unified Report Generator)
cov:
	urg -dir simv.vdb -report urgReport

# Atividade 12: abre o banco de cobertura (simv.vdb) na GUI de cobertura do Verdi
verdi_cov:
	verdi -cov -covdir simv.vdb

clean: vcs_clean

vcs_clean:
	rm -rf csrc *.daidir simv *.log *.key *.conf *.rc *.fsdb verdiLog/ simv.vdb vdCovLog urgReport vc_hdrs.h sysBusyPLog
```

Três coisas a notar:

1. **`vcs` e `run` receberam `$(VCS_COV_FLAGS)`**: o VCS precisa da flag `-cm` tanto na compilação (para instrumentar o design) quanto na execução do `simv` (para de fato coletar e gravar os dados no banco de cobertura). Sem a flag em `run`, o design ficaria instrumentado mas nenhum dado seria salvo.
2. **`cov` chama `urg`** (Unified Report Generator, ferramenta padrão do VCS), gerando um relatório HTML navegável em `urgReport/` — útil como relatório textual/portátil, complementar ao Verdi.
3. **`verdi_cov` é novo**, seguindo o mesmo padrão de nomenclatura já usado no projeto (`verdi_wf`, `verdi_sc`) — abre a GUI de cobertura do Verdi apontando para `simv.vdb`.
4. **`clean: vcs_clean`** foi adicionado como alias — desde a Atividade 8 o roteiro pede `make clean`, mas o Makefile só tinha `vcs_clean`. Esse alias é puramente aditivo (não renomeia nem remove `vcs_clean`) e faz o comando literal pedido pela atividade funcionar. `vcs_clean` também passou a limpar `urgReport`.

Nenhuma outra receita, variável ou arquivo do projeto foi alterado.

## Flags de cobertura utilizadas

```makefile
VCS_COV_METRICS = line+cond+fsm+branch+tgl
VCS_COV_FLAGS   = -cm $(VCS_COV_METRICS)
```

`-cm line+cond+fsm+branch+tgl` habilita simultaneamente as 5 métricas de cobertura de código do VCS:

| Métrica (`-cm`) | Aba correspondente no Verdi |
|---|---|
| `line` | Line |
| `cond` | Condition |
| `fsm` | FSM |
| `branch` | Branch |
| `tgl` | Toggle |

Não foi adicionado `+assert` porque a atividade não pede cobertura de assertions como métrica separada (o Verdi ainda mostra uma aba "Assert" pela GUI, mas ela não tem dados de asserção de cobertura vinculados à instância do DUT — só a própria existência de `adder32_assertion.sv`, que já é coberta via `line`/`tgl` normalmente).

## Explicação de cada aba do Verdi

Capturas reais da GUI (`make verdi_cov`, abrindo `simv.vdb`) confirmam cada aba abaixo — ver seção "Evidências".

- **Line**: mede se cada linha de código executável (statement) do RTL foi executada pelo menos uma vez durante a simulação. No Verdi, para `uu_adder` (instância do DUT), a categoria "Block"/"Statement" aparece em **100.00%** — as 4 linhas instrumentadas de `rtl/adder32.v` (35, 36, 38, 39) foram todas executadas.
- **Toggle**: mede se cada bit de cada sinal (porta ou sinal interno) mudou de valor nas duas direções, `0→1` e `1→0`. É a métrica mais rigorosa das cinco porque cobra atividade bit a bit, não só "a linha rodou". Para `uu_adder`, o Verdi mostra por sinal: `clk`, `op_a[31:0]`, `op_b[31:0]`, `adder_out[31:0]`, `carry_out` e `adder_reg[32:0]` em **100%**, mas `en` em **0.00%** e `reset_n` em **50.00%** (ver "Resultado obtido" para a explicação exata).
- **Branch**: mede se cada ramo de decisão (`if`/`else`, `case`) foi tomado pelo menos uma vez. Para `uu_adder`, o Verdi lista 3 branches na linha 35 (`if (!reset_n)`): o `if` (linha 36), o `else if (en)` (linha 39) e o `MISSING_ELSE` implícito (linha 40, quando `en=0` e nada é escrito) — os três aparecem **100.00%** cobertos.
- **Condition**: mede se cada termo de uma expressão booleana **composta** (`&&`, `||`) foi exercitado nos dois valores possíveis. A aba aparece **vazia** para `uu_adder` porque nenhuma das duas condições do RTL (`!reset_n`, `en`) é uma expressão composta — são testes de um único sinal, então o VCS não gera objetos de condition coverage para elas (o dado de `cond` do relatório agregado vem do lado do testbench, não do DUT).
- **FSM**: mede transições de estado de máquinas de estado (`always` com `case` sobre um registrador de estado, ou blocos reconhecidos como FSM pelo VCS). A aba aparece **vazia** para `uu_adder`, e o `urg` avisou explicitamente: `'Fsm' coverage shape is not there in the vdb`. Isso é esperado e correto: `adder32.v` é um somador registrado simples, sem nenhuma máquina de estados — não há nada para essa métrica medir neste projeto.
- **Instance** (aba "Modules" no Verdi, equivalente a "Instance"): lista cada módulo definido no design com sua pontuação agregada. Mostra `adder` (99.62%/Line 100%), `adder32_assertion` (98.57%), `adder32_if` (98.50%), `adder_tb` (19.67%/Line 24.65%) e o bloco `$unit` que agrupa as funções/tasks soltas da TB (`adder32_scb`, `adder32_seqr`, `adder32_drv`, `adder32_mon`) em 38.78%/Line 44.71%.
- **Summary** (aba "Statistics" no Verdi): mostra a tabela agregada "Design Hierarchy" com Total/Covered/Score por métrica em todo o design: Line 77/231 (33.33%), Toggle 726/3934 (18.45%), Condition 3/6 (50.00%), Branch 13/47 (27.66%), Total 819/4218, **Average 32.36%**. Também mostra "Assertion Instances"/"Assertion Definitions" vazios (nenhuma assertion virou objeto de cobertura formal) e "Cover Groups" vazio (nenhum `covergroup` foi criado no projeto até esta atividade).

## Resultado obtido

Log real da execução (`source snps.sh; make clean; make all`):

```
==============================
Simulation Summary
==============================
Transactions : 100
Matches      : 100
Mismatches   : 0
Pass Rate    : 100.0 %
==============================
$finish called from file "tb/tb_adder32.sv", line 298.
$finish at simulation time              3038000

---------------------------------------------------------------------------
VCS Coverage Metrics: during simulation line, cond, FSM, branch, tgl was monitored
---------------------------------------------------------------------------

 Coverage status: End of All Coverages ...
```

Cobertura real do banco `simv.vdb` (extraída via `make cov` / `urg`, e conferida pixel a pixel contra a GUI do Verdi — os dois batem exatamente):

### Resumo agregado (todo o design)

| Métrica | Total | Covered | Score |
|---|---|---|---|
| Line | 231 | 77 | 33.33% |
| Toggle | 3934 | 726 | 18.45% |
| FSM | — | — | (sem shapes; design não tem FSM) |
| Condition | 6 | 3 | 50.00% |
| Branch | 47 | 13 | 27.66% |
| **Total** | **4218** | **819** | **Average: 32.36%** |

### Por módulo definido

| Módulo | Score | Line | Toggle | Branch | Observação |
|---|---|---|---|---|---|
| `adder` (o DUT, `rtl/adder32.v`) | 99.62% | **100.00%** | 98.87% | **100.00%** | Praticamente fechado |
| `adder32_if` | 98.50% | — | 98.50% | — | Só toggle se aplica (interface sem lógica procedural própria) |
| `adder32_assertion` | 98.57% | — | 98.57% | — | Idem |
| `adder_tb` (top do testbench) | 19.67% | 24.65% | 5.80% | 28.57% | Baixo porque só o branch `"baseline"` rodou nesta sessão |
| `$unit` (funções soltas: scb/seqr/drv/mon) | 38.78% | 44.71% | — | 21.62% | Baixo pelo mesmo motivo — modos dirigidos da Atividade 9/10 não executaram |

### Por que a nota agregada (32.36%) é baixa mesmo o DUT estando quase 100% coberto

A causa raiz é a **mesma em todos os pontos baixos**: esta rodada de cobertura usou `testname = "baseline"` (100 transações RANDOM, `en` sempre em `EN_BURST`), que é só **um** dos três fluxos de teste que o projeto já tem prontos desde as Atividades 9 e 10 (`"stimulus_modes"` e `"en_modes"` não rodaram nesta sessão). Isso explica cada lacuna especificamente:

- **`adder32_seqr.sv` (dentro de `$unit`)**: o `case (mode)` só executou o ramo `RANDOM` — todas as linhas dos ramos `BASIC`, `ZERO`, `MAX`, `CARRY`, `NO_CARRY`, `PATTERN`, `SMALL`, `BIG`, `MINMAX` aparecem com `0/1` no relatório de linha, porque o `testname="baseline"` nunca os chama.
- **`adder32_scb.sv` (dentro de `$unit`)**: o branch de mismatch (`if (dut_r != rfm_r) ... adder32_scb_mismatches++`) nunca executou, porque a Atividade 11 corrigiu o Reference Model e o resultado real é 100/100 matches — **0 mismatches é o resultado correto**, mas do ponto de vista de cobertura de código isso deixa esse branch formalmente "não coberto".
- **`adder_tb` (topo do TB)**: os branches `"stimulus_modes"` e `"en_modes"` do `case (testname)` nunca executam quando `testname="baseline"`.
- **Toggle do sinal `en` no DUT (0.00%)**: em `EN_BURST`, `en` é sempre `1` — nunca varia dentro desta rodada, então nunca "alterna" (nem 0→1 nem 1→0 acontecem *dentro* do período medido).
- **Toggle do sinal `reset_n` no DUT (50.00%)**: `reset_n` só cai uma vez, no início (`x→0`), e sobe uma vez (`0→1`); ele nunca mais retorna a `0` depois disso nesta rodada — então só a transição `0→1` é contabilizada, faltando `1→0`.
- **`FSM` vazio**: não é uma lacuna de teste, é uma característica real do design — `adder32.v` não tem máquina de estados.
- **`Condition` vazio para o DUT**: também não é lacuna de teste — o RTL do DUT só tem condições de um único termo, então essa métrica simplesmente não se aplica a ele (o número agregado de 50% no relatório vem de expressões compostas do lado do testbench).

## Evidências

Capturas reais da GUI de cobertura do Verdi (`make verdi_cov`), salvas em `evidence/activity_12/screenshots/`:

| Arquivo | O que mostra |
|---|---|
| `00_initial.png` | Janela inicial: aba Hierarchy com os dois nós de topo, e a barra de abas Line/Toggle/FSM/Condition/Branch/Assert |
| `01_hierarchy_expanded.png` | Hierarquia expandida (`adder_tb` → `uu_adder`, `uu_adder32_assertion`, `uu_adder32_if`) e aba **Line** de `uu_adder`: Block 100.00%, Statement 100.00%, com o código-fonte real de `adder32.v` no painel central |
| `02_toggle_tab.png` | Aba **Toggle** de `uu_adder`: tabela por sinal — `en` em vermelho (0.00%), `reset_n` em amarelo (50.00%), todos os demais em verde (100.00%) |
| `03_fsm_tab.png` | Aba **FSM** de `uu_adder`: vazia — confirma visualmente que o design não tem máquina de estados |
| `04_condition_tab.png` | Aba **Condition** de `uu_adder`: vazia — confirma que o RTL do DUT não tem expressões booleanas compostas |
| `05_branch_tab.png` / `05b_branch_expanded.png` | Aba **Branch** de `uu_adder`: 100.00%, com os 3 branches da linha 35 expandidos (linha 36, linha 39, `MISSING_ELSE` linha 40) |
| `06_assert_tab.png` | Aba **Assert**: sem dados de asserção vinculados à instância `uu_adder` |
| `07_statistics_tab.png` | Aba **Statistics** (Summary): tabela agregada Design Hierarchy — Line 77/231, Toggle 726/3934, Condition 3/6, Branch 13/47, Total 819/4218, Average 32.36% — os mesmos números do relatório `urg` |
| `08_modules_instance_tab.png` | Aba **Modules** (Instance): lista de todos os módulos definidos com sua pontuação — `adder` 99.62%, `adder32_assertion` 98.57%, `adder32_if` 98.50%, `adder_tb` 19.67% |

## Conclusão

A cobertura obtida conta duas histórias diferentes que precisam ser lidas separadamente. Do lado do **DUT** (`adder`, a única coisa que de fato precisa fechar 100% para o Adder32 ser considerado verificado), o resultado já é excelente: **Line 100%**, **Branch 100%**, **Toggle 98.87%**, com **Condition** e **FSM** corretamente vazios porque o design simplesmente não tem esse tipo de construção. As únicas duas lacunas reais do DUT — o toggle de `en` (0%) e de `reset_n` (50%) — não são bugs nem buracos de verificação profundos: são consequência direta de esta rodada específica ter usado só o cenário `"baseline"` (`en` fixo em rajada, reset acionado uma única vez no início).

Do lado do **testbench**, a nota baixa (~20-38%) também não indica um problema: ela reflete código que já existe e já foi testado manualmente nas Atividades 9, 10 e 11 (os modos `stimulus_modes` e `en_modes`), mas que não rodou *nesta sessão específica* porque `testname` estava fixo em `"baseline"`.

**Estímulos necessários para fechar o que falta, sem escrever nenhum RTL ou teste novo** — bastaria rodar, na mesma sessão de cobertura (usando `-cm_dir` acumulativo do VCS, ou mesclando bancos com `urg -dir simv.vdb -dir <outro_vdb>`), os testes que **já existem**:

1. Rodar `testname = "en_modes"` (Atividade 10): o bloco `EN_DISABLE`/`EN_RANDOM` alterna `en` entre 0 e 1 — fecha o toggle de `en` no DUT e os branches/linhas do `case (testname)` associados a esse cenário.
2. Rodar `testname = "stimulus_modes"` (Atividade 9): exercita todos os ramos de `adder32_seqr` (`BASIC`, `ZERO`, `MAX`, `CARRY`, `NO_CARRY`, `PATTERN`, `SMALL`, `BIG`, `MINMAX`) que ficaram em `0/1` nesta rodada.
3. Adicionar um segundo pulso de reset no meio da simulação (`reset_n` caindo e subindo de novo depois de já estar em operação) — fecha a transição `1→0` de `reset_n` que falta no DUT. Isso corresponde exatamente ao cenário **T9/T12** do mini-Verification Plan da Atividade 3 (reset a qualquer momento, inclusive durante `en=1`), que ainda não tem um teste dedicado no projeto.
4. Um mecanismo simples de estímulo que force pelo menos um mismatch controlado (ex.: comparar contra um Reference Model propositalmente errado por um instante, ou usar `dut_r`/`rfm_r` diferentes de propósito num teste isolado) fecharia o branch de erro do scoreboard — mas isso é um teste "negativo" de infraestrutura, não um cenário funcional do DUT, então tem prioridade mais baixa.

Nenhum desses quatro pontos exige alterar o RTL nem inventar arquitetura nova — é executar, na mesma coleta de cobertura, os cenários que os próprios roteiros das Atividades 9 e 10 já implementaram, mais um teste de reset a meio da operação (T9/T12) que ainda está pendente no Verification Plan.
