# Atividade 15

## Objetivo

Expandir `tb/adder32_assertion.sv` com três novas assertions temporais (SVA) que apontam direto para a causa de um bug em vez de só observar o sintoma na saída — latência, retenção e causalidade do carry — e adicionar um `cover property` para cada uma, comprovando que todas foram de fato exercitadas durante a simulação (não apenas escritas). Nenhum outro arquivo da arquitetura foi alterado além do necessário para conectar os novos sinais que as assertions passaram a observar.

## Assertions implementadas

Arquivo completo `tb/adder32_assertion.sv`:

```systemverilog
module adder32_assertion #(
  parameter int NBW = 32
)(
  input logic           clk,
  input logic           reset_n,

  input logic           en,
  input logic [NBW-1:0] op_a,
  input logic [NBW-1:0] op_b,

  input logic [NBW-1:0] adder_out,
  input logic           carry_out
);

  // During reset, DUT outputs must be zero.
  property p_reset_outputs_zero;
    @(posedge clk)
      (!reset_n) |-> (adder_out == '0 && carry_out == 1'b0);
  endproperty

  a_reset_outputs_zero: assert property (p_reset_outputs_zero)
    else begin
      $error("[ASSERTION] Reset failure: adder_out=%0h carry_out=%0b while reset_n=0",
             adder_out,
             carry_out);
    end

  cov_reset_outputs_zero: cover property (p_reset_outputs_zero);

  //
  // Atividade 15: assertions temporais alem do reset
  //

  // Latencia: 1 ciclo depois de en=1 amostrado (com reset_n=1) junto com
  // op_a/op_b, a saida {carry_out, adder_out} deve refletir exatamente a
  // soma de 33 bits desses operandos (LATENCY=1, Figura 2 do caderno).
  property p_latency_sum;
    @(posedge clk) disable iff (!reset_n)
      ($past(en) && $past(reset_n)) |->
        ({carry_out, adder_out} == ($past(op_a) + $past(op_b)));
  endproperty

  a_latency_sum: assert property (p_latency_sum)
    else begin
      $error("[ASSERTION] Latency failure: esperado {carry,adder_out}=%0h, obtido {%0b,%0h}",
             $past(op_a) + $past(op_b),
             carry_out,
             adder_out);
    end

  cov_latency_sum: cover property (p_latency_sum);

  // Retencao: se en=0 (fora de reset) no ciclo N, a saida {adder_out,
  // carry_out} no ciclo N+1 deve permanecer identica a do ciclo N.
  property p_retention;
    @(posedge clk) disable iff (!reset_n)
      (!en) |=> $stable({adder_out, carry_out});
  endproperty

  a_retention: assert property (p_retention)
    else begin
      $error("[ASSERTION] Retention failure: adder_out/carry_out mudaram com en=0");
    end

  cov_retention: cover property (p_retention);

  // Causalidade do carry: carry_out deve ser exatamente o bit mais
  // significativo (bit NBW) da soma de 33 bits de op_a+op_b amostrados no
  // ciclo em que a soma foi registrada (en=1 no ciclo anterior). Isolada da
  // checagem geral de latencia (p_latency_sum), serve como segunda fonte de
  // evidencia independente especificamente sobre o carry_out.
  property p_carry_causality;
    logic [NBW:0] sum33;
    @(posedge clk) disable iff (!reset_n)
      ($past(en) && $past(reset_n), sum33 = {1'b0, $past(op_a)} + {1'b0, $past(op_b)})
        |-> (carry_out == sum33[NBW]);
  endproperty

  a_carry_causality: assert property (p_carry_causality)
    else begin
      $error("[ASSERTION] Carry causality failure: carry_out=%0b nao bate com o MSB da soma registrada", carry_out);
    end

  cov_carry_causality: cover property (p_carry_causality);

endmodule: adder32_assertion
```

**Integração mínima e necessária**: `adder32_assertion` originalmente só recebia `clk`, `reset_n`, `adder_out`, `carry_out` — insuficiente para checar latência/retenção/causalidade, que dependem de `en`, `op_a` e `op_b`. Três novas portas de entrada foram adicionadas (mesmo padrão já usado pelo módulo `adder32_coverage` da Atividade 13), e a instância `uu_adder32_assertion` em `tb/tb_adder32.sv` foi atualizada para conectar `uu_adder32_if.en/op_a/op_b`. Nenhum outro arquivo (driver, monitor, sequencer, scoreboard, RTL) foi tocado.

## Explicação de cada assertion

