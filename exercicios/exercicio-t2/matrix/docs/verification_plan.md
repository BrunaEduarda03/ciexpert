# 4.2 Matrix2x2: Verification Plan (VP)

Segue o mesmo formato do mini-VP da Atividade 3 do caderno (Seção 2.2.2), aplicado ao `matrix2x2_mult`.

## A) Funcionalidades

| ID | Funcionalidade | Descrição | Prioridade |
|---|---|---|---|
| F1 | Multiplicação matricial | `Res = A × B` (produto de matrizes 2x2, elementos de 8 bits), registrado, latência 1 ciclo | Alta |
| F2 | Reset assíncrono | `!rstn` limpa `Res1` internamente; `Res` **retém** (não zera) — ver `docs/block_guide.md` | Alta |
| F3 | Enable / retenção | `en=0` (fora de reset) retém `Res` | Alta |
| F4 | Overflow por elemento | Soma de dois produtos de 8 bits que ultrapassa 255 é truncada para os 8 bits menos significativos, sem flag | Alta |
| F5 | Interação reset × enable | Comportamento de `Res` quando `en` e `rstn` mudam em ciclos próximos/simultâneos | Média |

## B) Cenários de Teste

| ID | Categoria | Descrição | Feature (o que cobre) |
|---|---|---|---|
| T1 | Básico | Valores fixos pequenos, conferíveis a mão (`A=[[1,2],[3,4]]`, `B=[[5,6],[7,8]]` → `Res=[[19,22],[43,50]]`) | F1 |
| T2 | Zero | `A=0` ou `B=0` (aleatório qual) | F1 |
| T3 | Máximo | Todos os elementos de `A` e `B` = `0xFF` (overflow garantido em todo `Res`) | F1, F4 |
| T4 | Overflow dirigido | `A=0xFFFF_0000`, `B=0xFF00_FF00` — overflow garantido em `Res[0][0]` independente de aleatoriedade | F4 |
| T5 | Sem overflow | Elementos ≤ `0xB` (11) — soma de produtos garantidamente ≤ 255 | F1, F4 |
| T6 | Padrão | `A=0xAAAAAAAA`, `B=0x55555555` | F1 |
| T7 | Faixa baixa | Elementos pequenos (apoio de cobertura) | F1 |
| T8 | Faixa alta | Elementos grandes (apoio de cobertura) | F1 |
| T9 | Cruzamento min/max | Combinações de `A`/`B` = 0 ou máximo | F1, F4 |
| T10 | Random | `A`/`B` totalmente aleatórios, várias transações (baseline: 100) | F1, F4 |
| T11 | EN_BURST/DISABLE/RANDOM | Varre os 3 modos do driver | F3 |
| T12 | Overflow/no-overflow retido com en=0 | Fecha cruzamento overflow × disabled | F3, F4 |
| T13 | Reset com en=0 / en=1 | Segundo e terceiro pulsos de reset com `en` fixo em cada valor | F2, F5 |
| D1 | Dirigido: B=0 | `B=0`, `A≠0` — fecha bin `cp_B=zero` que RANDOM/ZERO não garantem sozinhos | F1 |

## C) Estratégia de checagem

| ID | O que checar | Como (ref model / assertion / scoreboard) | Self-checking |
|---|---|---|---|
| C1 | `Res = A×B` (com truncamento de 8 bits por elemento) | Reference model em C via DPI-C (`dpi/refmod.c`) comparado no scoreboard (`tb/matrix_scb.sv`) | Sim |
| C2 | Latência de 1 ciclo | Assertion `p_latency_mult` (`tb/matrix_assertion.sv`), com função SVA local reproduzindo a mesma aritmética/truncamento do refmod | Sim |
| C3 | Retenção com `en=0` | Assertion `p_retention` (`$stable(Res)` quando `!en`, fora de reset) | Sim |
| C4 | Comportamento de `Res` durante reset | Assertion `p_reset_res_stable` (`Res` estável entre dois ciclos consecutivos já em reset) | Sim |
| C5 | Placar agregado (matches/mismatches) | `matrix_scb_report()` ao final da simulação | Sim |

