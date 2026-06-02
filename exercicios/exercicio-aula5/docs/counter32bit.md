# Contador 32 bits com Overflow — Guia Didático

## 1. O que é este circuito?

Imagine o **hodômetro do carro** — aquele contador de quilômetros que vai subindo a cada quilômetro rodado. Ele começa no zero, vai subindo, e quando chega no máximo... zera e começa de novo. Este circuito é a versão eletrônica disso, mas contando pulsos de clock e capaz de ir até 4.294.967.295 (o número máximo em 32 bits).

A grande diferença do hodômetro: este contador tem três recursos extras:

- Um botão de **reset** que zera tudo instantaneamente
- Um botão de **pausa** (`en = 0`) que congela a contagem
- Uma entrada **load** que permite "teleportar" o contador para um valor específico (como ajustar o hodômetro para um valor pré-definido)
- Um sinal de **overflow** que avisa quando o contador "deu a volta" e zerou

**Analogia alternativa:** Pense em um **cronômetro digital** com a opção de definir o tempo de início. Você pode pausar, reiniciar do zero, ou carregá-lo com um valor próximo do fim para testar o overflow rapidamente.

---

## 2. Como funciona?

A cada pulso de clock, o circuito verifica (nesta ordem de prioridade, com um detalhe importante de bug):

1. **Reset (`reset_n = 0`)?** Zera o contador.
2. **Load (`load = 1`)?** Carrega o valor pré-definido `0xFFFFFFF8` com o bit 32 em 1.
3. **Enable (`en = 1`)?** Incrementa o contador em 1.

O contador usa internamente **33 bits** (não 32!). O bit extra (bit 32) é o **bit de overflow** — ele fica em `1` quando o valor passou de `0xFFFFFFFF`. A saída `counter_out` mostra apenas os 32 bits inferiores, e `counter_overflow` mostra só o bit 32.

**O que é overflow?** Quando o contador chega em `0xFFFFFFFF` (4.294.967.295) e recebe mais um incremento, os 32 bits "dão a volta" para `0x00000000`. O bit 33 (bit de overflow) registra esse evento. É como o hodômetro que passa de 999.999 para 000.000 — você sabe que deu uma volta.

> **Atenção: BUG no RTL!** O código usa `if` separados em vez de `else if`. Veja a seção do código para detalhes.

---

## 3. Os sinais explicados

| Sinal              | Direção | Largura | O que faz                                                       |
| ------------------ | ------- | ------- | --------------------------------------------------------------- |
| `clk`              | Entrada | 1 bit   | Clock do sistema — cada pulso pode incrementar o contador       |
| `reset_n`          | Entrada | 1 bit   | Reset ativo em nível baixo: `0` zera tudo imediatamente         |
| `en`               | Entrada | 1 bit   | Enable: `1` permite contar, `0` pausa (congela)                 |
| `load`             | Entrada | 1 bit   | Carrega o valor `0xFFFFFFF8` no contador (8 passos do overflow) |
| `counter_out`      | Saída   | 32 bits | Valor atual do contador (0 a 4.294.967.295)                     |
| `counter_overflow` | Saída   | 1 bit   | `1` quando o contador ultrapassou 32 bits                       |

---

## 4. O código RTL linha a linha

```verilog
module counter_overflow(
    clk,
    reset_n,
    en,
    load,
    counter_out,
    counter_overflow
);
```

**Declaração do módulo:** Define o nome `counter_overflow` e lista os pinos.

```verilog
input clk, reset_n;
input en;
input load;
output [31:0] counter_out;
output counter_overflow;
```

**Tipos dos pinos:** Saídas de 32 bits para a contagem e 1 bit para o overflow.

```verilog
reg [32:0] counter_reg;
wire load;
```

**Registrador de 33 bits:** O segredo está aqui — `counter_reg` tem 33 bits (índices 32 a 0). O bit 32 é o de overflow, os bits 31 a 0 são a contagem visível. É como ter um dígito secreto extra no hodômetro que acende uma luz quando deu a volta.

```verilog
assign counter_overflow = counter_reg[32];
assign counter_out = counter_reg[31:0];
```

**Divisão da saída:** `counter_overflow` pega apenas o bit 32 (o bit mais alto). `counter_out` pega os 32 bits inferiores. O operador `assign` é como ligar um fio diretamente — sem clock, sem delay.

```verilog
always @(posedge clk or negedge reset_n)
begin
    if (!reset_n) begin
        counter_reg <= 33'd0;
    end
```

**Reset assíncrono:** Quando `reset_n` cai para `0`, zera os 33 bits imediatamente, sem esperar o clock.

