# 4 Matrix2x2 Project

> Documento consolidado com as respostas da Seção 4 do caderno (Matrix2x2 Project), na mesma ordem/numeração do enunciado, pronto para colar no `.docx` final. O conteúdo completo de cada subseção também existe como arquivo próprio em `docs/` (`block_guide.md`, `verification_plan.md`, `testbench_architecture.md`, `definition_of_done.md`) — este arquivo apenas os reúne em um só lugar, na ordem do caderno.

---

## 4.1 Matrix2x2: Block Guide

### Identificação

- **DUT**: `matrix2x2_mult` (arquivo `rtl/matrixmult.v`, não modificado).
- **Função**: multiplicação de duas matrizes 2x2, com elementos de 8 bits, empacotadas em barramentos de 32 bits.
- **Classe de circuito**: aritmético/datapath (mesma classe do Adder32, ver Seção 6.1 do caderno), registrado, sem pipeline.

### Portas (nomes preservados exatamente como no RTL)

| Porta   | Direção | Largura | Descrição |
|---|---|---|---|
| `clk`   | input  | 1 bit   | clock do sistema |
| `rstn`  | input  | 1 bit   | reset assíncrono, **ativo baixo** (nome do próprio DUT — não é `reset_n` como no Adder32) |
| `en`    | input  | 1 bit   | habilita o registro do resultado |
| `A`     | input  | 32 bits | matriz 2x2 de operandos, 4 elementos de 8 bits |
| `B`     | input  | 32 bits | matriz 2x2 de operandos, 4 elementos de 8 bits |
| `Res`   | output | 32 bits | matriz 2x2 resultado, 4 elementos de 8 bits |

### Empacotamento dos elementos (confirmado no RTL)

```verilog
{A1[0][0], A1[0][1], A1[1][0], A1[1][1]} = A;  // idem para B1/B
...
Res = {Res1[0][0], Res1[0][1], Res1[1][0], Res1[1][1]};
```

Ou seja, para A, B e Res, a ordem MSB→LSB é **[0][0], [0][1], [1][0], [1][1]** (linha 0 primeiro, depois linha 1 — row-major), cada elemento com 8 bits:

- `X[31:24]` = elemento `[0][0]`
- `X[23:16]` = elemento `[0][1]`
- `X[15:8]`  = elemento `[1][0]`
- `X[7:0]`   = elemento `[1][1]`

### Comportamento funcional

O DUT calcula o produto matricial padrão 2x2: `Res = A × B` (multiplicação de matrizes, não elemento-a-elemento), onde:

```
Res[0][0] = A[0][0]*B[0][0] + A[0][1]*B[1][0]
Res[0][1] = A[0][0]*B[0][1] + A[0][1]*B[1][1]
Res[1][0] = A[1][0]*B[0][0] + A[1][1]*B[1][0]
Res[1][1] = A[1][0]*B[0][1] + A[1][1]*B[1][1]
```

- **Registrado**: `always @(posedge clk or negedge rstn)`, mesma latência do Adder32 (**LATENCY = 1** ciclo: o resultado calculado a partir de A/B amostrados no ciclo N aparece em `Res` no ciclo N+1).
- **Enable**: só atualiza `Res`/`Res1` quando `en=1` (fora de reset). Com `en=0`, `Res` **retém** o último valor — mesmo padrão do Adder32.
- **Sem pipeline**: um único estágio de registro, sem estágios intermediários.

### Achado 1 (importante): overflow silencioso por elemento

Cada elemento de `Res1[x][y]` é um `reg [7:0]` (8 bits). A soma de dois produtos de 8 bits pode chegar a `255*255 + 255*255 = 130050`, que precisa de **17 bits** para ser representado sem perda. Como o RTL atribui esse valor a um registrador de 8 bits, **os bits acima do bit 7 são truncados silenciosamente** (semântica padrão de atribuição em Verilog: trunca para os bits menos significativos, sem saturação e sem sinalizar overflow). Não existe nenhum sinal de overflow/flag exposto pelo DUT.

