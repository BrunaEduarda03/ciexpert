# Atividade 8

## Clocking block analisado

Arquivo: `tb/adder32_if.sv`

```systemverilog
// clocking block to drive
clocking cb_drv @(posedge clk);
    default input #0s output #2ns; // we dont have inputs here...
    output en;
    output op_a;
    output op_b;
endclocking

// clocking block to monitor
clocking cb_mon @(posedge clk);
    default input #1ns output #0ns; // we dont have outputs here...
    input adder_out;
    input carry_out;
endclocking
```

O driver (`tb/adder32_drv.sv`) escreve nos sinais via clockvar do `cb_drv`, sincronizado à borda de subida:

```systemverilog
@(posedge vif.clk);
vif.cb_drv.en   <= 1'b1;
vif.cb_drv.op_a <= seq_item.a;
vif.cb_drv.op_b <= seq_item.b;
```

## Delay configurado

- `cb_drv`: `output #2ns` → `en`, `op_a` e `op_b` são escritos no clockvar na borda de subida (`posedge clk`) em que o driver sincroniza, mas o simulador só aplica o novo valor ao sinal físico da interface **2ns depois** dessa borda (output skew).
- `cb_mon`: `input #1ns` → `adder_out` e `carry_out` são amostrados automaticamente **1ns após** cada `posedge clk` (não altera quando o sinal físico muda, só quando o clocking block "tira a foto" para o testbench ler).

## Análise da waveform

Ambiente compilado e simulado nesta sessão (com display X11 real, `DISPLAY=localhost:12.0`) com o fluxo pedido:

```
source /Tools/synopsys/snps.sh
make vcs_clean   # o Makefile não define alvo "clean", apenas "vcs_clean" (equivalente funcional)
make all
make verdi_wf
```

`make all` compilou (VCS X-2025.06-SP2) e simulou sem erro de elaboração, terminando em `Time: 98000` (`$finish` em `tb/tb_adder32.sv:146`). Os 2 mismatches de scoreboard (`dut_r` vs `rfm_r`) são esperados nesta fase — `refmod.c` sempre retorna 0 (bug fora do escopo desta atividade).

O `cmd/adder32.cmd` original apontava para o caminho de outro usuário/máquina (`/home/klynger.dantas/...`); foi corrigido para o caminho real deste projeto (`/home/bruna.maciel/Bruna_Maciel_DV_Atividade2/adder2p0/...`) para que `make verdi_wf` conseguisse carregar `simv`/`simv.daidir`/`adder32.fsdb` corretamente. O Verdi abriu com a waveform já contendo os 7 sinais pedidos (`clk`, `reset_n`, `en`, `op_a[31:0]`, `op_b[31:0]`, `adder_out[31:0]`, `carry_out`), pois o próprio script já faz o `wvAddSignal`.

Foram usados o **Cursor** (`wvSetCursor`) e o **Marker** (`wvSetMarker`) do Verdi para medir o delta diretamente na régua da janela de waveform (campo `Δ` no toolbar da waveform):

| Evento | Transação 1 | Transação 2 |
|---|---|---|
| Cursor — borda de `clk` em que o driver sincronizou | **35.000 ns** | **65.000 ns** |
| Marker — instante em que `op_a`/`op_b` mudam no sinal físico | **37.000 ns** | **67.000 ns** |
| **Δ (lido no toolbar do Verdi, campo entre Cursor e Marker)** | **2.000 ns** | **2.000 ns** |

Valores de `op_a`/`op_b` nas transições (extraídos do próprio Verdi/FSDB):
- Transação 1 (37.000 ns): `op_a = afa9_5424`, `op_b = d340_cea3`
- Transação 2 (67.000 ns): `op_a = 49ce_7a0b`, `op_b = dae0_253f`

Observação visual: no Verdi, o intervalo `cb_drv` (skew de output) é destacado com uma caixa vermelha nas trilhas de `op_a`/`op_b`/`en`, que começa na borda do clock (cursor) e termina exatamente no instante em que o marker foi posicionado (37.000 ns / 67.000 ns) — evidência visual direta do output skew configurado.

`adder_out`/`carry_out` mudam na borda seguinte do clock (`P+10ns`: 45.000 ns e 75.000 ns), mesmo instante em que o registrador do DUT (`always@(posedge clk or negedge reset_n)`) atualiza `adder_reg` — latência de 1 ciclo, sem delay adicional no RTL (`assign` combinacional).

