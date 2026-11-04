# Atividade 16

## Definition of Done

Checklist avaliado com base em: (a) uma rodada de confirmação real, executada nesta sessão, com o estado atual do projeto (`testname="stimulus_modes"`, estímulos das Atividades 9/14, assertions da Atividade 8/15, cobertura funcional da Atividade 13); (b) as evidências já produzidas e arquivadas em `evidence/activity_08/` a `evidence/activity_15/`. Nenhum número abaixo foi estimado — todos vêm de log de simulação, `urgReport/*.html` (VCS `urg`) ou capturas de tela do Verdi já existentes.

| # | Item | Status | Evidência |
|---|------|--------|-----------|
| 1 | Compilação sem erros | **OK** | Rodada de confirmação desta sessão (`make clean && make all`): `0` linhas `^Error-` no log. Log completo também em `evidence/activity_08/make_all_verify_session.log` e nos logs de cada atividade subsequente. |
| 2 | Simulação executando corretamente | **OK** | Log desta sessão termina com `$finish called from file "tb/tb_adder32.sv", line 401.` / `$finish at simulation time 705000` — sem travamento, sem `$stop` inesperado. |
| 3 | Scoreboard funcionando | **OK** | `adder32_scb.sv` (Atividade 11) compara `dut_r` × `rfm_r` a cada transação e conta `adder32_scb_transactions/matches/mismatches`; `adder32_scb_report()` imprime o resumo. Rodada `"baseline"` (Atividade 11): `Transactions: 100, Matches: 100, Mismatches: 0, Pass Rate: 100.0%` (`evidence/activity_11/ATIVIDADE_11_RESPOSTA.md:227-230`). |
| 4 | Reference Model validado | **OK** | `dpi/refmod.c` corrigido na Atividade 11 (`r = a + b` com `a,b,r` em `uint64_t` para preservar o 33º bit/carry sem overflow). Validado contra o DUT nas 100/100 transações da Atividade 11 e em todas as rodadas subsequentes (nenhum mismatch de valor, só os 2 esperados de retenção — item 5). |
| 5 | Zero mismatches (ou justificar) | **OK, com justificativa documentada** | Cenário `"baseline"`: 100/100 = zero mismatches reais (Atividade 11). Cenário `"stimulus_modes"` atual (rodada desta sessão): `grep` no log mostra `17` linhas `pass` e `0` linhas `error` visíveis. As transações `D3`/`D5` (Atividade 14) são deliberadamente chamadas com `adder32_scb(dut_r, unsigned'(rfm_r), 0)` — `en_log=0` — porque comparam a saída **retida** do DUT (`en=0`) contra um Reference Model que não modela retenção; a divergência é esperada e documentada em `tb_adder32.sv` com o comentário `// mismatch esperado (retencao)`, não indica bug. Essa mesma retenção é formalmente coberta pela assertion `a_retention` (item 6), que nunca disparou. |
| 6 | Assertions implementadas | **OK** | `tb/adder32_assertion.sv`: 4 properties — `a_reset_outputs_zero` (Atividade 8), `a_latency_sum`, `a_retention`, `a_carry_causality` (Atividade 15). Nenhuma mensagem `[ASSERTION] ... failure` apareceu em nenhum log de nenhuma atividade. |
| 7 | Covers das assertions atingidos | **OK — 100%** | Log desta sessão: `cov_reset_outputs_zero` 70 attempts/5 match; `cov_latency_sum` 70/51; `cov_retention` 70/7; `cov_carry_causality` 70/51. `urgReport/asserts.html`: `Total Number: 4  Uncovered: 0  Matches: 4 -> 100.00%` (também `evidence/activity_15/ATIVIDADE_15_RESPOSTA.md`). |
| 8 | Cobertura funcional analisada | **OK — 100%** | Covergroup `cg_adder32` (`tb/adder32_coverage.sv`, Atividade 13): partiu de 72.14% com estímulo aleatório puro (Atividade 13) e fechou em **100.00%** (Variables 16/16, Crosses 8/8) após as 7 transações dirigidas D1–D7 (Atividade 14), confirmado no dashboard `urg` (`GROUP=100.00` na rodada desta sessão) e nas capturas `evidence/activity_14/screenshots/02_after_directed_100pct.png` e `03_cx_reset_en_100pct.png`. |
| 9 | Cobertura de código analisada | **OK para o DUT / Parcial no agregado do projeto** | `urgReport/modlist.html` (rodada desta sessão): módulo **`adder` (o DUT, `rtl/adder32.v`)** = `Score=100.00 Line=100.00 Toggle=100.00 Branch=100.00` (Condition/FSM vazios porque o RTL não tem essas construções). `adder32_assertion`=100.00 (Line/Toggle/Assert). `adder32_coverage`=100.00 (Toggle). O **dashboard agregado** do projeto mostra `SCORE=64.79 LINE=76.25 COND=33.33 TOGGLE=23.81 BRANCH=55.32 ASSERT=100.00 GROUP=100.00` — puxado para baixo pelo código de testbench (`adder_tb`=Score 37.82%, `$unit`=Score 52.78%) que não é 100% *nesta única rodada* porque os ramos `"baseline"` e `"en_modes"` do `case(testname)` em `tb_adder32.sv`, e o caminho de erro do scoreboard, não são exercitados quando `testname="stimulus_modes"`. Ver limitação detalhada na Conclusão. |
| 10 | Waveforms revisadas | **OK** | Capturas reais no Verdi com cursor/marker/delta conferidos manualmente: `evidence/activity_08/screenshots/` (3 imagens, reset/primeira transação), `evidence/activity_09/screenshots/` (8 modos dirigidos + RANDOM), `evidence/activity_10/screenshots/` (BURST/DISABLE/RANDOM de `en`), `evidence/activity_11/screenshots/` (`dut_r`/`rfm_r` lado a lado). |
| 11 | Todos os testes executados | **Parcial** | Os 3 cenários do `case(testname)` (`"baseline"`, `"stimulus_modes"`, `"en_modes"`) **foram cada um executado e evidenciado individualmente** em atividades distintas (`"baseline"`: Atividades 11/12; `"stimulus_modes"`: Atividades 9/13/14/15 e a rodada desta sessão; `"en_modes"`: Atividade 10) — nenhum é hipotético. A limitação real é **arquitetural**: `testname` é uma `string` fixa escolhida em tempo de compilação (`tb_adder32.sv`), então os 3 cenários nunca rodam **na mesma execução** de `./simv`; fechar isso exigiria reestruturar `tb_adder32.sv` para rodar os 3 em sequência ou via `+define`/plusarg, o que estava fora do escopo de "preservar a arquitetura" pedido em cada atividade. |
| 12 | Bugs conhecidos documentados | **OK** | (1) `dpi/refmod.c` sempre retornava `0` (variável `r` nunca somada) — identificado desde a Atividade 8, causa raiz confirmada e **corrigido** na Atividade 11. (2) Driver de `en` preso em `1'b1` — identificado, **corrigido** na Atividade 10 (`tb/adder32_drv.sv`, `en_mode_t`). (3) `Makefile` original não tinha target `clean` (só `vcs_clean`) — **corrigido** na Atividade 12 com alias `clean: vcs_clean`. Os três estão descritos com causa raiz em `evidence/activity_10/` e `evidence/activity_11/`. |
| 13 | Limitações documentadas | **OK** | (1) Item 11 acima (um `testname` por compilação). (2) `+ntb_random_seed=random` está em `VCS_DEBUG`, usado dentro de `VCS_FLAGS` no target `vcs:` (compilação) — `+ntb_random_seed` é um plusarg de **runtime**, então o VCS o ignora nesse ponto (aviso "Unknown compile time plus argument used" em todo log de compilação); o target `run:` não passa `+ntb_random_seed=<N>`, logo `make all` sozinho é determinístico (mesma seed padrão do VCS a cada rodada) — variar a seed exige passar `+ntb_random_seed=<N>` manualmente ao `./simv`, como feito na varredura de 5 seeds da Atividade 14. (3) O covergroup da Atividade 13 não criou um `coverpoint` dedicado para o modo `PATTERN`/`alt_pattern` (CP8 do mini-VP) — o estímulo `PATTERN` existe e roda (Atividade 9), mas não é amostrado como bin próprio, por não ter sido pedido no escopo daquela atividade. |