Isso **não é um bug introduzido por nós** — é o comportamento real e não-modificado do RTL fornecido — mas é um achado relevante de verificação: se a especificação pretendida do bloco assume que "produto de matrizes de 8 bits" deveria saturar, alertar, ou usar uma largura maior de acumulador, isso precisaria ser levantado com o time de design (mesmo raciocínio da Seção 2.1 do caderno: a spec deixa isso em aberto). Como não podemos alterar o RTL, o ambiente de verificação **modela e testa exatamente esse comportamento de truncamento** (ver `dpi/refmod.c` e `tb/matrix_assertion.sv`), em vez de assumir saturação.

### Achado 2 (importante): `Res` NÃO é zerado durante o reset

Ao contrário do Adder32 (onde `adder_out` volta a `0` durante `!reset_n`, pois é uma saída combinacional derivada do próprio registrador que é limpo no reset), o RTL do `matrix2x2_mult` só limpa o registrador **interno** `Res1` durante `!rstn`:

```verilog
always @ (posedge clk or negedge rstn)
begin
    if (!rstn) begin
        {Res1[0][0], Res1[0][1], Res1[1][0], Res1[1][1]} = 32'd0;   // Res1 zerado
    end
    else if (en) begin
        ...
        Res = {Res1[0][0], Res1[0][1], Res1[1][0], Res1[1][1]};    // Res SO e escrito aqui
    end
end
```

`Res` (a saída de fato) só é escrita dentro do ramo `else if (en)`. Durante o reset, esse ramo nunca executa, então **`Res` retém o último valor amostrado antes do reset**, em vez de ir a zero. `Res1` é zerado "por baixo dos panos", mas isso só ficaria visível em `Res` na primeira vez que `en=1` acontecer depois do reset (nesse ciclo, `Res` seria escrito com o valor de `Res1`, que nesse momento é 0 — a menos que `A`/`B` também estejam com o mesmo valor amostrado, o que faria `Res1` ser recalculado antes de `Res` ser lido).

Isso é uma divergência real de comportamento em relação ao Adder32 e está documentada, testada por assertion (`tb/matrix_assertion.sv::p_reset_res_stable`) e coberta por cobertura funcional (`cx_reset_en`). Ver "Lições Aprendidas" em 4.4 para a discussão de uma armadilha de amostragem SVA (*preponed sampling*) descoberta ao escrever essa assertion.

### Resumo para o Verification Plan

| Item | Valor |
|---|---|
| Latência | 1 ciclo |
| Pipeline | Não |
| Reset | Assíncrono, ativo baixo (`rstn`); zera só `Res1` internamente, `Res` retém |
| Enable | Retém `Res` quando `en=0` (fora de reset) |
| Overflow | Truncamento silencioso por elemento (8 bits), sem flag |
| Largura A/B/Res | 32 bits (4 elementos × 8 bits) |

---

## 4.2 Verification Plan (VP)

Segue o mesmo formato do mini-VP da Atividade 3 do caderno (Seção 2.2.2), aplicado ao `matrix2x2_mult`.

### A) Funcionalidades

| ID | Funcionalidade | Descrição | Prioridade |
|---|---|---|---|
| F1 | Multiplicação matricial | `Res = A × B` (produto de matrizes 2x2, elementos de 8 bits), registrado, latência 1 ciclo | Alta |
| F2 | Reset assíncrono | `!rstn` limpa `Res1` internamente; `Res` **retém** (não zera) — ver 4.1 | Alta |
| F3 | Enable / retenção | `en=0` (fora de reset) retém `Res` | Alta |
| F4 | Overflow por elemento | Soma de dois produtos de 8 bits que ultrapassa 255 é truncada para os 8 bits menos significativos, sem flag | Alta |
| F5 | Interação reset × enable | Comportamento de `Res` quando `en` e `rstn` mudam em ciclos próximos/simultâneos | Média |

### B) Cenários de Teste

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

### C) Estratégia de checagem

| ID | O que checar | Como (ref model / assertion / scoreboard) | Self-checking |
|---|---|---|---|
| C1 | `Res = A×B` (com truncamento de 8 bits por elemento) | Reference model em C via DPI-C (`dpi/refmod.c`) comparado no scoreboard (`tb/matrix_scb.sv`) | Sim |
| C2 | Latência de 1 ciclo | Assertion `p_latency_mult` (`tb/matrix_assertion.sv`), com função SVA local reproduzindo a mesma aritmética/truncamento do refmod | Sim |
| C3 | Retenção com `en=0` | Assertion `p_retention` (`$stable(Res)` quando `!en`, fora de reset) | Sim |
| C4 | Comportamento de `Res` durante reset | Assertion `p_reset_res_stable` (`Res` estável entre dois ciclos consecutivos já em reset) | Sim |
| C5 | Placar agregado (matches/mismatches) | `matrix_scb_report()` ao final da simulação | Sim |

