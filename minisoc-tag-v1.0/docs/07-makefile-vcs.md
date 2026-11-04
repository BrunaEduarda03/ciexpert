# 07 — Makefile e ambiente VCS neste servidor

## Como ativar as ferramentas Synopsys em qualquer sessão nova

O VCS/Verdi não está no `PATH` por padrão. Em **toda** sessão de shell nova
neste servidor (`srv-microeletronica3`), antes de usar `make`, `vcs` ou
`verdi`:

```bash
source /Tools/synopsys-scripts/snps.sh
```

Isso define `VCS_HOME`, `VERDI_HOME`, `UVM_HOME` e `SNPSLMD_LICENSE_FILE`
(licença em `27020@melicense.embedded.ufcg.edu.br`) e adiciona os `bin/` de
cada ferramenta ao `PATH`. Sem isso, `make compile` falha com
`vcs: command not found`.

> Nota: o `~/.bash_history` tinha `source /Tools/synopsys/snps.sh` (caminho
> antigo) — hoje o arquivo real está em `/Tools/synopsys-scripts/snps.sh`.
> Se algum dia esse source falhar de novo, confira `ls /Tools/synopsys-scripts/`.

## Targets do `Makefile` (`verif/Makefile`)

```makefile
make                      # compile + run com o teste default (smoke)
make compile              # só compila (gera verif/sim/simv)
make run TEST=<nome> SEED=<n> VERBOSITY=UVM_HIGH WAVES=fsdb|vcd
make verdi                # abre Verdi com a waveform do último run
make clean                # remove verif/sim inteiro
```

## `VCS_FLAGS` explicadas

```makefile
VCS_FLAGS := -full64 -sverilog -ntb_opts uvm-1.2 \
  -timescale=1ns/1ps \
  -debug_access+all -kdb \
  +lint=TFIPC-L \
  -top top_tb \
  -l $(LOG_DIR)/compile.log
```

| Flag | Para que serve |
|---|---|
| `-full64` | compila/roda em modo 64-bit |
| `-sverilog` | habilita sintaxe SystemVerilog (classes, interfaces, etc.) |
| `-ntb_opts uvm-1.2` | usa a biblioteca UVM-1.2 que vem embutida no VCS (`$VCS_HOME/etc/uvm-1.2`) |
| `-debug_access+all -kdb` | gera banco de dados de debug do Verdi (`simv.daidir`) e habilita `$fsdbDumpvars`/sinais internos visíveis no Verdi |
| `+lint=TFIPC-L` | liga checagens de lint (ex.: porta não conectada) durante a compilação |
| `-top top_tb` | módulo de topo é `top_tb`, não precisa de auto-detecção |

## Ordem dos arquivos importa

```makefile
TB_SRCS := clk_if.sv rst_if.sv minisoc_probe_if.sv clk_pkg.sv rst_pkg.sv \
           minisoc_env_pkg.sv minisoc_test_pkg.sv
```
Interfaces (`*_if.sv`) vêm **antes** dos pacotes que as usam (`clk_pkg`
inclui `clk_if` internamente via referência de tipo). RTL vem depois dos
pacotes TB, e `top_assertions.sv`/`top_tb.sv` por último, porque dependem de
tudo (DUT + pacotes UVM) já estar elaborado.

## Correção aplicada hoje: geração de FSDB

O `Makefile` já tinha `WAVES=fsdb` como opção, mas confiava em
`+vcs+fsdbon +fsdbfile+...` como *plusargs* de runtime para disparar um
"auto-dump" do VCS — nesta instalação (VCS X-2025.06-SP2) isso não é
suficiente: nenhum arquivo `.fsdb` era gerado, sem erro nenhum no log (plusarg
desconhecido é silenciosamente ignorado pelo VCS). O `top_tb.sv` já tinha até
um comentário dizendo "para FSDB use WAVES=fsdb", mas a chamada que realmente
cria o dump nunca tinha sido escrita.

Correção (testada isoladamente antes de aplicar, ver [08](08-evidencias-outubro.md)):

```systemverilog
// top_tb.sv
initial begin
  if ($test$plusargs("VCD")) begin
    $dumpfile("waves.vcd");
    $dumpvars(0, top_tb);
  end
  if ($test$plusargs("FSDB")) begin
    $fsdbDumpfile("waves.fsdb");
    $fsdbDumpvars(0, top_tb, "+all");
  end
end
```
```makefile
# Makefile
ifeq ($(WAVES),fsdb)
RUN_FLAGS += +FSDB
endif
...
verdi:
	cd $(SIM_DIR) && verdi -dbdir simv.daidir -ssf waves.fsdb &
```

Agora `make run WAVES=fsdb` chama `$fsdbDumpvars` explicitamente dentro do
testbench, que é o jeito garantido de funcionar com `-debug_access+all -kdb`
(as flags de compilação não precisaram mudar). Testado e confirmado: gera
`verif/sim/waves.fsdb` e o Verdi abre normalmente com a licença deste
servidor.

## Rodando

```bash
source /Tools/synopsys-scripts/snps.sh
cd minisoc-tag-v1.0/verif
make                       # compila + roda smoke, sem waveform
make run WAVES=fsdb        # roda de novo só gerando waves.fsdb (reusa o simv já compilado)
make verdi                 # abre o Verdi com clk, mem_clk e rst_n disponíveis
```