## Evidências

**Log de simulação (rodada de confirmação desta sessão, `make clean && make all`, `testname="stimulus_modes"`):**
```
$finish called from file "tb/tb_adder32.sv", line 401.
$finish at simulation time               705000
"tb/adder32_assertion.sv", 28: adder_tb.uu_adder32_assertion.cov_reset_outputs_zero, 70 attempts, 5 match
"tb/adder32_assertion.sv", 51: adder_tb.uu_adder32_assertion.cov_latency_sum, 70 attempts, 51 match
"tb/adder32_assertion.sv", 65: adder_tb.uu_adder32_assertion.cov_retention, 70 attempts, 7 match
"tb/adder32_assertion.sv", 84: adder_tb.uu_adder32_assertion.cov_carry_causality, 70 attempts, 51 match
```
`grep` de confirmação sobre o mesmo log: `17` linhas `^pass`, `0` linhas `^error`, `0` linhas `ASSERTION...failure`, `0` linhas `^Error-`.

**Cobertura de assertions (`make cov`, `urgReport/asserts.html`):**
```
Summary for Cover Properties
Total Number: 4    Uncovered: 0    Matches: 4   -> 100.00%
```

**Cobertura de código — dashboard agregado (`urgReport/dashboard.html`, rodada desta sessão):**
```
SCORE=64.79  LINE=76.25  COND=33.33  TOGGLE=23.81  BRANCH=55.32  ASSERT=100.00  GROUP=100.00
```

