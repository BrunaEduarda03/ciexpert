# 4.3 Matrix2x2: Arquitetura do Testbench

Reaproveita exatamente o arquétipo do Adder32 (Figura 1 do caderno / `adder2p0`): sequencer → driver → interface (BFM) → DUT → monitor → scoreboard, com reference model (DPI-C) alimentando o scoreboard e assertions + coverage observando a interface diretamente.

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

## Sequencer (`tb/matrix_seqr.sv`)

Function `matrix_seqr(mode, en_log)` que retorna uma `matrix_seq_item_t` (struct packed com `a`/`b` de 32 bits). Não usa classes — segue a mesma filosofia "transação ≠ classe" do Capítulo 2.2.4 do caderno. Os modos (`stimulus_mode_t`, definidos em `tb/matrix_datatypes.sv`) cobrem os cenários T1–T10 e D1 do Verification Plan: `BASIC`, `ZERO`, `MAX`, `OVERFLOW`, `NO_OVERFLOW`, `PATTERN`, `SMALL`, `BIG`, `MINMAX`, `RANDOM`.

- **Recebe**: modo de estímulo (enum) + flag de log.
- **Produz**: uma transação (`matrix_seq_item_t`) com `A`/`B` já empacotados nos 4 elementos de 8 bits, prontos para o driver.

## Driver (`tb/matrix_drv.sv`)

Task `matrix_drv(vif, seq_item, en_mode, en_log)`. Sincroniza com `@(posedge vif.clk)` e escreve `en`/`A`/`B` via clockvar (`vif.cb_drv.*`), respeitando o skew de saída do clocking block (`output #2ns`). O modo de `en` (`en_mode_t`: `EN_RANDOM`/`EN_BURST`/`EN_DISABLE`) permite exercitar retenção (F3 do VP) sem precisar de um segundo sequencer.

- **Recebe**: transação + modo de `en`.
- **Produz**: sinais físicos `en`/`A`/`B` na interface, defasados 2ns da borda em que sincronizou (evita race com o `always@(posedge clk or negedge rstn)` do DUT — mesmo raciocínio comprovado empiricamente na Atividade 8 do Adder32).

## Monitor (`tb/matrix_mon.sv`)

Task `matrix_mon(vif, dut_r, en_log)`. Espera 2 bordas de `posedge clk` + 3ns (mesmo padrão do Adder32, validado empiricamente na Atividade 8: dá margem suficiente para o clocking block de monitor já ter amostrado o valor estável) e lê `Res` via `vif.cb_mon.Res` (input skew `#1ns`).

- **Recebe**: referência à interface (via `vif`).
- **Produz**: `dut_r` (32 bits), o valor de `Res` observado para aquela transação.

## Interface / BFM (`tb/matrix_if.sv`)

Declara os sinais do DUT com os **mesmos nomes do RTL** (`en`, `A`, `B`, `Res`; clock/reset são portas da própria interface: `clk`, `rstn`). Dois clocking blocks:

- `cb_drv`: `output #2ns` para `en`/`A`/`B` — o driver escreve aqui.
- `cb_mon`: `input #1ns` para `Res` — o monitor lê aqui.

Mesma justificativa de skew do Adder32 (Atividade 8): o output skew de 2ns dá folga de 8ns (num período de 10ns) antes da próxima borda, evitando que o DUT amostre um valor de `A`/`B` em transição; o input skew de 1ns garante que o clocking block de monitor só amostra `Res` depois que ele já está estável.

## Reference Model (`dpi/refmod.c`, função `refmod_matrix`)

Modelo de referência em C, chamado via DPI-C (mesmo padrão do Adder32 — ver Atividade 5c do caderno). Recebe `A`/`B` como `uint64_t` (mas usa só os 32 bits relevantes), desempacota os 4 elementos de 8 bits, calcula os 4 produtos-soma e **trunca cada resultado para 8 bits** (`& 0xFF`), reproduzindo bit-a-bit a semântica de truncamento do RTL (`reg [7:0]`) em vez de saturar. Sem esse truncamento explícito, o modelo divergiria do DUT em qualquer caso de overflow (T3, T4, MAX, etc.).

## Scoreboard (`tb/matrix_scb.sv`)

Função `matrix_scb(dut_r, rfm_r, en_log)`: compara `Res` observado pelo monitor com o valor calculado pelo reference model, contabiliza matches/mismatches/total, e `matrix_scb_report()` imprime o placar final — mesmo padrão do Adder32 pós-Atividade 11.

## Assertions (`tb/matrix_assertion.sv`)

Três properties (SVA), mesma filosofia da Atividade 15 do Adder32 — mas **sem** equivalente a `p_carry_causality`, pois este DUT não tem sinal de carry:

1. `p_reset_res_stable`: durante o reset (dois ciclos consecutivos já em `!rstn`), `Res` deve permanecer estável — reflete o achado real de que este RTL **retém** `Res` durante reset (não zera, ver `block_guide.md`). Exige `$past(!rstn) && !rstn` (não apenas `!rstn`) para evitar um falso positivo de amostragem *preponed* na fronteira de entrada no reset — ver `definition_of_done.md`.
2. `p_latency_mult`: 1 ciclo depois de `en=1` amostrado (fora de reset), `Res` deve bater com o modelo de referência local em SVA (mesma aritmética/truncamento do `refmod.c`).
3. `p_retention`: com `en=0` (fora de reset), `Res` deve permanecer estável no ciclo seguinte.

Cada `assert property` tem um `cover property` irmão, seguindo a orientação do caderno (Seção 2.2.8: "se a assertion não disparar, isso não significa que está tudo certo — pode ser que a condição nunca tenha sido estimulada").

## Coverage (`tb/matrix_coverage.sv`)

`covergroup cg_matrix`, amostrado em `@(posedge clk)`, com os coverpoints `cp_A`/`cp_B` (mesmas faixas do Adder32: zero/low/mid/high/max), `cp_overflow` (substitui `cp_carry` do Adder32 — deriva se algum elemento de `Res` estourou 8 bits, já que este DUT não expõe flag de overflow), `cp_en`, `cp_reset`, e os cruzamentos `cx_overflow_en`/`cx_reset_en` (equivalentes a `cx_carry_en`/`cx_reset_en` do Adder32).