## Resposta

**Sim, o delay está correto** e bate exatamente com o especificado no `cb_drv`.

- Nas duas transações medidas com Cursor+Marker no Verdi, `op_a`/`op_b` mudam sempre **2ns depois** da borda de `clk` em que o driver sincronizou (35→37ns e 65→67ns) — igual ao `output #2ns` declarado em `cb_drv`. O delta é constante nas duas amostras, não é coincidência de uma única borda.
- Essa mudança em `P+2ns` ocorre bem antes da próxima borda de clock (`P+10ns`, período de 10ns), deixando **8ns de folga** (37→45ns e 67→75ns) — suficiente para que o `always@(posedge clk or negedge reset_n)` do DUT (`rtl/adder32.v`) amostre `op_a+op_b` já estável, sem risco de race condition.
- O DUT registra a soma exatamente **1 ciclo depois** da borda em que os operandos foram dirigidos (35→45ns e 65→75ns). `adder_out`/`carry_out` mudam no mesmo instante da borda de registro — o `input #1ns` do `cb_mon` afeta apenas quando o *testbench* lê o valor via clockvar, não quando o sinal físico do DUT muda.

Conclusão: o output skew de `cb_drv` (2ns) está corretamente dimensionado — grande o suficiente para não colidir com o instante `0ns` da borda (onde haveria race com o registrador do DUT), e pequeno o suficiente para deixar folga confortável antes da borda seguinte.

## O que é output skew e por que evita race conditions

Em um `clocking block`, o `output skew` (`output #Xns`) é o atraso que o simulador aplica entre o instante em que o testbench escreve num sinal via clockvar (ex.: `vif.cb_drv.op_a <= valor`, na borda de `posedge clk`) e o instante em que esse valor é de fato colocado no sinal físico da interface. Em vez de o valor aparecer no mesmo delta-cycle da borda de clock (instante ambíguo do ponto de vista de simulação de eventos, pois o RTL também dispara nesse exato instante), o clocking block empurra a mudança para `borda + Xns`.

Isso evita race conditions porque, sem esse deslocamento, o driver do testbench e a lógica síncrona do DUT (`always@(posedge clk)`) estariam escrevendo/lendo sinais na mesma borda de clock, e a ordem de avaliação entre blocos `always`/processos concorrentes nesse mesmo instante não é garantida pelo padrão SystemVerilog — o resultado dependeria da ordem arbitrária com que o simulador agenda os processos, podendo o DUT amostrar o valor antigo ou o novo dependendo do simulador/versão. Com `output #2ns`, a mudança do sinal fica claramente **depois** da borda de amostragem do DUT, então não há ambiguidade: o DUT sempre lê o valor estável do ciclo anterior, e o novo valor só fica visível a tempo de ser amostrado na borda seguinte (com folga de 8ns, como medido acima).

## Evidência

Screenshots reais do Verdi capturados nesta sessão (`evidence/activity_08/screenshots/`):

1. `01_overview_full_waveform.png` — visão geral da waveform (`clk`, `reset_n`, `en`, `op_a`, `op_b`, `adder_out`, `carry_out`) de t=0 até `$finish` em 98ns, mostrando reset e as 2 transações.
2. `02_cursor_marker_delta_op_a_op_b.png` — Cursor em 35.000ns (borda de clk) e Marker em 37.000ns (mudança de `op_a`/`op_b`), com o toolbar do Verdi mostrando `Δ = 2.000 x 1ps`. A caixa vermelha do output-skew de `cb_drv` termina exatamente no marker.
3. `03_cursor_marker_delta_transacao2.png` — mesma medição na segunda transação: Cursor em 65.000ns, Marker em 67.000ns, `Δ = 2.000 x 1ps`, confirmando que o delta de 2ns se repete.

`cmd/adder32_cursors.cmd` contém o script Tcl usado para reproduzir essas capturas (`wvSetCursor`, `wvSetMarker`, `wvZoom`). O `cmd/adder32.cmd` original (com os sinais já pré-carregados) foi corrigido apenas nos 3 caminhos absolutos; backup do original em `backup_before_activity_08/cmd/adder32.cmd.orig`.
