# 12 — O que fazer até 30/11/2026 (checkpoint de novembro)

Montado a partir de uma varredura em `docs/especificacao/` (Plano de Projeto e
Avaliação, Block Guide MiniSoC AES v1.0.0, Plano Dia 3), `docs/templates/`, no
VPLAN v1 (`verif/doc/CI-Expert_Fase2_Verification_Plan_v1.docx`) e no código
atual de `verif/tb/`.

Hoje: **ter 24/11**. Prazo: **seg 30/11**. São **6 dias**.



## 1. O que o plano de projeto exige para novembro

| Campo | Texto oficial (Plano de Projeto, seção 5) |
|---|---|
| Foco técnico | VIPs das interfaces externas e configuração. |
| Entrega obrigatória | VIP CLK, VIP RESET, **VIP SPI**, **VIP MEMORY DATA**; **configuração básica do DUT**; **atualização do VPLAN**; **primeiros testes de interface**. |
| Checkpoint individual | Demonstrar **transações SPI e de dados (MEMORY DATA)**, **monitores e checagens locais**; **justificar escolhas de arquitetura**. |

No seu VPLAN v1 isso corresponde às fases **P2 (SPI + PLL)** e **P3 (MEMORY DATA)**.

**"Pronto" para o marco (seção 5.1 do plano):**
- versionado e executável (`make compile run` passando);
- evidência objetiva: logs, waves, resultados de regressão;
- checagem automática em tudo que for possível (scoreboard/assertion, não "olhar a wave");
- VPLAN atualizado: o que foi feito, o que falta, gaps;
- você consegue explicar arquitetura, problemas e próximos passos.

**Como o checkpoint é avaliado (seção 6.1):** entrega técnica 50% · domínio e
justificativas 25% · evidências e reprodutibilidade 15% · organização da
apresentação 10%.

---

## 2. Onde você está hoje

| Item | Status | Onde |
|---|---|---|
| VIP CLK (`clk_if/cfg/driver/agent/pkg`) | ✅ feito em out. (há alterações em `clk_driver.sv`/`clk_if.sv` ainda não commitadas) | `verif/tb/agents/clk/` |
| VIP RESET | ✅ feito | `verif/tb/agents/rst/` |
| `minisoc_env`, `env_cfg`, `probe_if` | ✅ só clk + rst | `verif/tb/env/`, `verif/tb/minisoc_probe_if.sv` |
| `top_assertions.sv` (A-01, A-02a, A-03) | ✅ | `verif/tb/` |
| `minisoc_base_test`, `minisoc_smoke_test` | ✅ PASS | `verif/tb/tests/` |
| Makefile (`TEST`, `SEED`, `WAVES`) | ✅ — mas roda **um** teste por vez, sem alvo de regressão | `verif/Makefile` |
| SPI em `top_tb.sv` | ❌ sinais fixos em repouso (`spi_cs_n = 1`) | `verif/tb/top_tb.sv` |
| MEMORY DATA em `top_tb.sv` | ❌ sinais fixos em 0 | `verif/tb/top_tb.sv` |
| `verif/tb/sequences/` | ❌ vazio | |
| VPLAN | v1 (outubro) — versões VCS/UVM ainda "[a registrar]", tudo `PLANEJADO` | `verif/doc/` |
| Evidências de outubro | ⚠️ `verif/doc/evidencias/` **não existe neste repositório** (o doc 09 diz que foi salvo lá) — confira se ficou em outra cópia | |

### Pendências de outubro (feche primeiro — 1 h no máximo)
- [x] `clk_if.sv` (só comentário) staged para commit.
- [x] `clk_driver.sv`: o `connect_phase` (que faz `vif = cfg.vif`) estava
      comentado, o que deixaria `vif` nulo. Descomentado (arquivo voltou a ser
      igual ao último commit). `make compile run WAVES=fsdb` em 24/11:
      **PASS**, `UVM_ERROR = 0`, `UVM_FATAL = 0`.
