# Ambiente de verificação – MiniSoC AES

Testbench UVM do MiniSoC AES (Fase 2 – Parte II, CI-Expert / Residência em Microeletrônica, Polo UFCG).
Estratégia, features, checkers e cobertura estão no Verification Plan em `doc/`.

## Estrutura

```
verif/
├── Makefile                  compilação, execução, waves (VCS)
├── doc/                      VPLAN e diagrama da arquitetura
├── sim/                      saída da simulação (gerado, fora do git)
└── tb/
    ├── top_tb.sv             DUT + interfaces + config_db + run_test()
    ├── top_assertions.sv     SVA de sistema (bind no minisoc_top)
    ├── minisoc_probe_if.sv   observação de sinais internos do DUT
    ├── agents/
    │   ├── clk/              VIP de CLOCK: clk_if, clk_cfg, clk_driver, clk_agent, clk_pkg
    │   └── rst/              VIP de RESET: rst_if, rst_cfg, rst_driver, rst_agent, rst_pkg
    ├── env/                  minisoc_env_cfg, minisoc_env, minisoc_env_pkg
    ├── sequences/            (P2+)
    ├── tests/                minisoc_base_test, minisoc_smoke_test, minisoc_test_pkg
    └── refmod/               reference model AES (C++/DPI-C, a partir de P4)
```

## Como rodar

Pré-requisitos: Synopsys VCS com UVM 1.2 (`-ntb_opts uvm-1.2`); Verdi para FSDB (opcional).

```
cd verif
make                                   # compila + roda minisoc_smoke_test, seed 1
make run SEED=42                       # outra seed
make run VERBOSITY=UVM_HIGH            # mostra cada checagem
make run WAVES=fsdb && make verdi      # waves no Verdi
make run WAVES=vcd                     # waves em sim/waves.vcd
make clean
```

Resultado: `make run` imprime `PASS`/`FAIL` e o log fica em `sim/logs/<teste>_<seed>.log`.

## Status (VPLAN v1 – outubro/2026)

| Fase | Conteúdo | Status |
|---|---|---|
| P0 | Baseline: top_tb, env, base test, Makefile | implementado |
| P1 | VIPs de clock e reset, T-SMOKE, SVA A-01/A-02a/A-03 | implementado |
| P2 | SPI agent + PLL monitor/checker | planejado (nov) |
| P3 | MEMORY DATA agent + scoreboard | planejado (nov) |
| P4 | AES end-to-end com refmod | planejado (dez) |
