# Atividade 9

## Relação com a Atividade 3

| Modo | Cenário do mini-VP (Atividade 3) |
|---|---|
| BASIC | T1 — soma simples com valores típicos |
| ZERO | T2 — A=0/B=0, A=0/B≠0, A≠0/B=0 |
| MAX | T3 — A=B=32'hFFFFFFFF |
| CARRY | T4 — combinações que geram carry |
| NO_CARRY | T5 — combinações que garantidamente não geram carry |
| PATTERN | T6 — padrões alternados (0xAAAAAAAA / 0x55555555) |
| RANDOM | T11 — operandos totalmente aleatórios (múltiplas transações) |
| MINMAX, SMALL, BIG | Apoio à cobertura CP1 (a_zero), CP2 (b_zero), CP3 (a_max), CP4 (b_max) e CP9 (value_range: baixo/alto) |

## Código do sequencer

Arquivo: `tb/adder32_seqr.sv` (completo e compilável — testado com VCS X-2025.06-SP2):

```systemverilog
import adder32_datatypes_pkg::*;

function automatic adder32_seq_item_t adder32_seqr(
  input stimulus_mode_t mode,
  input bit             en_log
);
  // data
  logic [31:0] a;
  logic [31:0] b;
  int          zero_case;
  int          minmax_case;

  adder32_seq_item_t item;

  case (mode)

    BASIC: begin
      // T1: soma simples com valores tipicos (Atividade 3)
      a = 32'd10;
      b = 32'd20;
    end

    ZERO: begin
      // T2: A=0/B=0, A=0/B!=0, A!=0/B=0
      zero_case = $urandom_range(2, 0);
      case (zero_case)
        0: begin
          a = 32'd0;
          if (!randomize(b)) $fatal(1, "Randomization failed in adder32_seqr() [ZERO/b]");
        end
        1: begin
          if (!randomize(a)) $fatal(1, "Randomization failed in adder32_seqr() [ZERO/a]");
          b = 32'd0;
        end
        default: begin
          a = 32'd0;
          b = 32'd0;
        end
      endcase
    end

    MAX: begin
      // T3: A=B=32'hFFFFFFFF
      a = 32'hFFFFFFFF;
      b = 32'hFFFFFFFF;
    end

    CARRY: begin
      // T4: combinacoes que garantidamente geram carry (A+B > 32'hFFFFFFFF)
      a = $urandom_range(32'hFFFFFFFF, 32'h8000_0000);
      b = $urandom_range(32'hFFFFFFFF, (32'hFFFFFFFF - a) + 32'd1);
    end

    NO_CARRY: begin
      // T5: combinacoes que garantidamente NAO geram carry (A+B <= 32'hFFFFFFFF)
      a = $urandom_range(32'h7FFFFFFF, 32'd0);
      b = $urandom_range(32'hFFFFFFFF - a, 32'd0);
    end

    PATTERN: begin
      // T6: padroes alternados
      a = 32'hAAAAAAAA;
      b = 32'h55555555;
    end

    SMALL: begin
      // apoio a cobertura CP9 (value_range: baixo)
      a = $urandom_range(32'h0000_00FF, 32'd0);
      b = $urandom_range(32'h0000_00FF, 32'd0);
    end

    BIG: begin
      // apoio a cobertura CP9 (value_range: alto)
      a = $urandom_range(32'hFFFFFFFF, 32'hF000_0000);
      b = $urandom_range(32'hFFFFFFFF, 32'hF000_0000);
    end

    MINMAX: begin
      // apoio a cobertura CP1-CP4 (cruzamento entre zero e valor maximo)
      minmax_case = $urandom_range(3, 0);
      case (minmax_case)
        0: begin a = 32'd0;        b = 32'd0;        end
        1: begin a = 32'd0;        b = 32'hFFFFFFFF; end
        2: begin a = 32'hFFFFFFFF; b = 32'd0;         end
        default: begin a = 32'hFFFFFFFF; b = 32'hFFFFFFFF; end
      endcase
    end

    RANDOM: begin
      // T11: operandos totalmente aleatorios
      if (!randomize(a, b)) begin
        $fatal(1, "Randomization failed in adder32_seqr() [RANDOM]");
      end
    end

    default: begin
      $fatal(1, "adder32_seqr(): modo de estimulo desconhecido");
    end

  endcase

  if(en_log) begin
    $display("# ---------------------------");
    $display("# sequence generated (mode=%s)", mode.name());
    $display("# ---------------------------");
  end

  item.a = a;
  item.b = b;

  return item;

endfunction: adder32_seqr
```