- [x] `verif/doc/evidencias/outubro/` recuperado da cópia em
      `~/minisoc-tag-v1.0/` (log do smoke test com `TEST PASSED` e `waves.fsdb`
      de 29/10). Os dois arquivos estão no `.gitignore` (`*.log`, `*.fsdb`) e
      foram adicionados com `git add -f`.
- [x] Print do Verdi: `verif/doc/evidencias/outubro/verdi_clk_rst.png`, gerado
      do `waves.fsdb` de 29/10 (Verdi em modo headless via `xvfb-run`), 0–40 ns,
      cursor em 20 ns na liberação do reset. Os nomes dos sinais foram rotulados
      na imagem porque a coluna de nomes do nWave fica estreita no modo headless.
- [ ] `docs/especificacao/` e `docs/templates/` estão staged. Os PDFs do
      Plano de Projeto e do Block Guide são marcados **CONFIDENCIAL**: só faça
      push se o repositório `BrunaEduarda03/ciexpert` for **privado**.
- [ ] Feedback do checkpoint de outubro: _anotar aqui o que foi pedido_ e incluir no cronograma.

---

## 3. O que precisa existir no dia 30/11 (escopo mínimo)

Ordem de prioridade — se faltar tempo, corte de baixo para cima.

### 3.1 VIP SPI — **obrigatório**

Arquivos (estrutura do Plano Dia 3, seção 5):

```
verif/tb/agents/spi/
  spi_if.sv  spi_item.sv  spi_cfg.sv  spi_driver.sv
  spi_monitor.sv  spi_sequencer.sv  spi_agent.sv  spi_pkg.sv
verif/tb/sequences/spi/
  spi_write_seq.sv  spi_read_seq.sv  spi_reg_seqs.sv
```

O que cada peça precisa fazer (regras do Block Guide seção 5):

| Peça | Conteúdo |
|---|---|
| `spi_if` | `sclk`, `cs_n`, `mosi`, `miso`. |
| `spi_item` | `op` (WRITE/READ), `addr[5:0]`, `wdata[31:0]`, `rdata[31:0]`; constraint `addr` em 0x00–0x0F/0x3F (e um modo "não mapeado" para 0x10–0x3E). |
| `spi_cfg` | `sclk_period_ns` (default 50 ns = 20 MHz; **mínimo 40 ns = 25 MHz**), gap entre frames, `is_active`. |
| `spi_driver` | Gera o próprio `sclk`. Mode 0: `sclk` em 0 no repouso, MOSI muda com `sclk` baixo, DUT amostra na **subida**. Frame de 40 bits MSB-first: `{RWb, ADDR[5:0], RSV=0, DATA[31:0]}`. **WRITE** = 1 frame. **READ** = 2 frames: request (`RWb=1`, addr) + frame NOP (addr `0x3F`), capturando MISO bits [31:0] do 2º frame. Devolve `rdata` com `put_response()` (decisão do Dia 3: "resposta separada via `get_response()`"). |
| `spi_monitor` | Passivo. Amostra MOSI e MISO na subida de `sclk`; fecha o frame na subida de `cs_n`. Frame com ≠ 40 bits → reporta como abortado. Junta request + NOP em **uma** transação READ com o dado lido. Publica no `analysis_port`. |
| `spi_agent` | Ativo: sequencer + driver + monitor. Passivo: só monitor. |
| Sequences | `spi_write_seq(addr, data)`, `spi_read_seq(addr) → data`, `spi_reg_rw_seq` (escreve e lê de volta). |

> Atenção ao CDC (spec 5.3): o frame é capturado em `sclk` e transportado para
> o `clk` por toggle sync. Deixe um gap entre frames (≥ 1 período de `sclk`
> já é muito mais que os ciclos de 2 GHz necessários).

### 3.2 Checagem local do SPI — **obrigatório** (o checkpoint pede "checagens locais")

`verif/tb/env/spi_scoreboard.sv` (CHK-02 do VPLAN) — modelo simples de
registradores, sem RAL (decisão do Dia 3):

