# 11 — Do zero: como o testbench de clk e rst foi construído (e como fazer o SPI)

> **Para quem é:** você, estudando para escrever o `spi_agent` sozinha.
> **Como ler:** de cima para baixo, uma vez. Depois use as seções
> "🧠 Entender" e "📌 Decorar" como consulta enquanto escreve código.
>
> Tudo aqui foi tirado do código real em `verif/tb/`. Os números de linha e
> os nomes são os do projeto, não de um exemplo genérico.

---

## Sumário

0. [O mapa: a figura e o nosso código](#0-o-mapa-a-figura-e-o-nosso-código)
1. [Antes de tudo: o que é herdado de quem](#1-antes-de-tudo-o-que-é-herdado-de-quem)
2. [As fases: em que ordem o UVM chama suas funções](#2-as-fases-em-que-ordem-o-uvm-chama-suas-funções)
3. [O config_db: como a interface chega no driver](#3-o-config_db-como-a-interface-chega-no-driver)
4. [Passo a passo, de dentro para fora](#4-passo-a-passo-de-dentro-para-fora)
   - 4.1 Interface · 4.2 Config · 4.3 Driver · 4.4 Agent · 4.5 Package
   - 4.6 Env cfg · 4.7 Env · 4.8 Base test · 4.9 Smoke test · 4.10 top_tb
5. [Checklist: o que SEMPRE aparece](#5-checklist-o-que-sempre-aparece)
6. [Bug encontrado no clk_driver](#6-bug-encontrado-no-clk_driver)
7. [Agora você: o roteiro do SPI](#7-agora-você-o-roteiro-do-spi)
8. [Erros clássicos e como reconhecer no log](#8-erros-clássicos-e-como-reconhecer-no-log)
9. [Exercícios para fixar](#9-exercícios-para-fixar)

---

## 0. O mapa: a figura e o nosso código

A figura da aula mostra um testbench UVM **completo**. O nosso, hoje (P0/P1),
é uma versão **reduzida** dele: só tem agentes de clock e reset, que não
precisam de sequencer, monitor nem scoreboard.

```
 Figura da aula                  Nosso projeto (hoje)                    Arquivo
 ─────────────────────────────   ────────────────────────────────────   ─────────────────────────────
 Top                         →   top_tb (module)                         tb/top_tb.sv
   DUT                       →   minisoc_top dut                         frontend/rtl/minisoc_top.sv
   input_if / output_if      →   clk_if, rst_if, minisoc_probe_if        tb/agents/*/..._if.sv
   simple_test               →   minisoc_smoke_test                      tb/tests/minisoc_smoke_test.sv
                                   └ herda de minisoc_base_test          tb/tests/minisoc_base_test.sv
     env                     →   minisoc_env                             tb/env/minisoc_env.sv
       agent (input)         →   ref_clk_agt, mem_clk_agt, rst_agt       tb/agents/clk|rst/..._agent.sv
         driver              →   clk_driver, rst_driver                  tb/agents/clk|rst/..._driver.sv
         sequencer           →   (não tem — clock/reset não têm transação)
         monitor             →   (não tem ainda)
       agent_out             →   (não tem ainda)
       scoreboard/refmod     →   (não tem ainda — refmod em C++ já existe em tb/refmod/)
```

Leia a figura **de fora para dentro** para entender *quem contém quem*.
Mas **escreva o código de dentro para fora**: primeiro o que encosta no
pino (interface), depois o driver, depois o agent, e assim por diante.
Cada camada só pode ser escrita quando a camada de dentro já existe.

```
  ESCREVER nesta ordem ───────────────────────────────────────────►
  interface → cfg → driver → agent → pkg → env_cfg → env → test → top_tb
  (pino)                                                         (mundo)
```

---

## 1. Antes de tudo: o que é herdado de quem

UVM é uma biblioteca de **classes prontas**. Você nunca escreve um driver do
zero: você escreve `class clk_driver extends uvm_driver` e **herda** tudo que o
`uvm_driver` já sabe fazer. Por isso tem tanto código "decoreba": é o mínimo
para se encaixar na biblioteca.

### 1.1 A árvore de herança (só o que você usa)

```
uvm_void
 └─ uvm_object                      ← "dado": tem nome, print, copy, compare, randomize
     ├─ uvm_transaction
     │   └─ uvm_sequence_item       ← uma transação (ex.: um frame SPI)
     │       └─ uvm_sequence        ← gera vários itens (o "programa" do teste)
     │
     │   (classes de config herdam direto de uvm_object: clk_cfg, rst_cfg, minisoc_env_cfg)
     │
     └─ uvm_report_object           ← ganha `uvm_info / `uvm_error / `uvm_fatal
         └─ uvm_component           ← "peça fixa": tem pai, filhos e FASES
             ├─ uvm_driver #(REQ)   ← + seq_item_port (fala com o sequencer)
             ├─ uvm_monitor         ← (só um nome; você adiciona a analysis port)
             ├─ uvm_sequencer #(REQ)← fila de itens entre sequence e driver
             ├─ uvm_agent           ← + get_is_active() (ACTIVE / PASSIVE)
             ├─ uvm_scoreboard      ← (só um nome)
             ├─ uvm_env             ← (só um nome)
             └─ uvm_test            ← (só um nome)
```

### 1.2 A diferença mais importante: object × component

| | `uvm_object` | `uvm_component` |
|---|---|---|
| O que é | Um **dado**. Nasce, é usado, some. | Uma **peça fixa** do testbench. Existe a simulação toda. |
| Exemplos no projeto | `clk_cfg`, `rst_cfg`, `minisoc_env_cfg` | `clk_driver`, `clk_agent`, `minisoc_env`, `minisoc_base_test` |
| Tem pai? | Não | **Sim** — forma a árvore `uvm_test_top.env.rst_agt.drv` |
| Tem fases (build, run…)? | Não | **Sim** |
| Macro de registro | `` `uvm_object_utils(NOME) `` | `` `uvm_component_utils(NOME) `` |
| Construtor | `new(string name = "NOME")` | `new(string name, uvm_component parent)` |
| Como criar | `NOME::type_id::create("nome")` | `NOME::type_id::create("nome", this)` |

> 🧠 **Regra para nunca errar:** *"Tem fase? Tem pai? Então é component."*
> Config e transação são objects. Todo o resto é component.

### 1.3 O que cada classe base te dá de presente

| Você escreve | Herda de | O que vem "de graça" | O que você precisa preencher |
|---|---|---|---|
| `clk_cfg`, `rst_cfg` | `uvm_object` | `print()`, `copy()`, `randomize()`, `get_name()` | os campos (período, ciclos…) e o `vif` |
| `clk_driver`, `rst_driver` | `uvm_driver #(uvm_sequence_item)` | `seq_item_port`, `req`, `rsp`, todas as fases | o `run_phase` que mexe nos pinos |
| `clk_agent`, `rst_agent` | `uvm_agent` | `is_active`, `get_is_active()`, fases | `build_phase` que cria o driver |
| `minisoc_env` | `uvm_env` | fases | `build_phase` que cria os agentes |
| `minisoc_base_test` | `uvm_test` | fases, é o topo da árvore | `build_phase` que monta config e env |
| `minisoc_smoke_test` | `minisoc_base_test` | **tudo do base_test** (env, env_cfg, timeout, PASS/FAIL) | só o `run_phase` com o estímulo |

Repare na última linha: o `smoke_test` não herda de `uvm_test` direto, herda
do **seu** `base_test`. Isso é herança de verdade sendo usada: o que é comum a
todos os testes fica no base, e cada teste novo só escreve o que é diferente.

### 1.4 O que o `super.` faz (e por que você sempre chama)

`super.xxx()` = "executa a versão do meu pai primeiro".

| Chamada | O que o pai faz lá dentro | Se você esquecer |
|---|---|---|
| `super.new(name, parent)` | Registra o componente na árvore, embaixo do `parent` | Não compila (construtor do pai é obrigatório) |
| `super.new(name)` (object) | Guarda o nome | Não compila |
| `super.build_phase(phase)` | Aplica automaticamente configs do `config_db` em campos registrados com `` `uvm_field_* `` | Funciona hoje, mas quebra "do nada" quando alguém usar config automática |
| `super.connect_phase(phase)` | Nada relevante hoje | Nada — mas chame por hábito |
| `super.report_phase(phase)` | Nada relevante hoje | Nada — mas chame por hábito |

> 📌 **Decorar:** *toda função de fase começa com `super.<mesma_fase>(phase);`*
> A **exceção** é o `run_phase`: não precisa de `super.run_phase` (o do pai é vazio).

### 1.5 As macros, sem mistério

```systemverilog
`uvm_component_utils(clk_driver)
```

Isso faz duas coisas:
1. Registra `clk_driver` na **factory** (a "fábrica" de objetos do UVM).
   É por isso que você escreve `clk_driver::type_id::create(...)` em vez de
   `new(...)`. A factory permite trocar a classe depois sem mexer no código
   (ex.: um teste pede "onde tiver `clk_driver`, use `clk_driver_com_jitter`").
2. Cria `get_type_name()`, que devolve `"clk_driver"` — usado nos `` `uvm_info ``.

```systemverilog
`uvm_object_utils_begin(clk_cfg)
  `uvm_field_int(period_ps, UVM_DEFAULT | UVM_DEC)
`uvm_object_utils_end
```

Mesma coisa, mas para object, e **ainda** ensina o UVM a imprimir/copiar/comparar
o campo `period_ps` sozinho. `UVM_DEC` = imprimir em decimal.
Se você não precisa disso, `` `uvm_object_utils(NOME) `` sozinho basta
(é o que o `minisoc_env_cfg` faz).

---

## 2. As fases: em que ordem o UVM chama suas funções

Você **nunca** chama `build_phase` ou `run_phase` diretamente. Quem chama é o
UVM, quando o `top_tb` executa `run_test()`. Você só escreve o que cada fase
deve fazer.

```
run_test()
   │
   ├─ build_phase          function  ↓ de cima p/ baixo (test → env → agent → driver)
   │                                   "crie seus filhos e pegue sua config"
   ├─ connect_phase        function  ↑ de baixo p/ cima
   │                                   "ligue as portas / pegue o vif"
   ├─ end_of_elaboration   function    "imprima a topologia" (base_test faz isso)
   ├─ start_of_simulation  function
   │
   ├─ run_phase            TASK      ⇉ TODOS os componentes rodam em PARALELO
   │                                   e consome tempo de simulação (#, @)
   │
   ├─ extract / check      function
   ├─ report_phase         function    "imprima PASS/FAIL" (base_test faz isso)
   └─ final_phase          function
```

### Por que o build vai de cima para baixo?

Porque **o pai cria o filho**. O env só existe depois que o test roda o
`build_phase` dele e faz `create("env", this)`. Aí o UVM chama o `build_phase`
do env, que cria os agents, e assim por diante. Por isso:

> 🧠 O `config_db::set` tem que acontecer **antes** do `create` do filho.
> Olhe o `minisoc_env.sv:25-31`: primeiro os 3 `set`, depois os 3 `create`.

### Por que o run_phase é task e o resto é function?

`function` não pode esperar tempo (não aceita `#10` nem `@(posedge clk)`).
`task` pode. Só o `run_phase` mexe em sinais ao longo do tempo, então só ele
é task. Se você escrever `function void run_phase`, o compilador reclama.

### Objection: quem decide quando a simulação acaba

O `run_phase` de todos os componentes roda em paralelo. Quando acaba? Quando
**ninguém mais está segurando uma objection**.

```systemverilog
task run_phase(uvm_phase phase);
  phase.raise_objection(this);   // "não termina ainda, estou trabalhando"
  ... estímulo ...
  phase.drop_objection(this);    // "pode terminar"
endtask
```

- O **teste** levanta e baixa a objection (`minisoc_smoke_test.sv:27,57`).
- Os **drivers não** levantam: o `clk_driver` tem um `forever` que nunca
  termina. Se ele segurasse objection, a simulação nunca acabaria.
- Se **ninguém** levantar, o `run_phase` acaba no tempo 0 e o teste "passa"
  sem testar nada. Esse é um erro clássico.

---

## 3. O config_db: como a interface chega no driver

Esse é o ponto que mais confunde no começo, então vale um desenho.

**O problema:** o driver é uma *classe* (dentro de um package). Classes não
enxergam a hierarquia do Verilog: o driver não pode escrever
`top_tb.ref_clk_if.clk = 1`. Ele precisa receber um **ponteiro** para a
interface: a `virtual interface` (`vif`).

**A solução:** o `uvm_config_db` funciona como um **quadro de recados**
global. Alguém pendura um recado (`set`) com um nome e um "endereço"
(caminho na árvore), e quem estiver naquele endereço pega o recado (`get`).

```systemverilog
uvm_config_db #( TIPO )::set( contexto, "caminho", "nome", valor );
uvm_config_db #( TIPO )::get( this,     "",        "nome", variavel );
```

- `TIPO` tem que ser **idêntico** no set e no get.
- `contexto + caminho` = para quem é o recado.
- `"nome"` tem que ser **idêntico** no set e no get.
- `get` retorna 0 se não achou → sempre teste com `if (!...) uvm_fatal`.

### O caminho completo do `vif` do clock no nosso projeto

```
top_tb.sv:82        set(null, "uvm_test_top", "ref_clk_vif", ref_clk_if)
     │              "recado para o teste: aqui está a interface física"
     ▼
base_test.sv:24     get(this, "", "ref_clk_vif", env_cfg.ref_clk.vif)
     │              o teste guarda o vif DENTRO do clk_cfg
     ▼
base_test.sv:38     set(this, "env", "cfg", env_cfg)
     │              "recado para o env: aqui está a config de tudo"
     ▼
env.sv:22           get(this, "", "cfg", cfg)
env.sv:25           set(this, "ref_clk_agt", "cfg", cfg.ref_clk)
     │              o env desmonta e entrega um pedaço para cada agente
     ▼
clk_agent.sv:19     get(this, "", "cfg", cfg)
clk_agent.sv:27     drv.cfg = cfg;
     │              o agente passa a config direto para o filho (sem config_db)
     ▼
clk_driver (connect_phase)   vif = cfg.vif;
     │
     ▼
clk_driver (run_phase)       vif.clk = 1'b1;   ← finalmente mexe no pino
```

> 🧠 **A ideia de projeto:** o `vif` viaja **dentro** do objeto de config.
> Cada camada só conhece a camada de baixo. O env não sabe que existe um
> `clk_if`; ele só repassa um `clk_cfg`. Isso deixa cada peça reutilizável.

> 🧠 **Por que `"uvm_test_top"`?** É o nome que o UVM dá automaticamente ao
> teste que ele cria em `run_test()`. Todo caminho da árvore começa por ele:
> `uvm_test_top.env.ref_clk_agt.drv`.

---

## 4. Passo a passo, de dentro para fora

Para cada arquivo: **o que é**, **o código**, e a separação entre
📌 **Decorar** (estrutura que se repete sempre) e 🧠 **Entender**
(decisão de projeto, que muda de protocolo para protocolo).

---

### 4.1 PASSO 1 — Interface (`clk_if.sv`, `rst_if.sv`)

**O que é:** o "cabo" entre o mundo das classes e o DUT. É um bloco
Verilog comum (não é classe), com os sinais do protocolo.

```systemverilog
interface clk_if;
  logic clk = 1'b0;
endinterface : clk_if

interface rst_if (input logic clk);
  logic rst_n = 1'b0;
endinterface : rst_if
```

📌 **Decorar:**
- `interface NOME; ... endinterface`
- Um `logic` por sinal do protocolo.

🧠 **Entender:**
- `clk = 1'b0` e `rst_n = 1'b0` têm valor inicial para o DUT nunca ver `X`.
  O `rst_n` começa em **0** de propósito: o DUT já nasce em reset.
- O `rst_if` recebe `clk` como porta porque o driver de reset precisa
  **contar ciclos** (`@(posedge vif.clk)`). O `clk_if` não recebe nada: ele
  *gera* o clock.
- Uma interface por **protocolo**, não por sinal. O SPI vai ter uma
  interface com 4 sinais (sclk, cs_n, mosi, miso).

---

### 4.2 PASSO 2 — Config (`clk_cfg.sv`, `rst_cfg.sv`)

**O que é:** um objeto com os **parâmetros** do agente e o `vif`. É o
"formulário" que o teste preenche para dizer como o agente deve se comportar.

```systemverilog
class rst_cfg extends uvm_object;          // object: é dado, não tem fase

  virtual rst_if vif;                      // ← o ponteiro para a interface

  rand int unsigned assert_cycles;         // rand = pode ser sorteado
  constraint c_assert_cycles { assert_cycles inside {[10:50]}; }

  `uvm_object_utils_begin(rst_cfg)
    `uvm_field_int(assert_cycles, UVM_DEFAULT | UVM_DEC)
  `uvm_object_utils_end

  function new(string name = "rst_cfg");   // object: só name, com default
    super.new(name);
    assert_cycles = 10;
  endfunction

endclass
```

📌 **Decorar:**
- `extends uvm_object`
- `virtual NOME_if vif;`
- `` `uvm_object_utils `` (ou `_begin/_end` com campos)
- `new(string name = "NOME")` + `super.new(name)`

🧠 **Entender:**
- **Por que separar config do agente?** Porque o mesmo `clk_agent` é usado
  duas vezes (`ref_clk_agt` a 2 GHz e `mem_clk_agt` a 100 MHz). O código é o
  mesmo; só o config muda. Isso é **reuso**.
- `rand` + `constraint`: o teste chama `env_cfg.rst.randomize()`
  (`base_test.sv:33`) e cada seed sorteia uma duração de reset diferente entre
  10 e 50 ciclos. Testar valores variados acha mais bugs que um valor fixo.
- `clk_cfg` tem **funções auxiliares** (`high_ps()`, `low_ps()`,
  `is_valid()`). Config pode ter lógica: o cálculo fica num lugar só.
- Tempos em **picossegundos inteiros** (`period_ps`) para não depender do
  `timescale` de cada arquivo. Na hora de usar: `#(cfg.low_ps() * 1ps)`.

---

### 4.3 PASSO 3 — Driver (`clk_driver.sv`, `rst_driver.sv`)

**O que é:** a única peça que **mexe nos pinos**. Recebe "o que fazer"
(do config ou de um sequencer) e transforma em sinais ao longo do tempo.

```systemverilog
class rst_driver extends uvm_driver #(uvm_sequence_item);
  `uvm_component_utils(rst_driver)

  rst_cfg        cfg;    // o agente preenche isto
  virtual rst_if vif;    // copiado do cfg no connect_phase

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // connect: pega o vif de dentro do cfg (o cfg já chegou no build do agente)
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg == null) `uvm_fatal("RST_NOCFG", "rst_cfg nao atribuido ao driver")
    vif = cfg.vif;
    if (vif == null) `uvm_fatal("RST_NOVIF", "rst_cfg.vif e nulo")
  endfunction

  // run: o comportamento no tempo
  task run_phase(uvm_phase phase);
    drive_reset(cfg.assert_cycles);        // reset de power-on
  endtask

  task drive_reset(int unsigned cycles);
    in_reset  = 1'b1;
    vif.rst_n = 1'b0;                      // assert imediato (reset assíncrono)
    repeat (cycles) @(posedge vif.clk);    // segura N ciclos
    @(negedge vif.clk);                    // solta na borda de DESCIDA
    vif.rst_n = 1'b1;
    in_reset  = 1'b0;
  endtask
endclass
```

📌 **Decorar:**
- `extends uvm_driver #(TIPO_DO_ITEM)` — aqui `uvm_sequence_item` genérico,
  porque não usamos itens.
- `cfg` + `virtual ..._if vif;`
- `connect_phase`: `vif = cfg.vif;` com checagem de `null`.
- `run_phase` é **task**.

🧠 **Entender:**
- **Por que não tem sequencer?** Clock e reset não têm *transações*. Um
  clock é "gere uma onda com período X para sempre". Não existe "item 1,
  item 2". Então o driver lê direto do config. O SPI **tem** transações
  (cada frame de 40 bits é uma), então o SPI vai precisar de item + sequencer
  (seção 7).
- **Por que soltar o reset na borda de descida?** Se o driver mudasse
  `rst_n` na mesma borda de subida em que o DUT amostra, haveria uma
  *corrida*: o simulador decide a ordem e o resultado fica imprevisível.
  Na descida não tem ninguém amostrando. Mesma ideia vale para o MOSI do SPI.
- `drive_reset` e `wait_reset_done` são tasks **públicas**: o teste pode
  chamar um reset no meio da simulação (o smoke test faz isso).
- O `clk_driver` tem `forever`: gera clock até a simulação acabar. Ele
  **não** levanta objection (ver seção 2).

---

### 4.4 PASSO 4 — Agent (`clk_agent.sv`, `rst_agent.sv`)

**O que é:** a "caixa" que agrupa driver (+ sequencer + monitor, quando
houver) de **um** protocolo. É o que você instancia no env.

```systemverilog
class rst_agent extends uvm_agent;
  `uvm_component_utils(rst_agent)

  rst_cfg    cfg;
  rst_driver drv;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // 1. pega a própria config
    if (!uvm_config_db#(rst_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("RST_NOCFG", {"rst_cfg nao encontrado para ", get_full_name()})
    if (cfg.vif == null)
      `uvm_fatal("RST_NOVIF", {"rst_cfg.vif nulo em ", get_full_name()})

    // 2. cria os filhos
    drv     = rst_driver::type_id::create("drv", this);
    drv.cfg = cfg;                          // 3. entrega a config ao filho
  endfunction

  // API para o teste usar (atalhos para o driver)
  task apply_reset(int unsigned cycles);  drv.drive_reset(cycles); endtask
  task wait_reset_done();                 drv.wait_reset_done();   endtask
endclass
```

📌 **Decorar — o `build_phase` de todo agent tem 3 partes:**
1. `config_db::get` da config + `uvm_fatal` se não achar.
2. `type_id::create` dos filhos (com `this` como pai).
3. Entregar a config para os filhos.

🧠 **Entender:**
- `create("drv", this)`: o `"drv"` vira o nome na árvore
  (`uvm_test_top.env.rst_agt.drv`); o `this` diz "eu sou o pai".
- `get(this, "", "cfg", cfg)`: `this` + `""` = "procure um recado
  endereçado **a mim**". O env pendurou o recado em `"rst_agt"`, que é
  exatamente o nome deste agente.
- `drv.cfg = cfg` é atribuição direta, sem config_db. Pode fazer isso
  porque o agente acabou de criar o driver e tem o handle dele.
- `apply_reset` e `wait_reset_done` existem no agente para o teste não
  precisar conhecer o driver: `env.rst_agt.apply_reset(20)`.
- **Agente ACTIVE × PASSIVE:** `uvm_agent` herda `is_active`. ACTIVE = tem
  driver (dirige pinos). PASSIVE = só monitor (só observa). Clock e reset
  sempre ACTIVE, por isso o código nem checa. No SPI você vai checar.

---

### 4.5 PASSO 5 — Package (`clk_pkg.sv`, `rst_pkg.sv`)

**O que é:** a "pasta" que junta as classes de um agente para poder
`import` em outro lugar.

```systemverilog
package rst_pkg;
  import uvm_pkg::*;               // as classes do UVM
  `include "uvm_macros.svh"        // as macros `uvm_*

  `include "rst_cfg.sv"            // ordem importa:
  `include "rst_driver.sv"         //   quem é usado vem antes
  `include "rst_agent.sv"          //   de quem usa
endpackage
```

📌 **Decorar:**
- As duas primeiras linhas são **sempre** iguais.
- A ordem dos includes é **de dentro para fora**: cfg → (item) → driver →
  (monitor) → agent. O driver usa `rst_cfg`, então o cfg vem antes.

🧠 **Entender:**
- **A interface NÃO entra no package.** Interface é Verilog estrutural,
  não classe. Ela é compilada separada (veja `TB_SRCS` no `Makefile`:
  `clk_if.sv` vem antes de `clk_pkg.sv`).
- O `+incdir+` no Makefile é o que faz o `` `include "rst_cfg.sv" `` achar
  o arquivo.

---

### 4.6 PASSO 6 — Env cfg (`minisoc_env_cfg.sv`)

**O que é:** um config "guarda-chuva" que contém o config de cada agente.

```systemverilog
class minisoc_env_cfg extends uvm_object;
  `uvm_object_utils(minisoc_env_cfg)

  clk_cfg ref_clk;   // 2 GHz
  clk_cfg mem_clk;   // 100 MHz
  rst_cfg rst;
  virtual minisoc_probe_if probe_vif;

  function new(string name = "minisoc_env_cfg");
    super.new(name);
    ref_clk = clk_cfg::type_id::create("ref_clk");  ref_clk.period_ps = 500;
    mem_clk = clk_cfg::type_id::create("mem_clk");  mem_clk.period_ps = 10000;
    rst     = rst_cfg::type_id::create("rst");
  endfunction
endclass
```

🧠 **Entender:**
- O teste só precisa mexer em **um** objeto para configurar o ambiente
  inteiro.
- Os sub-configs são criados no `new`, com os valores default do VPLAN. O
  teste pode mudar depois (gancho `configure_env()`).
- **No SPI:** você vai acrescentar uma linha `spi_cfg spi;` aqui e criar no
  `new`.

---

### 4.7 PASSO 7 — Env (`minisoc_env.sv`)

**O que é:** o lugar onde os agentes (e depois scoreboard e coverage)
moram juntos. Na figura, é a caixa laranja.

```systemverilog
class minisoc_env extends uvm_env;
  `uvm_component_utils(minisoc_env)

  minisoc_env_cfg cfg;
  clk_agent ref_clk_agt;
  clk_agent mem_clk_agt;     // mesma classe, outra instância!
  rst_agent rst_agt;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(minisoc_env_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("ENV_NOCFG", "minisoc_env_cfg nao encontrado")

    // set ANTES do create
    uvm_config_db#(clk_cfg)::set(this, "ref_clk_agt", "cfg", cfg.ref_clk);
    uvm_config_db#(clk_cfg)::set(this, "mem_clk_agt", "cfg", cfg.mem_clk);
    uvm_config_db#(rst_cfg)::set(this, "rst_agt",     "cfg", cfg.rst);

    ref_clk_agt = clk_agent::type_id::create("ref_clk_agt", this);
    mem_clk_agt = clk_agent::type_id::create("mem_clk_agt", this);
    rst_agt     = rst_agent::type_id::create("rst_agt",     this);
  endfunction
endclass
```

📌 **Decorar:** o mesmo padrão de 3 partes do agent: **get, set, create**.

🧠 **Entender:**
- O nome no `set` (`"ref_clk_agt"`) tem que ser **igual** ao nome no
  `create` (`"ref_clk_agt"`). É assim que o recado chega no agente certo.
  Se você escrever `"ref_clk_agent"` num e `"ref_clk_agt"` no outro, o
  agente dá `CLK_NOCFG`.
- Quando houver **monitor + scoreboard**, o env ganha um `connect_phase`:
  `spi_agt.mon.ap.connect(scb.analysis_export);` — é a seta da figura que
  vai do monitor para o scoreboard.

---

### 4.8 PASSO 8 — Base test (`minisoc_base_test.sv`)

**O que é:** o teste "pai" com tudo que é comum: montar config, criar env,
timeout, imprimir PASS/FAIL. Nenhum teste real roda o base sozinho.

O `build_phase` dele, em ordem:

```systemverilog
env_cfg = minisoc_env_cfg::type_id::create("env_cfg");     // 1. cria config

uvm_config_db#(virtual clk_if)::get(this, "", "ref_clk_vif", env_cfg.ref_clk.vif);
uvm_config_db#(virtual clk_if)::get(this, "", "mem_clk_vif", env_cfg.mem_clk.vif);
uvm_config_db#(virtual rst_if)::get(this, "", "rst_vif",     env_cfg.rst.vif);
uvm_config_db#(virtual minisoc_probe_if)::get(this, "", "probe_vif", env_cfg.probe_vif);
                                                           // 2. pega os vifs do top_tb
env_cfg.rst.randomize();                                   // 3. sorteia o que é rand
configure_env();                                           // 4. gancho p/ testes filhos
uvm_config_db#(minisoc_env_cfg)::set(this, "env", "cfg", env_cfg);  // 5. entrega ao env
env = minisoc_env::type_id::create("env", this);           // 6. cria o env
uvm_top.set_timeout(test_timeout, 1);                      // 7. trava de segurança
```

🧠 **Entender:**
- **`configure_env()` é `virtual` e vazia.** É um *gancho*: um teste filho
  pode sobrescrever para mudar, por exemplo, o período do clock, sem copiar o
  `build_phase` inteiro:
  ```systemverilog
  class meu_teste extends minisoc_base_test;
    function void configure_env();
      env_cfg.mem_clk.period_ps = 20000;   // 50 MHz neste teste
    endfunction
  endclass
  ```
- **`report_phase`** conta quantos `UVM_ERROR` + `UVM_FATAL` aconteceram e
  imprime `TEST PASSED` ou `TEST FAILED`. O Makefile procura essa string no
  log (`make run`). Por isso todo erro de checagem **tem** que ser
  `` `uvm_error ``, não `$display`.
- **`end_of_elaboration_phase`** imprime a árvore (`print_topology`). Olhe
  no log: é a figura da aula, em texto.

---

### 4.9 PASSO 9 — Smoke test (`minisoc_smoke_test.sv`)

**O que é:** um teste de verdade. Herda tudo do base e só escreve o
**estímulo e as checagens** no `run_phase`.

```systemverilog
class minisoc_smoke_test extends minisoc_base_test;   // ← herda do SEU base
  `uvm_component_utils(minisoc_smoke_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    env.rst_agt.wait_reset_done();          // usa a API do agente
    measure_clock("clk", env_cfg.ref_clk);  // checa período
    check_defaults("apos reset inicial");   // checa registradores
    ...
    fork                                    // reset no meio da simulação
      env.rst_agt.apply_reset(runtime_cycles);
      begin repeat (3) @(posedge probe.clk); check_defaults("durante"); end
    join

    phase.drop_objection(this);
  endtask
endclass
```

🧠 **Entender:**
- Não tem `build_phase`! Ele herda o do base inteiro. Isso é o ganho da
  herança.
- `check_value` usa `!==` (e não `!=`) para que `X` e `Z` também contem
  como erro. Com `!=`, comparar com `X` dá `X`, que o `if` trata como falso,
  e o bug passa despercebido.
- Hoje os defaults são lidos pela `minisoc_probe_if` (espiando sinais
  internos). **Quando o SPI existir**, o certo é ler pelos registradores via
  SPI, como um software faria. Esse é o próximo teste que você vai escrever.

---

### 4.10 PASSO 10 — top_tb (`top_tb.sv`)

**O que é:** o `module` Verilog no topo de tudo. Na figura, é a caixa azul.
É o único lugar onde mundo Verilog (DUT, interfaces) e mundo UVM (classes)
se encontram.

Ele faz 4 coisas, sempre nesta ordem:

```systemverilog
module top_tb;
  import uvm_pkg::*;  `include "uvm_macros.svh"
  import minisoc_test_pkg::*;                     // traz as classes de teste

  // 1. instancia as interfaces
  clk_if ref_clk_if ();
  rst_if rst_if_i (.clk(ref_clk_if.clk));

  // 2. instancia o DUT ligado nas interfaces
  minisoc_top dut (.clk(ref_clk_if.clk), .rst_n(rst_if_i.rst_n), ...);

  // 3 e 4. publica os vifs e chama run_test
  initial begin
    uvm_config_db#(virtual clk_if)::set(null, "uvm_test_top", "ref_clk_vif", ref_clk_if);
    uvm_config_db#(virtual rst_if)::set(null, "uvm_test_top", "rst_vif",     rst_if_i);
    run_test();          // o nome do teste vem de +UVM_TESTNAME=... (Makefile)
  end
endmodule
```

📌 **Decorar:** interfaces → DUT → `config_db::set` → `run_test()`.

🧠 **Entender:**
- `set(null, "uvm_test_top", ...)`: `null` porque o module não é um
  componente UVM. O caminho absoluto é `"uvm_test_top"`.
- `run_test()` **sem argumento** lê `+UVM_TESTNAME`. É por isso que
  `make run TEST=minisoc_smoke_test` escolhe o teste sem recompilar.
- Hoje os sinais SPI estão parados em constantes (`spi_cs_n = 1'b1` etc.,
  `top_tb.sv:23-26`). **Quando você fizer o SPI, essas linhas somem** e
  viram uma `spi_if`.

---

## 5. Checklist: o que SEMPRE aparece

Cole isto do lado do monitor.

### Em todo component (driver, monitor, agent, env, test)

```systemverilog
class NOME extends uvm_XXX;
  `uvm_component_utils(NOME)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // config_db::get  → uvm_fatal se falhar
    // config_db::set  para os filhos
    // type_id::create dos filhos
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // ligar portas; copiar vif do cfg
  endfunction

  task run_phase(uvm_phase phase);
    // comportamento no tempo
  endtask
endclass
```

### Em todo object (cfg, item, sequence)

```systemverilog
class NOME extends uvm_XXX;
  `uvm_object_utils(NOME)            // ou _begin / `uvm_field_* / _end

  function new(string name = "NOME");
    super.new(name);
  endfunction
endclass
```

### Quem faz o quê

| Classe | `build_phase` | `connect_phase` | `run_phase` |
|---|---|---|---|
| cfg / item | — (object, não tem) | — | — |
| driver | — | `vif = cfg.vif` / (ou get do vif) | dirige pinos (`forever` ou por item) |
| monitor | — | `vif = cfg.vif` | `forever`: observa pinos, monta item, `ap.write(item)` |
| agent | get cfg, create driver/seqr/monitor | `drv.seq_item_port.connect(seqr.seq_item_export)` | — |
| env | get env_cfg, set cfgs, create agents/scoreboard | `agt.mon.ap.connect(scb...)` | — |
| test | create env_cfg, get vifs, set, create env | — | raise → estímulo → drop |

---

## 6. Bug encontrado no clk_driver

No seu `clk_driver.sv`, o `connect_phase` está **comentado** (alteração
local, ainda não commitada). Sem ele, a linha `vif = cfg.vif` nunca roda,
`vif` fica `null`, e o `run_phase` morre na primeira linha
(`vif.clk = 1'b0`) com erro de *null object access* no VCS.

Se você comentou para reescrever como exercício, ótimo, é exatamente a
parte para praticar. Se foi sem querer, descomente. Para conferir:
`git diff verif/tb/agents/clk/clk_driver.sv`.

---

## 7. Agora você: o roteiro do SPI

O SPI é diferente de clk/rst num ponto central: **ele tem transações**.
Cada frame de 40 bits é uma escrita ou leitura de registrador. Por isso ele
usa a figura **inteira**: item, sequence, sequencer, driver, monitor.

### 7.1 Entenda o protocolo antes de codar (tirado de `minisoc_spi.sv`)

```
Frame de 40 bits, MSB primeiro:

  39     38:33    32     31:0
 ┌─────┬────────┬─────┬──────────────┐
 │ RWb │ ADDR   │ RSV │ DATA[31:0]   │
 └─────┴────────┴─────┴──────────────┘
  RWb = 0 → escrita    RWb = 1 → pedido de leitura

Modo 0 (CPOL=0, CPHA=0):
  - sclk parado em 0, cs_n parado em 1
  - DUT amostra MOSI na SUBIDA de sclk   → driver muda MOSI na DESCIDA
  - DUT muda MISO na DESCIDA de sclk     → driver/monitor amostra MISO na SUBIDA
  - sclk ≤ 25 MHz → período ≥ 40 ns

Leitura usa DOIS frames:
  Frame A: RWb=1 + ADDR          (pede o valor)
  Frame B: qualquer frame (NOP=0x3F) → o MISO devolve {8'h00, DATA[31:0]}
```

Registrador bom para o primeiro teste: **VERSION (0x0D) = 0x0001_0100**.
É só leitura e tem valor fixo, então ou o seu agente funciona ou não.

> 🧠 Entre os frames, suba `cs_n` e espere alguns ciclos: o DUT passa o
> frame do domínio `sclk` para o domínio `clk` por um sincronizador (CDC),
> e o valor de leitura só fica pronto depois disso.

### 7.2 A ordem de construção (igual à seção 4, com 3 peças novas)

```
1. spi_if          interface      sclk, cs_n, mosi, miso
2. spi_cfg         uvm_object     vif, is_active, sclk_period_ps
3. spi_item   NOVO uvm_sequence_item  rwb, addr, data (+ rdata da resposta)
4. spi_sequencer NOVO  typedef uvm_sequencer #(spi_item) spi_sequencer;
5. spi_driver      uvm_driver #(spi_item)   ← agora com o tipo do item!
6. spi_monitor NOVO uvm_monitor  + uvm_analysis_port #(spi_item) ap
7. spi_agent       uvm_agent     monitor sempre; driver+seqr se ACTIVE
8. spi_pkg         include: cfg, item, seqr, driver, monitor, agent
   ── depois, no ambiente ──
9. env_cfg         + spi_cfg spi;
10. env            + spi_agent spi_agt;  set/create
11. base_test      + get "spi_vif"
12. sequence NOVO  spi_write_seq / spi_read_seq
13. teste          minisoc_spi_version_test
14. top_tb         troca os logic soltos por spi_if; set "spi_vif"
```

### 7.3 Esqueletos para você completar

Os `// TODO` são para você escrever. Tente sem olhar a seção 4 primeiro.

**spi_if.sv**
```systemverilog
interface spi_if;
  logic sclk = 1'b0;
  logic cs_n = 1'b1;     // TODO: por que começa em 1?
  logic mosi = 1'b0;
  logic miso;            // saída do DUT: sem valor inicial
endinterface
```

**spi_item.sv** — a transação (é o que viaja do sequencer para o driver
e do monitor para o scoreboard)
```systemverilog
class spi_item extends uvm_sequence_item;
  rand bit        rwb;     // 0 = write, 1 = read
  rand bit [5:0]  addr;
  rand bit [31:0] data;    // dado escrito
       bit [31:0] rdata;   // dado lido (o driver preenche)

  `uvm_object_utils_begin(spi_item)
    `uvm_field_int(rwb,   UVM_DEFAULT)
    `uvm_field_int(addr,  UVM_DEFAULT | UVM_HEX)
    `uvm_field_int(data,  UVM_DEFAULT | UVM_HEX)
    `uvm_field_int(rdata, UVM_DEFAULT | UVM_HEX)
  `uvm_object_utils_end

  function new(string name = "spi_item");
    super.new(name);
  endfunction

  function bit [39:0] to_frame();
    return {rwb, addr, 1'b0, data};   // bate com o formato da 7.1
  endfunction
endclass
```

**spi_driver.sv** — o laço que **todo driver com sequencer** tem
```systemverilog
class spi_driver extends uvm_driver #(spi_item);    // ← tipo do item aqui
  `uvm_component_utils(spi_driver)
  spi_cfg        cfg;
  virtual spi_if vif;

  // TODO: new e connect_phase (igual ao rst_driver)

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);   // 📌 decorar: pede o próximo item
      drive_frame(req);
      seq_item_port.item_done();          // 📌 decorar: "terminei este"
    end
  endtask

  task drive_frame(spi_item it);
    bit [39:0] tx = it.to_frame();
    bit [39:0] rx;
    int half = cfg.sclk_period_ps / 2;

    vif.cs_n = 1'b0;
    for (int i = 39; i >= 0; i--) begin
      vif.mosi = tx[i];             // muda MOSI com sclk em 0
      #(half * 1ps);
      vif.sclk = 1'b1;              // subida: DUT amostra MOSI
      rx[i] = vif.miso;             //         nós amostramos MISO
      #(half * 1ps);
      vif.sclk = 1'b0;              // descida: DUT muda MISO
    end
    #(half * 1ps);
    vif.cs_n = 1'b1;
    it.rdata = rx[31:0];
    // TODO: esperar alguns ciclos com cs_n=1 antes do próximo frame (CDC)
  endtask
endclass
```

**spi_monitor.sv** — só observa, nunca escreve no `vif`
```systemverilog
class spi_monitor extends uvm_monitor;
  `uvm_component_utils(spi_monitor)
  spi_cfg        cfg;
  virtual spi_if vif;
  uvm_analysis_port #(spi_item) ap;      // 📌 a "seta" que sai do monitor

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);                // 📌 porta se cria com new, no construtor
  endfunction

  // TODO: connect_phase pegando vif

  task run_phase(uvm_phase phase);
    forever begin
      bit [39:0] mosi_bits, miso_bits;
      spi_item it;
      @(negedge vif.cs_n);                       // início do frame
      for (int i = 39; i >= 0; i--) begin
        @(posedge vif.sclk);
        mosi_bits[i] = vif.mosi;
        miso_bits[i] = vif.miso;
      end
      it = spi_item::type_id::create("it");
      // TODO: desmontar mosi_bits em rwb/addr/data e miso_bits em rdata
      ap.write(it);                              // 📌 publica para quem estiver ouvindo
    end
  endtask
endclass
```

**spi_agent.sv** — a novidade é o `if (is_active)` e o `connect`
```systemverilog
class spi_agent extends uvm_agent;
  `uvm_component_utils(spi_agent)
  spi_cfg       cfg;
  spi_driver    drv;
  spi_sequencer seqr;
  spi_monitor   mon;

  // TODO: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // TODO: get do cfg + checagens (igual rst_agent)
    is_active = cfg.is_active;

    mon = spi_monitor::type_id::create("mon", this);      // monitor SEMPRE
    mon.cfg = cfg;
    if (get_is_active() == UVM_ACTIVE) begin               // driver só se ACTIVE
      drv  = spi_driver::type_id::create("drv", this);
      seqr = spi_sequencer::type_id::create("seqr", this);
      drv.cfg = cfg;
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE)
      drv.seq_item_port.connect(seqr.seq_item_export);    // 📌 a seta seqr → driver
  endfunction
endclass
```

**spi_read_seq.sv** — a sequence é o "programa"; roda no sequencer
```systemverilog
class spi_read_seq extends uvm_sequence #(spi_item);
  `uvm_object_utils(spi_read_seq)          // sequence é OBJECT!
  bit [5:0]  addr;
  bit [31:0] rdata;

  function new(string name = "spi_read_seq");
    super.new(name);
  endfunction

  task body();                              // 📌 o código da sequence fica no body()
    spi_item it;
    // Frame A: pedido de leitura
    it = spi_item::type_id::create("frameA");
    start_item(it);                         // 📌 decorar: start_item / finish_item
    it.rwb = 1; it.addr = addr; it.data = 0;
    finish_item(it);
    // Frame B: NOP para trazer o dado
    it = spi_item::type_id::create("frameB");
    start_item(it);
    it.rwb = 0; it.addr = 6'h3F; it.data = 0;
    finish_item(it);
    rdata = it.rdata;
  endtask
endclass
```

**No teste:**
```systemverilog
task run_phase(uvm_phase phase);
  spi_read_seq rd;
  phase.raise_objection(this);
  env.rst_agt.wait_reset_done();

  rd = spi_read_seq::type_id::create("rd");
  rd.addr = 6'h0D;                          // VERSION
  rd.start(env.spi_agt.seqr);               // 📌 sequence roda NO sequencer
  if (rd.rdata !== 32'h0001_0100)
    `uvm_error("SPI_VER", $sformatf("VERSION = 0x%08h, esperado 0x00010100", rd.rdata))

  phase.drop_objection(this);
endtask
```

### 7.4 O caminho de um item (para entender a figura de verdade)

```
 teste                sequence               sequencer          driver               DUT
   │  rd.start(seqr)     │                       │                  │                   │
   │────────────────────►│ start_item(it)        │                  │                   │
   │                     │──────────────────────►│ get_next_item()  │                   │
   │                     │ finish_item(it)       │◄─────────────────│                   │
   │                     │──────────────────────►│─────── it ──────►│ drive_frame(it)   │
   │                     │                       │                  │──── pinos ───────►│
   │                     │                       │   item_done()    │                   │
   │                     │◄──────────────────────│◄─────────────────│                   │
   │◄────────────────────│ (body termina)        │                  │                   │
                                                                      monitor vê os pinos
                                                                      → ap.write(it)
                                                                      → scoreboard
```

### 7.5 Ordem sugerida de trabalho (um passo testável por vez)

1. `spi_if` + ligar no `top_tb`. Compile. Nada muda ainda.
2. `spi_cfg`, `spi_item`, `spi_sequencer`, `spi_driver`, `spi_agent` (sem
   monitor). `spi_pkg`. Compile.
3. Pôr o agente no env, `get` do vif no base_test. Rode o `smoke_test`: tem
   que continuar passando (o driver fica parado esperando item).
4. `spi_read_seq` + teste que lê VERSION. **Primeiro marco: ler 0x00010100.**
   Abra as waves (`make run WAVES=fsdb` + `make verdi`) e confira os 40
   pulsos de sclk.
5. `spi_write_seq` + teste que escreve KEY0 e lê de volta.
6. `spi_monitor` + imprimir o item com `` `uvm_info(..., it.sprint(), ...) ``.
7. Só então: scoreboard.

---

## 8. Erros clássicos e como reconhecer no log

| Mensagem / sintoma | Causa provável |
|---|---|
| `UVM_FATAL ... XXX_NOCFG ... nao encontrado` | Nome ou caminho diferente entre `set` e `get`, ou `set` depois do `create` |
| `Null object access` no `run_phase` do driver | `vif` nunca foi atribuído (ver seção 6) |
| Teste termina em 0 ns e "passa" | Faltou `raise_objection` no teste |
| Teste nunca termina → `TIMEOUT` | Objection levantada e nunca baixada, ou driver esperando item que não vem |
| `Error-[ICTA] Incompatible type` no `config_db` | Tipo do `#( )` diferente no set e no get (ex.: `virtual spi_if` × `spi_if`) |
| `Could not create an object of type 'X'` / factory | Faltou `` `uvm_component_utils(X) `` ou a classe não está no pkg |
| `run_phase` não compila | Escreveu `function` em vez de `task` |
| Driver fica travado em `get_next_item` | Esqueceu `item_done()`, ou não ligou `seq_item_port` no `connect_phase` do agent |
| Comparação passa com `X` | Usou `!=` em vez de `!==` |

---

## 9. Exercícios para fixar

Faça sem olhar o código, depois compare.

1. **Desenhe a árvore** `uvm_test_top.env...` completa do projeto atual.
   Confira com o `print_topology` do log.
2. **Reescreva o `rst_agent`** do zero num arquivo à parte. Quais linhas
   você esqueceu?
3. **Crie um teste filho** que muda o `mem_clk` para 50 MHz usando apenas
   `configure_env()`. Rode e veja o `smoke` medir o novo período.
4. **Quebre de propósito:** troque `"rst_agt"` por `"rst_agent"` no `set`
   do env. Leia o erro. Desfaça.
5. **Responda:** por que o `clk_driver` não levanta objection, mas o teste
   levanta?
6. **Responda:** por que o MOSI muda na descida de `sclk` e é lido na
   subida? Qual é a relação com o `@(negedge vif.clk)` do `rst_driver`?
7. **Implemente o SPI** seguindo a 7.5. O primeiro marco é ler `0x00010100`.

---

> **Resumo em uma frase:** *a interface é o cabo, o config é o formulário,
> o driver mexe no cabo, o agent embrulha o driver, o env junta os agents,
> o test monta tudo e dá a ordem, e o top_tb liga o cabo no chip e aperta o
> play.*