```verilog
    if (load)
        counter_reg <= 33'b111111111111111111111111111111000;
```

**Load — o BUG aparece aqui:** Este `if` deveria ser `else if`. Como é um `if` separado, ele sempre executa após o reset, podendo sobrescrever o zero recém-atribuído. O valor `33'b111...11000` em hexadecimal é `overflow=1, counter_out=0xFFFFFFF8` — exatamente 8 passos antes do wrap de 32 bits (voltando a zero).

```verilog
    if (en)
        counter_reg <= counter_reg + 33'd1;
end
```

**Incremento — o BUG se aprofunda:** Outro `if` separado. Se `en` e `load` estiverem ativos ao mesmo tempo, **ambas as atribuições não-bloqueantes (`<=`) são programadas**, mas como `en` vem depois, o incremento sobrescreve o load. Isso significa que a **prioridade real** é: `en > load > reset_n`. O inverso do que parece ser intenção do design.

> **Resumo do bug:** Com `if` separados e atribuições `<=`, a última atribuição ganha. A ordem correta deveria ser `else if (load) ... else if (en)`.

---

## 5. O testbench explicado

O testbench é cuidadosamente construído para explorar todos os comportamentos, incluindo o bug:

```verilog
// Gera clock de período 10 ns
always #5 clk = ~clk;

initial begin
    // Reset inicial
    clk=0; reset_n=0; en=0; load=0;
    @(posedge clk); #1; reset_n=1;
    // Verifica: cnt=0, overflow=0
```

**Teste de contagem básica:**

```verilog
    en = 1; load = 0;
    repeat(8) @(posedge clk);
    // Verifica que contou de 1 a 8, mostra cada ciclo
```

**Teste de congelamento:**

```verilog
    en = 0;  // para a contagem
    @(posedge clk); #1;
    // Verifica que cnt ainda é 8 (não avançou)
```

**Teste de load — o teste mais importante:**

```verilog
    load = 1; en = 0;  // IMPORTANTE: en=0 para load funcionar (por causa do bug)
    @(posedge clk); #1;
    load = 0;
    // Verifica: cnt=0xFFFFFFF8, overflow=1

    // Agora conta a partir de 0xFFFFFFF8
    en = 1;
    repeat(10) @(posedge clk);
    // Observa o wrap em 0xFFFFFFFF → 0x00000000
```

**Por que `en=0` durante o load?** Causa do bug! Se `en=1` e `load=1` ao mesmo tempo, o incremento sobrescreve o load. O testbench contorna isso desligando `en` durante o load.

---

## 6. Resultado real da simulação

```
  SIMULACAO: Contador 32 bits com Overflow
  Funcao: contar de 0 ate 4.294.967.295 (2^32 - 1)
  [RESET] cnt=0 overflow=0  [OK]

  --- Contagem basica (en=1, load=0) ---
  ciclo | counter_out | overflow
    1   | 00000000001 | 0
    2   | 00000000002 | 0
    3   | 00000000003 | 0
    4   | 00000000004 | 0
    5   | 00000000005 | 0
    6   | 00000000006 | 0
    7   | 00000000007 | 0
    8   | 00000000008 | 0

  --- Freeze: en=0 para a contagem ---
  en=0 -> cnt=8 (deve manter 8)  [OK - congelou]

  --- Load: carrega 0xFFFFFFF8 (decimal 4294967288) ---
  Isso = 8 posicoes antes do overflow!
  load=1 en=0 -> cnt=0xfffffff8 ovf=1  [OK]

  --- Contando a partir de 0xFFFFFFF8 ate overflow ---
     1  | 0xfffffff9  |    1     | 4294967289
     2  | 0xfffffffa  |    1     | 4294967290
     3  | 0xfffffffb  |    1     | 4294967291
     4  | 0xfffffffc  |    1     | 4294967292
     5  | 0xfffffffd  |    1     | 4294967293
     6  | 0xfffffffe  |    1     | 4294967294
     7  | 0xffffffff  |    1     | 4294967295
     8  | 0x00000000  |    0     | 0   <- wrap!
     9  | 0x00000001  |    0     | 1
    10  | 0x00000002  |    0     | 2

  BUG NO RTL: if separados em vez de else if
  reset_n=0 (com en=0) -> cnt=0 ovf=0  [OK]
  RESULTADO FINAL: TODOS OS TESTES PASSARAM (0 erros)
```

---

## 7. Interpretando os resultados

**`[RESET] cnt=0 overflow=0 [OK]`**
Estado inicial correto: ao aplicar reset, tudo vai a zero.