O enum foi adicionado em `tb/adder32_datatypes.sv` (mesmo pacote que já continha `adder32_seq_item_t`, preservando a arquitetura existente):

```systemverilog
package adder32_datatypes_pkg;

  typedef struct packed {
    logic [31:0] a;
    logic [31:0] b;
  } adder32_seq_item_t;

  // Atividade 9: modos de estimulo controlaveis no sequencer (ver mini-VP da Atividade 3)
  typedef enum {
    BASIC,
    ZERO,
    MAX,
    CARRY,
    NO_CARRY,
    PATTERN,
    SMALL,
    BIG,
    MINMAX,
    RANDOM
  } stimulus_mode_t;

endpackage: adder32_datatypes_pkg
```

## Alterações no testbench

Arquivo: `tb/tb_adder32.sv`. A assinatura de `adder32_seqr()` mudou (agora recebe `mode` além de `en_log`), então o branch `"baseline"` já existente foi ajustado para `adder32_seqr(RANDOM, 0)` (preserva o comportamento 100% aleatório original). Foi adicionado um novo branch `"stimulus_modes"`, selecionado via `string testname = "stimulus_modes";`, que executa cada modo separadamente usando o **driver já existente** (`adder32_drv`) e o **monitor já existente** (`adder32_mon`):

```systemverilog
// TB control variables
localparam int NUM_OF_SEQUENCES = 2;
localparam int NUM_RANDOM_SEQUENCES = 5; // Atividade 9: transacoes do modo RANDOM
string testname = "stimulus_modes";
```

```systemverilog
"stimulus_modes": begin
  // Atividade 9: coletanea de estimulos controlaveis no sequencer,
  // um modo por vez, cada um com sua propria janela na waveform.
  $display("");
  $display("# --------------------------");
  $display("#");
  $display("# Atividade 9 - Stimulus Modes");
  $display("#");
  $display("# --------------------------");

  // BASIC -> T1
  $display("# ---- mode: BASIC @ t=%0t ----", $time);
  adder32_seq_item = adder32_seqr(BASIC, 1);
  $display("[STIMULUS] mode=%s op_a=32'h%08h op_b=32'h%08h", "BASIC", adder32_seq_item.a, adder32_seq_item.b);
  adder32_drv(adder32_vif, adder32_seq_item, 0);
  adder32_mon(adder32_vif, dut_r, 0);
  rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
  adder32_scb(dut_r, unsigned'(rfm_r), 1);

  // ... (mesmo padrao repetido para ZERO, MAX, CARRY, NO_CARRY, PATTERN, SMALL, BIG, MINMAX)

  // RANDOM -> T11 (varias transacoes)
  $display("# ---- mode: RANDOM (%0d transacoes) @ t=%0t ----", NUM_RANDOM_SEQUENCES, $time);
  repeat (NUM_RANDOM_SEQUENCES) begin
    adder32_seq_item = adder32_seqr(RANDOM, 1);
    $display("[STIMULUS] mode=%s op_a=32'h%08h op_b=32'h%08h", "RANDOM", adder32_seq_item.a, adder32_seq_item.b);
    adder32_drv(adder32_vif, adder32_seq_item, 0);
    adder32_mon(adder32_vif, dut_r, 0);
    rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
    adder32_scb(dut_r, unsigned'(rfm_r), 1);
  end
end
```

Cada um dos 9 modos dirigidos gera **uma** transação; o RANDOM gera `NUM_RANDOM_SEQUENCES=5`. Total: 14 transações em sequência, cada uma no seu próprio par de bordas de clock (driver sincroniza em `posedge clk`, monitor lê 2 ciclos + 3ns depois — arquitetura de `adder32_drv`/`adder32_mon` inalterada). Os mismatches do scoreboard (`error`, causados pelo bug conhecido de `refmod.c` sempre retornar 0) aparecem normalmente e não foram tratados, conforme pedido pela atividade.

