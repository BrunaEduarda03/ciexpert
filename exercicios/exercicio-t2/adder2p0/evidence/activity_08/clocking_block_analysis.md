# Atividade 8 — Análise dos Clocking Blocks (op_a / op_b)

Projeto: `Bruna_Maciel_DV_Atividade2/adder2p0`
Data da análise: 2026-07-17

## 1. Arquivos lidos (Etapa 1)

- `Makefile` — receitas `vcs`, `run`, `all`, `verdi_wf`, `verdi_wf_easy`, `verdi_sc`, `vcs_clean`.
- `tb/adder32_if.sv` — interface, clocking blocks `cb_drv` e `cb_mon`.
- `tb/tb_adder32.sv` — top do testbench, geração de clk/reset, instância do DUT e do módulo de assertions.
- `tb/adder32_drv.sv` — driver (usa `cb_drv`).
- `tb/adder32_mon.sv` — monitor (usa `cb_mon`).
- `rtl/adder32.v` — DUT (`adder`), registrado, `always@(posedge clk or negedge reset_n)`.
- `tb/adder32_assertion.sv`, `tb/adder32_seqr.sv`, `tb/adder32_scb.sv`, `tb/adder32_datatypes.sv`, `dpi/refmod.c`.

## 2. O que `make all` e `make verdi_wf` fazem

```
all: vcs run
vcs:  vcs -full64 -sverilog -l ./vcs_logger.log -kdb -debug_access+all \
          +ntb_random_seed=random -timescale=1ns/1ps \
          <pkg> <dpi-c> <if> <rtl> <assertions> <tb files>
run:  ./simv +FSDB=adder32.fsdb
verdi_wf: verdi -play cmd/adder32.cmd
verdi_wf_easy: verdi -nologo -ssf adder32.fsdb
```

- `make all` = compila (VCS, KDB habilitado para debug no Verdi) + elabora + roda 1 simulação, dumpando FSDB em `adder32.fsdb`.
- `make verdi_wf` reproduz uma sessão do Verdi a partir do script Tcl `cmd/adder32.cmd` (gravado anteriormente pelo instrutor).
- `make verdi_wf_easy` simplesmente abre o `.fsdb` gerado, sem depender de nenhum script de sessão.

## 3. Configuração real da interface (`tb/adder32_if.sv`)

```systemverilog
clocking cb_drv @(posedge clk);
    default input #0s output #2ns;
    output en;
    output op_a;
    output op_b;
endclocking

clocking cb_mon @(posedge clk);
    default input #1ns output #0ns;
    input adder_out;
    input carry_out;
endclocking
```

| Item | cb_drv | cb_mon |
|---|---|---|
| Evento de amostragem | `posedge clk` | `posedge clk` |
| Sinais | `en`, `op_a`, `op_b` (todos `output` do ponto de vista do TB → dirigidos pelo driver) | `adder_out`, `carry_out` (todos `input` do ponto de vista do TB → observados pelo monitor) |
| Skew relevante | **output #2ns** (não há input, pois o bloco só dirige) | **input #1ns** (não há output, pois o bloco só observa) |
| Unidade/precisão | `timescale=1ns/1ps` (VCS_FLAGS do Makefile) → unidade de tempo 1ns, precisão 1ps. Os skews `#2ns`/`#1ns`/`#0s`/`#0ns` são resolvidos nessa base. | idem |

**Direção de cada sinal** (do ponto de vista do testbench, olhando a interface):
- `en`, `op_a`, `op_b`: dirigidos pelo `adder32_drv` via `cb_drv` → chegam ao DUT como entradas.
- `adder_out`, `carry_out`: saídas do DUT, observadas pelo `adder32_mon` via `cb_mon`.
- `clk`, `reset_n`: **não** passam pelos clocking blocks — são portas da própria interface, geradas no `tb_adder32.sv` e conectadas diretamente ao DUT (fora do domínio "transaction-based" do clocking block).

## 4. Momento em que o testbench dirige os operandos (driver)

`tb/adder32_drv.sv`:
```systemverilog
@(posedge vif.clk);
vif.cb_drv.en   <= 1'b1;
vif.cb_drv.op_a <= seq_item.a;
vif.cb_drv.op_b <= seq_item.b;
```

Isso é executado logo após uma sincronização explícita com a borda de subida (`@(posedge vif.clk)`), portanto a atribuição ao clockvar ocorre no mesmo instante de simulação da borda. Pela semântica de clocking blocks (IEEE 1800-2017 §14.16), a borda em que o assign é feito é a "clocking event" de referência para aquele drive, e o simulador aplica o valor ao sinal físico da interface **output-skew depois dessa borda**, ou seja, **2ns após o posedge de clk**.

## 5. Momento em que DUT e monitor observam a saída

- **DUT** (`rtl/adder32.v`): registrador síncrono, `always@(posedge clk or negedge reset_n)`. Se `en=1`, `adder_reg <= op_a + op_b` **na mesma borda de posedge** em que os operandos estão estáveis na entrada do DUT. `adder_out`/`carry_out` são `assign` combinacionais de `adder_reg`, portanto mudam junto com o registrador, no delta-cycle daquela borda (latência = 1 ciclo, conforme rotulado `LATENCY=1` na Figura 2 do caderno).
- **Monitor** (`tb/adder32_mon.sv`):
  ```systemverilog
  @(posedge vif.clk);
  @(posedge vif.clk);
  #3ns;
  dut_r = {vif.cb_mon.carry_out, vif.cb_mon.adder_out};
  ```
  Espera **2 bordas de clk completas + 3ns** antes de ler. A leitura em si (`vif.cb_mon.adder_out`) não pega o valor "cru" do sinal no instante da leitura — pega a amostra que o clocking block já capturou automaticamente **1ns após a borda de posedge mais recente** (input skew `#1ns`), como o próprio comentário do arquivo já observa.

