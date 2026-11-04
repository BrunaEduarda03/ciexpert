//-----------------------------------------------------------------------------
// minisoc_env.sv
// Ambiente de topo. Nesta versao (P0/P1) contem os agentes de clock e reset.
// spi_agent, mem_agent, monitores passivos, scoreboards e coverage entram nas
// fases P2-P5 (VPLAN, secao 4.2).
//-----------------------------------------------------------------------------
class minisoc_env extends uvm_env;
  `uvm_component_utils(minisoc_env)

  minisoc_env_cfg cfg;

  clk_agent ref_clk_agt;   // clk de 2 GHz
  clk_agent mem_clk_agt;   // mem_clk
  rst_agent rst_agt;       // rst_n

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(minisoc_env_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("ENV_NOCFG", "minisoc_env_cfg nao encontrado")

    uvm_config_db#(clk_cfg)::set(this, "ref_clk_agt", "cfg", cfg.ref_clk);
    uvm_config_db#(clk_cfg)::set(this, "mem_clk_agt", "cfg", cfg.mem_clk);
    uvm_config_db#(rst_cfg)::set(this, "rst_agt",     "cfg", cfg.rst);

    ref_clk_agt = clk_agent::type_id::create("ref_clk_agt", this);
    mem_clk_agt = clk_agent::type_id::create("mem_clk_agt", this);
    rst_agt     = rst_agent::type_id::create("rst_agt",     this);
  endfunction

endclass : minisoc_env
