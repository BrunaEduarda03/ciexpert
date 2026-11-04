# Atividade 11

## Problema encontrado

Antes desta atividade, `dpi/refmod.c` era:

```c
uint64_t refmod(uint64_t a, uint64_t b, bool en_log) {
  uint64_t r = 0;

  if(en_log) {
    printf("\n\r");
    printf("# ---------------------------\n");
    printf("# refmod execution\n");
    printf("# ---------------------------\n");
  }
  return r;
}
```

A variável `r` era declarada com o valor `0` e **retornada sem nunca ser atualizada** — não existia nenhuma linha somando `a + b`. Ou seja, o Reference Model sempre devolvia `0` para o testbench, independentemente dos operandos recebidos via DPI-C. Como o scoreboard (`adder32_scb.sv`) compara `dut_r` (resultado real do DUT) com `rfm_r` (resultado do Reference Model), e `rfm_r` era sempre `0`, todo mismatch registrado nas Atividades 8–10 (`error` no log, sempre que `dut_r != 0`) era **esperado e não indicava bug no DUT** — o Adder32 em si sempre esteve correto; o ambiente de verificação é que não tinha um modelo de referência funcional para comparar contra. Isso está documentado desde a Atividade 8, onde os mismatches foram explicitamente atribuídos a esse bug conhecido do `refmod.c`, fora do escopo até esta atividade.

## Correção do Reference Model

Arquivo: `dpi/refmod.c` (completo e compilável — testado com VCS X-2025.06-SP2):

```c
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <inttypes.h>
#include "svdpi.h"

uint64_t refmod(uint64_t a, uint64_t b, bool en_log) {
  // a e b chegam do SV ja como uint64_t (longint unsigned), mas representam
  // operandos de 32 bits (op_a/op_b). A soma de dois valores de 32 bits pode
  // precisar de 33 bits para representar o carry (ex.: 0xFFFFFFFF + 0xFFFFFFFF
  // = 0x1FFFFFFFE). Se a soma fosse feita em uint32_t, o carry seria perdido
  // por overflow silencioso (wrap-around modulo 2^32). Como a e b ja sao
  // uint64_t, a soma abaixo e feita em aritmetica de 64 bits, preservando o
  // 33o bit (carry) sem qualquer risco de overflow.
  uint64_t r = a + b;

  if(en_log) {
    printf("\n\r");
    printf("# ---------------------------\n");
    printf("# refmod execution\n");
    printf("# ---------------------------\n");
    printf("# a = 0x%016" PRIx64 ", b = 0x%016" PRIx64 ", r = 0x%016" PRIx64 "\n", a, b, r);
  }
  return r;
}
```

A única mudança funcional é `uint64_t r = a + b;` no lugar de `uint64_t r = 0;` (mais um `printf` opcional, só ativado com `en_log=1`, para depuração). Nenhuma outra estrutura do arquivo foi alterada: mesmos `#include`s, mesma assinatura de função, mesmo bloco de log condicional.

### Por que `uint64_t` e não `uint32_t`?

`op_a` e `op_b` são operandos de 32 bits, então `a + b` pode valer, no máximo, `0xFFFFFFFF + 0xFFFFFFFF = 0x1FFFFFFFE` — um valor que precisa de **33 bits** para ser representado sem perda (o 33º bit é exatamente o `carry_out` do somador). Se `a`, `b` e `r` fossem `uint32_t`, a soma estouraria a largura do tipo e o compilador C faria *wrap-around* silencioso módulo `2^32` (comportamento definido para inteiros sem sinal em C, mas incorreto para o que queremos representar) — o carry seria perdido sem nenhum aviso, e `r` conteria só os 32 bits baixos da soma, igual ao `adder_out` do DUT mas sem o `carry_out`. Como `dut_r` no SV é `logic [32:0]` (33 bits: `{carry_out, adder_out}`), comparar contra um `rfm_r` de 32 bits geraria mismatches sistemáticos toda vez que houvesse carry — exatamente o tipo de bug sutil que motivou o `C5` do mini-VP da Atividade 3 ("Verificação do Carry"). Usando `uint64_t` (64 bits) para `a`, `b` e `r`, a soma de dois valores de até 32 bits nunca estoura os 64 bits disponíveis, e os 33 bits baixos do resultado já são exatamente `{carry, soma}` — sem necessidade de nenhuma lógica extra de detecção de overflow no C.

## Integração DPI-C

