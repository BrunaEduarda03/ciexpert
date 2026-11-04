# 02 — VIP de Clock (`tb/agents/clk/`)

Arquivos: `clk_if.sv`, `clk_cfg.sv`, `clk_driver.sv`, `clk_agent.sv`, `clk_pkg.sv`.

## `clk_if.sv` — a interface

```systemverilog
interface clk_if;
  logic clk = 1'b0;
endinterface : clk_if
```

Só um sinal. Começa em `0` explicitamente para o clock nascer determinístico
(sem X). Uma instância é criada por clock que o testbench precisa gerar —
no `top_tb` existem duas: `ref_clk_if` (2 GHz) e `mem_clk_if` (100 MHz).

## `clk_cfg.sv` — os parâmetros

Campos: `period_ps`, `duty_pct`, `start_delay_ps`, `enable`. Tudo em
**picossegundos inteiros**, de propósito — se fosse em `ns` ou `real`, o
resultado dependeria do `` `timescale `` de cada arquivo que inclui a classe,
o que é frágil. Em ps inteiro o cálculo é sempre exato.

`is_valid()` é a validação defensiva: pega configurações impossíveis
(`period_ps < 2`, `duty_pct` fora de 1–99, fase alta/baixa resultando em 0)
*antes* de começar a gerar clock, com uma mensagem de erro específica — em
vez de o simulador travar silenciosamente com um `#0` no driver.

`high_ps()`/`low_ps()` fazem a conta de duty cycle uma vez só, reusada pelo
driver e por quem quiser inspecionar a config.

## `clk_driver.sv` — quem gera o clock

Ponto mais importante do arquivo: **não herda de nada com sequencer por
baixo dele ser usado como tal** — ele estende `uvm_driver#(uvm_sequence_item)`
só para ganhar de graça a infraestrutura UVM padrão (reporting, phases,
`uvm_component_utils`), mas nunca puxa um `seq_item_port.get_next_item()`.
Um clock não é uma sequência de transações, é um sinal periódico — não faz
sentido ele pedir "próximo item" a um sequencer.

Lógica do `run_phase`:
```systemverilog
#(cfg.start_delay_ps * 1ps);
forever begin
  #(cfg.low_ps() * 1ps);  vif.clk = 1'b1;
  #(cfg.high_ps() * 1ps); vif.clk = 1'b0;
end
```
Começa em fase **baixa**: a primeira borda de subida só ocorre depois de
`low_ps()`. Isso importa porque o reset (`rst_if`) é amostrado em bordas de
clock — gerar a primeira borda de forma previsível evita condição de corrida
na inicialização.

Se `cfg.enable == 0`, o driver simplesmente retorna sem entrar no `forever` —
o clock fica parado em `0`. Não é usado no P0/P1, mas deixa o VIP pronto para
cenários futuros (ex.: PLL desabilitado).

## `clk_agent.sv` — monta o driver

`build_phase` busca `clk_cfg` do `config_db`, roda `cfg.is_valid()` e só
então cria o `clk_driver`. Os três `uvm_fatal` (`CLK_NOCFG`, `CLK_BADCFG`,
`CLK_NOVIF`) existem para que um erro de configuração pare a simulação
imediatamente com uma mensagem clara, em vez de produzir um clock errado
silenciosamente e confundir o debug 50 linhas de log depois.

## Por que duas instâncias

```systemverilog
// minisoc_env.sv
clk_agent ref_clk_agt;   // 2 GHz  — clock de referência do DUT
clk_agent mem_clk_agt;   // 100 MHz — interface MEMORY DATA
```

Mesma classe, configs diferentes (`minisoc_env_cfg.ref_clk.period_ps = 500`,
`.mem_clk.period_ps = 10000`). Essa é a prova prática de que o VIP é
reutilizável — não precisou duplicar código para o segundo clock.