- defaults pós-reset: KEY/IV/COUNTER = 0, `NUM_BLOCKS = 1`, `AES_CONTROL = 0`,
  `SYSTEM_CONTROL`: `MEM_SEL_AES = 0`, `PLL_ENABLE = 0`, `PLL_DIV_SEL = 11`;
- R/W (0x00–0x0B, 0x0E) devolvem o último valor escrito (com máscara de bits válidos);
- RO (0x0C `AES_STATUS`, 0x0D `VERSION` = `0x0001_0100`, 0x0F `SYSTEM_STATUS`) ignoram escrita;
- `START` lê sempre 0; não mapeados (0x10–0x3E) leem 0;
- para `AES_STATUS`/`SYSTEM_STATUS` em novembro basta comparar com o `probe_vif`
  (ou deixar como "não checado" e registrar no VPLAN).

Divergência → `UVM_ERROR`. Leitura do `VERSION` resolve o **OPEN-03**.

### 3.3 VIP MEMORY DATA — **obrigatório**

```
verif/tb/agents/mem/
  mem_if.sv  mem_item.sv  mem_cfg.sv  mem_driver.sv
  mem_monitor.sv  mem_sequencer.sv  mem_agent.sv  mem_pkg.sv
verif/tb/sequences/mem/
  mem_write_seq.sv  mem_read_seq.sv  mem_fill_seq.sv
```

| Peça | Conteúdo |
|---|---|
| `mem_if` | Recebe `mem_clk` como porta (como o `rst_if` recebe `clk`); sinais `mem_i_data[31:0]`, `mem_i_wr_en`, `mem_i_addr[9:0]`, `mem_o_data[31:0]`; clocking blocks para driver e monitor. O `mem_clk` continua vindo do `mem_clk_agt` que você já tem. |
| `mem_item` | `op` (R/W), `addr[9:0]`, `wdata`, `rdata`. |
| `mem_driver` | Escrita: `wr_en=1` + addr + data por 1 ciclo. Leitura: `wr_en=0` + addr, espera a latência de **1 ciclo** (VPLAN F12) e captura `mem_o_data`. Ociosa: `wr_en=0`. |
| `mem_monitor` | Publica escritas e leituras com o dado de retorno. |
| Sequences | escrita/leitura unitária; `fill` de N palavras; padrões 0, `0xFFFFFFFF`, `0xAAAA5555`, walking-1, aleatório (ST-MEM-01). |

> **Decisão de arquitetura que você vai ter que justificar:** a interface não
> tem sinal de *valid* — com `wr_en = 0` todo ciclo é uma leitura. O monitor
> precisa saber o que é "transação". Opções:
> (a) sinal `tb_valid` só no `mem_if` (não vai ao DUT), dirigido pelo driver — simples e sem ruído;
> (b) monitor publica toda escrita e só leituras com endereço novo — 100% passivo, mais frágil.
> Recomendo **(a)**, e registrar no VPLAN o motivo (interface sem handshake, spec 3/7.3).

### 3.4 Checagem local da memória — **obrigatório**

`verif/tb/env/mem_scoreboard.sv` (CHK-04): array associativo como modelo da RAM.
- Escrita com `MEM_SEL_AES = 0` → atualiza o modelo.
- Escrita com `MEM_SEL_AES = 1` → **não** atualiza (ownership, F13). Leia `MEM_SEL_AES` do `probe_vif.cfg_mem_sel_aes`.
- Leitura de endereço conhecido → compara; desconhecido → não checa (memória sem reset).

### 3.5 Configuração básica do DUT — **obrigatório**

Uma sequence (ou task no `base_test`) `minisoc_cfg_seq` que, via SPI:
1. lê `VERSION`;
2. escreve `PLL_DIV_SEL` e `PLL_ENABLE = 1` em `SYSTEM_CONTROL`;
3. faz polling de `SYSTEM_STATUS.PLL_LOCKED` com **timeout** (CHK-08);
4. escreve/limpa `MEM_SEL_AES`.

