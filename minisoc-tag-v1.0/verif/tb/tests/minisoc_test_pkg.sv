//-----------------------------------------------------------------------------
// minisoc_test_pkg.sv - pacote dos testes
//-----------------------------------------------------------------------------
package minisoc_test_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import clk_pkg::*;
  import rst_pkg::*;
  import minisoc_env_pkg::*;

  `include "minisoc_base_test.sv"
  `include "minisoc_smoke_test.sv"
endpackage : minisoc_test_pkg
