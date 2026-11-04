# 4.4 Matrix2x2: Definition of Done

Checklist adaptado do modelo da Seção 2.3 do caderno, com referência direta à evidência de cada item. Todas as evidências abaixo são de execuções reais (`make clean && make all` com VCS X-2025.06-SP2), arquivadas em `evidence/<teste>/`.

## Como reproduzir

```bash
source /Tools/synopsys/snps.sh
cd /home/bruna.maciel/Bruna_Maciel_DV_Atividade2/matrix
make clean
make all         # roda o teste default (testname = "stimulus_modes")
make cov         # gera urgReport/ (relatório de cobertura)
make verdi_wf    # abre o Verdi com a sessao gravada (requer display X11 grafico -- ver nota abaixo)
```

Para rodar os outros dois cenários, edite `string testname = "..."` em `tb/tb_matrix.sv` (linha ~100) para `"baseline"` ou `"en_modes"` e repita `make clean && make all`. Esse é o mesmo mecanismo de seleção de teste usado no Adder32 (`adder2p0/tb/tb_adder32.sv`) — não há plusarg de runtime.

## Checklist

- [x] **Todos os cenários previstos no VP foram executados** — teste `stimulus_modes` (padrão) executa T1–T10 + D1 (agora chamado D1b no código) + os cruzamentos dirigidos D1–D4, cobrindo operação normal, reset, enable e overflow. Evidência: `evidence/stimulus_modes/simulation_log.txt`.

- [x] **Casos de valor conhecido comparados manualmente** — T1 (`BASIC`): `A=[[1,2],[3,4]]`, `B=[[5,6],[7,8]]`. Cálculo manual: `Res[0][0]=1*5+2*7=19=0x13`, `Res[0][1]=1*6+2*8=22=0x16`, `Res[1][0]=3*5+4*7=43=0x2B`, `Res[1][1]=3*6+4*8=50=0x32` → `Res=0x13162B32`. Log real confirma: `dut_r 32'h13162b32, rfm_r 32'h13162b32 / pass` (`evidence/stimulus_modes/simulation_log.txt`).

- [x] **Ambiente possui checagem automática (self-checking)** — scoreboard (`tb/matrix_scb.sv`) compara `Res` contra o reference model DPI-C em toda transação, sem depender de inspeção visual de waveform.

- [x] **Critério de comparação definido e justificado** — comparação bit-exata de 32 bits (`dut_r !== rfm_r`), latência de 1 ciclo confirmada por assertion (`p_latency_mult`), reference model reproduzindo explicitamente o truncamento de 8 bits por elemento (não há tolerância — output é discreto/determinístico).

- [x] **Principais propriedades funcionais verificadas por assertions** — `tb/matrix_assertion.sv`: `p_reset_res_stable`, `p_latency_mult`, `p_retention`. Evidência: **ASSERT coverage = 100.00%** no dashboard URG (`evidence/stimulus_modes/urgReport/dashboard.html`), sem nenhuma linha `Error` no log de simulação.

- [x] **Sinais de controle exercitados em condições normais e de borda** — `en` nos 3 modos (`EN_BURST`/`EN_DISABLE`/`EN_RANDOM`, teste `en_modes`), `rstn` em 3 pulsos (inicial + 2 dirigidos com `en` fixo em cada valor, D3/D4), overflow dirigido e não-dirigido.

- [x] **Latência medida e confirmada** — `LATENCY=1` ciclo, confirmado por `p_latency_mult` (51 matches em 70 tentativas no teste `stimulus_modes`+coverage acumulado; as demais tentativas correspondem a ciclos fora de reset sem `en=1` no ciclo anterior, portanto vácuas, não falhas) e pelas transições reais extraídas do FSDB (`evidence/stimulus_modes/fsdbreport_transitions.txt`).