Isso mostra a "configuração básica" e já prepara o fluxo de dezembro
(passos 1–10 do modelo de programação, Block Guide seção 9).

### 3.6 Integração no ambiente

- `top_tb.sv`: trocar os `logic` fixos de SPI e MEMORY por `spi_if` e `mem_if`; publicar `spi_vif`/`mem_vif` no `config_db`.
- `minisoc_env_cfg`: adicionar `spi_cfg` e `mem_cfg`.
- `minisoc_env`: criar `spi_agt`, `mem_agt`, `spi_scb`, `mem_scb` e conectar `monitor.ap → scoreboard` no `connect_phase`.
- `Makefile`: incluir os novos pacotes/`+incdir+`.

### 3.7 Testes de interface — **obrigatório** (pelo menos os 4 primeiros)

Nomes e IDs já definidos no VPLAN v1, seção 8:

| Teste | O que faz | Checker | Prioridade |
|---|---|---|---|
| `minisoc_smoke_test` (T-SMOKE) | já existe — manter passando | CHK-01, A-01 | mantém |
| `minisoc_rst_default_test` (T-RST-DEFAULT) | reset + leitura via SPI de **todos** os registradores, `VERSION`, `SYSTEM_STATUS` | CHK-01, CHK-02 | 1 |
| `minisoc_spi_reg_test` (T-SPI-REG) | escrita/leitura de todos os endereços (R/W, RO, reservados, não mapeados), dados dirigidos + aleatórios | CHK-02 | 1 |
| `minisoc_mem_rw_test` (T-MEM-RW) | escrita/leitura 0, 1023, limites de bloco, aleatórios; padrões; **acesso com `MEM_SEL_AES = 1` não tem efeito** | CHK-04 | 1 |
| `minisoc_pll_bringup_test` (T-PLL-BRINGUP, versão básica) | habilita PLL com cada divisor e espera `PLL_LOCKED` via SPI | timeout + leitura | 2 |
| `minisoc_spi_abort_test` (T-SPI-ABORT) | frames abortados intercalados com válidos | CHK-02 | 3 (se sobrar tempo) |

### 3.8 Assertions novas (baratas e contam como "checagem local")

Já planejadas no VPLAN, seção 6:
- **A-09** — período de `spi_sclk` ≥ 40 ns e `RSV = 0` com `cs_n = 0` (checa o próprio TB).
- **A-10** — `mem_i_addr/wr_en/data` sem X/Z na borda de `mem_clk` com `MEM_SEL_AES = 0`.
- (opcional) **A-04** — `o_locked` sobe entre 8 e 31 ciclos após o enable.

### 3.9 Regressão mínima

Alvo `make regress` que roda a lista de testes acima com 2–3 seeds cada e
imprime um resumo PASS/FAIL. Não precisa ser sofisticado — o plano de dezembro
pede "primeira regressão", então ter isso já em novembro é ponto a favor.

### 3.10 O que pode ficar para dezembro (e registrar no VPLAN)

O VPLAN v1 coloca `pll_monitor` + `pll_checker` (CHK-03) em P2. O plano de
projeto **não** cita PLL no marco de novembro. Se o tempo apertar, entregue
só o bring-up básico via SPI (3.5) e mova `pll_monitor`/`pll_checker`/coverage
para dezembro — **registrando o replanejamento no VPLAN v2**. Também ficam
para depois: virtual sequencer, covergroups, `aes_monitor`, refmod/scoreboard AES.

---

## 4. Atualização do VPLAN (v1 → v2)

Use o próprio `CI-Expert_Fase2_Verification_Plan_v1.docx` (feito a partir do
template `docs/templates/CI-Expert_Fase2_Verification_Plan.docx`) e salve como
`verif/doc/CI-Expert_Fase2_Verification_Plan_v2.docx`.

