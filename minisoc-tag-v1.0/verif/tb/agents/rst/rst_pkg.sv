//-----------------------------------------------------------------------------
// rst_pkg.sv - pacote do VIP de RESET
//-----------------------------------------------------------------------------
package rst_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "rst_cfg.sv"
  `include "rst_driver.sv"
  `include "rst_agent.sv"
endpackage : rst_pkg
