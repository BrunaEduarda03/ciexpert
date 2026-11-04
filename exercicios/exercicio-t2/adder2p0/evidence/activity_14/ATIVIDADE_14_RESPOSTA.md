# Atividade 14

## Cobertura antes dos testes dirigidos

Duas medições reais de "antes", ambas extraídas do mesmo covergroup `cg_adder32` (Atividade 13):

### (a) Estado ao final da Atividade 13 (`testname="stimulus_modes"`)

**Score: 72.14%** — Variables 86.00% (14/16), Crosses 37.50% (3/8). Já documentado em `evidence/activity_13/`.

### (b) RANDOM puro, 5 seeds diferentes, 100% aleatório (demonstração desta atividade)

Para atender ao pedido explícito de "rodar random com várias seeds", o `testname` foi temporariamente ajustado para `"baseline"` (o teste 100% aleatório já existente desde a Atividade 11: `adder32_seqr(RANDOM,...)`, `EN_BURST` fixo, 100 sequências) e executado 5 vezes com seeds diferentes, todas acumuladas no mesmo banco de cobertura:

```
vcs ... -cm line+cond+fsm+branch+tgl  <arquivos>          # compila 1x com testname="baseline"
./simv +FSDB=adder32.fsdb -cm line+cond+fsm+branch+tgl -cm_name seed_1      +ntb_random_seed=1
./simv +FSDB=adder32.fsdb -cm line+cond+fsm+branch+tgl -cm_name seed_12345  +ntb_random_seed=12345
./simv +FSDB=adder32.fsdb -cm line+cond+fsm+branch+tgl -cm_name seed_999983 +ntb_random_seed=999983
./simv +FSDB=adder32.fsdb -cm line+cond+fsm+branch+tgl -cm_name seed_424242 +ntb_random_seed=424242
./simv +FSDB=adder32.fsdb -cm line+cond+fsm+branch+tgl -cm_name seed_777    +ntb_random_seed=777
```

Resultado real agregado (500 transações no total, 5×100), confirmado no Verdi (`evidence/activity_14/screenshots/01_before_random_only.png`) e no `urg`:

| Coverpoint/Cross | Score | Detalhe real |
|---|---|---|
| **Covergroup (geral)** | **57.86%** | U+C:24 · U:12 · C:12 |
| `cp_op_a` | 40.00% (2/5) | `mid`=729 hits, `high`=771 hits — `zero`, `low`, `max` = **0 hits** |
| `cp_op_b` | 40.00% (2/5) | `mid`=720 hits, `high`=780 hits — `zero`, `low`, `max` = **0 hits** |
| `cp_carry` | 100.00% | ambos os bins batidos facilmente (~50% de chance por transação) |
| `cp_en` | 50.00% | só `enabled` (o `"baseline"` nunca varia `en`) |
| `cp_reset` | 100.00% | o pulso de reset inicial já cobre `in_reset` uma vez |
| `cx_carry_en` | 50.00% | só as combinações `×enabled` |
| `cx_reset_en` | 25.00% | só `not_in_reset×enabled` |

## Análise dos bins não cobertos

**Por que `zero`, `low` e `max` de `op_a`/`op_b` nunca foram atingidos, mesmo com 500 amostras aleatórias de 5 seeds diferentes?**

Cada bin representa uma fração ínfima do espaço de 32 bits:

| Bin | Tamanho do intervalo | Probabilidade por amostra (`$urandom` uniforme em 2³²) |
|---|---|---|
| `zero` | 1 valor (`0x00000000`) | 1 / 2³² ≈ 2,3 × 10⁻¹⁰ |
| `low` | 255 valores (`0x1`–`0xFF`) | 255 / 2³² ≈ 5,9 × 10⁻⁸ |
| `max` | 1 valor (`0xFFFFFFFF`) | 1 / 2³² ≈ 2,3 × 10⁻¹⁰ |
| `mid` | ≈ 2³¹ valores | ≈ 50% |
| `high` | ≈ 2³¹ valores | ≈ 50% |