### D) Cobertura/Coverage/Covergroup

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

### E) Critérios de fechamento

| Critério | Meta | Status (evidência) |
|---|---|---|
| Cobertura funcional | 100% dos coverpoints/crosses | **100.00%** atingido no teste `stimulus_modes` — ver `evidence/stimulus_modes/urgReport/grp0.html` (aba **Groups**) e `evidence/stimulus_modes/screenshots/verdi_coverage_groups_100pct.png`. Não confundir com cobertura de código (aba **Hierarchy**, `Line`/`Toggle`/`Branch`), que é outra métrica e fica abaixo de 100% de propósito |
| Cenários do plano | Todos os T# executados | Todos executados no teste `stimulus_modes` (`evidence/stimulus_modes/simulation_log.txt`) |
| Checagens | Toda saída C# comparada | Scoreboard self-checking em todas as transações (100/100 em `baseline`, 19/19 em `stimulus_modes`) |
| Assertions | 0 falhas não-explicadas | 100% de cobertura de assertion (`ASSERT: 100.00` no dashboard URG), sem `Error` no log final |
| Mismatches esperados vs. reais | Todo mismatch justificado | O teste `stimulus_modes` fecha 100% sem nenhum mismatch (19/19). Os mismatches do teste `en_modes` (7/12) são **esperados e documentados**: bloco `EN_DISABLE` dirige uma transação `RANDOM` nova a cada iteração enquanto `en=0`, então o DUT retém o `Res` anterior e o `refmod` calcula o par novo — divergência intencional que prova a retenção (ver 4.4) |

---

## 4.3 Arquitetura do testbench

A base é a mesma da Figura 1 do caderno (arquétipo do Adder32): sequencer → driver → interface (BFM) → DUT → monitor → scoreboard, com reference model (DPI-C) alimentando o scoreboard e assertions + coverage observando a interface diretamente. Nenhum bloco foi removido; o que muda em relação ao Adder32 é só o conteúdo interno de cada bloco (adaptado à semântica de matriz 2x2), como esperado pela Seção 6.1 do caderno ("o arquétipo se mantém, mas o conteúdo de cada bloco é dependente da classe do DUT").

```
transaction-based domain
                                   Scoreboard  <---- expected data ---- Ref. Model (DPI-C, dpi/refmod.c)
                                        ^
                                        | RTL data
Sequencer --data in--> matrix_seq_item_t
      |
      v
   Driver (tb/matrix_drv.sv) --cb_drv--> Interface (matrix_if) --> DUT (matrix2x2_mult) --> Interface --cb_mon--> Monitor (tb/matrix_mon.sv)
      |                                                                  |
      v                                                                  v
  Coverage (tb/matrix_coverage.sv)                              Assertions (tb/matrix_assertion.sv)
device domain
```

### Sequencer (`tb/matrix_seqr.sv`)

Function `matrix_seqr(mode, en_log)` que retorna uma `matrix_seq_item_t` (struct packed com `a`/`b` de 32 bits). Não usa classes — segue a mesma filosofia "transação ≠ classe" do Capítulo 2.2.4 do caderno. Os modos (`stimulus_mode_t`, definidos em `tb/matrix_datatypes.sv`) cobrem os cenários T1–T10 e D1 do Verification Plan: `BASIC`, `ZERO`, `MAX`, `OVERFLOW`, `NO_OVERFLOW`, `PATTERN`, `SMALL`, `BIG`, `MINMAX`, `RANDOM`.

- **Recebe**: modo de estímulo (enum) + flag de log.
- **Produz**: uma transação (`matrix_seq_item_t`) com `A`/`B` já empacotados nos 4 elementos de 8 bits, prontos para o driver.

### Driver (`tb/matrix_drv.sv`)

Task `matrix_drv(vif, seq_item, en_mode, en_log)`. Sincroniza com `@(posedge vif.clk)` e escreve `en`/`A`/`B` via clockvar (`vif.cb_drv.*`), respeitando o skew de saída do clocking block (`output #2ns`). O modo de `en` (`en_mode_t`: `EN_RANDOM`/`EN_BURST`/`EN_DISABLE`) permite exercitar retenção (F3 do VP) sem precisar de um segundo sequencer.

