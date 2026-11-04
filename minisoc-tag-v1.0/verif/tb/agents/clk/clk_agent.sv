//-----------------------------------------------------------------------------
// clk_agent.sv
// Agente do VIP de CLOCK: obtem clk_cfg do config_db, valida e cria o driver.
//-----------------------------------------------------------------------------
class clk_agent extends uvm_agent;
  `uvm_component_utils(clk_agent)

  clk_cfg    cfg;
  clk_driver drv;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    string msg;
    super.build_phase(phase);

    if (!uvm_config_db#(clk_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("CLK_NOCFG", {"clk_cfg nao encontrado para ", get_full_name()})
    if (!cfg.is_valid(msg))
      `uvm_fatal("CLK_BADCFG", msg)
    if (cfg.vif == null)
      `uvm_fatal("CLK_NOVIF", {"clk_cfg.vif nulo em ", get_full_name()})

    drv     = clk_driver::type_id::create("drv", this);
    drv.cfg = cfg;
  endfunction

endclass : clk_agent