Com 500 amostras, o número **esperado** de acertos no bin `zero` é `500 × 2,3×10⁻¹⁰ ≈ 1,15×10⁻⁷` — ou seja, seria necessário rodar a simulação **na casa de dezenas de milhões de vezes** para ter uma chance razoável de acertar `A=0` por puro sorteio uniforme. Isso bate exatamente com a dica do enunciado da Atividade 1 (item c.v) e com o que a Seção 2.1 do caderno chama de "explosão do espaço de comportamentos": aumentar seeds ajuda a cobrir a faixa *provável* (`mid`/`high`, ambas com ~50% de chance, por isso fecham rápido), mas **não** ajuda a cobrir os *corner cases* de probabilidade extremamente baixa (`zero`, `max`) nem faixas estreitas (`low`, 255 em 4 bilhões) — não importa quantas seeds diferentes se rode, o comportamento assintótico não muda, só a esperança matemática de acerto, que continua desprezível.

**Por que `cp_en`/`cx_carry_en`/`cx_reset_en` não fecham com RANDOM puro (`"baseline"`)?** Esse não é um problema de probabilidade — é estrutural: o teste `"baseline"` dirige todas as transações com `EN_BURST` (`en=1` fixo por construção, ver Atividade 10). Não importa quantas seeds ou quantas transações rodem, `en` **nunca** assume o valor `0` nesse cenário, então o bin `disabled` de `cp_en` e todas as combinações `×disabled` dos dois crosses ficam permanentemente em 0% — nenhuma quantidade de aleatoriedade em `op_a`/`op_b` resolve isso, porque a variável que falta variar (`en`) não é sequer sorteada nesse teste.

## Estratégia utilizada

Em vez de "chutar" mais seeds ou usar `randcase`/pesos sobre o espaço de 32 bits inteiro (o que ainda deixaria a probabilidade de acertar `zero`/`max` desprezível), a estratégia foi **atribuição direta e determinística** dos valores exatos que faltavam, adicionada ao final do bloco `"stimulus_modes"` (Atividade 9) — que já fecha `cp_op_a`, `cp_carry` e `cp_reset` via `BASIC`/`ZERO`/`MAX`/`SMALL`/`BIG`/`CARRY`/`NO_CARRY`. Sete transações dirigidas (`D1`–`D7`) foram adicionadas para fechar exatamente os bins que sobraram (confirmados na tabela acima):

```systemverilog
// Atividade 14: estimulos dirigidos para fechar os bins que RANDOM
// puro nao fecha isoladamente (op_b=zero, en=disabled, e os
// cruzamentos com reset). cp_carry/cx_carry_en amostram carry_out
// (saida do DUT), que so atualiza quando en=1; por isso, para
// cobrir cada combinacao "x disabled", primeiro fixamos o valor de
// carry_out desejado com en=1 e so depois mantemos en=0 (retencao).

// D1: op_b=0 (op_a != 0), en=1 -> fecha cp_op_b bin "zero"
adder32_seq_item.a = 32'hDEAD_BEEF;
adder32_seq_item.b = 32'h0000_0000;
adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 1);
adder32_mon(adder32_vif, dut_r, 0);
rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
adder32_scb(dut_r, unsigned'(rfm_r), 1);

// D2: latch carry_out=1 com en=1 (a=b=max garante overflow)
adder32_seq_item.a = 32'hFFFF_FFFF;
adder32_seq_item.b = 32'hFFFF_FFFF;
adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 1);
adder32_mon(adder32_vif, dut_r, 0);
rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
adder32_scb(dut_r, unsigned'(rfm_r), 1);

// D3: en=0 logo em seguida -> carry_out retem 1, fecha cx_carry_en
//     "carry x disabled" e cp_en bin "disabled"
adder32_seq_item = adder32_seqr(RANDOM, 0);
adder32_drv(adder32_vif, adder32_seq_item, EN_DISABLE, 0);
adder32_mon(adder32_vif, dut_r, 0);
rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
adder32_scb(dut_r, unsigned'(rfm_r), 0); // mismatch esperado (retencao, ver abaixo)

// D4: latch carry_out=0 com en=1 (a=b=0 garante ausencia de overflow)
adder32_seq_item.a = 32'h0000_0000;
adder32_seq_item.b = 32'h0000_0000;
adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 1);
adder32_mon(adder32_vif, dut_r, 0);
rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
adder32_scb(dut_r, unsigned'(rfm_r), 1);

// D5: en=0 logo em seguida -> carry_out retem 0, fecha cx_carry_en "no_carry x disabled"
adder32_seq_item = adder32_seqr(RANDOM, 0);
adder32_drv(adder32_vif, adder32_seq_item, EN_DISABLE, 0);
adder32_mon(adder32_vif, dut_r, 0);
rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
adder32_scb(dut_r, unsigned'(rfm_r), 0); // mismatch esperado (retencao)

// D6: manter en=0 durante um 2o pulso de reset -> fecha cx_reset_en "in_reset x disabled"
adder32_seq_item = adder32_seqr(RANDOM, 0);
adder32_drv(adder32_vif, adder32_seq_item, EN_DISABLE, 0);
@(posedge clk);
reset_n = 1'b0;
@(posedge clk);
@(posedge clk);
reset_n = 1'b1;
@(posedge clk);

// D7: manter en=1 durante um 3o pulso de reset -> fecha cx_reset_en "in_reset x enabled"
adder32_seq_item = adder32_seqr(RANDOM, 0);
adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 0);
@(posedge clk);
reset_n = 1'b0;
@(posedge clk);
@(posedge clk);
reset_n = 1'b1;
@(posedge clk);
```