- **Recebe**: transação + modo de `en`.
- **Produz**: sinais físicos `en`/`A`/`B` na interface, defasados 2ns da borda em que sincronizou (evita race com o `always@(posedge clk or negedge rstn)` do DUT — mesmo raciocínio comprovado empiricamente na Atividade 8 do Adder32).

### Monitor (`tb/matrix_mon.sv`)

Task `matrix_mon(vif, dut_r, en_log)`. Espera 2 bordas de `posedge clk` + 3ns (mesmo padrão do Adder32, validado empiricamente na Atividade 8: dá margem suficiente para o clocking block de monitor já ter amostrado o valor estável) e lê `Res` via `vif.cb_mon.Res` (input skew `#1ns`).

- **Recebe**: referência à interface (via `vif`).
- **Produz**: `dut_r` (32 bits), o valor de `Res` observado para aquela transação.

### Interface / BFM (`tb/matrix_if.sv`)

Declara os sinais do DUT com os **mesmos nomes do RTL** (`en`, `A`, `B`, `Res`; clock/reset são portas da própria interface: `clk`, `rstn`). Dois clocking blocks:

- `cb_drv`: `output #2ns` para `en`/`A`/`B` — o driver escreve aqui.
- `cb_mon`: `input #1ns` para `Res` — o monitor lê aqui.

Mesma justificativa de skew do Adder32 (Atividade 8): o output skew de 2ns dá folga de 8ns (num período de 10ns) antes da próxima borda, evitando que o DUT amostre um valor de `A`/`B` em transição; o input skew de 1ns garante que o clocking block de monitor só amostra `Res` depois que ele já está estável. **Ponto onde a arquitetura foi adaptada** em relação ao Adder32: os nomes de sinal na interface seguem o RTL do Matrix2x2 (`A`, `B`, `Res`, `rstn`), não os nomes do Adder32 (`op_a`, `op_b`, `adder_out`, `reset_n`).

### Reference Model (`dpi/refmod.c`, função `refmod_matrix`)

Modelo de referência em C, chamado via DPI-C (mesmo padrão do Adder32 — ver Atividade 5c do caderno). Recebe `A`/`B` como `uint64_t` (mas usa só os 32 bits relevantes), desempacota os 4 elementos de 8 bits, calcula os 4 produtos-soma e **trunca cada resultado para 8 bits** (`& 0xFF`), reproduzindo bit-a-bit a semântica de truncamento do RTL (`reg [7:0]`) em vez de saturar. **Adaptação em relação ao Adder32**: o refmod do Adder32 apenas somava dois operandos de 32 bits; aqui a aritmética é bem mais rica (produto matricial + truncamento por elemento), refletindo a mudança de classe funcional do bloco.

### Scoreboard (`tb/matrix_scb.sv`)

Função `matrix_scb(dut_r, rfm_r, en_log)`: compara `Res` observado pelo monitor com o valor calculado pelo reference model, contabiliza matches/mismatches/total, e `matrix_scb_report()` imprime o placar final — mesmo padrão do Adder32 pós-Atividade 11.

### Assertions (`tb/matrix_assertion.sv`)

Três properties (SVA), mesma filosofia da Atividade 15 do Adder32 — mas **sem** equivalente a `p_carry_causality`, pois este DUT não tem sinal de carry (adaptação: uma assertion a menos que o Adder32, porque a funcionalidade que ela checava não existe neste DUT):

1. `p_reset_res_stable`: durante o reset (dois ciclos consecutivos já em `!rstn`), `Res` deve permanecer estável — reflete o achado real de que este RTL **retém** `Res` durante reset (não zera, ver 4.1). Exige `$past(!rstn) && !rstn` (não apenas `!rstn`) para evitar um falso positivo de amostragem *preponed* na fronteira de entrada no reset — ver "Lições Aprendidas" em 4.4.
2. `p_latency_mult`: 1 ciclo depois de `en=1` amostrado (fora de reset), `Res` deve bater com o modelo de referência local em SVA (mesma aritmética/truncamento do `refmod.c`).
3. `p_retention`: com `en=0` (fora de reset), `Res` deve permanecer estável no ciclo seguinte.