A comunicação entre SystemVerilog e C acontece via a declaração de importação já existente em `tb/tb_adder32.sv`, **inalterada** nesta atividade:

```systemverilog
import "DPI-C" function longint unsigned refmod(
  input longint unsigned a,
  input longint unsigned b,
  input bit en_log
);
```

Essa assinatura permanece **compatível** com o `refmod.c` corrigido:

| SystemVerilog | Tipo DPI-C correspondente | C (`refmod.c`) |
|---|---|---|
| `longint unsigned` (retorno) | `uint64_t` | `uint64_t` (retorno) |
| `input longint unsigned a` | `uint64_t` | `uint64_t a` |
| `input longint unsigned b` | `uint64_t` | `uint64_t b` |
| `input bit en_log` | tipo escalar de 1 bit | `bool en_log` |

O padrão IEEE 1800 (DPI-C) mapeia `longint unsigned` para `uint64_t` e `longint` para `int64_t` — já era exatamente o que o `refmod.c` original usava, então **nenhuma mudança na declaração `import "DPI-C"` foi necessária**. Como só o *corpo* da função C mudou (a lógica interna), e não sua assinatura, a interface entre as duas linguagens permanece idêntica — exatamente o que a atividade pede ("não altere a interface... sem necessidade").

Cada chamada `rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);` no testbench invoca essa função C diretamente durante a simulação (linkada estaticamente no `simv` pelo Makefile, via `gcc -c dpi/refmod.c` + link no `g++`), de forma síncrona: o SV bloqueia até o C retornar, e o valor de retorno (`uint64_t`) é atribuído a `rfm_r` (`longint unsigned` no SV, mesma largura).

O Reference Model é essencial num ambiente **self-checking** porque ele fornece um segundo caminho, **independente do RTL**, para calcular o resultado esperado. Sem ele, "verificar" o DUT significaria só olhar a waveform manualmente e confiar que os números "parecem certos" — não escala para 100, 1000 ou mais transações, e não pega bugs sutis. Com o Reference Model funcionando, o scoreboard consegue comparar automaticamente `dut_r` (o que o hardware calculou) contra `rfm_r` (o que deveria ter sido calculado, por uma implementação simples e auditável em C) a cada transação, sem intervenção humana — isso é exatamente o que torna o ambiente "self-checking": ele mesmo decide passa/falha, em vez de depender de inspeção visual.

## Alterações no Testbench

Arquivo: `tb/tb_adder32.sv`. Duas mudanças mínimas, sem tocar na arquitetura do monitor (`adder32_mon.sv`, inalterado) nem no driver:

```systemverilog
// TB control variables
localparam int NUM_OF_SEQUENCES = 100; // Atividade 11: 100 sequencias self-checking
...
string testname = "baseline";
```

O branch `"baseline"` já existia desde as primeiras atividades e já fazia exatamente o fluxo pedido (seqr → driver → monitor → refmod → scoreboard, em loop); só precisou de uma linha adicional ao final do loop, chamando o novo resumo do scoreboard:

```systemverilog
"baseline": begin
  ...
  repeat(NUM_OF_SEQUENCES) begin
    // seqr (modo RANDOM preserva o comportamento original deste teste)
    adder32_seq_item = adder32_seqr(RANDOM, 0);

    // driver+monitor (EN_BURST preserva o comportamento original: en sempre 1)
    adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 0);
    adder32_mon(adder32_vif, dut_r, 0);

    // rfm
    rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);

    // scoreboard
    adder32_scb(dut_r, unsigned'(rfm_r), 1);
  end

  // Atividade 11: resumo final de matches/mismatches
  adder32_scb_report();
end
```

## Alterações no Scoreboard

Arquivo: `tb/adder32_scb.sv`. A função `adder32_scb()` original (comparação `dut_r != rfm_r` com `$display("pass")`/`$display("error")`) foi **preservada integralmente** — só foram adicionados contadores (variáveis de escopo de arquivo, que persistem entre chamadas) e uma nova função `adder32_scb_report()` para imprimir o resumo:

