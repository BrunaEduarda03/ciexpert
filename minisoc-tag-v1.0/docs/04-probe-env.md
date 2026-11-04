# 04 — `minisoc_probe_if`, `minisoc_env_cfg`, `minisoc_env`

## `tb/minisoc_probe_if.sv` — ponte para sinais internos

O problema que resolve: classes UVM (dentro de pacotes) não podem escrever
`dut.spi_cfg_start` — hierarquia direta a um módulo só existe em código que
"enxerga" o módulo, ou seja, no `top_tb`. Mas o teste *precisa* checar sinais
internos do DUT (saídas do banco de registradores SPI, status do PLL, status
do AES) para implementar os checks de `CHK-01` do VPLAN.

A solução é uma interface só de leitura, conectada no `top_tb` por `assign`:

```systemverilog
// top_tb.sv
assign probe_if.cfg_start = dut.spi_cfg_start;
assign probe_if.pll_locked = dut.pll_locked;
assign probe_if.sys_clk    = dut.sys_clk;
... (18 sinais no total)
```

e passada ao teste via `config_db` como `virtual minisoc_probe_if`, igual às
outras interfaces. O teste então lê `probe.cfg_start`, `probe.pll_locked`
etc. como se fossem campos normais.

Comentário no próprio arquivo já documenta o plano de evolução: em P2/P4 essa
interface única será dividida em `pll_mon_if` e `aes_mon_if` — faz sentido
porque hoje ela mistura sinais de domínios diferentes (config SPI, PLL, AES)
só porque é tudo que o T-SMOKE precisa; quando entrarem monitores de verdade
por protocolo, cada um deve observar só o que é dele.

## `tb/env/minisoc_env_cfg.sv` — agrega as configs

```systemverilog
class minisoc_env_cfg extends uvm_object;
  clk_cfg ref_clk;   // 500 ps  = 2 GHz
  clk_cfg mem_clk;   // 10000 ps = 100 MHz
  rst_cfg rst;
  virtual minisoc_probe_if probe_vif;
```

Um único objeto de configuração para todo o ambiente, criado uma vez no
`build_phase` do teste e distribuído aos agentes via `config_db`. Os valores
default (`500`/`10000` ps) vêm diretamente dos requisitos `ST-CLK-01`/`02`
do VPLAN — se o VPLAN mudar esses números, é aqui que se corrige.

`convert2string()` existe só para log legível — é o que aparece na linha
`[minisoc_smoke_test] Configuracao: ref_clk=500 ps | mem_clk=10000 ps | ...`
do log de simulação.

## `tb/env/minisoc_env.sv` — monta os agentes

```systemverilog
function void build_phase(uvm_phase phase);
  uvm_config_db#(clk_cfg)::set(this, "ref_clk_agt", "cfg", cfg.ref_clk);
  uvm_config_db#(clk_cfg)::set(this, "mem_clk_agt", "cfg", cfg.mem_clk);
  uvm_config_db#(rst_cfg)::set(this, "rst_agt",     "cfg", cfg.rst);

  ref_clk_agt = clk_agent::type_id::create("ref_clk_agt", this);
  mem_clk_agt = clk_agent::type_id::create("mem_clk_agt", this);
  rst_agt     = rst_agent::type_id::create("rst_agt",     this);
endfunction
```

Padrão UVM clássico: primeiro publica a configuração de cada agente no
`config_db` com o **path exato** do agente (`"ref_clk_agt"`), depois cria o
agente — quando o `build_phase` do agente rodar (phases de filhos rodam
depois da do pai, mas a ordem de código aqui já garante que o `set` aconteceu
antes), ele vai encontrar sua config pronta.

O comentário no topo do arquivo já deixa registrado o que falta: `spi_agent`,
`mem_agent`, monitores passivos, scoreboard e coverage entram em P2–P5. Isso
é intencional — o ambiente deste marco só precisa provar clock+reset, não
tem porque já ter peças que não serão exercitadas ainda.
