# Atividade 10

## Problema encontrado no driver

O driver original (`tb/adder32_drv.sv`, antes desta atividade) tinha o sinal `en` **hardcoded**:

```systemverilog
vif.cb_drv.en   <= 1'b1;
```

Ou seja, `en` era sempre `1`, em toda transação, independentemente do que o testbench precisasse verificar. Isso significa que o DUT (`rtl/adder32.v`) sempre caía no branch `if (en) adder_reg <= op_a + op_b;` do seu `always@(posedge clk or negedge reset_n)` — o branch de **retenção** (quando `en=0`, `adder_reg` simplesmente não é escrito e mantém o valor anterior) nunca era exercitado. Do ponto de vista do mini-Verification Plan da Atividade 3, isso deixava **F5 (Retenção)** e o cenário **T8 (Disable/retenção)** completamente descobertos — nenhum teste jamais provava que o Adder32 segura corretamente o último resultado quando desabilitado.

## Código do driver

Arquivo: `tb/adder32_drv.sv` (completo e compilável — testado com VCS X-2025.06-SP2):

```systemverilog
import adder32_datatypes_pkg::*;

task adder32_drv(
  virtual adder32_if vif,
  adder32_seq_item_t seq_item,
  en_mode_t           en_mode,
  bit                 en_log
);
  // en controlado pelo modo selecionado (Atividade 10)
  logic en_value;

  // align with driver clocking block
  @(posedge vif.clk);

  case (en_mode)
    EN_RANDOM:  en_value = 1'($urandom_range(1, 0));
    EN_BURST:   en_value = 1'b1;
    EN_DISABLE: en_value = 1'b0;
    default:    en_value = 1'b1;
  endcase

  vif.cb_drv.en   <= en_value;
  vif.cb_drv.op_a <= seq_item.a;
  vif.cb_drv.op_b <= seq_item.b;

  if(en_log)
    $display("[driver-log] en_mode=%s en=%0b op_a=32'h%08h op_b=32'h%08h",
              en_mode.name(), en_value, seq_item.a, seq_item.b);

endtask: adder32_drv
```

O enum foi adicionado em `tb/adder32_datatypes.sv` (mesmo pacote que já continha `adder32_seq_item_t` e `stimulus_mode_t` da Atividade 9, preservando a arquitetura existente):

```systemverilog
  // Atividade 10: modos de controle do sinal en no driver
  typedef enum {
    EN_RANDOM,
    EN_BURST,
    EN_DISABLE
  } en_mode_t;
```

A arquitetura do driver não mudou: continua sendo uma `task` só, sincronizada em `@(posedge vif.clk)`, escrevendo via `cb_drv` (mesmo clocking block, mesmo output skew de `#2ns` confirmado na Atividade 8). A única mudança é que `en` deixou de ser uma constante e passou a ser calculado a partir do novo parâmetro `en_mode`.

## Alterações no testbench

Como a assinatura de `adder32_drv()` mudou (novo parâmetro `en_mode`), **todos** os pontos de chamada existentes em `tb/tb_adder32.sv` precisaram ser ajustados — o branch `"baseline"` e os 10 pontos de chamada do branch `"stimulus_modes"` (Atividade 9) passaram a usar `EN_BURST`, que reproduz exatamente o comportamento antigo (`en=1` sempre), preservando esses testes sem alterar seu resultado.

Foi adicionado um novo branch `"stimulus_modes"` → agora selecionado via `string testname = "en_modes";`, que executa os 3 modos **separadamente**, reaproveitando o sequencer da Atividade 9 (`adder32_seqr(RANDOM, ...)`) só para variar `op_a`/`op_b` a cada transação — o foco aqui é isolar o efeito de `en_mode`, não o de `stimulus_mode`:

