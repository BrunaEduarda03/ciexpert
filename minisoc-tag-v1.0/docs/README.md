# docs/ — material de estudo do marco P0/P1

Esta pasta explica o ambiente de verificação UVM do `minisoc-tag-v1.0`, arquivo por
arquivo, para consulta e para a defesa do checkpoint. Ela é separada de
`verif/doc/`, que guarda os **entregáveis** (VPLAN, diagrama) — aqui é só
material de estudo, não entra na nota.

Ordem sugerida de leitura:

1. [01-visao-geral.md](01-visao-geral.md) — o que é UVM, como as peças se encaixam, por que essa estrutura
2. [02-vip-clock.md](02-vip-clock.md) — VIP de clock (`clk_if/cfg/driver/agent`)
3. [03-vip-reset.md](03-vip-reset.md) — VIP de reset (`rst_if/cfg/driver/agent`)
4. [04-probe-env.md](04-probe-env.md) — `minisoc_probe_if`, `minisoc_env_cfg`, `minisoc_env`
5. [05-testes.md](05-testes.md) — `minisoc_base_test`, `minisoc_smoke_test`
6. [06-assertions-sva.md](06-assertions-sva.md) — `top_assertions.sv` (A-01, A-02a, A-03)
7. [07-makefile-vcs.md](07-makefile-vcs.md) — `Makefile`, flags do VCS, como rodar
8. [08-evidencias-outubro.md](08-evidencias-outubro.md) — o log real de 29/10, linha a linha
9. [09-status-entregas.md](09-status-entregas.md) — status de cada entrega e o que foi feito hoje no servidor

Todo o conteúdo abaixo foi escrito a partir do código real em `verif/tb/` após
rodar no VCS X-2025.06-SP2 neste servidor (`srv-microeletronica3`), não é
uma descrição genérica de UVM.