## D) Cobertura/Coverage/Covergroup

Implementado em `tb/matrix_coverage.sv` (`covergroup cg_matrix`):

| ID | Coverpoint | Descrição | Bins | Acionado por |
|---|---|---|---|---|
| CP1 | `cp_A` | Faixa de valor de `A` | zero / low / mid / high / max | T2, T3, T7, T8, T9, T10 |
| CP2 | `cp_B` | Faixa de valor de `B` | zero / low / mid / high / max | T2, T3, T7, T8, T9, T10, **D1** |
| CP3 | `cp_overflow` | Algum elemento de `Res` estourou 8 bits (derivado de A/B) | no_overflow / overflow | T3, T4, T5, T10 |
| CP4 | `cp_en` | Estado do `en` | disabled / enabled | T11, T12 |
| CP5 | `cp_reset` | Estado do `rstn` | in_reset / not_in_reset | reset inicial + T13 |
| CP6 | `cx_overflow_en` | Cruzamento overflow × en | 4 combinações | T3+T12 (overflow×disabled), T4/T5 (×enabled) |
| CP7 | `cx_reset_en` | Cruzamento reset × en | 4 combinações | reset inicial + T13 (D3/D4) |

## E) Critérios de fechamento

| Critério | Meta | Status (evidência) |
|---|---|---|
| Cobertura funcional | 100% dos coverpoints/crosses | **100.00%** atingido no teste `stimulus_modes` — ver `evidence/stimulus_modes/urgReport/grp0.html` (aba **Groups**) e o screenshot `evidence/stimulus_modes/screenshots/verdi_coverage_groups_100pct.png`. **Não confundir com cobertura de código** (`Line`/`Toggle`/`Branch`, aba **Hierarchy** da mesma GUI) — essa é outra métrica, e fica abaixo de 100% de propósito (ver DoD, "Limitações Conhecidas") |
| Cenários do plano | Todos os T# executados | Todos executados no teste `stimulus_modes` (`evidence/stimulus_modes/simulation_log.txt`) |
| Checagens | Toda saída C# comparada | Scoreboard self-checking em todas as transações (100/100 em `baseline`, 19/19 em `stimulus_modes`) |
| Assertions | 0 falhas não-explicadas | 100% de cobertura de assertion (`ASSERT: 100.00` no dashboard URG), sem `Error` no log final |
| Mismatches esperados vs. reais | Todo mismatch justificado | O teste `stimulus_modes` fecha 100% sem nenhum mismatch (19/19). Os mismatches do teste `en_modes` (7/12) são **esperados e documentados**: bloco `EN_DISABLE` dirige uma transação `RANDOM` nova a cada iteração enquanto `en=0`, então o DUT retém o `Res` anterior e o `refmod` calcula o par novo — divergência intencional que prova a retenção (ver `docs/definition_of_done.md`) |

**Leitura correta da imagem de cobertura (para evitar confusão):**

- `evidence/stimulus_modes/screenshots/verdi_coverage_gui.png` mostra a aba **Hierarchy** (cobertura de código): `matrix_tb SCORE=65.01`, `$unit::rtl/matrixmult... SCORE=60.85`, e no dashboard `Total SCORE=67.98` com `LINE=81.10`, `COND=50.00`, `TOGGLE=22.41`, `BRANCH=54.35`, `ASSERT=100.00`.
- `evidence/stimulus_modes/screenshots/verdi_coverage_groups_100pct.png` mostra a aba **Groups** (cobertura funcional): `cg_matrix SCORE=100.00`, `Variables=16/16`, `Crosses=8/8`.
- Portanto, os **100% do VP** referem-se à cobertura **funcional** (Groups), não ao score de cobertura de código (Hierarchy).

Ver `docs/definition_of_done.md` para o checklist final com referência direta às evidências.