**`ciclos 1 a 8: 1, 2, 3, ... 8 | overflow=0`**
Contagem linear simples. O overflow permanece `0` porque ainda estamos longe do valor máximo. Nota: o overflow começa em `1` logo após o load — isso porque o valor `0xFFFFFFF8` carregado inclui o bit 32 em `1`.

**`en=0 -> cnt=8 (deve manter 8) [OK - congelou]`**
Quando desligamos o enable, o contador para exatamente onde estava. O valor `8` se mantém por quantos clocks quisermos.

**`load=1 en=0 -> cnt=0xfffffff8 ovf=1 [OK]`**
Após o load, o contador salta diretamente para `4.294.967.288` com o bit de overflow já em `1`. Isso é proposital: o valor carregado (`33'b111...11000`) inclui o bit de overflow.

**`ciclo 7: 0xffffffff | ovf=1`**
O contador chega ao valor máximo de 32 bits: 4.294.967.295. Próximo passo será o wrap.

**`ciclo 8: 0x00000000 | ovf=0 <- wrap!`**
O grande momento: `0xFFFFFFFF + 1` com 33 bits resulta em `0x100000000`. Os 32 bits inferiores são `0x00000000` e o bit 32 zera também (passou de `1` para `0`). É o "hodômetro dando a volta".

**`ciclos 9 e 10: 0x00000001, 0x00000002`**
Após o wrap, a contagem continua normalmente a partir do zero.

**`BUG NO RTL: if separados em vez de else if`**
O testbench detecta e documenta o bug. O design funciona nos testes porque foram cuidadosamente escritos para evitar os casos problemáticos.

---

## 8. Na prática: para que serve e quando usar?

O contador é um dos blocos **mais usados em hardware**. Todo sistema digital que precisa medir tempo, cadenciar eventos ou gerar sinais periódicos usa um contador por baixo dos panos.

**Onde aparece na vida real:**
- **Timers e watchdogs:** microcontroladores têm contadores de 16 ou 32 bits que contam ciclos de clock. Quando chegam a um valor alvo, disparam uma interrupção. É assim que `delay_ms(100)` funciona — um contador contando até o valor equivalente a 100 ms de clock.
- **Geração de PWM:** o sinal PWM (usado para controlar motores, LEDs com dimmer, servos) é gerado comparando o contador com um threshold. Quando `counter < duty_cycle`, saída = 1; senão saída = 0.
- **Baud rate de UART:** a transmissão serial precisa de um clock derivado. Um contador divide o clock do sistema para gerar a frequência correta (9600, 115200 bps).
- **Endereçamento sequencial:** leitura de memória FIFO, streaming de dados para DAC, escrita em buffers — tudo usa um contador como ponteiro que avança automaticamente.
- **Medição de frequência:** conta pulsos externos durante um intervalo fixo. No final, o valor do contador é a frequência medida.

**O sinal de overflow é crítico** em qualquer aplicação onde o contador pode atingir o limite: timers de watchdog precisam detectar o overflow para resetar o sistema; acumuladores de DSP precisam saturar ou sinalizar overflow para não corromper o sinal.

**Quando escolher 32 bits:** quando você precisa contar por longos períodos sem overflow. Com clock de 100 MHz e contador de 32 bits, o overflow ocorre a cada ~42 segundos. Para contadores de tempo real ou de posição de motor, 32 bits é o mínimo prático.

---

## 9. Waveform da Simulação Real

A captura abaixo foi gerada no Surfer após rodar `make wave BLOCK=counter32bit`:

![waveform counter32bit](../images/image-3.png)

Esta é a simulação mais longa (~200.000 ps) — precisa contar desde `0xFFFFFFF8` até o wrap. Vale a pena.

O waveform conta três momentos distintos. **Primeiro**, `counter_out` sobe linearmente de 0 — parece que vai ficar assim para sempre. **Segundo**, o sinal `load` aparece como um pulso fino de 1 ciclo e `counter_out` dá um salto brusco para `0xFFFFFFF8`. Junto disso, `overflow` sobe para 1 — porque esse valor alto já está na região de estouro.

**Terceiro e mais dramático**: `counter_out` passa por `0xFFFFFFFF` e no ciclo seguinte aparece `0x00000000`. Nesse exato instante, `overflow` cai de volta para 0 simultaneamente. Você vê os dois sinais mudando juntos na mesma borda de clock — é o wrap-around, o hodômetro voltando ao zero.

O `en` cai brevemente no teste de freeze: `counter_out` para completamente, sem avançar um único valor. Ao religar, retoma de onde parou. `errors` permanece em 0 em todos os 11 testes.
