//-----------------------------------------------------------------------------
// minisoc_probe_if.sv
// Interface de observacao (somente leitura) de sinais internos do DUT, ligada
// no top_tb por referencia hierarquica. Classes UVM dentro de pacotes nao podem
// usar hierarquia; por isso os sinais chegam aos testes por esta interface.
// Em P2/P4 ela sera dividida em pll_mon_if e aes_mon_if (VPLAN, secao 4.3).
//-----------------------------------------------------------------------------
interface minisoc_probe_if;
  logic         clk;               // referencia 2 GHz
  logic         rst_n;

  // Saidas do banco de registradores SPI
  logic         cfg_start;
  logic         cfg_decrypt;
  logic [2:0]   cfg_mode;
  logic [8:0]   cfg_num_blocks;
  logic [127:0] cfg_key;
  logic [127:0] cfg_iv;
  logic [63:0]  cfg_counter;
  logic         cfg_mem_sel_aes;
  logic         cfg_pll_enable;
  logic [1:0]   cfg_pll_div_sel;

  // PLL e reset interno do dominio AES
  logic         pll_locked;
  logic         sys_clk;
  logic         sys_rst_n;

  // Status do AES como visto pelo SPI (apos o CDC)
  logic         aes_busy_spi;
  logic         aes_done_spi;
  logic         aes_error_spi;
  logic [8:0]   aes_blocks_done_spi;

  // Saida de topo
  logic         spi_miso;
endinterface : minisoc_probe_if