## 6. Por que a margem de 2 ciclos + 3ns no monitor faz sentido

1. Borda **N**: driver sincroniza (`@(posedge vif.clk)` dentro de `adder32_drv`) e agenda `op_a/op_b/en` para aparecerem no sinal físico em **N+2ns**.
2. Como `2ns < 10ns` (período do clock), o novo valor de `op_a/op_b` já está estável bem antes da borda **N+1** — sem risco de corrida com o registrador do DUT.
3. Borda **N+1**: o DUT amostra `op_a+op_b` (agora com o valor correto) e atualiza `adder_reg`/`adder_out`/`carry_out` nesse mesmo instante.
4. `cb_mon` amostra `adder_out`/`carry_out` em **(N+1)+1ns**.
5. O monitor, chamado logo após o driver ter terminado no instante **N** (mesma borda do passo 1), espera 2 bordas (→ chega em **N+2**, ou seja, uma borda depois de o resultado já estar disponível em N+1) mais 3ns de folga — garantindo, com margem extra, que a leitura ocorre bem depois do resultado ter sido capturado por `cb_mon`. A folga de +3ns não é estritamente necessária pela aritmética acima (1 borda de sobra já bastaria), mas é uma prática comum de dar folga extra para não depender de timing "no limite".

## 7. O delay está correto?

**Sim, é o comportamento pretendido pelo autor da interface** (os comentários no próprio arquivo `adder32_if.sv` já descrevem a intenção: *"output #2ns -> output signals are routed 2ns after the posedge clock"* e *"input #1ns -> input signals would be sampled ... after the posedge clock"*). O valor de 2ns para o drive evita corrida com o `always@(posedge clk)` do DUT (que dispara na mesma borda em que o driver sincronizou) e ainda deixa folga de 8ns antes da próxima borda (período de 10ns). Isso **precisa ser confirmado empiricamente na forma de onda** (Etapa 3 do Verdi) — ver `waveform_capture_guide.md`. Nenhum delay foi alterado neste exercício, conforme instrução N/regra 12 (Não altere os delays apenas porque parecem incomuns).

## 8. Cálculo teórico dos instantes (timescale 1ns/1ps)

- `CLK_PERIOD = 10ns`; `clk` parte de 0 e alterna a cada `CLK_PERIOD/2 = 5ns`.
- Primeira borda de subida (posedge) em **t = 5ns**. Bordas de subida seguintes: **t = 5 + 10·k ns**, k = 0,1,2,...
  (5, 15, 25, 35, 45, 55, ...)
- Bordas de descida: **t = 10 + 10·k ns** (10, 20, 30, ...)
- Reset (`tb_adder32.sv`):
  - `reset_n=1'bx` em t=0.
  - `reset_n=0` em t ∈ [10, 13] ns (`CLK_PERIOD + $urandom_range(3,0)*1ns`).
  - `reset_n=1` em t ∈ [20, 26] ns.
  - `@(posedge clk)` sincroniza no primeiro posedge ≥ t_reset_n=1 → tipicamente **t = 25ns** (posedge k=2), podendo cair em **35ns** (k=3) se o sorteio dos delays empurrar `reset_n=1` para depois de 25ns.
- Para uma borda de referência **P** (qualquer uma das listadas acima) em que o driver sincronizou e dirigiu a transação:
  - `op_a`, `op_b`, `en` devem mudar de valor no sinal físico em **P + 2ns** (ex.: P=35ns → mudança visível em **37ns**; P=45ns → mudança em **47ns**).
  - `adder_out`/`carry_out` do DUT mudam na borda seguinte, **P+10ns** (mesmo delta-cycle do posedge, sem delay adicional no RTL).
  - `cb_mon` amostra esse resultado em **(P+10)+1ns = P+11ns**.

> Observação importante: por causa do sorteio aleatório do reset (`$urandom_range`), o valor exato de P na primeira transação varia entre execuções — **mas isso só afeta o instante inicial, não a relação relativa (+2ns / +1ns) que deve se repetir em toda borda subsequente**. É essa relação relativa (delta constante de 2ns entre a borda e a mudança de `op_a`/`op_b`) que deve ser confirmada no Verdi, e não um instante absoluto fixo.

## 9. Nota sobre `+ntb_random_seed=random` (achado, fora do escopo de correção da Atividade 8)

O Makefile passa `+ntb_random_seed=random` na receita `vcs` (compile-time), não na receita `run` (que só usa `+FSDB=...`). O próprio VCS avisa:

```
Warning-[UNK_COMP_ARG] Unknown compile time plus argument used
  Unknown compile time plus argument 'ntb_random_seed=random' is ignored.
```

Executei `make all` duas vezes seguidas (ver `make_all_original.log` e `make_all_run2.log`) e os dois `dut_r` (6491349703 e 4910391114) saíram **idênticos** nas duas rodadas — confirmando que a randomização não está de fato variando entre execuções (a flag está no lugar errado do Makefile). Isso não afeta a Atividade 8 (não fiz nenhuma correção, conforme escopo), mas é relevante para a Atividade 5 (seeds) e para o Capítulo 6 (feedback do material).