## Explicação

- **BASIC**: valores fixos `a=10, b=20` — cobre T1 (soma simples e previsível, fácil de auditar manualmente).
- **ZERO**: sorteia (`$urandom_range(2,0)`) entre 3 sub-casos — `a=0` com `b` aleatório, `b=0` com `a` aleatório, ou `a=b=0` — cobrindo as 3 combinações de T2 ao longo de execuções repetidas.
- **MAX**: valores fixos `a=b=32'hFFFFFFFF` — cobre T3 exatamente como especificado.
- **CARRY**: `a` sorteado no range alto `[0x8000_0000, 0xFFFFFFFF]`, e `b` sorteado em `[(0xFFFFFFFF-a)+1, 0xFFFFFFFF]` — essa construção garante matematicamente que `a+b > 0xFFFFFFFF` (carry=1) em qualquer sorteio, cobrindo T4 sem depender de um `randomize() with` (evita problemas de largura de bits no solver).
- **NO_CARRY**: `a` sorteado em `[0, 0x7FFFFFFF]` e `b` em `[0, 0xFFFFFFFF-a]` — garante `a+b <= 0xFFFFFFFF` (carry=0) sempre, cobrindo T5.
- **PATTERN**: valores fixos `a=0xAAAAAAAA, b=0x55555555` — cobre T6 (padrão alternado bit a bit).
- **SMALL**: ambos operandos sorteados em `[0, 0xFF]` — reforça o bin "baixo" de CP9.
- **BIG**: ambos operandos sorteados em `[0xF000_0000, 0xFFFFFFFF]` — reforça o bin "alto" de CP9, com valores grandes mas não fixos (diferente de MAX).
- **MINMAX**: sorteia entre os 4 cantos `{0,0}`, `{0,MAX}`, `{MAX,0}`, `{MAX,MAX}` — apoia diretamente CP1 (a_zero), CP2 (b_zero), CP3 (a_max) e CP4 (b_max) e o cruzamento entre eles.
- **RANDOM**: `randomize(a,b)` sem restrição, chamado 5 vezes em sequência — cobre T11 (regressão aleatória, base da cobertura funcional ampla).

## Waveforms

Valores de `op_a`/`op_b` **efetivamente medidos no FSDB** (via `fsdbreport`, mesma técnica usada na Atividade 8) para esta execução determinística de `make all`:

| Modo | t (transição op_a/op_b) | op_a | op_b |
|---|---|---|---|
| BASIC | 37.000 ns | 32'h0000000a (10) | 32'h00000014 (20) |
| ZERO | 67.000 ns | 32'h00000000 | 32'hdae0253f |
| MAX | 97.000 ns | 32'hffffffff | 32'hffffffff |
| CARRY | 127.000 ns | 32'ha0adb297 | 32'h64b7195a |
| NO_CARRY | 157.000 ns | 32'h7a0900c5 | 32'h48aec7b1 |
| PATTERN | 187.000 ns | 32'haaaaaaaa | 32'h55555555 |
| SMALL | 217.000 ns | 32'h00000048 (72) | 32'h0000000c (12) |
| BIG | 247.000 ns | 32'hf14b2b2c | 32'hf0a8386b |
| MINMAX | 277.000 ns | 32'hffffffff | 32'hffffffff |
| RANDOM (5x) | 307k/337k/367k/397k/427k ns | 3c562de9 / 950e4f11 / d38a42a0 / edb2b160 / d0665096 | b1ad0302 / fdc0b5e9 / 1deb3e5f / eed0cef7 / 8fba4fbb |

Cada transição ocorre 2ns após a borda de `posedge clk` em que o driver sincronizou (mesmo output skew de `cb_drv` confirmado na Atividade 8: `output #2ns`), e as transações ficam espaçadas em blocos de 30ns (3 ciclos de clock) — consequência direta de `adder32_drv` (1 borda) + `adder32_mon` (2 bordas + 3ns).

