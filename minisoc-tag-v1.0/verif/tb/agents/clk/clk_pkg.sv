//-----------------------------------------------------------------------------
// clk_pkg.sv - pacote do VIP de CLOCK
//-----------------------------------------------------------------------------
package clk_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "clk_cfg.sv"
  `include "clk_driver.sv"
  `include "clk_agent.sv"
endpackage : clk_pkg
