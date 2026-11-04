# Atividade 13

## Objetivo

Implementar cobertura funcional (via `covergroup`) para `op_a`, `op_b`, `carry_out`, `en` e `reset_n`, cobrindo diretamente os coverpoints CP1–CP9 e os crosses CP10/CP11 já planejados no mini-Verification Plan da Atividade 3, sem alterar a arquitetura existente do projeto (interface, driver, monitor, scoreboard, sequencer e RTL permanecem intocados).

## Covergroup implementado

Seguindo o mesmo padrão arquitetural já usado por `adder32_assertion.sv` (um módulo auxiliar, parametrizado por `NBW`, conectado à `adder32_if` e instanciado ao lado da assertion em `tb_adder32.sv`), foi criado um novo arquivo `tb/adder32_coverage.sv`:

```systemverilog
/**
 * Adder32 Functional Coverage
 *
 * @brief: covergroup para op_a, op_b, carry_out, en e reset_n (Atividade 13),
 *         implementando os coverpoints CP1-CP9 e os crosses CP10/CP11 do
 *         mini-Verification Plan da Atividade 3.
 */
module adder32_coverage #(
  parameter int NBW = 32
)(
  input logic           clk,
  input logic           reset_n,
  input logic           en,

  input logic [NBW-1:0] op_a,
  input logic [NBW-1:0] op_b,
  input logic           carry_out
);

  covergroup cg_adder32 @(posedge clk);
    option.per_instance = 1;
    option.name = "cg_adder32";

    // CP1/CP3/CP9: faixa de valor de op_a (zero, baixo, medio, alto, maximo)
    cp_op_a: coverpoint op_a {
      bins zero   = {32'h0000_0000};
      bins low    = {[32'h0000_0001 : 32'h0000_00FF]};
      bins mid    = {[32'h0000_0100 : 32'h7FFF_FFFF]}; // "medium" e palavra reservada (trireg charge strength)
      bins high   = {[32'h8000_0000 : 32'hFFFF_FFFE]};
      bins max    = {32'hFFFF_FFFF};
    }

    // CP2/CP4/CP9: faixa de valor de op_b (zero, baixo, medio, alto, maximo)
    cp_op_b: coverpoint op_b {
      bins zero   = {32'h0000_0000};
      bins low    = {[32'h0000_0001 : 32'h0000_00FF]};
      bins mid    = {[32'h0000_0100 : 32'h7FFF_FFFF]}; // "medium" e palavra reservada (trireg charge strength)
      bins high   = {[32'h8000_0000 : 32'hFFFF_FFFE]};
      bins max    = {32'hFFFF_FFFF};
    }

    // CP5: carry_out
    cp_carry: coverpoint carry_out {
      bins no_carry = {1'b0};
      bins carry    = {1'b1};
    }

    // CP6: en (enable)
    cp_en: coverpoint en {
      bins disabled = {1'b0};
      bins enabled  = {1'b1};
    }

    // CP7: reset_n
    cp_reset: coverpoint reset_n {
      bins in_reset     = {1'b0};
      bins not_in_reset = {1'b1};
    }

    // CP10: cruzamento carry_out x en
    cx_carry_en: cross cp_carry, cp_en;

    // CP11: cruzamento reset_n x en
    cx_reset_en: cross cp_reset, cp_en;

  endgroup: cg_adder32

  cg_adder32 cg_adder32_inst = new();

endmodule: adder32_coverage
```

**Integração** (mínima e aditiva, mesma técnica já usada para `adder32_assertion`):

- `tb/tb_adder32.sv`: nova instância `uu_adder32_coverage`, cabeada aos mesmos sinais de `uu_adder32_if` (`clk`, `reset_n`, `en`, `op_a`, `op_b`, `carry_out`) — copiado logo abaixo da instância existente `uu_adder32_assertion`.
- `Makefile`: nova variável `COV_FILES = tb/adder32_coverage.sv`, adicionada à linha de compilação do `vcs`, na mesma posição em que `ASSERT_FILES` já era usado.

**Duas descobertas reais durante a implementação, corrigidas:**

