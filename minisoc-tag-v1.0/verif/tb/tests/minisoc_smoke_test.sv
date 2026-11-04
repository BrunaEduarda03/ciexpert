//-----------------------------------------------------------------------------
// minisoc_smoke_test.sv  (T-SMOKE, VPLAN secao 8)
// P0/P1: verifica que clock e reset funcionam e que o DUT inicializa.
//   1. Espera o reset inicial (duracao randomizada 10..50 ciclos).
//   2. Mede o periodo de clk (500 ps) e de mem_clk (10 ns).
//   3. Confere os valores default apos o reset (F01 / CHK-01).
//   4. Aplica um reset em runtime e confere os defaults durante e apos o
//      reset, exercitando a API do rst_agent.
// Nesta versao os defaults sao lidos pela minisoc_probe_if; a partir de P2 a
// leitura passa a ser feita via SPI (T-RST-DEFAULT).
//-----------------------------------------------------------------------------
class minisoc_smoke_test extends minisoc_base_test;
  `uvm_component_utils(minisoc_smoke_test)

  virtual minisoc_probe_if probe;

  int unsigned n_checks;
  int unsigned n_fails;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    int unsigned runtime_cycles;

    phase.raise_objection(this, "T-SMOKE em execucao");
    probe = env_cfg.probe_vif;

    // 1. Reset inicial
    env.rst_agt.wait_reset_done();
    `uvm_info("SMOKE", "Reset inicial liberado", UVM_LOW)

    // 2. Clocks
    measure_clock("clk (referencia)", env_cfg.ref_clk);
    measure_clock("mem_clk",          env_cfg.mem_clk);

    // 3. Defaults apos o reset inicial
    repeat (20) @(posedge probe.clk);
    check_defaults("apos reset inicial");

    // 4. Reset em runtime, em instante aleatorio
    runtime_cycles = $urandom_range(10, 30);
    repeat ($urandom_range(5, 50)) @(posedge probe.clk);
    fork
      env.rst_agt.apply_reset(runtime_cycles);
      begin
        repeat (3) @(posedge probe.clk);
        check_value("durante reset em runtime", "rst_n", probe.rst_n, 0);
        check_defaults("durante reset em runtime");
      end
    join
    repeat (20) @(posedge probe.clk);
    check_defaults("apos reset em runtime");

    `uvm_info("SMOKE", $sformatf("Checagens: %0d executadas, %0d falhas", n_checks, n_fails), UVM_LOW)
    phase.drop_objection(this, "T-SMOKE concluido");
  endtask

  // Mede o intervalo entre duas bordas de subida e compara com o configurado.
  task measure_clock(string name, clk_cfg c);
    realtime t0, t1;
    real     meas_ps;

    @(posedge c.vif.clk);
    t0 = $realtime;
    @(posedge c.vif.clk);
    t1 = $realtime;
    meas_ps = (t1 - t0) / 1ps;

    n_checks++;
    if ((meas_ps > c.period_ps + 0.5) || (meas_ps < c.period_ps - 0.5)) begin
      n_fails++;
      `uvm_error("SMOKE_CLK", $sformatf("%s: periodo medido %0.1f ps, esperado %0d ps",
                                        name, meas_ps, c.period_ps))
    end
    else
      `uvm_info("SMOKE_CLK", $sformatf("%s: periodo medido %0.1f ps (%0.1f MHz) - OK",
                                       name, meas_ps, 1.0e6 / meas_ps), UVM_LOW)
  endtask

  // Valores esperados apos reset (Block Guide secao 6 + minisoc_spi.sv).
  function void check_defaults(string when);
    check_value(when, "KEY",               probe.cfg_key,             0);
    check_value(when, "IV",                probe.cfg_iv,              0);
    check_value(when, "COUNTER",           probe.cfg_counter,         0);
    check_value(when, "NUM_BLOCKS",        probe.cfg_num_blocks,      1);
    check_value(when, "MODE",              probe.cfg_mode,            0);
    check_value(when, "DECRYPT",           probe.cfg_decrypt,         0);
    check_value(when, "START",             probe.cfg_start,           0);
    check_value(when, "MEM_SEL_AES",       probe.cfg_mem_sel_aes,     0);
    check_value(when, "PLL_ENABLE",        probe.cfg_pll_enable,      0);
    check_value(when, "PLL_DIV_SEL",       probe.cfg_pll_div_sel,     2'b11);
    check_value(when, "PLL_LOCKED",        probe.pll_locked,          0);
    check_value(when, "sys_clk (parado)",  probe.sys_clk,             0);
    check_value(when, "sys_rst_n",         probe.sys_rst_n,           0);
    check_value(when, "AES_STATUS.BUSY",   probe.aes_busy_spi,        0);
    check_value(when, "AES_STATUS.DONE",   probe.aes_done_spi,        0);
    check_value(when, "AES_STATUS.ERROR",  probe.aes_error_spi,       0);
    check_value(when, "AES_STATUS.BLOCKS", probe.aes_blocks_done_spi, 0);
    check_value(when, "spi_miso",          probe.spi_miso,            0);
  endfunction

  // Comparacao com !== para que X/Z tambem sejam detectados.
  function void check_value(string when, string name, logic [127:0] got, logic [127:0] exp);
    n_checks++;
    if (got !== exp) begin
      n_fails++;
      `uvm_error("SMOKE_DEFAULT", $sformatf("[%s] %s = 0x%0h, esperado 0x%0h", when, name, got, exp))
    end
    else
      `uvm_info("SMOKE_DEFAULT", $sformatf("[%s] %s = 0x%0h OK", when, name, got), UVM_HIGH)
  endfunction

endclass : minisoc_smoke_test