**Cobertura de código — por módulo (`urgReport/modlist.html`, rodada desta sessão):**
```
adder                (DUT, rtl/adder32.v)   Score=100.00  Line=100.00              Toggle=100.00  Branch=100.00
adder32_assertion     (tb/adder32_assertion.sv)  Score=100.00  Line=100.00         Toggle=100.00                 Assert=100.00
adder32_coverage      (tb/adder32_coverage.sv)   Score=100.00                      Toggle=100.00
adder32_if                                        Score=100.00                      Toggle=100.00
adder_tb              (tb/tb_adder32.sv, top)     Score=37.82   Line=79.05         Toggle=5.83    Branch=28.57
$unit                 (funções/tasks globais)     Score=52.78   Line=68.24  Cond=33.33            Branch=56.76
```
O DUT (`adder`) — o único módulo que precisa estar em 100% para o Adder32 em si ser considerado verificado — está em **Line 100%, Toggle 100%, Branch 100%**, uma melhora sobre a rodada só-`"baseline"` da Atividade 12 (Toggle 98.87%, faltavam os toggles de `en=0` e do segundo/terceiro pulso de `reset_n`), fechados justamente pelas transações D1–D7 da Atividade 14 e pelo próprio cenário `"stimulus_modes"`.

**Cobertura funcional (Atividades 13/14):** covergroup `cg_adder32` evoluiu de 72.14% (RANDOM puro) para **100.00%** (Variables 16/16, Crosses 8/8) — capturas `evidence/activity_14/screenshots/01_before_random_only.png`, `02_after_directed_100pct.png`, `03_cx_reset_en_100pct.png`.

**Scoreboard (Atividade 11, cenário `"baseline"`, 100 transações RANDOM/EN_BURST):**
```
Transactions : 100
Matches      : 100
Mismatches   : 0
Pass Rate    : 100.0 %
```

**Assertions (Atividade 15):** 4 properties, 0 falhas em toda a simulação, 4/4 cover properties atingidos com contagens reais de match (5, 51, 7, 51) — `evidence/activity_15/ATIVIDADE_15_RESPOSTA.md`, captura `evidence/activity_15/screenshots/01_asserts_tab.png`.

**Waveforms no Verdi (Atividades 8–11):** capturas reais com cursor/marker e delta conferidos contra os valores calculados manualmente — `evidence/activity_08/screenshots/`, `evidence/activity_09/screenshots/` (9 modos dirigidos), `evidence/activity_10/screenshots/` (BURST/DISABLE/RANDOM de `en`), `evidence/activity_11/screenshots/` (`dut_r` vs `rfm_r`).

**Cobertura de código no Verdi GUI (Atividade 12):** `evidence/activity_12/screenshots/` — abas Hierarchy/Line/Toggle/FSM/Condition/Branch/Assert/Statistics, todas com números batendo com o `urgReport` textual da mesma rodada.