```systemverilog
localparam int NUM_BURST_SEQUENCES    = 3; // Atividade 10: transacoes com EN_BURST
localparam int NUM_DISABLE_SEQUENCES  = 3; // Atividade 10: transacoes com EN_DISABLE
localparam int NUM_ENRANDOM_SEQUENCES = 6; // Atividade 10: transacoes com EN_RANDOM
string testname = "en_modes";
```

```systemverilog
"en_modes": begin
  // Atividade 10: controle do sinal en no driver (RANDOM / BURST / DISABLE).
  // Usa os estimulos da Atividade 9 (adder32_seqr em modo RANDOM) para variar op_a/op_b
  // em cada transacao, isolando assim o efeito do en_mode sobre adder_out/carry_out.
  $display("");
  $display("# --------------------------");
  $display("#");
  $display("# Atividade 10 - EN Modes");
  $display("#");
  $display("# --------------------------");

  // BURST -> T7, F4, F6 (en=1 constante, DUT atualiza a cada transacao)
  $display("# ---- en_mode: EN_BURST (%0d transacoes) @ t=%0t ----", NUM_BURST_SEQUENCES, $time);
  repeat (NUM_BURST_SEQUENCES) begin
    adder32_seq_item = adder32_seqr(RANDOM, 0);
    adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 1);
    adder32_mon(adder32_vif, dut_r, 0);
    rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
    adder32_scb(dut_r, unsigned'(rfm_r), 0);
  end

  // DISABLE -> T8, F5 (en=0 constante, saida deve reter o ultimo valor do bloco BURST)
  $display("# ---- en_mode: EN_DISABLE (%0d transacoes) @ t=%0t ----", NUM_DISABLE_SEQUENCES, $time);
  repeat (NUM_DISABLE_SEQUENCES) begin
    adder32_seq_item = adder32_seqr(RANDOM, 0);
    adder32_drv(adder32_vif, adder32_seq_item, EN_DISABLE, 1);
    adder32_mon(adder32_vif, dut_r, 0);
    rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
    adder32_scb(dut_r, unsigned'(rfm_r), 0);
  end

  // RANDOM -> T11, F4, F5 (en alterna 0/1 aleatoriamente a cada transacao)
  $display("# ---- en_mode: EN_RANDOM (%0d transacoes) @ t=%0t ----", NUM_ENRANDOM_SEQUENCES, $time);
  repeat (NUM_ENRANDOM_SEQUENCES) begin
    adder32_seq_item = adder32_seqr(RANDOM, 0);
    adder32_drv(adder32_vif, adder32_seq_item, EN_RANDOM, 1);
    adder32_mon(adder32_vif, dut_r, 0);
    rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
    adder32_scb(dut_r, unsigned'(rfm_r), 0);
  end
end
```

O modo selecionado e o valor de `en` aplicado em cada transação aparecem no terminal através do `$display` já embutido no próprio driver (`[driver-log] en_mode=... en=... op_a=... op_b=...`), sem precisar duplicar essa lógica no testbench. Os mismatches de scoreboard (`refmod.c` ainda sempre retorna 0) não foram tratados, conforme pedido — por isso `adder32_scb` é chamado com `en_log=0` neste branch, para não poluir o log com "error" repetido, já que não é o foco desta atividade.

## Explicação dos modos

- **RANDOM (`EN_RANDOM`)**: a cada transação, `en_value = 1'($urandom_range(1, 0))` — sorteia 0 ou 1 de forma independente e imprevisível a cada ciclo. Simula um cenário de handshake irregular, onde o consumidor habilita/desabilita a soma sem padrão fixo.
- **BURST (`EN_BURST`)**: `en_value = 1'b1` sempre — o DUT atualiza `adder_reg` (e portanto `adder_out`/`carry_out`) em **toda** borda de clock em que uma nova transação foi dirigida, sem nunca reter. É o modo "rajada": máxima vazão, uma soma nova por transação.
- **DISABLE (`EN_DISABLE`)**: `en_value = 1'b0` sempre — o branch `if (en)` do RTL nunca é tomado, então `adder_reg` **nunca** é escrito enquanto esse modo estiver ativo. `op_a`/`op_b` continuam sendo dirigidos normalmente pelo driver (o barramento muda), mas o resultado registrado (`adder_out`/`carry_out`) fica congelado no último valor válido antes do `EN_DISABLE` começar — essa é exatamente a prova de retenção pedida por F5/T8.

