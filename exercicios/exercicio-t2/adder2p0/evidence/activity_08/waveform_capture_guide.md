# Atividade 8 — Guia de Captura de Waveform (Verdi)

Este guia é para você (usuário) executar manualmente na sua sessão gráfica (x2go),
pois o Verdi precisa de um `$DISPLAY` X11 que não existe neste shell automatizado
(confirmado em `verdi_wf_attempt.log`: `invalidDisplay::xtInitialize::XtToolkitError::Can't open display`).

## Como abrir

Na sua sessão gráfica real:
```bash
cd /home/klynger.dantas/Bruna_Maciel_DV_Atividade2/adder2p0
source /Tools/synopsys/snps.sh
make verdi_wf
```

**Atualização:** o exercício oficial (E3) pede `make verdi_wf`. O script
`cmd/adder32.cmd` estava gravado com caminhos absolutos de outra máquina/usuário
(`/home/gabriel.magalhaes/workspace/synopsis-dv-track-prv/...`), inacessíveis
neste ambiente. Corrigi os 3 caminhos (`simv`, `simv.daidir`, `adder32.fsdb`)
para apontar para este projeto (`/home/klynger.dantas/Bruna_Maciel_DV_Atividade2/adder2p0/...`).
Original preservado em `backup_before_activity_08/cmd/adder32.cmd.orig` antes
da edição. `make verdi_wf` agora deve carregar o Verdi já com os sinais da
interface adicionados automaticamente à waveform (o script já faz
`wvAddSignal` para `clk`, `reset_n`, `en`, `op_a`, `op_b`, `adder_out`,
`carry_out`), sem precisar adicionar manualmente.

Alternativa mais simples, caso `make verdi_wf` ainda apresente problema:
```bash
make verdi_wf_easy
```
(abre `adder32.fsdb` direto, com `-ssf`, sem sinais pré-adicionados — precisa
adicionar manualmente como já orientado).

Se preferir reabrir a partir do `simv` (permite Rerun/interatividade):
```bash
make gui        # ./simv -gui
```

## Sinais a adicionar (hierarquia)

Instância top do testbench: `adder_tb`.

| Sinal | Caminho hierárquico | Papel |
|---|---|---|
| Clock | `adder_tb.uu_adder32_if.clk` | referência de tempo |
| Reset | `adder_tb.uu_adder32_if.reset_n` | contexto (ativo-baixo) |
| Enable dirigido | `adder_tb.uu_adder32_if.en` | sinal de `cb_drv` |
| Operando A (dirigido) | `adder_tb.uu_adder32_if.op_a[31:0]` | sinal de `cb_drv` — **alvo principal** |
| Operando B (dirigido) | `adder_tb.uu_adder32_if.op_b[31:0]` | sinal de `cb_drv` — **alvo principal** |
| Saída soma | `adder_tb.uu_adder32_if.adder_out[31:0]` | sinal de `cb_mon` |
| Saída carry | `adder_tb.uu_adder32_if.carry_out` | sinal de `cb_mon` |
| Registrador interno do DUT (opcional, contexto) | `adder_tb.uu_adder.adder_reg[32:0]` | mostra o instante exato do registro síncrono |

No Verdi: clique-direito na instância `adder_tb` (ou `adder_tb.uu_adder32_if`) na
árvore de hierarquia (Inst. Tree) → "Send To Waveform", ou arraste os sinais
individualmente para a janela de waveform (mesmo fluxo já usado no
`cmd/adder32.cmd` original: `srcHBSelect` + `srcHBDrag` + `wvDumpScope`).

## Unidade de tempo

`-timescale=1ns/1ps` (definido em `VCS_FLAGS` do Makefile) → régua do Verdi em
**ns**, com precisão de exibição até **ps** se necessário (ajuste "Time Unit" na
waveform se quiser ver a casa dos ps).

## Bordas a observar

- `clk` sobe em **t = 5, 15, 25, 35, 45, ... ns** (5 + 10·k).
- Escolha **qualquer par de bordas consecutivas em que `op_a`/`op_b` mudem de
  valor** (você verá o barramento de 32 bits mudar de cor/valor no Verdi).
  A primeira mudança relevante tende a ocorrer perto de 35–47ns (após o reset
  aleatório terminar), mas o valor exato varia por execução — **use a mudança
  que você efetivamente observar**, não um número fixo.