```systemverilog
//
// Atividade 11: contabiliza matches/mismatches/total de transacoes
// e imprime um resumo ao final da simulacao.
//
int unsigned adder32_scb_transactions = 0;
int unsigned adder32_scb_matches      = 0;
int unsigned adder32_scb_mismatches   = 0;

function void adder32_scb(logic [32:0] dut_r, logic [32:0] rfm_r, bit en_log);
  if(en_log)
    $display("dut_r %d, rfm_r %d", dut_r, rfm_r);

  adder32_scb_transactions++;

  if (dut_r != rfm_r) begin
    adder32_scb_mismatches++;
    if(en_log)
      $display("error");
  end else begin
    adder32_scb_matches++;
    if(en_log)
      $display("pass");
  end
endfunction: adder32_scb

// Atividade 11: resumo final (chamado uma vez, ao termino de todas as transacoes)
function void adder32_scb_report();
  real pass_rate;
  pass_rate = (adder32_scb_transactions == 0) ? 0.0 :
              100.0 * real'(adder32_scb_matches) / real'(adder32_scb_transactions);

  $display("==============================");
  $display("Simulation Summary");
  $display("==============================");
  $display("Transactions : %0d", adder32_scb_transactions);
  $display("Matches      : %0d", adder32_scb_matches);
  $display("Mismatches   : %0d", adder32_scb_mismatches);
  $display("Pass Rate    : %0.1f %%", pass_rate);
  $display("==============================");
endfunction: adder32_scb_report
```

Como `adder32_scb.sv` não está dentro de nenhum `module`/`package` (é compilado no escopo de unidade de compilação, `$unit`, igual aos demais arquivos de TB deste projeto — `adder32_drv.sv`, `adder32_seqr.sv`), os contadores declarados no topo do arquivo ficam visíveis tanto para `adder32_scb()` (que os incrementa a cada chamada) quanto para `adder32_scb_report()` e para `tb_adder32.sv` (que só chama `adder32_scb_report()` uma vez, ao final do loop de 100 sequências).

## Resultados

Log real da execução (`source snps.sh; make vcs_clean; make all`, VCS X-2025.06-SP2), mostrando o final das 100 transações e o resumo:

```
dut_r 5218186491, rfm_r 5218186491
pass
dut_r 6838213843, rfm_r 6838213843
pass
dut_r 3453437256, rfm_r 3453437256
pass
dut_r 6227938063, rfm_r 6227938063
pass
dut_r 5474725887, rfm_r 5474725887
pass
dut_r 1119760838, rfm_r 1119760838
pass
dut_r 6797476685, rfm_r 6797476685
pass
dut_r 4790529381, rfm_r 4790529381
pass
dut_r 2117740014, rfm_r 2117740014
pass
dut_r 5391554095, rfm_r 5391554095
pass
dut_r 7029864861, rfm_r 7029864861
pass
dut_r 5867401907, rfm_r 5867401907
pass
dut_r 5919178361, rfm_r 5919178361
pass
dut_r 4060063538, rfm_r 4060063538
pass
dut_r 5462994034, rfm_r 5462994034
pass
dut_r 5854861856, rfm_r 5854861856
pass
dut_r 4051671157, rfm_r 4051671157
pass
dut_r 3758471986, rfm_r 3758471986
pass
dut_r  852602295, rfm_r  852602295
pass
dut_r 4428276809, rfm_r 4428276809
pass
dut_r 6658756847, rfm_r 6658756847
pass
dut_r 2694532330, rfm_r 2694532330
pass
dut_r 1729648693, rfm_r 1729648693
pass
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
```

**100 de 100 transações com `dut_r == rfm_r`, 0 mismatches, 100.0% de pass rate** — nenhum erro de compilação/elaboração, `$finish` normal em 3.038 us de simulação. Este é o primeiro resultado limpo desde a Atividade 8 (todas as atividades anteriores documentaram mismatches esperados por causa do `refmod.c` quebrado).

## Waveforms

Capturas reais no Verdi (`clk`, `reset_n`, `en`, `op_a`, `op_b`, `adder_out`, `carry_out`, `dut_r`, `rfm_r`), salvas em `evidence/activity_11/screenshots/`:

- **`01_overview.png`** — visão geral das 100 transações (t=0 a t=3.038.000 ps, cursor em 58.000ns / marker em 3.028.000ns, delta=2.970.000ps cobrindo as 100 transações): `dut_r` e `rfm_r` aparecem lado a lado, com a mesma cadência de mudança de `op_a`/`op_b`, sem nenhum ponto de divergência visível ao longo de toda a simulação.
- **`02_dut_rfm_match.png`** — zoom nas 4 primeiras transações (0–150.000 ps, cursor=58.000ns, marker=88.000ns, delta=30.000ps = 1 transação): mostra `op_a`/`op_b` mudando a cada 30ns, `adder_out`/`carry_out` do DUT atualizando 1 ciclo depois, `dut_r` (33 bits, `{carry_out, adder_out}`) e `rfm_r` (calculado pelo `refmod.c` corrigido) **exibindo exatamente o mesmo valor numérico** a cada transação — a prova visual direta de que o DUT e o Reference Model calculam o mesmo resultado.