Cada `assert property` tem um `cover property` irmão, seguindo a orientação do caderno (Seção 2.2.8: "se a assertion não disparar, isso não significa que está tudo certo — pode ser que a condição nunca tenha sido estimulada").

### Coverage (`tb/matrix_coverage.sv`)

`covergroup cg_matrix`, amostrado em `@(posedge clk)`, com os coverpoints `cp_A`/`cp_B` (mesmas faixas do Adder32: zero/low/mid/high/max), `cp_overflow` (**adaptação**: substitui `cp_carry` do Adder32 — deriva se algum elemento de `Res` estourou 8 bits, já que este DUT não expõe flag de overflow), `cp_en`, `cp_reset`, e os cruzamentos `cx_overflow_en`/`cx_reset_en` (equivalentes a `cx_carry_en`/`cx_reset_en` do Adder32).

---

## 4.4 DoD com evidências

Checklist adaptado do modelo da Seção 2.3 do caderno, com referência direta à evidência de cada item. Todas as evidências abaixo são de execuções reais (`make clean && make all` com VCS X-2025.06-SP2), arquivadas em `evidence/<teste>/`.

### Como reproduzir

```bash
source /Tools/synopsys/snps.sh
cd /home/bruna.maciel/Bruna_Maciel_DV_Atividade2/matrix
make clean
make all         # roda o teste default (testname = "stimulus_modes")
make cov         # gera urgReport/ (relatório de cobertura)
make verdi_wf    # abre o Verdi com a sessao gravada (requer display X11 grafico)
```

Para rodar os outros dois cenários, edite `string testname = "..."` em `tb/tb_matrix.sv` (linha ~100) para `"baseline"` ou `"en_modes"` e repita `make clean && make all`. Mesmo mecanismo de seleção de teste usado no Adder32 (`adder2p0/tb/tb_adder32.sv`) — não há plusarg de runtime.

### Checklist

- [x] **Todos os cenários previstos no VP foram executados** — teste `stimulus_modes` (padrão) executa T1–T10 + D1 (chamado D1b no código) + os cruzamentos dirigidos D1–D4, cobrindo operação normal, reset, enable e overflow. Evidência: `evidence/stimulus_modes/simulation_log.txt`.

- [x] **Casos de valor conhecido comparados manualmente** — T1 (`BASIC`): `A=[[1,2],[3,4]]`, `B=[[5,6],[7,8]]`. Cálculo manual: `Res[0][0]=1*5+2*7=19=0x13`, `Res[0][1]=1*6+2*8=22=0x16`, `Res[1][0]=3*5+4*7=43=0x2B`, `Res[1][1]=3*6+4*8=50=0x32` → `Res=0x13162B32`. Log real confirma: `dut_r 32'h13162b32, rfm_r 32'h13162b32 / pass` (`evidence/stimulus_modes/simulation_log.txt`).

- [x] **Ambiente possui checagem automática (self-checking)** — scoreboard (`tb/matrix_scb.sv`) compara `Res` contra o reference model DPI-C em toda transação, sem depender de inspeção visual de waveform.

- [x] **Critério de comparação definido e justificado** — comparação bit-exata de 32 bits (`dut_r !== rfm_r`), latência de 1 ciclo confirmada por assertion (`p_latency_mult`), reference model reproduzindo explicitamente o truncamento de 8 bits por elemento (não há tolerância — output é discreto/determinístico).

- [x] **Principais propriedades funcionais verificadas por assertions** — `tb/matrix_assertion.sv`: `p_reset_res_stable`, `p_latency_mult`, `p_retention`. Evidência: **ASSERT coverage = 100.00%** no dashboard URG (`evidence/stimulus_modes/urgReport/dashboard.html`), sem nenhuma linha `Error` no log de simulação.

- [x] **Sinais de controle exercitados em condições normais e de borda** — `en` nos 3 modos (`EN_BURST`/`EN_DISABLE`/`EN_RANDOM`, teste `en_modes`), `rstn` em 3 pulsos (inicial + 2 dirigidos com `en` fixo em cada valor, D3/D4), overflow dirigido e não-dirigido.

- [x] **Latência medida e confirmada** — `LATENCY=1` ciclo, confirmado por `p_latency_mult` (51 matches em 70 tentativas no teste `stimulus_modes`; as demais tentativas correspondem a ciclos fora de reset sem `en=1` no ciclo anterior, portanto vácuas, não falhas) e pelas transições reais extraídas do FSDB (`evidence/stimulus_modes/fsdbreport_transitions.txt`).