## Waveforms

Ambiente compilado e simulado com `source snps.sh; make vcs_clean; make all` (VCS X-2025.06-SP2), sem erro de elaboração, `$finish` em `Time: 398000`. Os tempos abaixo foram extraídos do `adder32.fsdb` via `fsdbreport` (mesma técnica das Atividades 8 e 9).

### Log do console (driver)

```
# ---- en_mode: EN_BURST (3 transacoes) @ t=25000 ----
[driver-log] en_mode=EN_BURST en=1 op_a=32'hafa95424 op_b=32'hd340cea3
[driver-log] en_mode=EN_BURST en=1 op_a=32'h49ce7a0b op_b=32'hdae0253f
[driver-log] en_mode=EN_BURST en=1 op_a=32'h6357c748 op_b=32'h0c42cc64
# ---- en_mode: EN_DISABLE (3 transacoes) @ t=118000 ----
[driver-log] en_mode=EN_DISABLE en=0 op_a=32'h5fecee92 op_b=32'h20364f25
[driver-log] en_mode=EN_DISABLE en=0 op_a=32'haf9f43a3 op_b=32'ha63337df
[driver-log] en_mode=EN_DISABLE en=0 op_a=32'h2926e543 op_b=32'h018c3239
# ---- en_mode: EN_RANDOM (6 transacoes) @ t=208000 ----
[driver-log] en_mode=EN_RANDOM en=0 op_a=32'hb11da1d0 op_b=32'h9739b3a2
[driver-log] en_mode=EN_RANDOM en=1 op_a=32'h07fa968f op_b=32'h03d7315a
[driver-log] en_mode=EN_RANDOM en=1 op_a=32'h6489ef03 op_b=32'h2a0dd272
[driver-log] en_mode=EN_RANDOM en=0 op_a=32'h950e4f11 op_b=32'hfdc0b5e9
[driver-log] en_mode=EN_RANDOM en=0 op_a=32'hedb2b160 op_b=32'heed0cef7
[driver-log] en_mode=EN_RANDOM en=0 op_a=32'h7c8dc713 op_b=32'h4041b82f
```

### BURST — `en=1` constante, atualização a cada transação

| Transação | posedge (driver sincroniza) | `op_a`/`op_b` mudam (P+2ns) | `adder_out`/`carry_out` atualizam (P+10ns) |
|---|---|---|---|
| 1 | 35.000 ns | 37.000 ns | 45.000 ns |
| 2 | 65.000 ns | 67.000 ns | 75.000 ns |
| 3 | 95.000 ns | 97.000 ns | 105.000 ns |

`en=1` do início ao fim do bloco (transição `x→1` em 37.000 ns, sem nenhuma queda até o próximo bloco). Cada uma das 3 transações gera uma atualização de `adder_out`/`carry_out` exatamente 1 ciclo depois de `op_a`/`op_b` mudarem — igual à latência já confirmada na Atividade 8, agora repetida 3 vezes seguidas sem nenhuma retenção. `carry_out` valeu `1` na transação 1 (45.000 ns) e `0` na transação 3 (105.000 ns) — dado real, confirma que o carry realmente reflete a soma calculada a cada rodada.

### DISABLE — `en=0` constante, saída congelada apesar de `op_a`/`op_b` mudarem

