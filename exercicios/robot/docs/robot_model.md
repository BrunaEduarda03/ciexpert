# Robot Model — Guia Didático

## 1. O que é este circuito?

Imagine um braço robótico numa linha de montagem: ele precisa saber **qual estação pediu primeiro**, executar a sequência certa de movimentos para pegar e entregar a peça, e nunca atender duas estações ao mesmo tempo.

Esse é o `robot_model`. Um controlador em Verilog que gerencia **4 estações de trabalho** (s0 a s3) com dois tipos de operação:

- **Carga:** o braço se move horizontalmente, pega a peça e volta para a posição vertical
- **Descarga:** o braço rotaciona até a estação, posiciona a junta, solta a garra e retorna

**Onde isso aparece no mundo real?** Em braços robóticos de CNC, linhas de montagem automotivas e até nos robôs que manipulam wafers de silício em fábricas de chips — onde um movimento errado na sequência errada destrói a peça.

---

## 2. Como funciona?

O circuito tem **três máquinas de estado rodando ao mesmo tempo**. Pense nelas como três funcionários que trabalham juntos:

**FSM Principal (Main Control)** — o "gerente". Recebe os pedidos das estações e decide quem vai ser atendido. As estações s0 e s1 têm prioridade sobre s2 e s3. Quando o atendimento termina, volta ao estado de espera (IDLE).

**Load FSM** — o "operador de carga". Quando qualquer estação pede, ele executa a sequência de carga em 4 passos:

```
IDLE → WRIST_HOR → LOAD_ITEM → WRIST_VERT → IDLE
          ↑                          ↑
    load_start = 1          load_done_int = 1
   (braço horizontal)       (carga concluída)
```

**Unload FSM** — o "operador de descarga". Executa a sequência de movimentos para soltar a peça na estação. Tem dois caminhos diferentes dependendo da estação. ⚠️ Esta FSM tem um bug crítico — veja a Seção 5.

---

## 3. Os sinais explicados

| Sinal | Direção | O que faz |
|-------|---------|-----------|
| `clock` | Entrada | Pulso que sincroniza tudo |
| `reset_n` | Entrada | Zera tudo imediatamente (ativo em nível baixo) |
| `s0_req … s3_req` | Entrada | "Estação X quer ser atendida" |
| `s0_unload_done … s3_unload_done` | Entrada | "Estação X terminou a descarga" |
| `load_start` | Saída | Ativo por 1 ciclo quando o braço vai para posição horizontal |
| `s0_unloadstart` | Saída | Ativo quando a carga termina (= `load_done_int`) |
| `s1_unloadstart` | Saída | **Igual ao s0** — ambos recebem o mesmo sinal (Bug 3) |
| `s2_unloadstart` | Saída | Baseado nos estados da Unload FSM |
| `s3_unloadstart` | Saída | **Sempre em 1** — bug de precedência de operadores |

---

## 4. O código RTL — o que cada parte faz

**O coração do circuito:** um único `always` com clock atualiza os três estados de uma vez:

```verilog
always @(posedge clock or negedge reset_n) begin
   if (~reset_n) begin
      curr_state    <= 2'b00;  // todas as FSMs vão para IDLE
      load_cstate   <= 2'b00;
      unload_cstate <= 2'b00;
   end else begin
      curr_state    <= next_state;
      load_cstate   <= load_nstate;
      unload_cstate <= unload_nstate;
   end
end
```

**A Load FSM — funciona corretamente:**

```verilog
IDLE:      se tem req → vai para WRIST_HOR
WRIST_HOR: → LOAD_ITEM     (load_start = 1 aqui)
LOAD_ITEM: → WRIST_VERT
WRIST_VERT:→ IDLE           (load_done_int = 1 aqui → avisa s0 e s1)
```

**As saídas — onde estão os bugs:**

```verilog
assign s0_unloadstart = load_done_int;   // ok, mas igual ao s1
assign s1_unloadstart = load_done_int;   // Bug 3: deveria ser diferente

assign s2_unloadstart = (unload_cstate == JOINTA_RIGHT | RELEASE_CLAWE | JOINTA_LEFT);
//                       ↑ faltam parênteses: Bug 2

assign s3_unloadstart = (unload_cstate == JOINTA_RIGHT | JOINTC_DOWN | JOINTC_UP | RELEASE_CLAWE | JOINTA_LEFT);
//                       ↑ JOINTC_UP=011 tem bit0=1 → resultado sempre = 1: Bug 2
```