**Por que essa lógica funciona (raciocínio de causa-e-efeito, não tentativa e erro):**

- `cp_op_b` "zero": basta **uma** transação com `op_b=0` conduzida deterministicamente (`D1`) — sem depender do sorteio aleatório de qual operando o modo `ZERO` vai zerar.
- `cx_carry_en` "×disabled": `carry_out` é uma **saída do DUT**, e o DUT só atualiza `carry_out` quando `en=1` (retenção, Atividade 10). Portanto **não adianta** dirigir `op_a=op_b=0xFFFFFFFF` diretamente com `en=0` — o DUT nunca chegaria a calcular esse carry. A sequência correta é: (1) `en=1` com os operandos que geram o carry desejado, deixando o DUT *registrar* esse valor (`D2`/`D4`); (2) **na transação seguinte**, `en=0` — `carry_out` retém o valor já registrado, e é *esse* valor (retido) que o covergroup amostra junto com `en=disabled` (`D3`/`D5`).
- `cx_reset_en` "in_reset×{enabled,disabled}": exige `reset_n=0` e `en` com um valor definido **na mesma borda de clock**. Como isso nunca acontece nos testes existentes (o único pulso de reset ocorre antes de qualquer transação, quando `en` ainda é `X`), a solução foi **programar um segundo e um terceiro pulso de reset** diretamente no `initial` (mesma técnica já usada no início do arquivo para o reset original), um logo depois de fixar `en=0` (`D6`) e outro logo depois de fixar `en=1` (`D7`) — como nada mais altera `en` nesse intervalo, o valor permanece estável durante o pulso de reset, e o covergroup amostra a combinação exata que faltava.

Os `$display("[DRIVER-LOG]...")`/`adder32_scb(..., 0)` em `D3`/`D5` usam `en_log=0` de propósito — igual ao padrão já usado no branch `"en_modes"` da Atividade 10 — porque o scoreboard sempre compara `dut_r` (que retém o valor antigo quando `en=0`) contra um `rfm_r` recém-calculado a partir dos novos operandos sorteados; esse "mismatch" é **esperado e não é um bug** (é a prova visual de retenção, já documentada na Atividade 10), então foi silenciado no log para não confundir a leitura, exatamente como já era feito.

## Nova execução

```
source /Tools/synopsys/snps.sh
make clean
make all
make cov
make verdi_cov
```

`make all` compila (`-cm line+cond+fsm+branch+tgl`, mantido sem alteração desde a Atividade 12/13) e roda os 14 estímulos de `"stimulus_modes"` + as 7 transações dirigidas `D1`–`D7`, terminando em `$finish at simulation time 705000` sem erros de compilação/elaboração.

## Cobertura final

Real, extraída de `simv.vdb` via `make cov` (`urg`) e conferida pixel a pixel contra a GUI do Verdi (`make verdi_cov`):

| Coverpoint/Cross | Antes (`stimulus_modes`, Ativ. 13) | Depois (`stimulus_modes` + D1–D7) |
|---|---|---|
| `cp_op_a` | 100.00% | **100.00%** |
| `cp_op_b` | 80.00% | **100.00%** |
| `cp_carry` | 100.00% | **100.00%** |
| `cp_en` | 50.00% | **100.00%** |
| `cp_reset` | 100.00% | **100.00%** |
| `cx_carry_en` | 50.00% | **100.00%** |
| `cx_reset_en` | 25.00% | **100.00%** |
| **Variables (geral)** | 86.00% (14/16) | **100.00% (16/16)** |
| **Crosses (geral)** | 37.50% (3/8) | **100.00% (8/8)** |
| **Covergroup `cg_adder32` (Score)** | 72.14% | **100.00%** |

