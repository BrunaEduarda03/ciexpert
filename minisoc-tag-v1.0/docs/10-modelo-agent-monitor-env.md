# 10 — Modelo para decorar: item, driver, monitor, agent, env

Este é um **gabarito genérico**. Troque `xxx` pelo nome do protocolo
(`spi`, `mem`, ...) e preencha os sinais. Os agentes atuais (`clk_agent`,
`rst_agent`) são uma versão reduzida dele: não têm item, sequencer nem monitor,
porque clock e reset não têm transações (ver [02-vip-clock.md](02-vip-clock.md)).
O `spi_agent` e o `mem_agent` das fases P2–P5 vão precisar do modelo completo.

---

## A ordem para decorar (8 passos)

```
1. IF        → interface com os sinais
2. ITEM      → a transação (uvm_sequence_item)
3. SEQR      → typedef uvm_sequencer #(item)
4. DRIVER    → pega item do sequencer e mexe nos pinos
5. MONITOR   → olha os pinos, monta item e manda pela analysis port
6. AGENT     → cria monitor sempre; driver + sequencer só se ACTIVE; liga driver↔seqr
7. ENV       → cria agentes (+ scoreboard), liga monitor → scoreboard
8. PKG       → include na ordem: item, seqr, driver, monitor, agent
```

Frase para lembrar: **"Interface, Item, Sequencer, Driver, Monitor, Agent, Env"**
— do pino para cima.

### O esqueleto que se repete em TODA classe

Toda classe UVM tem as mesmas 3 coisas. Decore isso uma vez só:

```systemverilog
class NOME extends uvm_BASE;
  `uvm_component_utils(NOME)        // 1. registra na factory (object_utils p/ item/cfg)

  function new(string name, uvm_component parent);   // 2. construtor padrão
    super.new(name, parent);
  endfunction

  // 3. as fases que você precisa: build → connect → run
endclass
```

| Tipo | Macro | `new` |
|---|---|---|
| component (driver, monitor, agent, env, test) | `` `uvm_component_utils `` | `new(string name, uvm_component parent)` |
| object (item, cfg, sequence) | `` `uvm_object_utils `` | `new(string name = "nome")` |

### Quem faz o quê em cada fase

| Fase | O que entra aqui |
|---|---|
| `build_phase` | `config_db::get`, `type_id::create` dos filhos |
| `connect_phase` | ligar portas (`seq_item_port.connect`, `ap.connect`) |
| `run_phase` | o laço `forever` que dirige ou observa sinais |

---

## 1. Interface

```systemverilog
interface xxx_if (input logic clk);
  logic       valid;
  logic [7:0] data;
endinterface : xxx_if
```

## 2. Item (a transação)

```systemverilog
class xxx_item extends uvm_sequence_item;
  rand bit [7:0] data;

  `uvm_object_utils_begin(xxx_item)
    `uvm_field_int(data, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "xxx_item");
    super.new(name);
  endfunction
endclass : xxx_item
```

## 3. Sequencer

Quase nunca precisa de código próprio:

```systemverilog
typedef uvm_sequencer #(xxx_item) xxx_sequencer;
```

## 4. Driver — item → pinos

```systemverilog
class xxx_driver extends uvm_driver #(xxx_item);
  `uvm_component_utils(xxx_driver)

  virtual xxx_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual xxx_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "vif nao encontrada")
  endfunction

  task run_phase(uvm_phase phase);
    vif.valid <= 0;
    forever begin
      seq_item_port.get_next_item(req);   // 1. pede item
      @(posedge vif.clk);                 // 2. dirige os pinos
      vif.valid <= 1;
      vif.data  <= req.data;
      @(posedge vif.clk);
      vif.valid <= 0;
      seq_item_port.item_done();          // 3. avisa que terminou
    end
  endtask
endclass : xxx_driver
```

**Decore:** `get_next_item` → dirige → `item_done`.

## 5. Monitor — pinos → item