**Cobertura funcional no Verdi GUI (Atividade 13):** `evidence/activity_13/screenshots/` — aba Groups, detalhe de `cp_op_b` e `cx_reset_en`.

## Avaliação do ambiente

**Manutenção.** No testbench linear original (Atividade 7 e anteriores), cada novo estímulo era uma sequência de atribuições e `@(posedge clk)` escritas diretamente no `initial` do topo — qualquer mudança de padrão de estímulo exigia editar `tb_adder32.sv` no meio de um bloco monolítico. No ambiente atual, estímulo e controle de `en` viraram funções isoladas (`adder32_seqr`, `adder32_drv`) parametrizadas por enum (`stimulus_mode_t`, `en_mode_t` — `tb/adder32_datatypes.sv`); adicionar o modo `PATTERN` (Atividade 9) ou o modo `EN_DISABLE` (Atividade 10) foi um `case` novo dentro de uma função existente, sem tocar em `tb_adder32.sv` além de invocar a função com o enum certo. Bugs como o do `refmod.c` (Atividade 11) e do driver de `en` (Atividade 10) ficaram isolados em um único arquivo cada, sem efeito colateral no resto do ambiente — no linear, o mesmo bug estaria espalhado por trechos repetidos de código inline.

**Reutilização.** As mesmas funções `adder32_seqr`/`adder32_drv`/`adder32_scb` são chamadas por todos os 3 cenários (`"baseline"`, `"stimulus_modes"`, `"en_modes"`) e pelas 7 transações dirigidas D1–D7 da Atividade 14 — cada transação dirigida reaproveitou `adder32_drv`/`adder32_mon`/`adder32_scb`/`refmod` sem duplicar lógica de sincronização de clock. Num testbench linear, cada cenário novo normalmente significa copiar e colar o bloco de estímulo anterior e editar valores, multiplicando o código a manter.

**Escalabilidade.** Assertions (Atividade 8/15) e covergroup (Atividade 13) observam o DUT de forma passiva, por interface, independente de qual código de estímulo está ativo — rodaram sem alteração em `"baseline"`, `"stimulus_modes"` e `"en_modes"`. Adicionar uma quarta assertion (`a_carry_causality`) não exigiu tocar em nenhum outro bloco; a soma de comportamento verificado cresceu sem crescer o acoplamento entre arquivos. Num ambiente linear, verificação adicional normalmente significa inserir `if`/`$display` de checagem manual espalhados pelo mesmo bloco de estímulo, o que não escala.

**Geração de estímulos.** O ambiente combina estímulo dirigido determinístico (modos `BASIC`/`ZERO`/`MAX`/`CARRY`/... da Atividade 9, D1–D7 da Atividade 14) com estímulo pseudoaleatório (`RANDOM`, `$urandom_range`) no mesmo `seqr`, escolhido por parâmetro — permitindo fechar coverpoints específicos (Atividade 14) sem abrir mão de aleatoriedade onde ela é suficiente (Atividade 11, 100 transações RANDOM). Um testbench linear não tem esse grau de composição: cada padrão de estímulo é código fixo, então "aleatório com fallback dirigido para os cantos" exigiria lógica ad hoc no meio do fluxo principal.

**Debug.** O scoreboard automatizado (Atividade 11) e as assertions (Atividade 15) reduzem o debug a "que transação/ciclo específico falhou" em vez de inspeção visual de forma de onda transação por transação — a diferença concreta observada nesta própria atividade: o log aponta exatamente `cov_retention: 70 attempts, 7 match` e zero `[ASSERTION] ... failure`, sem precisar abrir o Verdi para confirmar que a retenção nunca quebrou. No linear, a única forma de saber se uma transação passou seria olhar a waveform manualmente ou instrumentar `$display` ad hoc a cada rodada.

**Cobertura.** Cobertura de código (Atividade 12) e cobertura funcional (Atividade 13) só são possíveis de forma estruturada porque o ambiente tem uma superfície estável (DUT + interface) para instrumentar — o `covergroup` amostra em `@(posedge clk)` de forma totalmente desacoplada do código de estímulo. Isso permitiu identificar objetivamente (não por inspeção) exatamente quais combinações faltavam (Atividade 13: `cp_op_a`/`cp_op_b` em 40%, crosses em 25–50%) e fechar cada uma com estímulo dirigido rastreável (Atividade 14). Um testbench linear não oferece esse tipo de métrica objetiva por padrão.