- [x] **Cobertura funcional planejada atingida (100%)** — dashboard URG: `GROUP: 100.00`. Todos os 5 coverpoints (`cp_A`, `cp_B`, `cp_overflow`, `cp_en`, `cp_reset`) e os 2 crosses (`cx_overflow_en`, `cx_reset_en`) fecharam 100%. Evidência: `evidence/stimulus_modes/urgReport/grp0.html` e o screenshot `evidence/stimulus_modes/screenshots/verdi_coverage_groups_100pct.png` (aba **Groups**, `SCORE 100.00`, `Variables 16/16`, `Crosses 8/8`). **Achado documentado**: `RANDOM`/`ZERO`/`MINMAX` sozinhos não garantiam fechar `cp_B=zero` (dependem de sorteio aleatório escolher esse caso específico) — foi necessário o passo dirigido **D1b** (`B=0x00000000, A=0xDEADBEEF`) para fechar esse bin de forma determinística. Confirma na prática a lição do Capítulo 2.2.7 do caderno: *"random puro raramente fecha cobertura sozinho"*.
>
> **Atenção para não confundir**: a GUI de cobertura (`make verdi_cov`) abre por padrão na aba **Hierarchy**, mostrando `Line`/`Toggle`/`Branch`/`Condition` — isso é **cobertura de código**, fica abaixo de 100% de propósito (ver "Limitações Conhecidas"). O 100% deste item é a **cobertura funcional (covergroup)**, visível só na aba **Groups** ou em `urgReport/grp0.html`. São métricas diferentes — o VP usa a funcional como critério de fechamento (Seção E acima).

- [x] **Testes terminaram sem erros não-explicados** — `stimulus_modes`: 19/19 matches (100%), sem nenhum `Error` de assertion. `baseline`: 100/100 matches (100%). `en_modes`: 5/12 matches — os 7 mismatches são **esperados e documentados** (bloco `EN_DISABLE` dirige uma transação `RANDOM` nova a cada iteração com `en=0`; o DUT retém o `Res` anterior enquanto o `refmod` calcula o par novo — divergência intencional que comprova a retenção, mesmo padrão do teste `en_modes` do Adder32). Nenhum desses mismatches é causado por uma falha de assertion (0 `Error` nos 3 logs).

- [x] **Cenários que falharam durante o desenvolvimento foram registrados, corrigidos e reexecutados** — ver "Lições Aprendidas" abaixo.

- [x] **Limitações conhecidas documentadas** — ver "Limitações Conhecidas" abaixo.

### Evidência gráfica do Verdi (GUI)

Capturada com sucesso numa sessão X11 real (`ssh -X` + XQuartz) — ver `evidence/stimulus_modes/screenshots/`:

- `verdi_waveform_overview.png`: `make verdi_wf` (script `cmd/matrix2x2.cmd`) abrindo a waveform completa do teste `stimulus_modes` — hierarquia (`matrix_tb`, `uu_matrix`, `uu_matrix_assertion`, `uu_matrix_coverage`), sinais `clk`/`rstn`/`en`/`A`/`B`/`Res`, fonte (`tb/tb_matrix.sv`) parado na linha do `$finish`, e `Time: 705,000`/`Finished: 705000ps` — batendo exatamente com o log de simulação.
- `verdi_coverage_gui.png`: `verdi -cov -covdir simv.vdb` (equivalente a `make verdi_cov`), aba **Hierarchy** (padrão ao abrir) — mostra **cobertura de código** (`Line`/`Toggle`/`Branch`/`Condition`). Não é a métrica de 100% citada no VP — essa aba fica abaixo de 100% de propósito.
- `verdi_coverage_groups_100pct.png`: `urgReport/grp0.html` aberto no navegador, aba **Groups** — mostra o covergroup `cg_matrix` em `SCORE 100.00`, `Variables 16/16`, `Crosses 8/8`, com contagem real de hits por bin. **Esta é a evidência visual do 100% de cobertura funcional citado no VP e no DoD.**

### Lições Aprendidas (achados reais durante o desenvolvimento)

