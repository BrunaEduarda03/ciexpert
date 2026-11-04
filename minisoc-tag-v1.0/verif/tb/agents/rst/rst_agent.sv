//-----------------------------------------------------------------------------
// rst_agent.sv
// Agente do VIP de RESET. Expoe apply_reset() e wait_reset_done() para que
// testes e virtual sequences controlem o reset (T-RST-RUN, F04).
//-----------------------------------------------------------------------------
class rst_agent extends uvm_agent;
  `uvm_component_utils(rst_agent)

  rst_cfg    cfg;
  rst_driver drv;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(rst_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("RST_NOCFG", {"rst_cfg nao encontrado para ", get_full_name()})
    if (cfg.vif == null)
      `uvm_fatal("RST_NOVIF", {"rst_cfg.vif nulo em ", get_full_name()})

    drv     = rst_driver::type_id::create("drv", this);
    drv.cfg = cfg;
  endfunction

  task apply_reset(int unsigned cycles);
    drv.drive_reset(cycles);
  endtask

  task wait_reset_done();
    drv.wait_reset_done();
  endtask

endclass : rst_agent