---

## 5. Os bugs do RTL

### Bug 1 — Registrador de 2 bits para estados que precisam de 3 bits

```verilog
reg [1:0] unload_cstate;  // ← 2 bits não são suficientes
```

Os estados da Unload FSM chegam a 6 (JOINTA_LEFT = `3'b110`), mas com 2 bits só cabem valores até 3. Quando o Verilog tenta guardar o valor 4 ou 6 em 2 bits, ele **corta os bits de cima**:

| Estado | Valor original | O que é guardado | Efeito |
|--------|---------------|------------------|--------|
| JOINTA_RIGHT | 1 | 1 | ✓ OK |
| JOINTC_DOWN | 2 | 2 | ✓ OK |
| JOINTC_UP | 3 | 3 | ✓ OK |
| RELEASE_CLAWE | **4** | **0** | ✗ vira IDLE |
| JOINTA_LEFT | **6** | **2** | ✗ vira JOINTC_DOWN |

**Resultado:** a Unload FSM nunca completa o ciclo. Para s0/s2, fica em loop `IDLE → JOINTA_RIGHT → IDLE`. Para s1/s3, vai até `JOINTC_DOWN` e volta ao IDLE.

**Correção:** trocar `[1:0]` por `[2:0]`.

---

### Bug 2 — Parênteses faltando nas saídas s2 e s3

Em Verilog, `==` tem **maior prioridade** que `|`. Então esta linha:

```verilog
assign s3_unloadstart = (unload_cstate == JOINTA_RIGHT | JOINTC_DOWN | JOINTC_UP | ...);
```

É lida pelo compilador como:

```verilog
assign s3_unloadstart = (unload_cstate == 1) | 2 | 3 | 4 | 6;
//                       ↑ 0 ou 1            ↑ constantes com bit0=1 em JOINTC_UP (=3)
//                       resultado: sempre não-zero → s3_unloadstart = SEMPRE 1
```

**Resultado:** `s3_unloadstart` fica permanentemente em `1` — a estação 3 nunca recebe o sinal correto.

**Correção:** colocar parênteses em cada comparação:
```verilog
assign s3_unloadstart = (unload_cstate == JOINTA_RIGHT) |
                        (unload_cstate == JOINTC_DOWN)  |
                        (unload_cstate == JOINTC_UP)    | ...
```

---

### Bug 3 — s0 e s1 com o mesmo sinal de saída

O código comentado no RTL deixa claro que a intenção era cada estação ter uma sequência diferente de descarga. Mas os comentários foram substituídos por atribuições simplificadas que fazem s0 e s1 se comportarem de forma idêntica:

```verilog
// Intenção original (comentada no código):
// assign s0_unloadstart = (unload_cstate == JOINTA_RIGHT | RELEASE_CLAWE | JOINTA_LEFT);
// assign s1_unloadstart = (unload_cstate == JOINTA_RIGHT | JOINTC_DOWN | ... | JOINTA_LEFT);

// O que ficou:
assign s0_unloadstart = load_done_int;  // iguais
assign s1_unloadstart = load_done_int;  // iguais
```

---

## 6. Resultado da simulação

```
  SIMULACAO: Robot Model — FSM de Controle Industrial

  --- TESTE 1: Reset assincrono ---
  [OK]   load_start=0, s0/s1_unloadstart=0 (reset ativo)
  [OK]   todos os sinais = 0 apos soltar reset

  --- TESTE 2: Load FSM — sequencia s0_req ---
  [OK]   load_start=1 (WRIST_HOR)
  [OK]   load_start=0 (LOAD_ITEM)
  [OK]   s0_unloadstart=1, s1_unloadstart=1 (WRIST_VERT)
  [OK]   s0/s1_unloadstart=0 (Load FSM voltou ao IDLE)

  --- TESTES 3, 4 e 5: Load FSM para s1, s2 e s3 ---
  [OK]   comportamento identico ao s0 para todas as estacoes

  --- TESTE 6: Main FSM — prioridade s0/s1 sobre s2/s3 ---
  [OK]   s0 atendido primeiro quando s0 e s2 chegam juntos

  --- TESTE 7: Main FSM — retorno ao IDLE por unload_done ---
  [OK]   FSM volta ao IDLE apos receber unload_done

  --- TESTE 8: Reset assincrono durante operacao ---
  [OK]   interrompe qualquer operacao em andamento

  --- TESTE 9: BUG documentado — reg [1:0] unload_cstate ---
  RELEASE_CLAWE e JOINTA_LEFT sao inalcancaveis (truncado para IDLE)

  --- TESTE 10: BUG confirmado — s3_unloadstart ---
  [FAIL] s3_unloadstart=1 em IDLE (esperado=0) — bug de precedencia

  --- TESTE 11: s0 == s1 sempre ---
  [OK]   s0_unloadstart identico a s1_unloadstart em todos os ciclos

  RESULTADO FINAL: 1 FALHA em 38 testes
```