```systemverilog
class xxx_monitor extends uvm_monitor;
  `uvm_component_utils(xxx_monitor)

  virtual xxx_if vif;
  uvm_analysis_port #(xxx_item) ap;       // por onde o item sai

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);                 // porta: new(), NAO type_id::create
    if (!uvm_config_db#(virtual xxx_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "vif nao encontrada")
  endfunction

  task run_phase(uvm_phase phase);
    xxx_item tr;
    forever begin
      @(posedge vif.clk);
      if (vif.valid) begin
        tr      = xxx_item::type_id::create("tr");   // item NOVO a cada vez
        tr.data = vif.data;
        ap.write(tr);                                 // publica
      end
    end
  endtask
endclass : xxx_monitor
```

**Decore:** espera clock → se tem transação válida → `create` item novo →
copia sinais → `ap.write`. O monitor **só lê**, nunca dirige sinal.

## 6. Agent — junta tudo

```systemverilog
class xxx_agent extends uvm_agent;
  `uvm_component_utils(xxx_agent)

  xxx_sequencer seqr;
  xxx_driver    drv;
  xxx_monitor   mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = xxx_monitor::type_id::create("mon", this);         // sempre
    if (get_is_active() == UVM_ACTIVE) begin                 // só se ativo
      seqr = xxx_sequencer::type_id::create("seqr", this);
      drv  = xxx_driver   ::type_id::create("drv",  this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE)
      drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass : xxx_agent
```

**Decore:** monitor sempre; driver + sequencer só se `UVM_ACTIVE`;
no connect, `drv.seq_item_port` → `seqr.seq_item_export`.

Agente **passivo** (`UVM_PASSIVE`) = só monitor. É o que se usa para observar
uma interface que o próprio DUT dirige.

## 7. Env — agentes + scoreboard

```systemverilog
class xxx_env extends uvm_env;
  `uvm_component_utils(xxx_env)

  xxx_agent      agt;
  xxx_scoreboard sb;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt = xxx_agent     ::type_id::create("agt", this);
    sb  = xxx_scoreboard::type_id::create("sb",  this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agt.mon.ap.connect(sb.analysis_export);   // monitor → scoreboard
  endfunction
endclass : xxx_env
```

Scoreboard mínimo, só para fechar a conexão:

```systemverilog
class xxx_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(xxx_scoreboard)

  uvm_analysis_imp #(xxx_item, xxx_scoreboard) analysis_export;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_export = new("analysis_export", this);
  endfunction

  function void write(xxx_item tr);           // chamado a cada ap.write()
    `uvm_info("SB", $sformatf("recebi data=0x%0h", tr.data), UVM_MEDIUM)
  endfunction
endclass : xxx_scoreboard
```

## 8. Package

```systemverilog
package xxx_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "xxx_item.sv"
  `include "xxx_sequencer.sv"
  `include "xxx_driver.sv"
  `include "xxx_monitor.sv"
  `include "xxx_agent.sv"
endpackage : xxx_pkg
```

A ordem importa: quem é usado vem antes de quem usa. A interface fica **fora**
do package (interface não pode estar dentro de package).

---

## No top: entregar a vif

```systemverilog
xxx_if u_xxx_if (.clk(clk));

initial begin
  uvm_config_db#(virtual xxx_if)::set(null, "uvm_test_top.*", "vif", u_xxx_if);
  run_test();
end
```

No `minisoc` atual a vif não vai sozinha pelo config_db: ela vai dentro do
objeto de cfg (`clk_cfg.vif`), e o env repassa o cfg para cada agente
(ver [04-probe-env.md](04-probe-env.md)). As duas formas funcionam; o padrão
com cfg deixa tudo do agente num lugar só.

---

## Erros clássicos (cai na prova / na defesa)

| Erro | Sintoma |
|---|---|
| Esquecer `super.build_phase(phase)` | config automática não acontece |
| Criar a analysis port com `type_id::create` | erro de compilação — porta usa `new` |
| Reaproveitar o mesmo item no monitor | scoreboard recebe todos os itens com o último valor |
| Esquecer `item_done()` | sequence trava, simulação não termina |
| Criar driver no agente passivo | dois drivers brigando pelo mesmo sinal |
| Conectar porta no `build_phase` | filho ainda não existe — conecte no `connect_phase` |
| Nome no `create("x", this)` diferente do caminho do `config_db::set` | `uvm_fatal` de cfg/vif não encontrada |

## Cola de 10 segundos

```
item     : object_utils, rand campos
driver   : get_next_item → pinos → item_done
monitor  : pinos → create item → ap.write   (ap = new)
agent    : mon sempre | drv+seqr se ACTIVE | connect drv↔seqr
env      : create agentes + sb | connect mon.ap → sb.analysis_export
fases    : build = get/create | connect = ligar | run = forever
```