- [x] **Cobertura funcional planejada atingida (100%)** — dashboard URG: `GROUP: 100.00`. Todos os 5 coverpoints (`cp_A`, `cp_B`, `cp_overflow`, `cp_en`, `cp_reset`) e os 2 crosses (`cx_overflow_en`, `cx_reset_en`) fecharam 100%. Evidência: `evidence/stimulus_modes/urgReport/grp0.html` e o screenshot `evidence/stimulus_modes/screenshots/verdi_coverage_groups_100pct.png` (mostra a aba **Groups** do relatório, com `SCORE 100.00`, `Variables 16/16` e `Crosses 8/8`, todos verdes). **Achado documentado**: `RANDOM`/`ZERO`/`MINMAX` sozinhos não garantiam fechar `cp_B=zero` (dependem de sorteio aleatório escolher esse caso específico) — foi necessário o passo dirigido **D1b** (`B=0'h00000000, A=0xDEADBEEF`) para fechar esse bin de forma determinística. Confirma na prática a lição do Capítulo 2.2.7 do caderno: *"random puro raramente fecha cobertura sozinho"*.
>
> **Atenção para não confundir na hora de olhar o Verdi**: a GUI de cobertura (`make verdi_cov`) abre por padrão na aba **Hierarchy**, que mostra `Line`/`Toggle`/`Branch`/`Condition` — isso é **cobertura de código**, não cobertura funcional, e por isso aparece abaixo de 100% ali (nesta execução: `matrix_tb SCORE=65.01`, `$unit::rtl/matrixmult... SCORE=60.85`, `Total SCORE=67.98`, `LINE=81.10`, `COND=50.00`, `TOGGLE=22.41`, `BRANCH=54.35`, `ASSERT=100.00`). O número de **100% que este item do DoD está comprovando é a cobertura FUNCIONAL (covergroup)**, que só aparece na aba **Groups** da mesma GUI, ou no arquivo `urgReport/grp0.html`. São duas métricas diferentes — 100% numa não implica 100% na outra, e o VP deste projeto usa a funcional como critério de fechamento (Seção E do `verification_plan.md`), exatamente como o caderno recomenda.

- [x] **Testes terminaram sem erros não-explicados** — `stimulus_modes`: 19/19 matches (100%), sem nenhum `Error` de assertion. `baseline`: 100/100 matches (100%). `en_modes`: 5/12 matches — os 7 mismatches são **esperados e documentados** (bloco `EN_DISABLE` dirige uma transação `RANDOM` nova a cada iteração com `en=0`; o DUT retém o `Res` anterior enquanto o `refmod` calcula o par novo — divergência intencional que comprova a retenção, mesmo padrão do teste `en_modes` do Adder32). Nenhum desses mismatches é causado por uma falha de assertion (0 `Error` nos 3 logs).

- [x] **Cenários que falharam durante o desenvolvimento foram registrados, corrigidos e reexecutados** — ver seção "Lições Aprendidas" abaixo (dois achados reais durante o desenvolvimento, ambos corrigidos e reconfirmados).

- [x] **Limitações conhecidas documentadas** — ver "Limitações Conhecidas" abaixo.

## Lições Aprendidas (achados reais durante o desenvolvimento)

### 1. Amostragem SVA *preponed* na fronteira de entrada no reset

Ao escrever `p_reset_res_stable` com a forma inicial `(!rstn) |-> $stable(Res)`, a simulação real (não hipotética) disparou uma falha de assertion no primeiro ciclo dentro de um pulso de reset dirigido (teste D4), mesmo sabendo — por leitura do RTL — que `Res` não é tocado durante `!rstn`. Investigação com `fsdbreport` (extração real das transições do sinal, sem GUI) mostrou que `Res` de fato só mudou de valor no ciclo *anterior* ao início do reset (uma escrita legítima com `en=1`), não durante o reset em si.

A causa raiz: SVA usa amostragem *preponed* — o valor "corrente" de um sinal num tick só reflete uma escrita feita naquele mesmo tick a partir do *próximo* tick em diante. Como o último ciclo antes do reset foi um ciclo de escrita válida, o primeiro tick *dentro* do reset via `$stable(Res)` comparando o valor novo (deste tick) contra o valor antigo (do tick anterior, pré-escrita) — um falso positivo de fronteira, não uma mudança real durante o reset.

**Correção**: a property passou a exigir que *ambos* os ciclos comparados já estejam em reset (`$past(!rstn) && !rstn`), não apenas o ciclo atual. Reconfirmado sem falhas após a correção (ver `tb/matrix_assertion.sv`, comentário na property).

### 2. Reset alinhado exatamente na borda de clock (mitigado por precaução, não pela causa raiz real)

Como precaução adicional (antes de identificar a causa raiz real, acima), os passos dirigidos de reset (D3/D4) tiveram a troca de `rstn` deslocada para `#1ns` depois do `@(posedge clk)`, em vez de exatamente em cima da borda — mesma técnica já usada no reset inicial deste testbench (`+$urandom_range(3,0)*1ns`) e sugerida pela análise da Atividade 8 do Adder32. Mantido no código como boa prática (evita ambiguidade de ordem de avaliação entre processos concorrentes no mesmo instante de simulação), mesmo não tendo sido a causa raiz da falha do item 1.

### 3. Estímulo aleatório sozinho não fecha cobertura

Confirmado empiricamente (não apenas por dedução teórica): rodar apenas os modos `RANDOM`/`ZERO`/`MINMAX` deixou o bin `cp_B=zero` descoberto na primeira execução completa do teste `stimulus_modes` (cada um desses modos só produz `B=0` por sorteio de 1-em-3 ou 1-em-4). Só fechou 100% depois de adicionar o passo dirigido D1b. Reproduz na prática a mesma lição da Atividade 14 do Adder32 (Seção 3.7 do caderno).