| Evento | Tempo |
|---|---|
| Último valor válido de `adder_out`/`carry_out` (fim do bloco BURST) | 105.000 ns |
| `en` cai para 0 (início do bloco DISABLE) | 127.000 ns |
| `op_a`/`op_b` mudam (transação DISABLE 1) | 127.000 ns |
| `op_a`/`op_b` mudam (transação DISABLE 2) | 157.000 ns |
| `op_a`/`op_b` mudam (transação DISABLE 3) | 187.000 ns |
| `adder_out`/`carry_out` — **nenhuma mudança** neste intervalo | — |
| Próxima mudança real de `adder_out`/`carry_out` (já no bloco RANDOM, en=1) | 255.000 ns |

Esta é a evidência central da atividade: entre **105.000 ns e 255.000 ns** (150 ns, 15 ciclos de clock), `op_a` e `op_b` mudam **3 vezes** no barramento (o driver continua dirigindo normalmente), mas `adder_out` e `carry_out` **não mudam nenhuma vez** — o registrador do DUT (`adder_reg`) está retendo o valor calculado na última transação do bloco BURST, exatamente como especifica `rtl/adder32.v`: `if (en) adder_reg <= op_a + op_b;` sem `else`, ou seja, sem o `en`, não há escrita, e o valor anterior simplesmente persiste.

### RANDOM — atualização seletiva, só quando `en=1` na transação

| Transação | posedge | `en` aplicado | `op_a`/`op_b` mudam | `adder_out`/`carry_out` atualiza em P+10ns? |
|---|---|---|---|---|
| 1 | 215.000 ns | 0 | 217.000 ns | não (225.000 ns sem mudança) |
| 2 | 245.000 ns | 1 | 247.000 ns | **sim** — 255.000 ns |
| 3 | 275.000 ns | 1 | 277.000 ns | **sim** — 285.000 ns |
| 4 | 305.000 ns | 0 | 307.000 ns | não (315.000 ns sem mudança) |
| 5 | 335.000 ns | 0 | 337.000 ns | não (345.000 ns sem mudança) |
| 6 | 365.000 ns | 0 | 367.000 ns | não (375.000 ns sem mudança) |

`en` no FSDB mostra transições `247.000 ns → 1` e `307.000 ns → 0`, exatamente casando com a 2ª e a 4ª transação deste bloco (as únicas em que o valor de `en` mudou em relação à transação anterior). `adder_out`/`carry_out` só mudam de valor em **255.000 ns** e **285.000 ns** — as duas únicas transações com `en=1` — confirmando bit a bit a correlação `en=1 → atualiza`, `en=0 → retém`, dentro do mesmo bloco onde `en` está de fato alternando.

## Evidências no Verdi

Capturas reais feitas no Verdi (Cursor + Marker, mesma técnica das Atividades 8 e 9), salvas em `evidence/activity_10/screenshots/`:

| Modo | Cursor | Marker | Δ no toolbar | Zoom | Arquivo |
|---|---|---|---|---|---|
| BURST | 35.000 ns (1ª borda) | 105.000 ns (3ª atualização) | **70.000 x 1ps** | 25.000–115.000 ns | `01_BURST.png` |
| DISABLE | 105.000 ns (último valor válido) | 255.000 ns (próxima atualização real) | **150.000 x 1ps** | 95.000–260.000 ns | `02_DISABLE.png` |
| RANDOM | 215.000 ns (1ª transação, en=0) | 285.000 ns (2ª atualização real) | **70.000 x 1ps** | 205.000–320.000 ns | `03_RANDOM.png` |

Os três deltas medidos no toolbar do Verdi batem exatamente com os calculados nas tabelas acima (70ns, 150ns e 70ns), confirmando visualmente:

- **`01_BURST.png`**: `op_a`/`op_b` mudam 3 vezes (`afa9_5424`/`d340_cea3` → `49ce_7a0b`/`dae0_253f` → `6357_c748`/`c42_cc64`) e `adder_out` acompanha em 3 atualizações consecutivas (`82ea_22c7` → `24ae_9f4a` → `6f9a_93ac`), uma por transação, sem nenhuma retenção.
- **`02_DISABLE.png`**: esta é a imagem central da atividade. Entre o cursor (105.000 ns) e o marker (255.000 ns), `op_a`/`op_b` mudam 4 vezes na waveform (as 3 transações DISABLE + a 1ª transação do bloco RANDOM seguinte, que também teve `en=0`), mas `adder_out`/`carry_out` permanecem **visivelmente parados em `6f9a_93ac`** a régua inteira, só mudando exatamente no instante do marker — a prova visual direta de que o registrador reteve o valor por 150 ns (15 ciclos de clock) apesar do barramento de entrada mudar livremente.
- **`03_RANDOM.png`**: `adder_out` sai de `6f9a_93ac` (herdado do bloco anterior) e atualiza só 2 vezes (`bd1_c7e9`, depois `8e97_c175`) dentro da janela — exatamente nas 2 transações em que `en=1` (a 2ª e a 3ª do bloco RANDOM); nas transações com `en=0` (1ª, 4ª, 5ª, 6ª) a saída não se move, confirmando a correlação seletiva `en=1 → atualiza`, `en=0 → retém`.

## Relação com a Atividade 3

| Modo | Cenário / Feature do mini-VP |
|---|---|
| BURST | **T7** (en=1 constante por várias operações seguidas) / **F4** (Enable) / **F6** (Latência — 1 ciclo, repetida a cada transação sem interrupção) |
| DISABLE | **T8** (Disable/retenção — en=0 após soma válida; saída não deve mudar) / **F5** (Retenção com en=0) |
| RANDOM | **T11** (regressão com en aleatório) / **F4** (Enable) / **F5** (Retenção, nos ciclos em que o sorteio resultou em en=0) |
| Transições entre modos (BURST→DISABLE→RANDOM, e as alternâncias 0/1/1/0 dentro do próprio bloco RANDOM) | Apoio a **T12** (sequência dirigida en 0→1→0→1) e **F8** (transições en/reset) — a própria ordem dos blocos já força uma transição `en=1→0` (fim do BURST) e depois `en=0→(0 ou 1)` alternado (bloco RANDOM), sem precisar de um cenário extra dedicado |

## Conclusão

Antes desta atividade, o driver não tinha nenhum controle sobre `en` — o sinal estava fixo em `1`, o que tornava a verificação estruturalmente incapaz de exercitar F5/T8 (retenção), por mais cenários de `op_a`/`op_b` que a Atividade 9 já soubesse gerar. Com `en_mode_t` e o `case (en_mode)` no driver, o testbench passou a controlar **de forma independente** o que entra em `op_a`/`op_b` (via `stimulus_mode_t`, Atividade 9) e o que acontece com `en` (via `en_mode_t`, Atividade 10) — as duas dimensões do espaço de verificação do Adder32 agora são compostas livremente, sem alterar a interface, o clocking block, o monitor ou o RTL.

Isso permite comprovar, com evidência de waveform, as três facetas do enable:
- **atualização contínua** (BURST): o DUT nunca perde uma soma quando `en=1` em toda borda;
- **retenção** (DISABLE): o DUT nunca corrompe o último resultado quando `en=0`, mesmo com o barramento de entrada mudando livremente;
- **alternância** (RANDOM): o DUT reage exatamente ao valor de `en` amostrado em cada borda, atualizando só quando deve e retendo só quando deve — sem nenhum caso de amostragem "no ciclo errado".

Combinado com os modos de estímulo da Atividade 9, o driver agora oferece um espaço de teste dirigido e reproduzível tanto para os operandos quanto para o enable, cobrindo diretamente T7, T8, T11, T12, F4, F5, F6 e F8 do Verification Plan da Atividade 3 — a base que faltava para depois fechar a cobertura funcional completa (CP6 `en_s` e os cruzamentos CP10/CP11 do VP).
