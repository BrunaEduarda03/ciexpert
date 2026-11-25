//-----------------------------------------------------------------------------
// clk_if.sv
// Interface do VIP de CLOCK. Uma instancia por clock gerado pelo testbench
// (ex.: clock de referencia de 2 GHz e mem_clk da interface MEMORY DATA).
//-----------------------------------------------------------------------------
interface clk_if;
  logic clk = 1'b0;
endinterface : clk_if
