/**
 * MiniSoC AES SPI control and monitoring front-end.
 *
 * SPI electrical/protocol assumptions:
 *   - SCLK <= 25 MHz
 *   - CPOL = 0
 *   - CPHA = 0
 *   - MOSI sampled on rising edge
 *   - MISO changes on falling edge
 *   - MSB-first
 *
 * Frame format: 40 bits
 *
 *   39      38:33   32      31:0
 *  +-------+-------+-------+--------------------------------+
 *  | RWb   | ADDR  | RSV   | DATA[31:0]                    |
 *  +-------+-------+-------+--------------------------------+
 *
 *   RWb = 0 -> write
 *   RWb = 1 -> read request
 *
 * Reads use two frames:
 *   Frame A: READ + address
 *   Frame B: clocks the previously requested 32-bit value out on MISO.
 *
 * Register map:
 *   0x00 KEY0             cfg_key[127:96]
 *   0x01 KEY1             cfg_key[95:64]
 *   0x02 KEY2             cfg_key[63:32]
 *   0x03 KEY3             cfg_key[31:0]
 *   0x04 IV0              cfg_iv[127:96]
 *   0x05 IV1              cfg_iv[95:64]
 *   0x06 IV2              cfg_iv[63:32]
 *   0x07 IV3              cfg_iv[31:0]
 *   0x08 COUNTER_HI       cfg_counter[63:32]
 *   0x09 COUNTER_LO       cfg_counter[31:0]
 *   0x0A NUM_BLOCKS       [8:0], valid 1..256
 *   0x0B AES_CONTROL      [0] START (write-one pulse)
 *                         [1] DECRYPT
 *                         [4:2] MODE
 *   0x0C AES_STATUS       [0] BUSY
 *                         [1] DONE
 *                         [2] ERROR
 *                         [11:3] BLOCKS_DONE
 *   0x0D VERSION          0x0001_0100
 *   0x0E SYSTEM_CONTROL   [0] MEM_SEL_AES
 *                         [1] PLL_ENABLE
 *                         [3:2] PLL_DIV_SEL
 *   0x0F SYSTEM_STATUS    [0] PLL_LOCKED
 *   0x3F NOP
 *
 * PLL_DIV_SEL:
 *   00 -> /1 = 2 GHz
 *   01 -> /2 = 1 GHz
 *   10 -> /4 = 500 MHz
 *   11 -> /8 = 250 MHz
 *
 * Configuration writes are blocked while AES_BUSY is asserted. This prevents
 * software from changing memory ownership, PLL configuration, AES mode/key,
 * etc. while an AES operation is active.
 */