1. `medium` é uma **palavra reservada do Verilog** (força de carga de `trireg`: `small`/`medium`/`large`) — o VCS rejeitou `bins medium = {...}` com erro de sintaxe. O bin foi renomeado para `mid`.
2. A flag `-cm` desta versão do VCS **não tem uma keyword `cvg` separada** (`Error-[CM-ARGPL]`: as flags válidas são `line cond fsm tgl branch obc path assert sdc property_path`). Cobertura de `covergroup` é coletada automaticamente sempre que `-cm` está ativo, então `VCS_COV_METRICS` da Atividade 12 (`line+cond+fsm+branch+tgl`) foi mantida sem alteração — nenhuma flag nova foi necessária para a cobertura funcional funcionar.

## Explicação dos coverpoints

| Coverpoint | Sinal | Bins | O que mede |
|---|---|---|---|
| `cp_op_a` | `op_a` | `zero`, `low` (1–0xFF), `mid` (0x100–0x7FFFFFFF), `high` (0x80000000–0xFFFFFFFE), `max` | Se `op_a` já assumiu um valor em cada uma das 5 faixas pedidas pela atividade |
| `cp_op_b` | `op_b` | mesmos 5 bins de `cp_op_a` | Idem, para `op_b` |
| `cp_carry` | `carry_out` | `no_carry` (0), `carry` (1) | Se a saída de carry já foi observada nos dois estados |
| `cp_en` | `en` | `disabled` (0), `enabled` (1) | Se o enable já foi exercitado desabilitado e habilitado |
| `cp_reset` | `reset_n` | `in_reset` (0), `not_in_reset` (1) | Se o DUT já foi observado tanto em reset quanto fora dele |

Os limites de `low`/`high` foram alinhados de propósito aos modos já existentes no sequencer (Atividade 9): `low` = 1..0xFF é exatamente a faixa que o modo `SMALL` gera; `high` = 0x8000_0000..0xFFFF_FFFE cobre a faixa que o modo `BIG` (0xF000_0000..0xFFFFFFFF) e o modo `CARRY` (que sorteia `a` nesse intervalo) alcançam.

## Explicação dos crosses

- **`cx_carry_en = cross cp_carry, cp_en`** (CP10): verifica se todas as combinações entre `carry_out` (0/1) e `en` (0/1) já ocorreram simultaneamente — 4 combinações possíveis (`no_carry×disabled`, `no_carry×enabled`, `carry×disabled`, `carry×enabled`). É importante porque prova que a lógica de carry foi observada tanto com o somador ativo quanto desativado, não só isoladamente.
- **`cx_reset_en = cross cp_reset, cp_en`** (CP11): verifica as 4 combinações entre `reset_n` e `en` — em particular, se o projeto já testou `en=1` sendo aplicado **durante** o reset (`in_reset × enabled`), um cenário de borda clássico de verificação (T9/T12 do mini-VP).

Os dois crosses usam bins **automáticos** (produto cartesiano dos bins dos coverpoints cruzados) — não foi necessário declarar `bins` explícitos nos `cross`, já que os dois coverpoints envolvidos (`cp_carry`/`cp_en` e `cp_reset`/`cp_en`) já têm exatamente 2 bins nomeados cada, então o cross gera as 4 combinações nomeadas automaticamente (`<bin1>_<bin2>`).

## Relação com a Atividade 3

| Coverpoint/Cross | CP do mini-VP | Cenário(s) associado(s) |
|---|---|---|
| `cp_op_a` (bin `zero`) | **CP1** (a_zero) | T2, T11 |
| `cp_op_b` (bin `zero`) | **CP2** (b_zero) | T2, T11 |
| `cp_op_a` (bin `max`) | **CP3** (a_max) | T3, T11 |
| `cp_op_b` (bin `max`) | **CP4** (b_max) | T3, T11 |
| `cp_carry` | **CP5** (carry_out) | T4, T5, T11 |
| `cp_en` | **CP6** (en_s) | T7, T8, T11 |
| `cp_reset` | **CP7** (reset_active) | T9, T10, T12 |
| `cp_op_a`/`cp_op_b` (bins `low`/`mid`/`high`) | **CP9** (value_range) | T1, T2, T3, T11 |
| `cx_carry_en` | **CP10** (cross_carry_en) | T4, T5, T7, T11 |
| `cx_reset_en` | **CP11** (cross_reset_en) | T9, T10, T12 |