**Organização.** A separação em arquivos por papel (`adder32_seqr.sv`, `adder32_drv.sv`, `adder32_mon.sv`, `adder32_scb.sv`, `adder32_coverage.sv`, `adder32_assertion.sv`, `adder32_if.sv`, `tb_adder32.sv` como orquestrador) espelha o Figura 1 do material do curso (Sequencer → Driver → Interface/BFM → DUT → Monitor → Scoreboard, com Ref. Model e Assertions/Coverage observando em paralelo) — cada arquivo tem uma responsabilidade e pode ser lido/revisado isoladamente. Um testbench linear concentra sequenciamento, geração de estímulo, verificação e (se existisse) cobertura no mesmo bloco `initial`, sem essa fronteira.

**Resposta objetiva:** sim, tecnicamente este ambiente é melhor para desenvolver e manter que o testbench linear original. A evidência concreta não é opinião — é o próprio histórico das Atividades 9–15: cada extensão (novo modo de estímulo, novo modo de `en`, scoreboard com contadores, cobertura de código, cobertura funcional, assertions temporais) foi implementada tocando apenas o arquivo/função responsável por aquele aspecto, sem reescrever ou quebrar o que já existia — a marca de uma arquitetura que escala por composição em vez de duplicação.

## Conclusão

**O DUT (`adder`, `rtl/adder32.v`) pode ser considerado verificado** com o conjunto de evidências reais reunido: reference model corrigido e validado (Atividade 11), scoreboard automatizado com 100/100 matches numa rodada dedicada (Atividade 11) e zero mismatches não-justificados em todas as demais, 4 assertions temporais sem nenhuma falha e com 100% dos cover properties atingidos (Atividade 15), cobertura funcional do covergroup em 100% (Atividade 14) e cobertura de código do próprio módulo DUT em **Line 100% / Toggle 100% / Branch 100%** (confirmado nesta sessão). Os 3 bugs reais encontrados ao longo do projeto (Reference Model sempre `0`, driver de `en` preso em `1`, `Makefile` sem `clean`) foram todos corrigidos e documentados com causa raiz.

Dois itens do checklist ficam **Parcial**, e nenhum dos dois indica um problema do DUT — ambos são limitações do **ambiente/fluxo de execução**, honestamente documentadas em vez de escondidas:

1. **Item 9 (cobertura de código, no agregado do projeto)** — o dashboard `urg` mostra `SCORE=64.79%` porque os módulos de testbench (`adder_tb`=37.82%, `$unit`=52.78%) não chegam perto de 100% *nesta rodada única*, já que os ramos `"baseline"` e `"en_modes"` do `case(testname)` e o caminho de erro do scoreboard não são exercitados quando `testname="stimulus_modes"`. **Ação para fechar**: gerar os 3 relatórios de cobertura separadamente (um `make cov` por valor de `testname`, já executado individualmente nas Atividades 10/11/12) e mesclá-los com `urg -dir simv.vdb -dir <outro>.vdb -report urgReport_merged` (recurso nativo do `urg` para merge de bancos de cobertura), sem precisar alterar nenhum arquivo de código.

2. **Item 11 (todos os testes executados em uma única rodada)** — arquitetural: `testname` é fixado em tempo de compilação, então os 3 cenários nunca coexistem numa mesma execução de `./simv`, embora cada um já tenha rodado e sido evidenciado isoladamente. **Ação para fechar**: trocar a `string testname` fixa por um plusarg (`+testname=...` lido via `$value$plusargs`) e criar um alvo de regressão no Makefile que chama `./simv` 3 vezes (uma por cenário) — mudança pequena e não-invasiva, mas que não foi feita porque cada atividade pediu explicitamente para preservar a arquitetura existente e alterar apenas o necessário para o objetivo daquela atividade específica.

Nenhuma outra pendência foi encontrada: não há bugs conhecidos sem correção, não há assertion sem cover, não há coverpoint funcional aberto, e as waveforms de todas as transações relevantes já foram revisadas manualmente no Verdi. O Adder32 está verificado; o que resta é uma melhoria de **processo de regressão** (mesclar cobertura entre cenários), não uma lacuna de verificação do hardware em si.