module minisoc_spi #(
  parameter int SPI_TRANSF_SIZE = 40
)(
  // SPI interface
  input  logic sclk,
  input  logic cs_n,
  input  logic mosi,
  output logic miso,

  // Always-on control clock/reset.
  // In the integrated MiniSoC this is the 2 GHz reference clock, NOT the
  // PLL-gated system clock. This allows SPI to enable/configure the PLL.
  input  logic sys_clk,
  input  logic rstn,

  // AES configuration
  output logic         cfg_start,
  output logic         cfg_decrypt,
  output logic [2:0]   cfg_mode,
  output logic [8:0]   cfg_num_blocks,
  output logic [127:0] cfg_key,
  output logic [127:0] cfg_iv,
  output logic [63:0]  cfg_counter,

  // AES status
  input  logic         aes_busy,
  input  logic         aes_done,
  input  logic         aes_error,
  input  logic [8:0]   aes_blocks_done,

  // Memory ownership
  output logic         cfg_mem_sel_aes,

  // PLL configuration/status
  output logic         cfg_pll_enable,
  output logic [1:0]   cfg_pll_div_sel,
  input  logic         pll_locked,

  output logic [7:0]   leds
);

  localparam int ADDR_W   = 6;
  localparam int BITCNT_W = $clog2(SPI_TRANSF_SIZE);

  localparam logic [ADDR_W-1:0] REG_KEY0           = 6'h00;
  localparam logic [ADDR_W-1:0] REG_KEY1           = 6'h01;
  localparam logic [ADDR_W-1:0] REG_KEY2           = 6'h02;
  localparam logic [ADDR_W-1:0] REG_KEY3           = 6'h03;
  localparam logic [ADDR_W-1:0] REG_IV0            = 6'h04;
  localparam logic [ADDR_W-1:0] REG_IV1            = 6'h05;
  localparam logic [ADDR_W-1:0] REG_IV2            = 6'h06;
  localparam logic [ADDR_W-1:0] REG_IV3            = 6'h07;
  localparam logic [ADDR_W-1:0] REG_COUNTER_HI     = 6'h08;
  localparam logic [ADDR_W-1:0] REG_COUNTER_LO     = 6'h09;
  localparam logic [ADDR_W-1:0] REG_NUM_BLOCKS     = 6'h0A;
  localparam logic [ADDR_W-1:0] REG_AES_CONTROL    = 6'h0B;
  localparam logic [ADDR_W-1:0] REG_AES_STATUS     = 6'h0C;
  localparam logic [ADDR_W-1:0] REG_VERSION        = 6'h0D;
  localparam logic [ADDR_W-1:0] REG_SYSTEM_CONTROL = 6'h0E;
  localparam logic [ADDR_W-1:0] REG_SYSTEM_STATUS  = 6'h0F;
  localparam logic [ADDR_W-1:0] REG_NOP            = 6'h3F;

  localparam logic [31:0] VERSION_VALUE = 32'h0001_0100;

  // --------------------------------------------------------------------------
  // SCLK domain: receive one complete frame.
  // --------------------------------------------------------------------------
  logic [SPI_TRANSF_SIZE-1:0] rx_shift_sclk;
  logic [SPI_TRANSF_SIZE-1:0] rx_frame_sclk;
  logic [BITCNT_W-1:0]        rx_bitcnt_sclk;
  logic                        frame_toggle_sclk;

  always @(posedge sclk or posedge cs_n or negedge rstn) begin
    if (!rstn) begin
      rx_shift_sclk     <= '0;
      rx_frame_sclk     <= '0;
      rx_bitcnt_sclk    <= '0;
      frame_toggle_sclk <= 1'b0;
    end
    else if (cs_n) begin
      rx_shift_sclk  <= '0;
      rx_bitcnt_sclk <= '0;
    end
    else begin
      rx_shift_sclk <= {rx_shift_sclk[SPI_TRANSF_SIZE-2:0], mosi};

      if (rx_bitcnt_sclk == SPI_TRANSF_SIZE-1) begin
        rx_frame_sclk     <= {rx_shift_sclk[SPI_TRANSF_SIZE-2:0], mosi};
        rx_bitcnt_sclk    <= '0;
        frame_toggle_sclk <= ~frame_toggle_sclk;
      end
      else begin
        rx_bitcnt_sclk <= rx_bitcnt_sclk + 1'b1;
      end
    end
  end

  // --------------------------------------------------------------------------
  // SCLK -> always-on SYS_CLK event CDC.
  // --------------------------------------------------------------------------
  (* ASYNC_REG = "TRUE" *) logic frame_toggle_meta;
  (* ASYNC_REG = "TRUE" *) logic frame_toggle_sync;
  logic frame_toggle_sync_d;
  logic frame_event_sys;

  logic [SPI_TRANSF_SIZE-1:0] cmd_word_sync;
  logic                       cmd_valid_sys;

  assign frame_event_sys = frame_toggle_sync ^ frame_toggle_sync_d;

  always_ff @(posedge sys_clk) begin
    if (!rstn) begin
      frame_toggle_meta   <= 1'b0;
      frame_toggle_sync   <= 1'b0;
      frame_toggle_sync_d <= 1'b0;
      cmd_word_sync       <= '0;
      cmd_valid_sys       <= 1'b0;
    end
    else begin
      frame_toggle_meta   <= frame_toggle_sclk;
      frame_toggle_sync   <= frame_toggle_meta;
      frame_toggle_sync_d <= frame_toggle_sync;
      cmd_valid_sys       <= frame_event_sys;

      // The complete SCLK-domain frame remains stable until the next frame.
      if (frame_event_sys)
        cmd_word_sync <= rx_frame_sclk;
    end
  end

  logic              cmd_rwb;
  logic [ADDR_W-1:0] cmd_addr;
  logic [31:0]       cmd_data;

  assign cmd_rwb  = cmd_word_sync[39];
  assign cmd_addr = cmd_word_sync[38:33];
  assign cmd_data = cmd_word_sync[31:0];

  // --------------------------------------------------------------------------
  // Register read mux.
  // --------------------------------------------------------------------------
  logic [31:0] read_data_mux;
  logic [31:0] read_data_sys;

  always_comb begin
    unique case (cmd_addr)
      REG_KEY0:       read_data_mux = cfg_key[127:96];
      REG_KEY1:       read_data_mux = cfg_key[95:64];
      REG_KEY2:       read_data_mux = cfg_key[63:32];
      REG_KEY3:       read_data_mux = cfg_key[31:0];

      REG_IV0:        read_data_mux = cfg_iv[127:96];
      REG_IV1:        read_data_mux = cfg_iv[95:64];
      REG_IV2:        read_data_mux = cfg_iv[63:32];
      REG_IV3:        read_data_mux = cfg_iv[31:0];

      REG_COUNTER_HI: read_data_mux = cfg_counter[63:32];
      REG_COUNTER_LO: read_data_mux = cfg_counter[31:0];
      REG_NUM_BLOCKS: read_data_mux = {23'b0, cfg_num_blocks};

      REG_AES_CONTROL:
        read_data_mux = {27'b0, cfg_mode, cfg_decrypt, 1'b0};

      REG_AES_STATUS:
        read_data_mux = {20'b0, aes_blocks_done, aes_error, aes_done, aes_busy};

      REG_VERSION:
        read_data_mux = VERSION_VALUE;

      REG_SYSTEM_CONTROL:
        read_data_mux = {28'b0, cfg_pll_div_sel, cfg_pll_enable, cfg_mem_sel_aes};

      REG_SYSTEM_STATUS:
        read_data_mux = {31'b0, pll_locked};

      default:
        read_data_mux = 32'b0;
    endcase
  end

  // --------------------------------------------------------------------------
  // Register bank.
  // --------------------------------------------------------------------------
  always_ff @(posedge sys_clk) begin
    if (!rstn) begin
      cfg_start       <= 1'b0;
      cfg_decrypt     <= 1'b0;
      cfg_mode        <= 3'b000;
      cfg_num_blocks  <= 9'd1;
      cfg_key         <= '0;
      cfg_iv          <= '0;
      cfg_counter     <= '0;

      cfg_mem_sel_aes <= 1'b0;
      cfg_pll_enable  <= 1'b0;
      // Safe default: when software enables the PLL without reprogramming the
      // divider, the system starts at the slowest supported clock: 250 MHz.
      cfg_pll_div_sel <= 2'b11;

      read_data_sys   <= 32'b0;
    end
    else begin
      cfg_start <= 1'b0;

      if (cmd_valid_sys) begin
        if (cmd_rwb) begin
          read_data_sys <= read_data_mux;
        end
        else if (!aes_busy) begin
          unique case (cmd_addr)
            REG_KEY0:       cfg_key[127:96]    <= cmd_data;
            REG_KEY1:       cfg_key[95:64]     <= cmd_data;
            REG_KEY2:       cfg_key[63:32]     <= cmd_data;
            REG_KEY3:       cfg_key[31:0]      <= cmd_data;

            REG_IV0:        cfg_iv[127:96]     <= cmd_data;
            REG_IV1:        cfg_iv[95:64]      <= cmd_data;
            REG_IV2:        cfg_iv[63:32]      <= cmd_data;
            REG_IV3:        cfg_iv[31:0]       <= cmd_data;

            REG_COUNTER_HI: cfg_counter[63:32] <= cmd_data;
            REG_COUNTER_LO: cfg_counter[31:0]  <= cmd_data;

            REG_NUM_BLOCKS:
              cfg_num_blocks <= cmd_data[8:0];

            REG_AES_CONTROL: begin
              cfg_decrypt <= cmd_data[1];
              cfg_mode    <= cmd_data[4:2];

              if (cmd_data[0])
                cfg_start <= 1'b1;
            end

            REG_SYSTEM_CONTROL: begin
              cfg_mem_sel_aes <= cmd_data[0];
              cfg_pll_enable  <= cmd_data[1];
              cfg_pll_div_sel <= cmd_data[3:2];
            end

            default: begin
              // Read-only and undefined locations ignore writes.
            end
          endcase
        end
      end
    end
  end

  // --------------------------------------------------------------------------
  // MISO transmit path.
  // --------------------------------------------------------------------------
  logic [BITCNT_W-1:0]        tx_bitcnt_sclk;
  logic [SPI_TRANSF_SIZE-1:0] tx_response_sclk;

  assign tx_response_sclk = {8'h00, read_data_sys};

  always @(negedge sclk or posedge cs_n or negedge rstn) begin
    if (!rstn)
      tx_bitcnt_sclk <= '0;
    else if (cs_n)
      tx_bitcnt_sclk <= '0;
    else if (tx_bitcnt_sclk == SPI_TRANSF_SIZE-1)
      tx_bitcnt_sclk <= '0;
    else
      tx_bitcnt_sclk <= tx_bitcnt_sclk + 1'b1;
  end

  always_comb begin
    if (cs_n)
      miso = 1'b0;
    else
      miso = tx_response_sclk[SPI_TRANSF_SIZE-1-tx_bitcnt_sclk];
  end

  always_comb begin
    leds[0]   = aes_busy;
    leds[1]   = aes_done;
    leds[2]   = aes_error;
    leds[3]   = pll_locked;
    leds[4]   = cfg_mem_sel_aes;
    leds[7:5] = aes_blocks_done[2:0];
  end

`ifndef SYNTHESIS
  initial begin
    if (SPI_TRANSF_SIZE != 40)
      $fatal(1, "minisoc_spi requires SPI_TRANSF_SIZE=40");
  end
`endif

endmodule