**1. Amostragem SVA *preponed* na fronteira de entrada no reset.** Ao escrever `p_reset_res_stable` com a forma inicial `(!rstn) |-> $stable(Res)`, a simulação real (não hipotética) disparou uma falha de assertion no primeiro ciclo dentro de um pulso de reset dirigido (teste D4), mesmo sabendo — por leitura do RTL — que `Res` não é tocado durante `!rstn`. Investigação com `fsdbreport` (extração real das transições do sinal, sem GUI) mostrou que `Res` de fato só mudou de valor no ciclo *anterior* ao início do reset (uma escrita legítima com `en=1`), não durante o reset em si. Causa raiz: SVA usa amostragem *preponed* — o valor "corrente" de um sinal num tick só reflete uma escrita feita naquele mesmo tick a partir do *próximo* tick em diante; como o último ciclo antes do reset foi um ciclo de escrita válida, o primeiro tick *dentro* do reset comparava (via `$stable`) o valor novo (deste tick) contra o valor antigo (do tick anterior, pré-escrita) — um falso positivo de fronteira, não uma mudança real durante o reset. **Correção**: a property passou a exigir que *ambos* os ciclos comparados já estejam em reset (`$past(!rstn) && !rstn`). Reconfirmado sem falhas após a correção.

**2. Reset alinhado exatamente na borda de clock** (mitigado por precaução, não foi a causa raiz real do item 1). Os passos dirigidos de reset (D3/D4) tiveram a troca de `rstn` deslocada para `#1ns` depois do `@(posedge clk)`, em vez de exatamente em cima da borda — mesma técnica já usada no reset inicial deste testbench e sugerida pela análise da Atividade 8 do Adder32. Mantido como boa prática.

**3. Estímulo aleatório sozinho não fecha cobertura**, confirmado empiricamente (não só por dedução teórica): rodar apenas `RANDOM`/`ZERO`/`MINMAX` deixou o bin `cp_B=zero` descoberto na primeira execução completa do teste `stimulus_modes`. Só fechou 100% depois do passo dirigido D1b. Reproduz na prática a lição da Atividade 14 do Adder32 (Seção 3.7 do caderno).

**4. `Res` não é zerado no reset** (achado sobre o DUT, não sobre o testbench) — ver 4.1, "Achado 2". Comportamento real e não-modificado do RTL, diferente do Adder32. Documentado, testado (`p_reset_res_stable`) e coberto (`cx_reset_en`).

### Comparação com o testbench linear

Assim como no Adder32, este ambiente transaction-based é significativamente mais fácil de manter e estender do que um testbench linear equivalente seria: os 3 cenários (`baseline`/`stimulus_modes`/`en_modes`) reaproveitam os mesmos sequencer/driver/monitor/scoreboard sem duplicar lógica de estímulo ou checagem; adicionar um novo modo de estímulo (como foi feito com `OVERFLOW`/`NO_OVERFLOW`, que não existem no Adder32) exigiu apenas um novo `case` no sequencer, sem tocar em driver/monitor/scoreboard/assertions. A cobertura funcional também tornou visível, de forma objetiva, um buraco (`cp_B=zero`) que só apareceu porque a métrica existe — num testbench linear sem cobertura, esse buraco provavelmente passaria despercebido.

### Limitações Conhecidas

- Cobertura de **código** (line/cond/toggle/branch) não atingiu 100% (respectivamente ~81%/50%/22%/54% no dashboard) — isso é esperado e aceitável: o VP prioriza cobertura **funcional** (que fechou 100%), e parte do código não-coberto são ramos do próprio simulador/biblioteca padrão, não do DUT. Cobertura de toggle mais baixa é consequência de `Res1`/`A1`/`B1` serem arrays internos com bits que nunca saturam em todas as combinações possíveis dentro do orçamento de teste usado — não foi um objetivo do VP (Seção 2.2.7 do caderno: "cobertura de código alta não garante que a intenção foi verificada", e o inverso também vale: cobertura funcional alta é o critério primário aqui).
- O reference model (`dpi/refmod.c`) e a assertion `p_latency_mult` implementam a mesma aritmética de truncamento de 8 bits de forma independente (um em C, outro em SVA) — deliberado (evita que os dois "concordem" por compartilharem código-fonte), mas ambos partem do mesmo entendimento do RTL; um erro de interpretação da spec que afete os dois igualmente não seria pego por essa dupla checagem (limitação inerente ao método).