### `a_reset_outputs_zero` (já existente, preservada)
- **Comportamento verificado**: enquanto `reset_n=0`, `adder_out` e `carry_out` devem ser `0`.
- **Por que importa**: garante que o estado do somador após reset é sempre conhecido e limpo, sem lixo do ciclo anterior.
- **Quando dispara**: se, durante o reset assíncrono do RTL (`always@(posedge clk or negedge reset_n) if(!reset_n) adder_reg<=33'd0;`), a saída não fosse zerada — por exemplo, se alguém reescrevesse o RTL trocando o reset assíncrono por um síncrono mal implementado.

### `a_latency_sum` (nova)
- **Comportamento verificado**: se `en=1` e `reset_n=1` foram amostrados numa borda de clock, então na **borda seguinte** `{carry_out, adder_out}` deve ser exatamente igual à soma de 33 bits dos `op_a`/`op_b` daquela borda (`$past(op_a) + $past(op_b)`).
- **Por que importa**: é a checagem central da funcionalidade do DUT — sem ela, um erro na lógica de soma (`adder_reg <= op_a + op_b`) só seria pego pelo scoreboard (comparação estatística, sem apontar o ciclo exato) ou por inspeção manual de waveform.
- **Quando dispara**: se o RTL atrasasse a soma por mais de 1 ciclo (pipeline extra não documentado), se `en` fosse ignorado, ou se a lógica de soma estivesse simplesmente errada (ex.: subtração no lugar de soma).

### `a_retention` (nova)
- **Comportamento verificado**: se `en=0` (fora de reset) numa borda de clock, `{adder_out, carry_out}` deve permanecer **igual** na borda seguinte (`$stable`).
- **Por que importa**: é exatamente o comportamento de retenção especificado na Seção 2.2.1 do caderno ("O sinal fica retido se en=0 e não estiver em reset") e testado manualmente na Atividade 10 — agora vira uma checagem formal, automática, rodando em toda simulação, sem precisar de inspeção visual de waveform.
- **Quando dispara**: se o RTL atualizasse `adder_reg` mesmo com `en=0` (ex.: um bug removendo o `if(en)` do RTL), a saída mudaria indevidamente e a assertion pegaria isso no ciclo exato em que ocorreu.

### `a_carry_causality` (nova)
- **Comportamento verificado**: no ciclo em que a soma é registrada (`en=1` no ciclo anterior), `carry_out` deve ser exatamente o bit 32 (MSB) da soma de 33 bits `op_a+op_b` daquele ciclo — calculado de forma isolada de `adder_out`, e não apenas como parte da igualdade de 33 bits já verificada por `a_latency_sum`.
- **Por que importa**: separa a checagem do carry da checagem geral da soma. Se `a_latency_sum` falhasse só por causa do carry (por exemplo, um bug que inverte o bit de carry mas mantém os 32 bits baixos corretos), `a_carry_causality` aponta exatamente para esse sintoma, isolando mais rápido a causa (RTL: `carry_out = adder_reg[32]`).
- **Quando dispara**: se `carry_out` fosse calculado errado (ex.: usando `op_a[31] & op_b[31]` — heurística comum, porém incorreta — em vez do carry real de 33 bits).

## Cover das assertions

Um `cover property` para cada uma das 4 propriedades, feito referenciando a property já nomeada (sem duplicar a lógica temporal):

```systemverilog
cov_reset_outputs_zero: cover property (p_reset_outputs_zero);
cov_latency_sum:        cover property (p_latency_sum);
cov_retention:          cover property (p_retention);
cov_carry_causality:    cover property (p_carry_causality);
```

Cada `cover` conta quantas vezes a **implicação inteira** da property (antecedente E consequente, ambos verdadeiros) realmente aconteceu durante a simulação — não só quantas vezes o antecedente foi tentado. Isso é o que confirma, com números reais, que a regra não só "nunca foi violada" (o que poderia significar apenas que ela nunca foi testada) mas que **de fato ocorreu e passou**.

## Execução

```
source /Tools/synopsys/snps.sh
make clean
make all
make verdi_wf
```

Nenhuma alteração no Makefile foi necessária — `ASSERT_FILES = tb/adder32_assertion.sv` já compilava o arquivo, e o cenário ativo (`testname = "stimulus_modes"`, com os estímulos das Atividades 9/14) já dirige transações com `en=1` (a maioria) e `en=0` (as diretivas `D3`/`D5`/`D6` da Atividade 14) na mesma simulação — suficiente para exercitar as 4 propriedades sem precisar de nenhum cenário extra.