O único coverpoint do mini-VP não implementado aqui é **CP8** (`alt_pattern` — A/B em padrão alternado `0xAAAAAAAA`/`0x55555555`), porque a Atividade 13 pediu explicitamente cobertura para `op_a`, `op_b`, `carry_out`, `en` e `reset_n` com as categorias "zero/máximo/baixo/médio/alto/carry/enable/reset" — o padrão alternado não está nessa lista. O modo `PATTERN` do sequencer (Atividade 9) já gera esse estímulo; um coverpoint dedicado para CP8 pode ser adicionado depois sem alterar nada do que já existe.

## Resultados

Ambiente compilado e simulado com `source snps.sh; make clean; make all` (VCS X-2025.06-SP2), usando `testname = "stimulus_modes"` (Atividade 9) — escolha deliberada: é o único cenário já existente que exercita todas as 5 faixas de valor de `op_a`/`op_b` (`BASIC`, `ZERO`, `MAX`, `SMALL`, `BIG`, `MINMAX`, mais `CARRY`/`NO_CARRY`/`PATTERN`/`RANDOM`) na mesma rodada. Simulação terminou sem erros, todas as transações com `pass` (Reference Model corrigido na Atividade 11).

Cobertura funcional real, extraída de `simv.vdb` via `make cov` (`urg`) e conferida pixel a pixel contra a GUI do Verdi — os números batem exatamente nos dois:

### Resumo do covergroup

**`cg_adder32` — Score: 72.14%** (Variables: 14/16 = 86.00% · Crosses: 3/8 = 37.50%)

| Coverpoint/Cross | Bins esperados | Cobertos | Não cobertos | Score |
|---|---|---|---|---|
| `cp_op_a` | 5 | 5 | 0 | **100.00%** |
| `cp_op_b` | 5 | 4 | 1 (`zero`) | **80.00%** |
| `cp_carry` | 2 | 2 | 0 | **100.00%** |
| `cp_en` | 2 | 1 | 1 (`disabled`) | **50.00%** |
| `cp_reset` | 2 | 2 | 0 | **100.00%** |
| `cx_carry_en` | 4 | 2 | 2 (`*_disabled`) | **50.00%** |
| `cx_reset_en` | 4 | 1 | 3 | **25.00%** |

### Detalhe por bin (contagem de hits real)

- `cp_op_a`: `zero`=3, `low`=6, `mid`=6, `high`=21, `max`=6 — todos cobertos.
- `cp_op_b`: `zero`=**0** (não coberto), `low`=6, `mid`=12, `high`=18, `max`=6.
- `cp_carry`: `no_carry`=25, `carry`=20.
- `cp_en`: `enabled`=42, `disabled`=**0** (não coberto).
- `cp_reset`: `not_in_reset`=44, `in_reset`=1.
- `cx_carry_en`: `no_carry×enabled`=22, `carry×enabled`=20; `no_carry×disabled` e `carry×disabled` não cobertos.
- `cx_reset_en`: `not_in_reset×enabled`=42; `not_in_reset×disabled`, `in_reset×enabled` e `in_reset×disabled` não cobertos.

## Evidências

Capturas reais da GUI de cobertura do Verdi (`make verdi_cov`), salvas em `evidence/activity_13/screenshots/`:

