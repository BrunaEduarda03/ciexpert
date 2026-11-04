//-----------------------------------------------------------------------------
// clk_driver.sv
// Gera o clock na clk_if conforme clk_cfg. Nao usa sequencer: um clock nao
// tem transacoes, apenas parametros (periodo, duty, atraso inicial).
//-----------------------------------------------------------------------------
class clk_driver extends uvm_driver #(uvm_sequence_item);
  `uvm_component_utils(clk_driver)

  clk_cfg        cfg;   // atribuido pelo clk_agent
  virtual clk_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg == null)
      `uvm_fatal("CLK_NOCFG", "clk_cfg nao atribuido ao driver")
    vif = cfg.vif;
    if (vif == null)
      `uvm_fatal("CLK_NOVIF", "clk_cfg.vif e nulo")
  endfunction

  task run_phase(uvm_phase phase);
    vif.clk = 1'b0;

    if (!cfg.enable) begin
      `uvm_info(get_type_name(), "Clock desabilitado (enable=0): mantido em 0", UVM_LOW)
      return;
    end

    `uvm_info(get_type_name(),
              $sformatf("Gerando clock: periodo=%0d ps (%0.1f MHz), duty=%0d%%, atraso=%0d ps",
                        cfg.period_ps, cfg.freq_mhz(), cfg.duty_pct, cfg.start_delay_ps),
              UVM_LOW)

    if (cfg.start_delay_ps > 0)
      #(cfg.start_delay_ps * 1ps);

    // Fase baixa primeiro: a primeira borda de subida ocorre apos low_ps.
    forever begin
      #(cfg.low_ps() * 1ps);
      vif.clk = 1'b1;
      #(cfg.high_ps() * 1ps);
      vif.clk = 1'b0;
    end
  endtask

endclass : clk_driver
