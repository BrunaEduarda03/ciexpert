//-----------------------------------------------------------------------------
// rst_if.sv
// Interface do VIP de RESET. rst_n e ativo em nivel baixo e comeca em 0 para
// que o DUT ja esteja em reset na primeira borda de clock.
//-----------------------------------------------------------------------------
interface rst_if (input logic clk);
  logic rst_n = 1'b0;
endinterface : rst_if
