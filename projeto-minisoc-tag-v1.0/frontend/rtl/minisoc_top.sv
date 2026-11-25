/**
 * MiniSoC AES - system integration top.
 *
 * Top-level interface groups:
 *
 *   1) Reference clock
 *      clk        : 2 GHz PLL reference / always-on control clock
 *
 *   2) Reset
 *      rst_n      : active-low global reset
 *
 *   3) SPI
 *      spi_sclk   : <= 25 MHz
 *      spi_cs_n
 *      spi_mosi
 *      spi_miso
 *
 *   4) MEMORY DATA
 *      mem_clk
 *      mem_i_data
 *      mem_i_wr_en : 1 = write, 0 = read
 *      mem_i_addr
 *      mem_o_data
 *
 * Internal organization:
 *
 *                   +----------------+
 * SPI ------------->| control/status |
 *                   +---+--------+---+
 *                       |        |
 *                    PLL cfg   memory owner
 *                       |        |
 * 2 GHz ref -> PLL mock |        v
 *              |        |   +----------+
 *              +-> sys_clk   |  MEMORY  |<---- MEMORY DATA
 *                       |     | 1024x32  |
 *                       v     +----+-----+
 *                  +---------+     ^
 *                  | AES     |-----+
 *                  | engine  |
 *                  +---------+
 *
 * Bootstrap rule:
 * The SPI register bank is clocked directly from the always-on 2 GHz reference
 * clock. It therefore remains operational while the PLL-generated system clock
 * is stopped, allowing software to configure/enable the PLL and poll LOCKED.
 *
 * Memory clocking:
 * The current training/mock memory is a single-clock RAM. Its physical clock is
 * selected together with ownership:
 *
 *   MEM_SEL_AES = 0 -> mem_clk drives the RAM and MEMORY DATA owns the port.
 *   MEM_SEL_AES = 1 -> PLL-generated sys_clk drives the RAM and AES owns it.
 *
 * MEM_SEL_AES must only be changed while the AES engine is idle and while the
 * external memory interface is not performing a transaction. The SPI front-end
 * blocks configuration writes while AES_BUSY=1.
 */