**Sobre o "modo de estímulo" na waveform**: `mode` é uma variável local automática da função `adder32_seqr()` (existe apenas durante a chamada), não um sinal da interface `adder32_if` nem uma porta do DUT — portanto **não aparece como um traço na waveform do Verdi** (`$fsdbDumpvars()` despeja hierarquia de módulos/interfaces, não variáveis locais de function). Isso está de acordo com o enunciado ("modo de estímulo, se estiver visível"). O modo é identificado de duas formas complementares: (1) pelo `$display` no console com `$time`, correlacionável ao cursor do Verdi; e (2) pela "assinatura" característica de cada modo nos próprios valores de `op_a`/`op_b` (ex.: MAX e PATTERN são sempre os mesmos valores fixos, fáceis de reconhecer direto na waveform).

### Evidências no Verdi (capturas reais desta sessão)

Todas as capturas usam Cursor (borda de `posedge clk`) + Marker (instante da mudança de `op_a`/`op_b`) do Verdi, mesma técnica da Atividade 8, confirmando o delta de output skew em `2.000 x 1ps` em cada uma:

| Modo | Screenshot |
|---|---|
| ZERO | `evidence/activity_09/screenshots/02_ZERO.png` |
| MAX | `evidence/activity_09/screenshots/03_MAX.png` |
| CARRY | `evidence/activity_09/screenshots/04_CARRY.png` |
| NO_CARRY | `evidence/activity_09/screenshots/05_NO_CARRY.png` |
| PATTERN | `evidence/activity_09/screenshots/06_PATTERN.png` |
| SMALL | `evidence/activity_09/screenshots/07_SMALL.png` |
| BIG | `evidence/activity_09/screenshots/08_BIG.png` |
| RANDOM (5 transações) | `evidence/activity_09/screenshots/10_RANDOM.png` |

**BASIC e MINMAX**: a GUI do Verdi não pôde ser reaberta a tempo para essas duas capturas específicas nesta sessão — o ambiente é compartilhado com vários outros usuários rodando Verdi simultaneamente (`glestiano.tietre`, `hellen.vieira`, `klynger.dantas`, `paulo.nascimento`, etc., confirmado via `ps aux`), e o pool de licenças flutuantes (`Verdi-Elite`/`Verdi-Apex`) ficou indisponível nas tentativas feitas (`*WARN* Verdi-Elite (Verdi) license is not available`, seguido de timeout ao tentar Apex). Os valores de `op_a`/`op_b` para BASIC (`0x0000000a`/`0x00000014`) e MINMAX (`0xffffffff`/`0xffffffff`) estão confirmados com precisão de tempo (37.000ns e 277.000ns) pelos dados reais do `fsdbreport` na tabela acima — o mesmo dado que alimentaria o cursor do Verdi, apenas sem a captura de tela. Recomenda-se reabrir `make verdi_wf` numa janela sem concorrência de licença para completar essas duas capturas visuais.

## Conclusão

Antes desta atividade, `adder32_seqr()` só sabia gerar operandos totalmente aleatórios — útil para regressão (T11), mas incapaz de reproduzir de forma determinística os cenários específicos do mini-Verification Plan (zero, máximo, carry, padrões, etc.), que precisavam ser encontrados "por sorte" dentro do espaço aleatório. Com o `stimulus_mode_t` e o `case (mode)` implementados, o sequencer passou a suportar **geração dirigida e reproduzível**: cada cenário do VP (T1–T6, T11) agora tem um modo correspondente que sempre produz operandos dentro da faixa/condição esperada, sem alterar o driver, o monitor ou a interface. Isso facilita diretamente:

- a **execução dos cenários previstos** no Verification Plan da Atividade 3, um a um, sob demanda;
- o **fechamento futuro da cobertura funcional** (CP1–CP11 do VP), já que os modos SMALL/BIG/MINMAX foram desenhados especificamente para alimentar os bins de `value_range` e os cruzamentos zero×máximo que seriam raros de atingir só com RANDOM puro;
- a **depuração**, pois um mismatch em um modo específico (ex.: CARRY) aponta diretamente para a condição de borda relevante, em vez de exigir garimpar um log de estímulos aleatórios.

O modo RANDOM continua disponível e agora coexiste com os modos dirigidos — a combinação de ambos (dirigido para os cantos conhecidos do espaço de entrada, aleatório para explorar o resto) é exatamente a estratégia recomendada por um Verification Plan maduro.
