//-----------------------------------------------------------------------------
// rst_driver.sv
// Dirige rst_n. Assert imediato (o DUT tem reset assincrono no PLL e no top);
// release sincronizado na borda de descida de clk para evitar corrida com a
// borda de subida. Nao usa sequencer: o reset e controlado por metodos.
//-----------------------------------------------------------------------------
class rst_driver extends uvm_driver #(uvm_sequence_item);
  `uvm_component_utils(rst_driver)

  rst_cfg        cfg;   // atribuido pelo rst_agent
  virtual rst_if vif;

  bit          in_reset    = 1'b1;   // rst_n comeca em 0 na interface
  int unsigned reset_count = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg == null)
      `uvm_fatal("RST_NOCFG", "rst_cfg nao atribuido ao driver")
    vif = cfg.vif;
    if (vif == null)
      `uvm_fatal("RST_NOVIF", "rst_cfg.vif e nulo")
  endfunction

  // Reset inicial (power-on).
  task run_phase(uvm_phase phase);
    drive_reset(cfg.assert_cycles);
  endtask

  // Aplica um reset de 'cycles' ciclos de clk. Pode ser chamado em runtime.
  task drive_reset(int unsigned cycles);
    in_reset  = 1'b1;
    vif.rst_n = 1'b0;
    reset_count++;
    `uvm_info(get_type_name(),
              $sformatf("rst_n=0 (reset #%0d) por %0d ciclos de clk", reset_count, cycles),
              UVM_LOW)

    repeat (cycles) @(posedge vif.clk);
    @(negedge vif.clk);

    vif.rst_n = 1'b1;
    in_reset  = 1'b0;
    `uvm_info(get_type_name(), $sformatf("rst_n=1 (reset #%0d liberado)", reset_count), UVM_LOW)
  endtask

  task wait_reset_done();
    wait (in_reset == 1'b0);
  endtask

endclass : rst_driver