## Onde colocar os cursores

1. Cursor 1: exatamente na borda de subida de `clk` em que `op_a`/`op_b` mudam
   de valor lógico (não confunda com a borda em que a soma resultante aparece
   em `adder_out` — são bordas diferentes, uma borda depois).
2. Cursor 2: no instante exato em que `op_a` (ou `op_b`) efetivamente muda de
   valor no traço (a borda de transição do barramento, não o meio do intervalo
   estável).
3. Leia a diferença `Cursor2 - Cursor1` no painel de tempo do Verdi.

## Diferença temporal esperada

`Cursor2 - Cursor1 = 2.000 ns` (2000ps), correspondente ao `output #2ns` do
`cb_drv` em `adder32_if.sv`. Repita a medida em pelo menos **duas** transações
diferentes (duas mudanças de `op_a`/`op_b`) para confirmar que o delta é
constante e não um artefato de uma única borda.

Complementarmente, para `adder_out`/`carry_out`:
- Cursor 3 na borda de `clk` **seguinte** à que dirigiu os novos `op_a`/`op_b`
  (a borda em que o DUT registra a soma).
- Cursor 4 no instante em que `adder_out`/`carry_out` mudam.
- `Cursor4 - Cursor3` deve ser ~0ns (o RTL usa `assign` combinacional a partir
  do registrador, sem delay extra) — ou seja, `adder_out` muda no mesmo delta
  da borda de clock, sem esperar os "+1ns" do `cb_mon` (o `+1ns` é apenas
  quando/como o **testbench lê** o valor via clockvar, não quando o **sinal
  físico** muda).

## O que prova que o clocking block está correto

- `op_a`/`op_b` mudam **sempre 2ns depois** de uma borda de subida de `clk`
  (nunca no mesmo instante da borda, nunca antes dela) → confirma
  `output #2ns` de `cb_drv`.
- Essa mudança (em `P+2ns`) ocorre **antes** da próxima borda de `clk`
  (`P+10ns`), com folga de 8ns → não há risco de o DUT amostrar um valor em
  transição.
- O DUT sempre registra `op_a+op_b` **na borda seguinte** à que os operandos
  ficaram estáveis, nunca na mesma borda em que o driver sincronizou
  (confirma o latency=1 da Figura 2 do caderno).

## O que indicaria race condition ou skew incorreto

- `op_a`/`op_b` mudando **exatamente em cima** da borda de `clk` (delta = 0ns)
  — sinal de que o output skew não está sendo respeitado ou de que alguém
  está escrevendo direto no sinal (`vif.op_a = ...`) em vez de usar o clockvar
  (`vif.cb_drv.op_a <= ...`).
- `op_a`/`op_b` mudando **antes** da borda de `clk` que os originou (delta
  negativo) — inconsistente com `output #2ns` (que é sempre positivo/atrasado
  em relação à borda).
- Mudança de `op_a`/`op_b` ocorrendo **depois** de `P+8ns` (muito perto da
  próxima borda) — mesmo sem ser tecnicamente um race, indicaria um skew maior
  que o especificado, reduzindo a margem de segurança.
- `adder_out` mudando na **mesma borda** em que `op_a`/`op_b` também mudam (ou
  seja, sem 1 ciclo de defasagem) — indicaria que o DUT está combinacional (ou
  que a soma capturada não corresponde ao operando esperado), quebrando a
  suposição de `LATENCY=1`.

## Screenshots que devem ser tirados manualmente

1. **Overview geral**: janela de waveform completa mostrando `clk`, `reset_n`,
   `en`, `op_a`, `op_b`, `adder_out`, `carry_out` do início da simulação
   (t=0) até o `$finish` (t=98000ps / 98ns), mostrando a sequência de reset e
   as 2 transações do `NUM_OF_SEQUENCES=2`.
2. **Zoom na borda do driver**: cursores 1 e 2 posicionados (ver acima),
   com o painel de diferença de tempo (`2.000ns`) visível na tela.
3. **Zoom na borda do DUT/monitor**: cursores 3 e 4 posicionados, mostrando
   `adder_out`/`carry_out` mudando junto com a borda de clock seguinte.
4. (Opcional, reforça a prova) waveform com `adder_tb.uu_adder.adder_reg`
   visível, mostrando o registrador mudando na mesma borda em que
   `adder_out`/`carry_out` mudam.
