# 01 — Visão geral do ambiente

## O que o testbench precisa fazer neste marco

O DUT (`minisoc_top`) só se mexe se tiver clock e reset. Então, antes de
verificar qualquer funcionalidade (AES, SPI, memória), o P0/P1 prova duas
coisas:

1. O ambiente UVM gera os clocks certos e aplica reset corretamente.
2. Depois do reset, todos os registradores/sinais internos do DUT estão nos
   valores default documentados no Block Guide.

Isso é o **T-SMOKE** (`minisoc_smoke_test`) — um teste de fumaça, não testa
funcionalidade, só "o circuito liga e desliga direito".

## Hierarquia de classes UVM usada aqui

```
top_tb (module, não é UVM)
 └─ run_test() → instancia o teste escolhido por +UVM_TESTNAME
     minisoc_smoke_test extends minisoc_base_test extends uvm_test
      └─ env: minisoc_env extends uvm_env
          ├─ ref_clk_agt : clk_agent  (clock de referência, 2 GHz)
          ├─ mem_clk_agt : clk_agent  (mem_clk, 100 MHz)
          └─ rst_agt     : rst_agent (rst_n)
```

Cada `agent` tem um `cfg` (parâmetros) e um `driver` (quem efetivamente
mexe no sinal). Não há `sequencer` nem `monitor` nos VIPs de clock/reset —
isso é intencional, explicado em [02](02-vip-clock.md) e [03](03-vip-reset.md).

## Por que "VIP" (Verification IP)

`clk_agent`/`rst_agent` são escritos como componentes **genéricos e
reutilizáveis** — não sabem nada sobre AES, SPI ou minisoc. Por isso o mesmo
`clk_agent` é instanciado duas vezes no `minisoc_env` (`ref_clk_agt` e
`mem_clk_agt`), só mudando a configuração (`clk_cfg.period_ps`). Isso é reuso
de VIP e vale citar na defesa como boa prática de verificação.

## Como as virtual interfaces chegam até as classes

RTL e sinais físicos só existem no `top_tb` (um módulo SystemVerilog comum).
Classes UVM (`uvm_component`, `uvm_object`) vivem em pacotes e **não podem**
referenciar hierarquia de módulo diretamente (`dut.algum_sinal` não compila
dentro de uma classe). A ponte é o `uvm_config_db`:

```systemverilog
// no top_tb.sv (tem acesso físico ao DUT e às interfaces)
uvm_config_db#(virtual clk_if)::set(null, "uvm_test_top", "ref_clk_vif", ref_clk_if);

// no minisoc_base_test.sv (classe, só enxerga o config_db)
uvm_config_db#(virtual clk_if)::get(this, "", "ref_clk_vif", env_cfg.ref_clk.vif);
```

O mesmo problema de hierarquia é resolvido para sinais *internos* do DUT
(não são portas do `top_tb`) com a `minisoc_probe_if` — ver [04](04-probe-env.md).

## Fluxo de execução de um `make run`

1. `vcs` compila RTL + TB + UVM-1.2 em um executável `simv` (ver [07](07-makefile-vcs.md)).
2. `./simv +UVM_TESTNAME=minisoc_smoke_test ...` roda.
3. UVM entra nas phases padrão: `build_phase` (cria componentes, lê config_db) →
   `connect_phase` (liga driver↔vif) → `run_phase` (clock roda, reset é
   aplicado, checagens acontecem) → `report_phase` (imprime PASS/FAIL).
4. O Makefile faz `grep "TEST PASSED"` no log e decide o exit code de `make`.

## Separação de autoria no git

```
43acd09  Baseline do instrutor: RTL minisoc-tag-v1.0 e refmod AES   (tag minisoc-tag-v1.0)
bcecf18  P0/P1: ambiente UVM base, VIPs de clock e reset, smoke test e VPLAN v1
```

O primeiro commit é exatamente o que foi recebido (RTL + refmod), sem
alteração. Tudo que está no segundo commit é produção própria — é isso que a
banca avalia como autoria individual.