- [ ] Capa / histórico: **V2.0 — checkpoint de novembro (Nov/2026)**.
- [ ] Tabela 1.2: VCS `X-2025.06-SP2_Full64` e `UVM-1.2` (hoje "[a registrar]").
- [ ] Seção 4 (arquitetura): figura atualizada (`tb_arch.svg`) com `spi_agent`, `mem_agent`, `spi_scoreboard`, `mem_scoreboard`.
- [ ] Seção 4: registrar as decisões de novembro (ver seção 6 deste doc), inclusive a do *valid* do `mem_if`.
- [ ] Seção 4.2 (bring-up phases): P0/P1 = **concluído**, P2/P3 = **concluído / em andamento** conforme o real; se o `pll_checker` for para dezembro, dizer isso.
- [ ] Pontos em aberto: **OPEN-03** (VERSION) com o valor lido; OPEN-01 se der para observar no bring-up do PLL.
- [ ] Seção 8: nome real do arquivo de cada teste.
- [ ] Seção 9 (rastreabilidade): mudar status de F01, F08, F09, F12, F13 (e F05 se fizer o PLL) de `PLANEJADO` para `EM ANDAMENTO`/`IMPLEMENTADO`, com o log que é a evidência.
- [ ] Gaps conhecidos: listar o que ficou para dezembro.

Os templates `Verification_Guide` e `Verification_Report` são para fevereiro.
Se sobrar 30 min, crie só o esqueleto do Guide com "como compilar/rodar" —
você já tem o conteúdo em [07-makefile-vcs.md](07-makefile-vcs.md).

---

## 5. Evidências para a apresentação

Salvar em `verif/doc/evidencias/novembro/`:

- [ ] log de cada teste da 3.7 com `TEST PASSED`, `UVM_ERROR: 0`;
- [ ] saída do `make regress` (tabela PASS/FAIL por teste × seed);
- [ ] print do Verdi de **um frame SPI WRITE** e **um READ (request + NOP)** com `sclk/cs_n/mosi/miso`;
- [ ] print do Verdi de **escrita e leitura** na MEMORY DATA mostrando a latência de 1 ciclo;
- [ ] trecho de log do `spi_monitor`/`mem_monitor` imprimindo a transação reconstruída (`convert2string`);
- [ ] trecho de log do scoreboard: "N leituras comparadas, 0 erros";
- [ ] **uma falha provocada de propósito** (ex.: modelo esperando valor errado) mostrando o scoreboard pegando o erro — prova de que a checagem funciona;
- [ ] print de `SYSTEM_STATUS.PLL_LOCKED = 1` lido via SPI.

---

## 6. "Justificar escolhas de arquitetura" — prepare respostas

O checkpoint pede isso explicitamente (25% da nota é domínio/justificativa).

| Pergunta provável | Sua resposta (ajuste ao que implementar) |
|---|---|
| Por que clk/rst são agents sem sequencer? | Não há transação a sequenciar; parâmetros (período, duração) vêm do `cfg`. **Atenção:** o Plano Dia 3 dizia "drivers direto no env, sem agentes"; você implementou como agent (driver only). Justifique: padrão uniforme, reuso (dois `clk_agent` para `clk` e `mem_clk`), fácil tornar passivo. Registre no VPLAN. |
| Por que o SPI tem sequencer e o reset não? | SPI tem transações com conteúdo (op, addr, data) e ordem importa; reset é um nível. |
| Por que a leitura é um item só se no fio são 2 frames? | Abstração no nível de registrador: o teste pensa "ler addr X". O driver esconde o NOP; o monitor recompõe. |
| Por que `put_response` e não modificar o item? | Decisão do Dia 3; separa pedido de resposta e permite pipelining no futuro. |
| Por que scoreboard próprio e não RAL? | Mapa pequeno (16 registros), prazo curto, controle total da regra de BUSY/RO; RAL fica como evolução. |
| Como o monitor de memória sabe o que é transação? | Decisão do *valid* (3.3). |
| Como o scoreboard sabe se a escrita deve valer? | Lê `MEM_SEL_AES` pelo `probe_if` (sinal interno, sem bind ainda). |
| Por que `UVM_ERROR` × `UVM_FATAL`? | Divergência de dado = erro (continua para achar mais); falta de `vif`/timeout = fatal (ambiente quebrado). Decisão do Dia 3. |
| Por que `sclk` default de 20 MHz? | Dentro de REQ-SPI-01 (≤ 25 MHz) com margem; A-09 garante que o TB nunca passa disso. |