## Evidências

Capturas reais da GUI de cobertura do Verdi, salvas em `evidence/activity_14/screenshots/`:

| Arquivo | O que mostra |
|---|---|
| `01_before_random_only.png` | **Antes** — RANDOM puro (5 seeds, `"baseline"`): `Avg. Group Score: 57.86%`, `cp_op_a`/`cp_op_b` em 40.00% (vermelho), `cp_en` 50.00%, `cx_carry_en` 50.00%, `cx_reset_en` 25.00% |
| `02_after_directed_100pct.png` | **Depois** — `stimulus_modes` + `D1`–`D7`: `Avg. Group Score: 100.00%`, `U+C:24 U:0 C:24 X:0` — todos os 5 coverpoints e os 2 crosses em verde, 100.00% |
| `03_cx_reset_en_100pct.png` | Detalhe de bins do cruzamento mais difícil de fechar (`cx_reset_en`): as 4 combinações (`in_reset×disabled`, `in_reset×enabled`, `not_in_reset×disabled`, `not_in_reset×enabled`) com check verde |

## Relação com a Atividade 3

| Coverpoint/Cross fechado por `D1`–`D7` | CP do mini-VP | Como ficou 100% |
|---|---|---|
| `cp_op_b` (bin `zero`) | **CP2** (b_zero) | `D1`: `op_b=0` dirigido |
| `cp_en` (bin `disabled`) | **CP6** (en_s) | `D3`/`D5`/`D6`: `en=0` dirigido |
| `cx_carry_en` (`×disabled`) | **CP10** | `D2`+`D3` (carry) e `D4`+`D5` (no_carry): latch com `en=1`, depois retenção com `en=0` |
| `cx_reset_en` (as 3 combinações que faltavam) | **CP11** | `D6`/`D7`: segundo e terceiro pulso de reset com `en` fixado antes |

Combinado com o que a Atividade 13 já havia fechado (`cp_op_a`, `cp_carry`, `cp_reset`, 3/4 de `cx_carry_en` — na verdade 2/4 — e 1/4 de `cx_reset_en`), **todos os CP1–CP11** do mini-Verification Plan da Atividade 3 estão agora cobertos a 100%.

## Conclusão

**A cobertura chegou a 100%** — Variables 16/16, Crosses 8/8, Score do covergroup `cg_adder32` = 100.00%, confirmado tanto pelo relatório `urg` quanto pixel a pixel na GUI do Verdi. Não sobrou nenhum bin descoberto.

Isso só foi possível **combinando** as duas estratégias, e não uma sozinha:

- **RANDOM puro** (mesmo repetido com 5 seeds diferentes, 500 amostras) é ótimo para bins de alta probabilidade (`mid`/`high`, `carry`/`no_carry`, ambos ~50% de chance por amostra) e é insubstituível para achar bugs em regiões do espaço de entrada que ninguém pensou em testar manualmente — mas é estruturalmente incapaz de fechar bins de baixíssima probabilidade (`zero`/`max`/`low` de um espaço de 2³²) em tempo de simulação viável, e é **completamente cego** a variáveis que o próprio cenário de teste nunca varia (`en`, no caso do `"baseline"`), não importa quantas seeds se rode.
- **Estímulo dirigido** fecha exatamente os bins de baixa probabilidade ou estruturalmente inatingíveis por sorteio, com poucas transações (`D1`–`D7`, apenas 7 transações extras) — mas sozinho não teria a mesma robustez que o RANDOM tem para achar combinações inesperadas fora do que foi explicitamente pensado.

A combinação é mais eficiente que qualquer uma isolada: o RANDOM (via `stimulus_modes`'s bloco `RANDOM` e via os modos `CARRY`/`NO_CARRY`/`SMALL`/`BIG`) cobre a "massa" do espaço de forma barata e ampla; o dirigido cobre os "cantos" exatos que a probabilidade não alcançaria em nenhum tempo razoável. Essa é exatamente a lição da Seção 2.1 do caderno: verificar bem não é escolher entre aleatório e dirigido, é gerenciar deliberadamente a cobertura de cada um, usando a métrica de cobertura funcional para decidir *onde* a geração dirigida precisa entrar.