### 4. `Res` não é zerado no reset (achado sobre o DUT, não sobre o testbench)

Ver `docs/block_guide.md`, seção "Achado 2" — comportamento real e não-modificado do RTL, diferente do Adder32. Documentado, testado (`p_reset_res_stable`) e coberto (`cx_reset_en`).

## Comparação com o testbench linear (pergunta da Atividade 16 do Adder32, adaptada)

Assim como no Adder32, este ambiente transaction-based é significativamente mais fácil de manter e estender do que um testbench linear equivalente seria: os 3 cenários (`baseline`/`stimulus_modes`/`en_modes`) reaproveitam os mesmos sequencer/driver/monitor/scoreboard sem duplicar lógica de estímulo ou checagem; adicionar um novo modo de estímulo (como foi feito com `OVERFLOW`/`NO_OVERFLOW`, que não existem no Adder32) exigiu apenas um novo `case` no sequencer, sem tocar em driver/monitor/scoreboard/assertions. A cobertura funcional também tornou visível, de forma objetiva, um buraco (`cp_B=zero`) que só apareceu porque a métrica existe — num testbench linear sem cobertura, esse buraco provavelmente passaria despercebido.

## Evidência gráfica do Verdi (GUI)

Capturada com sucesso após a sessão X11 (`ssh -X` + XQuartz) ficar disponível — ver `evidence/stimulus_modes/screenshots/`:

- `verdi_waveform_overview.png`: `make verdi_wf` (script `cmd/matrix2x2.cmd`) abrindo a waveform completa do teste `stimulus_modes` — hierarquia (`matrix_tb`, `uu_matrix`, `uu_matrix_assertion`, `uu_matrix_coverage`), sinais `clk`/`rstn`/`en`/`A`/`B`/`Res`, fonte (`tb/tb_matrix.sv`) parado na linha do `$finish`, e `Time: 705,000`/`Finished: 705000ps` — batendo exatamente com o log de simulação (`evidence/stimulus_modes/simulation_log.txt`).
- `verdi_coverage_gui.png`: `verdi -cov -covdir simv.vdb` (equivalente a `make verdi_cov`), aba **Hierarchy** (a aba que abre por padrão) — mostra a **cobertura de código** (`Line`/`Toggle`/`Branch`/`Condition`) de `$unit::rtl/matrixmult.v` e `matrix_tb`. **Não é a cobertura de 100% citada no VP/DoD** — essa aba fica abaixo de 100% de propósito (ver "Limitações Conhecidas"). Serve como evidência complementar de que o banco `simv.vdb` carregou corretamente.
- `verdi_coverage_groups_100pct.png`: relatório HTML `urgReport/grp0.html` (gerado por `make cov`) aberto no navegador — mostra a aba **Groups**, com o covergroup `matrix_tb.uu_matrix_coverage::cg_matrix` em `SCORE 100.00`, `Variables 16/16` e `Crosses 8/8`, todos com contagem real de hits por bin (ex.: `cp_A` → `max=6, high=31, mid=23, low=3, zero=3`). **Esta é a evidência visual do 100% de cobertura funcional citado neste documento.**

Para reproduzir: numa sessão com X11 real (x2go ou `ssh -X` com XQuartz/VcXsrv configurado), rode `source /Tools/synopsys/snps.sh && make verdi_wf` (waveform) ou `make verdi_cov` (cobertura) dentro de `matrix/`.

## Limitações Conhecidas

- Cobertura de **código** (line/cond/toggle/branch) não atingiu 100% (nesta execução: `81.10%` / `50.00%` / `22.41%` / `54.35%` no dashboard) — isso é esperado e aceitável: o VP prioriza cobertura **funcional** (que fechou 100%), e parte do código não-coberto são ramos do próprio simulador/biblioteca padrão, não do DUT. Cobertura de toggle mais baixa é consequência de `Res1`/`A1`/`B1` serem arrays internos com bits que nunca saturam em todas as combinações possíveis dentro do orçamento de teste usado — não foi um objetivo do VP (Seção 2.2.7 do caderno: "cobertura de código alta não garante que a intenção foi verificada", e o inverso também vale: cobertura funcional alta é o critério primário aqui).
- O reference model (`dpi/refmod.c`) e a assertion `p_latency_mult` implementam a mesma aritmética de truncamento de 8 bits de forma independente (um em C, outro em SVA) — isso foi deliberado (evita que os dois "concordem" por compartilharem o mesmo código-fonte), mas ambos partem do mesmo entendimento do RTL; um erro de interpretação da spec que afete os dois igualmente não seria pego por essa dupla checagem (limitação inerente ao método, não específica deste projeto).