| Arquivo | O que mostra |
|---|---|
| `00_initial.png` | Janela inicial da GUI de cobertura, aba Hierarchy |
| `01_groups_tab.png` | Aba **Groups**: `Avg. Group Score: 72.14%` e a linha do covergroup `adder_tb.uu_adder32_coverage::cg_adder32` |
| `02_group_expanded.png` | Covergroup expandido mostrando **todos os coverpoints e os 2 crosses simultaneamente**: `cp_carry` 100%, `cp_en` 50% (vermelho), `cp_op_a` 100%, `cp_op_b` 80%, `cp_reset` 100%, `cx_carry_en` 50% (vermelho), `cx_reset_en` 25% (vermelho) |
| `03_cp_op_b_detail.png` | Detalhe de bins de `cp_op_b`: `high`/`low`/`max`/`mid` com check verde, `zero` com X vermelho — com o código-fonte real de `adder32_coverage.sv` no painel central |
| `04_cx_reset_en_detail.png` | Detalhe do cross `cx_reset_en`: linha `[in_reset]×[enabled,dis...]` (X vermelho), `[not_in_reset]×[disabled]` (X vermelho), `not_in_reset×enabled` (check verde) — com a linha `cx_reset_en: cross cp_reset, cp_en;` destacada no código-fonte |

## Conclusão

O covergroup `cg_adder32` fechou em **72.14%**, com um padrão bem definido e totalmente explicável pelos dados reais coletados — nenhum bin ficou sem cobertura por acaso:

- **`cp_op_a` 100%, `cp_carry` 100%, `cp_reset` 100%**: o cenário `"stimulus_modes"` já exercita deliberadamente zero, máximo, baixo, médio e alto para `op_a` (via `ZERO`, `MAX`, `SMALL`, `BIG`, `RANDOM`), ambos os valores de carry (via `CARRY`/`NO_CARRY`) e reset (o pulso de reset inicial já é amostrado uma vez em `in_reset`).
- **`cp_op_b` 80% — falta o bin `zero`**: o modo `ZERO` do sequencer (Atividade 9) sorteia aleatoriamente **qual** operando zera (`a=0`, `b=0`, ou os dois) a cada chamada; nesta rodada específica o sorteio caiu em `a=0` (visível no log: `mode=ZERO op_a=32'h00000000 op_b=32'hdae0253f`), então `op_b` nunca recebeu exatamente `0` nesta execução. **Não é um bug** — é a aleatoriedade do próprio `ZERO` combinada com uma única chamada por rodada. Rodar novamente (seed diferente) ou chamar `adder32_seqr(ZERO, ...)` mais de uma vez fecharia esse bin.
- **`cp_en` 50% — falta `disabled`, e os dois crosses ficam parcialmente vazios por causa disso**: `"stimulus_modes"` dirige todas as transações com `EN_BURST` (`en=1` fixo) — o cenário que varia `en` (`EN_DISABLE`/`EN_RANDOM`) só existe no branch `"en_modes"` (Atividade 10), que não rodou nesta sessão de cobertura. Isso explica **exatamente** por que `cx_carry_en` perde as duas combinações `×disabled` e `cx_reset_en` perde três das quatro combinações (qualquer uma envolvendo `disabled`, mais o `in_reset×enabled` que também nunca ocorreu porque durante o reset inicial `en` ainda estava em `X`, indefinido, e uma amostra com `en=X` não bate em nenhum bin de `cp_en`).

**Para fechar os 27.86% restantes, sem escrever nenhum teste novo**: bastaria rodar, na mesma coleta de cobertura (mesclando bancos com `urg -dir simv.vdb -dir <outro_vdb>`, ou repetindo a simulação com `-cm_dir` acumulativo), o cenário `testname = "en_modes"` já implementado na Atividade 10 — ele fecha `cp_en` (bin `disabled`) e as combinações `×disabled` dos dois crosses. O único bin que nenhum cenário atual fecha de forma garantida é `not_in_reset×disabled` e `in_reset×enabled`/`in_reset×disabled` em `cx_reset_en`, porque nenhum teste hoje aplica `en=0` **durante** o reset ou logo após — fechar isso exigiria um teste dirigido novo (fora do escopo desta atividade, que pede para não alterar a arquitetura): um cenário que force `en=0` enquanto `reset_n=0`, e depois mantenha `en=0` por pelo menos um ciclo após `reset_n` subir, exatamente o cenário T9/T12 do Verification Plan da Atividade 3 que já havia sido identificado como pendente na Atividade 10.