---

## 7. Apresentação (6–8 slides)

1. Onde paramos em outubro → o que o marco de novembro pede.
2. Arquitetura atualizada (diagrama com spi/mem agents e scoreboards).
3. VIP SPI: frame de 40 bits, write × read (2 frames), print da wave.
4. VIP MEMORY DATA: write/read, latência, decisão do *valid*, print da wave.
5. Checagens locais: `spi_scoreboard`, `mem_scoreboard`, A-09/A-10; a falha provocada.
6. Configuração básica do DUT: PLL enable → LOCKED via SPI; ownership.
7. Testes + regressão (tabela PASS/FAIL) + VPLAN v2 (o que mudou de status).
8. Gaps, OPEN-xx, plano de dezembro (AES end-to-end, refmod, primeira regressão completa).

Tenha `make compile run TEST=minisoc_spi_reg_test` pronto para rodar ao vivo.

---

## 8. Cronograma dia a dia

| Dia | Meta | Pronto quando |
|---|---|---|
| **Ter 24/11** | Pendências de outubro (2). `spi_if`, `spi_item`, `spi_cfg`, `spi_driver`. Ligar no `top_tb`. | Compila; um WRITE aparece certo na wave. |
| **Qua 25/11** | `spi_monitor`, `spi_agent`, sequences write/read. `minisoc_rst_default_test`. | Lê `VERSION = 0x0001_0100` via SPI e o monitor imprime a transação. |
| **Qui 26/11** | `spi_scoreboard`. `minisoc_spi_reg_test`. `minisoc_cfg_seq` + `minisoc_pll_bringup_test` básico. A-09. | T-RST-DEFAULT e T-SPI-REG PASS com scoreboard ativo; `PLL_LOCKED = 1` lido. |
| **Sex 27/11** | VIP MEMORY completo (if, item, driver, monitor, agent, seqs). `mem_scoreboard`. | Escrita/leitura em 0, 1023 e aleatórios batendo no scoreboard. |
| **Sáb 28/11** | `minisoc_mem_rw_test` com ownership (via SPI). A-10. `make regress`. Folga para bugs. | Todos os testes PASS em 2–3 seeds. |
| **Dom 29/11** | Evidências (5), VPLAN v2 (4), diagrama, slides (7). | Pasta `evidencias/novembro/` completa; slides prontos. |
| **Seg 30/11** | Ensaio (cronometrar), respostas da seção 6, commit + tag (`minisoc-nov-2026`). | Demo ao vivo roda do zero com `make clean compile run`. |

**Regra de corte:** se na sexta à noite o VIP SPI ainda não estiver com
scoreboard funcionando, pule T-PLL-BRINGUP e T-SPI-ABORT e vá direto para a
memória. SPI + MEMORY com checagem local são o núcleo obrigatório; PLL e
frame abortado não são.

---

## 9. Checklist final (30/11)

- [ ] `make clean compile` sem erros
- [ ] T-SMOKE, T-RST-DEFAULT, T-SPI-REG, T-MEM-RW passando (+ T-PLL-BRINGUP se feito)
- [ ] `make regress` com resumo PASS/FAIL
- [ ] `spi_scoreboard` e `mem_scoreboard` com contagem de comparações no `report_phase`
- [ ] A-09 e A-10 ativas
- [ ] VPLAN v2 salvo em `verif/doc/`
- [ ] diagrama `tb_arch` atualizado
- [ ] evidências em `verif/doc/evidencias/novembro/`
- [ ] slides prontos e ensaiados
- [ ] tudo commitado