module minisoc_top (
  // --------------------------------------------------------------------------
  // 1) Reference clock interface
  // --------------------------------------------------------------------------
  input  logic        clk,          // 2 GHz reference clock

  // --------------------------------------------------------------------------
  // 2) Reset interface
  // --------------------------------------------------------------------------
  input  logic        rst_n,

  // --------------------------------------------------------------------------
  // 3) SPI interface (SCLK <= 25 MHz)
  // --------------------------------------------------------------------------
  input  logic        spi_sclk,
  input  logic        spi_cs_n,
  input  logic        spi_mosi,
  output logic        spi_miso,

  // --------------------------------------------------------------------------
  // 4) MEMORY DATA interface
  // --------------------------------------------------------------------------
  input  logic        mem_clk,
  input  logic [31:0] mem_i_data,
  input  logic        mem_i_wr_en,   // 1 = write, 0 = read
  input  logic [9:0]  mem_i_addr,
  output logic [31:0] mem_o_data
);

  // --------------------------------------------------------------------------
  // SPI configuration signals: always-on 2 GHz control domain.
  // --------------------------------------------------------------------------
  logic         spi_cfg_start;
  logic         spi_cfg_decrypt;
  logic [2:0]   spi_cfg_mode;
  logic [8:0]   spi_cfg_num_blocks;
  logic [127:0] spi_cfg_key;
  logic [127:0] spi_cfg_iv;
  logic [63:0]  spi_cfg_counter;

  logic         spi_cfg_mem_sel_aes;
  logic         spi_cfg_pll_enable;
  logic [1:0]   spi_cfg_pll_div_sel;

  logic [7:0]   spi_leds;

  // --------------------------------------------------------------------------
  // PLL-generated system clock.
  // --------------------------------------------------------------------------
  logic sys_clk;
  logic pll_locked;

  minisoc_pll_mock u_pll (
    .i_clk_2ghz (clk),
    .rst_n      (rst_n),
    .i_enable   (spi_cfg_pll_enable),
    .i_div_sel  (spi_cfg_pll_div_sel),
    .o_clk      (sys_clk),
    .o_locked   (pll_locked)
  );

  // --------------------------------------------------------------------------
  // Internal system reset release.
  //
  // The AES logic uses synchronous reset internally. Since sys_clk is stopped
  // until PLL lock, keep the internal reset asserted for three generated-clock
  // cycles after lock before allowing the AES engine to operate.
  // --------------------------------------------------------------------------
  logic [2:0] sys_reset_pipe;
  logic       sys_rst_n;
  logic       sys_ready;

  always_ff @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n)
      sys_reset_pipe <= 3'b000;
    else if (!pll_locked)
      sys_reset_pipe <= 3'b000;
    else
      sys_reset_pipe <= {sys_reset_pipe[1:0], 1'b1};
  end

  assign sys_rst_n = sys_reset_pipe[2];
  assign sys_ready = sys_reset_pipe[2];

  // --------------------------------------------------------------------------
  // START event CDC: 2 GHz SPI/control domain -> generated SYS_CLK domain.
  //
  // cfg_start is only a one-reference-clock pulse. A toggle transports the
  // event so it cannot be missed by slower /2, /4 or /8 system clocks.
  // --------------------------------------------------------------------------
  logic start_toggle_ref;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      start_toggle_ref <= 1'b0;
    else if (spi_cfg_start && pll_locked && spi_cfg_mem_sel_aes)
      start_toggle_ref <= ~start_toggle_ref;
  end

  (* ASYNC_REG = "TRUE" *) logic start_toggle_meta_sys;
  (* ASYNC_REG = "TRUE" *) logic start_toggle_sync_sys;
  logic start_toggle_sync_d_sys;
  logic aes_cfg_start_sys;

  always_ff @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
      start_toggle_meta_sys   <= 1'b0;
      start_toggle_sync_sys   <= 1'b0;
      start_toggle_sync_d_sys <= 1'b0;
    end
    else if (!sys_rst_n) begin
      start_toggle_meta_sys   <= start_toggle_ref;
      start_toggle_sync_sys   <= start_toggle_ref;
      start_toggle_sync_d_sys <= start_toggle_ref;
    end
    else begin
      start_toggle_meta_sys   <= start_toggle_ref;
      start_toggle_sync_sys   <= start_toggle_meta_sys;
      start_toggle_sync_d_sys <= start_toggle_sync_sys;
    end
  end

  assign aes_cfg_start_sys =
      sys_rst_n && (start_toggle_sync_sys ^ start_toggle_sync_d_sys);

  // --------------------------------------------------------------------------
  // AES engine status: generated SYS_CLK domain.
  // --------------------------------------------------------------------------
  logic       aes_busy_sys;
  logic       aes_done_sys;
  logic       aes_error_sys;
  logic [8:0] aes_blocks_done_sys;

  logic       aes_mem_en;
  logic       aes_mem_wr_en;
  logic [9:0] aes_mem_addr;
  logic [31:0] aes_mem_wdata;
  logic [31:0] aes_mem_rdata;

  minisoc_aes_top u_aes (
    .clk            (sys_clk),
    .rst_n          (sys_rst_n),

    .cfg_start      (aes_cfg_start_sys),
    .cfg_decrypt    (spi_cfg_decrypt),
    .cfg_mode       (spi_cfg_mode),
    .cfg_num_blocks (spi_cfg_num_blocks),
    .cfg_key        (spi_cfg_key),
    .cfg_iv         (spi_cfg_iv),
    .cfg_counter    (spi_cfg_counter),

    .busy           (aes_busy_sys),
    .done           (aes_done_sys),
    .error          (aes_error_sys),
    .blocks_done    (aes_blocks_done_sys),

    .mem_en         (aes_mem_en),
    .mem_wr_en      (aes_mem_wr_en),
    .mem_addr       (aes_mem_addr),
    .mem_wdata      (aes_mem_wdata),
    .mem_rdata      (aes_mem_rdata)
  );

  // --------------------------------------------------------------------------
  // AES status CDC: generated SYS_CLK -> always-on 2 GHz SPI domain.
  //
  // BUSY/DONE/ERROR are synchronized as individual status bits.
  // BLOCKS_DONE is a slowly changing monitoring bus and is sampled through two
  // register stages. It is not used for functional control.
  // --------------------------------------------------------------------------
  (* ASYNC_REG = "TRUE" *) logic aes_busy_meta_ref;
  (* ASYNC_REG = "TRUE" *) logic aes_busy_sync_ref;
  (* ASYNC_REG = "TRUE" *) logic aes_done_meta_ref;
  (* ASYNC_REG = "TRUE" *) logic aes_done_sync_ref;
  (* ASYNC_REG = "TRUE" *) logic aes_error_meta_ref;
  (* ASYNC_REG = "TRUE" *) logic aes_error_sync_ref;

  logic [8:0] aes_blocks_meta_ref;
  logic [8:0] aes_blocks_sync_ref;

  (* ASYNC_REG = "TRUE" *) logic sys_ready_meta_ref;
  (* ASYNC_REG = "TRUE" *) logic sys_ready_sync_ref;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      aes_busy_meta_ref   <= 1'b0;
      aes_busy_sync_ref   <= 1'b0;
      aes_done_meta_ref   <= 1'b0;
      aes_done_sync_ref   <= 1'b0;
      aes_error_meta_ref  <= 1'b0;
      aes_error_sync_ref  <= 1'b0;
      aes_blocks_meta_ref <= '0;
      aes_blocks_sync_ref <= '0;
      sys_ready_meta_ref  <= 1'b0;
      sys_ready_sync_ref  <= 1'b0;
    end
    else begin
      aes_busy_meta_ref   <= aes_busy_sys;
      aes_busy_sync_ref   <= aes_busy_meta_ref;
      aes_done_meta_ref   <= aes_done_sys;
      aes_done_sync_ref   <= aes_done_meta_ref;
      aes_error_meta_ref  <= aes_error_sys;
      aes_error_sync_ref  <= aes_error_meta_ref;
      aes_blocks_meta_ref <= aes_blocks_done_sys;
      aes_blocks_sync_ref <= aes_blocks_meta_ref;
      sys_ready_meta_ref  <= sys_ready;
      sys_ready_sync_ref  <= sys_ready_meta_ref;
    end
  end

  wire aes_busy_spi =
      sys_ready_sync_ref ? aes_busy_sync_ref : 1'b0;
  wire aes_done_spi =
      sys_ready_sync_ref ? aes_done_sync_ref : 1'b0;
  wire aes_error_spi =
      sys_ready_sync_ref ? aes_error_sync_ref : 1'b0;
  wire [8:0] aes_blocks_done_spi =
      sys_ready_sync_ref ? aes_blocks_sync_ref : 9'd0;

  // --------------------------------------------------------------------------
  // SPI control/status block.
  //
  // IMPORTANT: sys_clk is intentionally the always-on 2 GHz reference clock.
  // --------------------------------------------------------------------------
  minisoc_spi u_spi (
    .sclk             (spi_sclk),
    .cs_n             (spi_cs_n),
    .mosi             (spi_mosi),
    .miso             (spi_miso),

    .sys_clk          (clk),
    .rstn             (rst_n),

    .cfg_start        (spi_cfg_start),
    .cfg_decrypt      (spi_cfg_decrypt),
    .cfg_mode         (spi_cfg_mode),
    .cfg_num_blocks   (spi_cfg_num_blocks),
    .cfg_key          (spi_cfg_key),
    .cfg_iv           (spi_cfg_iv),
    .cfg_counter      (spi_cfg_counter),

    .aes_busy         (aes_busy_spi),
    .aes_done         (aes_done_spi),
    .aes_error        (aes_error_spi),
    .aes_blocks_done  (aes_blocks_done_spi),

    .cfg_mem_sel_aes  (spi_cfg_mem_sel_aes),

    .cfg_pll_enable   (spi_cfg_pll_enable),
    .cfg_pll_div_sel  (spi_cfg_pll_div_sel),
    .pll_locked       (pll_locked),

    .leds             (spi_leds)
  );

  // --------------------------------------------------------------------------
  // Shared physical memory.
  //
  // The current memory wrapper has one physical clock input. Since ownership
  // is mutually exclusive, the selected owner also selects the RAM clock.
  //
  // This is appropriate for the current MiniSoC training/mock architecture.
  // For an implementation requiring arbitrary asynchronous ownership switching
  // or simultaneous access, replace this with a true dual-port dual-clock RAM.
  // --------------------------------------------------------------------------
  logic memory_clk;

  assign memory_clk = spi_cfg_mem_sel_aes ? sys_clk : mem_clk;

  minisoc_memory u_memory (
    .clk          (memory_clk),

    .i_sel_aes    (spi_cfg_mem_sel_aes),

    .i_user_data  (mem_i_data),
    .i_user_wr_en (mem_i_wr_en),
    .i_user_addr  (mem_i_addr),
    .o_user_data  (mem_o_data),

    .i_aes_data   (aes_mem_wdata),
    .i_aes_wr_en  (aes_mem_wr_en),
    .i_aes_addr   (aes_mem_addr),
    .o_aes_data   (aes_mem_rdata)
  );

`ifndef SYNTHESIS
  // System-level protocol checks useful during the training project.
  always @(posedge clk) begin
    if (rst_n) begin
      if (spi_cfg_start && !pll_locked)
        $warning("AES START ignored: PLL is not locked");

      if (spi_cfg_start && !spi_cfg_mem_sel_aes)
        $warning("AES START ignored: memory is not owned by AES");
    end
  end
`endif

endmodule