**Sobre "comparação realizada pelo scoreboard" na waveform**: o resultado da comparação (`dut_r != rfm_r`) é uma checagem pontual dentro da função `adder32_scb()`, não um sinal persistente do design — por isso não existe um traço "scb_result" na waveform. A evidência equivalente e correta é justamente `dut_r` e `rfm_r` lado a lado nas capturas acima: como os dois têm sempre o mesmo valor em todos os pontos de amostragem, isso é visualmente a mesma informação que o scoreboard verifica internamente a cada chamada — confirmado numericamente pelos 100/100 matches no log.

## Relação com a Atividade 3

| Feature/Checker do mini-VP | Como esta atividade valida |
|---|---|
| **F1 — Soma** | Cada uma das 100 transações RANDOM compara `dut_r` (soma real do DUT) contra `rfm_r` (soma do Reference Model corrigido); 100/100 matches confirma F1 em ampla amostragem aleatória. |
| **F2 — Carry Out** | Como `dut_r`/`rfm_r` são comparados como valor de 33 bits (`{carry_out, adder_out}`), qualquer transação com overflow de 32 bits (`carry_out=1`) só passaria se o carry também estivesse correto nos dois lados — os 100/100 matches cobrem isso automaticamente, sem precisar de um teste dedicado. |
| **F6 — Latência** | O monitor (`adder32_mon`, inalterado) só lê `dut_r` depois da latência de 1 ciclo já confirmada na Atividade 8; comparar contra `rfm_r` nesse instante certo é o que garante que a latência está sendo respeitada — um erro de timing apareceria como mismatch. |
| **C1 — Comparação com Reference Model** | É literalmente o que esta atividade implementa: o `refmod.c` corrigido é o Reference Model, e `adder32_scb()` é quem faz a comparação, transação a transação. |
| **C5 — Verificação do Carry** | Garantida pela decisão de usar `uint64_t` no C (ver seção "Correção do Reference Model") — sem isso, C5 falharia silenciosamente em qualquer transação com carry. |
| **C7 — Estatísticas do Scoreboard (matches/mismatches)** | É exatamente o que `adder32_scb_report()` entrega: contagem de transações, matches, mismatches e taxa de acerto, antes só um "TODO" no código original. |

Isso também contribui diretamente para os **Critérios de Fechamento (DoD)** do mini-VP: "Zero mismatches" (100/100, atingido) e parcialmente para "Bugs corrigidos" (o bug do `refmod` retornando 0 estava explicitamente listado como pendente desde a Atividade 3; segue pendente só o bug do driver com `en` preso em 1, que já foi corrigido na Atividade 10).

## Conclusão

Até a Atividade 10, o ambiente de verificação do Adder32 rodava, gerava estímulos dirigidos e aleatórios sofisticados (Atividades 9 e 10), mas **não conseguia se autoavaliar** — o scoreboard sempre reportava `error`, não porque o DUT estivesse errado, mas porque o Reference Model nunca calculava nada de fato. Depois de corrigir `refmod.c` para realizar a soma de verdade (em `uint64_t`, preservando o carry), o ambiente passou a ser **verdadeiramente self-checking**: a cada transação, o scoreboard compara automaticamente o resultado do hardware com um segundo cálculo independente em C, sem precisar de inspeção manual de waveform para saber se passou ou falhou.

Com 100 sequências aleatórias rodadas e 100/100 matches, este é o primeiro momento no projeto em que se pode afirmar, com evidência objetiva (não só leitura visual), que o Adder32 está funcionalmente correto para soma e carry na amostra testada. Essa é exatamente a base que faltava para as próximas atividades: agora que passa/falha é decidido automaticamente pelo próprio testbench, o próximo passo natural é medir e fechar a **cobertura funcional** (os coverpoints CP1–CP11 do Verification Plan da Atividade 3) com confiança de que qualquer bin coberto corresponde a um resultado realmente verificado, e não a um mismatch mascarado por um Reference Model quebrado.