## Evidências

### Log da simulação (real, sem nenhum `$error` de assertion)

```
$finish called from file "tb/tb_adder32.sv", line 401.
$finish at simulation time               705000
"tb/adder32_assertion.sv", 28: adder_tb.uu_adder32_assertion.cov_reset_outputs_zero, 70 attempts, 5 match
"tb/adder32_assertion.sv", 51: adder_tb.uu_adder32_assertion.cov_latency_sum, 70 attempts, 51 match
"tb/adder32_assertion.sv", 65: adder_tb.uu_adder32_assertion.cov_retention, 70 attempts, 7 match
"tb/adder32_assertion.sv", 84: adder_tb.uu_adder32_assertion.cov_carry_causality, 70 attempts, 51 match
```

Nenhuma linha `[ASSERTION] ... failure` apareceu em todo o log (confirmado com `grep -n "ASSERTION\|Error-" <log>` → nenhum resultado) — as 4 assertions passaram em **todas** as bordas de clock da simulação, e os 4 covers têm pelo menos 1 match (na prática, muitos: 51, 51, 7 e 5).

### Relatório de cobertura de assertions (`make cov`, real, `urgReport/asserts.html`)

```
Summary for Cover Properties
Total Number: 4    Uncovered: 0    Matches: 4   -> 100.00%

COVER PROPERTIES                                      ATTEMPTS   MATCHES
adder_tb.uu_adder32_assertion.cov_carry_causality         70        51
adder_tb.uu_adder32_assertion.cov_latency_sum              70        51
adder_tb.uu_adder32_assertion.cov_reset_outputs_zero       70         5
adder_tb.uu_adder32_assertion.cov_retention                70         7
```

**100% dos cover properties atingidos** — os 4 covers implementados nesta atividade tiveram match pelo menos uma vez.

### Captura do Verdi

`evidence/activity_15/screenshots/01_asserts_tab.png` — aba **Asserts** da GUI de cobertura do Verdi (`make verdi_cov`, mesma técnica das Atividades 12–14), mostrando as 4 cover properties com status **Success** (verde) e a contagem real de matches (51, 51, 5, 7) — batendo exatamente com o log do console e com o relatório `urg`.

## Relação com a Atividade 3

| Assertion | Item do mini-VP coberto |
|---|---|
| `a_reset_outputs_zero` / `cov_reset_outputs_zero` | **F3** (Reset assíncrono ativo baixo), **C2** (checagem de reset via assertion), **T9** (reset a qualquer momento) |
| `a_latency_sum` / `cov_latency_sum` | **F1** (Soma), **F6** (Latência), **C1**/**C3** (comparação com Reference Model / checagem de latência) — agora com uma segunda fonte de evidência independente do scoreboard, no nível de ciclo exato |
| `a_retention` / `cov_retention` | **F5** (Retenção com en=0), **C4** (assertion de retenção, que a Atividade 3 já previa como "a implementar") — item que ficava pendente desde o mini-VP original, fechado nesta atividade |
| `a_carry_causality` / `cov_carry_causality` | **F2** (Carry out), **C5** (Verificação do Carry) — reforça, de forma independente do scoreboard, que o carry corresponde exatamente ao MSB da soma registrada |

## Conclusão

Assertions aceleram o *debug* porque disparam **no exato ciclo e no exato ponto da regra violada**, em vez de deixar o engenheiro rastrear o sintoma desde a saída primária até a causa — é a diferença entre "o scoreboard disse que 1 em 100 transações deu erro" (Atividade 11) e "a assertion `a_retention` disparou no ciclo 598000, exatamente quando `en` caiu para 0" (o tipo de mensagem que `$error` já imprime, com os valores envolvidos). Como a Seção 2.2.6 do caderno explica, isso poupa o trabalho de "percorrer o caminho de trás para frente" a partir da saída.

Os `cover property`, por sua vez, são o que garante que essa velocidade de debug é real e não uma falsa sensação de segurança: uma assertion que nunca dispara pode significar tanto "está tudo certo" quanto "a regra nunca foi sequer testada" — são indistinguíveis sem o `cover`. Nesta atividade, os 4 covers com matches reais (51, 51, 7 e 5, respectivamente para carry, latência, retenção e reset) provam que as 4 regras foram genuinamente exercitadas pelos estímulos já existentes (Atividades 9/10/14), e não apenas escritas e nunca alcançadas — exatamente o alerta que o próprio caderno faz na caixa de destaque da Seção 2.2.8.