---

## 7. Waveform da Simulação Real

Gerado com `surfer sim/robot.vcd` após rodar o testbench:

![waveform robot_model](images/waveform_robot.png)

---

## 8. Lendo o waveform

O waveform conta a história da simulação de um jeito visual bem direto.

**`clock`** — Pulsos regulares no topo. Tudo acontece na borda de subida.

**`errors[31:0]`** — Fica em `0` por quase toda a simulação. Sobe para `1` só no final, quando o Teste 10 detecta o bug do `s3_unloadstart`. Um número simples que diz tudo: 1 bug encontrado.

**`reset_n`** — Vários pulsos curtos indo a zero ao longo da simulação. Cada um é um reset entre testes. Note que os outros sinais reagem imediatamente, sem esperar o clock — é o reset assíncrono funcionando.

**`load_start`** — Pulsa por exatamente **1 ciclo** a cada vez que uma estação é atendida. Você consegue contar quantos testes rodaram só olhando esses pulsos. Um por teste, regularmente espaçados.

**`s0_req … s3_req`** — Cada um aparece em um momento diferente, sem sobreposição — exceto no Teste 6, onde `s0_req` e `s2_req` sobem juntos para verificar a prioridade.

**`s0_unload_done … s3_unload_done`** — Pulsos curtíssimos (1 ciclo) após cada atendimento. São o sinal de "terminei" que libera o robô para o próximo pedido.

**`s0_unloadstart` e `s1_unloadstart`** — Os dois sinais são **exatamente iguais** o tempo todo — sobem e descem no mesmo instante, como se fossem um só. É o Bug 3 visível: ambos são o mesmo fio.

**`s2_unloadstart`** — Pulsa algumas vezes, mostrando atividade baseada no estado `JOINTA_RIGHT` da Unload FSM.

**`s3_unloadstart`** — O sinal mais fácil de identificar no waveform: **uma linha verde sólida que nunca vai a zero**. Fica em `1` do começo ao fim. É o Bug 2 — o cálculo com precedência errada resulta num valor sempre ativo. Qualquer engenheiro que abrir esse waveform vai enxergar o problema imediatamente.

---

## 9. Na prática: para que serve e quando usar?

FSMs são a forma padrão de controlar sequências de movimentos físicos em hardware. Cada estado é uma etapa clara, e o hardware garante que o robô nunca pule passos ou execute dois ao mesmo tempo.

**Onde isso aparece na vida real:**
- **Linhas de montagem automotiva (BMW, Tesla):** a sequência pegar → mover → soltar → retornar é uma FSM. O controlador nunca pula etapas, mesmo se um sensor falhar.
- **Fábricas de semicondutores (TSMC, Intel):** robôs de wafer usam FSMs para garantir que o braço só toque a peça na sequência certa — um erro destrói o chip.
- **CNC e fresadoras:** as fases de aproximação, usinagem, recuo e troca de ferramenta são estados de uma FSM. A prioridade entre operações é idêntica à Main FSM deste módulo.
- **Empacotamento industrial:** múltiplas estações sincronizadas por FSMs garantem que cada braço mecânico receba e entregue no momento correto.

**Por que 3 FSMs em paralelo em vez de uma só?** Porque cada uma tem um ritmo diferente — a Load FSM não precisa esperar a Main FSM terminar. Elas avançam em sincronia mas de forma independente, o que é mais rápido e mais fácil de debugar do que uma FSM gigante com dezenas de estados.
