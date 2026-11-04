//-----------------------------------------------------------------------------
// top_tb.sv
// Top do testbench: instancia DUT e interfaces, publica as virtual interfaces
// no uvm_config_db e chama run_test(). O teste e escolhido por +UVM_TESTNAME.
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

module top_tb;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import minisoc_test_pkg::*;

  //---------------------------------------------------------------------------
  // Interfaces dos VIPs
  //---------------------------------------------------------------------------
  clk_if ref_clk_if ();                       // clk 2 GHz
  clk_if mem_clk_if ();                       // mem_clk
  rst_if rst_if_i   (.clk(ref_clk_if.clk));   // rst_n

  //---------------------------------------------------------------------------
  // SPI e MEMORY DATA: mantidos em repouso ate os agentes de P2/P3.
  //---------------------------------------------------------------------------
  logic        spi_sclk    = 1'b0;
  logic        spi_cs_n    = 1'b1;
  logic        spi_mosi    = 1'b0;
  logic        spi_miso;

  logic [31:0] mem_i_data  = '0;
  logic        mem_i_wr_en = 1'b0;
  logic [9:0]  mem_i_addr  = '0;
  logic [31:0] mem_o_data;

  //---------------------------------------------------------------------------
  // DUT
  //---------------------------------------------------------------------------
  minisoc_top dut (
    .clk         (ref_clk_if.clk),
    .rst_n       (rst_if_i.rst_n),

    .spi_sclk    (spi_sclk),
    .spi_cs_n    (spi_cs_n),
    .spi_mosi    (spi_mosi),
    .spi_miso    (spi_miso),

    .mem_clk     (mem_clk_if.clk),
    .mem_i_data  (mem_i_data),
    .mem_i_wr_en (mem_i_wr_en),
    .mem_i_addr  (mem_i_addr),
    .mem_o_data  (mem_o_data)
  );

  //---------------------------------------------------------------------------
  // Probe de sinais internos (somente leitura)
  //---------------------------------------------------------------------------
  minisoc_probe_if probe_if ();

  assign probe_if.clk                 = ref_clk_if.clk;
  assign probe_if.rst_n               = rst_if_i.rst_n;
  assign probe_if.cfg_start           = dut.spi_cfg_start;
  assign probe_if.cfg_decrypt         = dut.spi_cfg_decrypt;
  assign probe_if.cfg_mode            = dut.spi_cfg_mode;
  assign probe_if.cfg_num_blocks      = dut.spi_cfg_num_blocks;
  assign probe_if.cfg_key             = dut.spi_cfg_key;
  assign probe_if.cfg_iv              = dut.spi_cfg_iv;
  assign probe_if.cfg_counter         = dut.spi_cfg_counter;
  assign probe_if.cfg_mem_sel_aes     = dut.spi_cfg_mem_sel_aes;
  assign probe_if.cfg_pll_enable      = dut.spi_cfg_pll_enable;
  assign probe_if.cfg_pll_div_sel     = dut.spi_cfg_pll_div_sel;
  assign probe_if.pll_locked          = dut.pll_locked;
  assign probe_if.sys_clk             = dut.sys_clk;
  assign probe_if.sys_rst_n           = dut.sys_rst_n;
  assign probe_if.aes_busy_spi        = dut.aes_busy_spi;
  assign probe_if.aes_done_spi        = dut.aes_done_spi;
  assign probe_if.aes_error_spi       = dut.aes_error_spi;
  assign probe_if.aes_blocks_done_spi = dut.aes_blocks_done_spi;
  assign probe_if.spi_miso            = spi_miso;

  //---------------------------------------------------------------------------
  // UVM
  //---------------------------------------------------------------------------
  initial begin
    uvm_config_db#(virtual clk_if)::set(null, "uvm_test_top", "ref_clk_vif", ref_clk_if);
    uvm_config_db#(virtual clk_if)::set(null, "uvm_test_top", "mem_clk_vif", mem_clk_if);
    uvm_config_db#(virtual rst_if)::set(null, "uvm_test_top", "rst_vif",     rst_if_i);
    uvm_config_db#(virtual minisoc_probe_if)::set(null, "uvm_test_top", "probe_vif", probe_if);
    run_test();
  end

  //---------------------------------------------------------------------------
  // Waves em VCD (+VCD) ou FSDB/Verdi (+FSDB). Selecionado via WAVES=vcd|fsdb
  // no Makefile, que repassa o plusarg correspondente para o simv.
  //---------------------------------------------------------------------------
  initial begin
    if ($test$plusargs("VCD")) begin
      $dumpfile("waves.vcd");
      $dumpvars(0, top_tb);
    end
    if ($test$plusargs("FSDB")) begin
      $fsdbDumpfile("waves.fsdb");
      $fsdbDumpvars(0, top_tb, "+all");
    end
  end

endmodule : top_tb
