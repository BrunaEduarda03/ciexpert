//-----------------------------------------------------------------------------
// minisoc_env_pkg.sv - pacote do ambiente de topo
//-----------------------------------------------------------------------------
package minisoc_env_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import clk_pkg::*;
  import rst_pkg::*;

  `include "minisoc_env_cfg.sv"
  `include "minisoc_env.sv"
endpackage : minisoc_env_pkg
