# Texto resumido — Atividade 8 (para colar no relatório)

## Execução

O ambiente original do `adder32` (interface, driver, monitor, DUT, scoreboard,
sequencer, assertions e testbench top) foi lido e compreendido antes de
qualquer modificação. Compilei e rodei o projeto sem alterações com
`make all` (VCS X-2025.06-SP2). A simulação terminou em `$finish` no tempo
98000ps, com 2 sequências (`NUM_OF_SEQUENCES=2`) e 2 mismatches:

```
dut_r 6491349703, rfm_r          0
error
dut_r 4910391114, rfm_r          0
error
```

Esses *mismatches* são **esperados nesta fase**: o modelo de referência
(`dpi/refmod.c`) está propositalmente retornando sempre `0` (bug plantado,
a ser corrigido na Atividade 11), então o scoreboard nunca compara com um
valor real ainda. Não houve nenhum erro de compilação, de elaboração ou de
ambiente — apenas o `Warning-[UNK_COMP_ARG]` (ver abaixo) e uma nota
informativa `Note-[SV-LCM-PPWI]` (import de pacote duplicado, inofensivo).

## Waveform

O dump FSDB (`adder32.fsdb`) foi gerado com sucesso pelo próprio `make all`
(`$fsdbDumpfile`/`$fsdbDumpvars` em `tb_adder32.sv`). A abertura gráfica do
Verdi precisa ser feita na sessão x2go real (não há `$DISPLAY` no shell
usado para automação); usei `make verdi_wf_easy` como receita recomendada,
pois `make verdi_wf` depende de um script de sessão (`cmd/adder32.cmd`)
gravado com caminhos absolutos de outra máquina/usuário.

## Análise dos clocking blocks (op_a / op_b)

A interface `adder32_if.sv` define:
- `cb_drv`: `output #2ns` para `en`, `op_a`, `op_b` — o driver sincroniza
  com `@(posedge vif.clk)` e então escreve via clockvar (`cb_drv.op_a <= ...`),
  então o valor só aparece no sinal físico **2ns depois** dessa borda.
- `cb_mon`: `input #1ns` para `adder_out`, `carry_out` — o clocking block
  amostra automaticamente essas saídas 1ns após cada borda de subida.

Teoricamente (clock de 10ns de período, bordas em 5+10k ns), a mudança de
`op_a`/`op_b` deve ocorrer sempre exatamente 2ns após a borda de `clk` em que
o driver sincronizou, com folga de 8ns até a próxima borda — evitando corrida
com o `always@(posedge clk)` do DUT, que amostra `op_a+op_b` na borda
seguinte (latência = 1 ciclo, como esperado pela Figura 2 do caderno).

**Medição real (extraída do `adder32.fsdb` via `fsdbreport`, ferramenta de
linha de comando do Verdi — ver `fsdbreport_transitions.txt`):**

| Evento | Transação 1 | Transação 2 |
|---|---|---|
| Borda de `clk` em que o driver sincronizou (P) | 35.000 ns | 65.000 ns |
| Instante em que `op_a`/`op_b`/`en` mudam no sinal físico | 37.000 ns | 67.000 ns |
| **Δt (mudança − borda P)** | **2.000 ns** | **2.000 ns** |
| Borda de `clk` seguinte (P+10ns, onde o DUT registra) | 45.000 ns | 75.000 ns |
| Instante em que `adder_out`/`carry_out` mudam | 45.000 ns | 75.000 ns |
| **Δt (mudança − borda seguinte)** | **0.000 ns** | **0.000 ns** |

- **Conclusão: o delay observado BATE exatamente** com o especificado nos
  clocking blocks — `output #2ns` em `cb_drv` (confirmado nas duas
  transações, valor idêntico e constante: 2.000ns) e o RTL (`assign`
  combinacional a partir do registrador, sem delay adicional: 0.000ns entre
  a borda de captura e a mudança de `adder_out`/`carry_out`).
- Margem de segurança: `op_a`/`op_b` ficam estáveis 8ns antes da próxima
  borda (37ns→45ns e 67ns→75ns), longe o suficiente do limite do período de
  10ns — **sem risco de corrida** com o `always@(posedge clk)` do DUT.
- Latência confirmada: exatamente **1 ciclo de clock** entre a borda que
  disparou o drive (35ns/65ns) e a borda em que a soma aparece registrada
  (45ns/75ns) — bate com `LATENCY=1` da Figura 2 do caderno.
- Bônus (reset): `reset_n` cai (`negedge`) em **13.000ns** e `adder_out`/
  `carry_out` vão a `0` **no mesmo instante** (13.000ns) — não numa borda de
  `clk` — confirmando que o reset do DUT é **assíncrono**
  (`always@(posedge clk or negedge reset_n)`), como já indicava o RTL.

## Verificação independente (nesta sessão)

Reexecutei `make all` de forma independente (não apenas por leitura dos logs
anteriores) — resultado salvo em `make_all_verify_session.log`. Os valores de
`dut_r` (6491349703 e 4910391114), os 2 mismatches e o `$finish` em 98000ps
saíram **idênticos** aos logs anteriores, confirmando: (1) reprodutibilidade
do ambiente; (2) a semente não está de fato variando entre execuções
(reforça o achado da flag `+ntb_random_seed=random` mal posicionada no
Makefile); (3) `$DISPLAY` continua vazio nesta shell, então a abertura
gráfica do Verdi permanece uma etapa manual (x2go).

## Observação adicional (achado, não corrigido nesta atividade)

O Makefile aplica `+ntb_random_seed=random` na etapa de **compilação** (`vcs`),
não na etapa de **simulação** (`run`). O VCS avisa que o argumento é
desconhecido em tempo de compilação e o ignora
(`Warning-[UNK_COMP_ARG] ... 'ntb_random_seed=random' is ignored`). Rodei
`make all` duas vezes seguidas e os valores de `dut_r` saíram idênticos nas
duas execuções, confirmando que a semente não está de fato variando entre
rodadas. Não alterei o Makefile (fora do escopo desta atividade), mas deixo
registrado para revisitar na Atividade 5 (seeds) e como possível ponto de
feedback do material (Capítulo 6).
