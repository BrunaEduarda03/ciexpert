
`timescale 1ps/1ps

module minisoc_top_tb;

  // --------------------------------------------------------------------------
  // Clock constants
  // --------------------------------------------------------------------------
  // Reference PLL clock: 2 GHz -> 500 ps period.
  localparam time REF_HALF_PERIOD = 250ps;

  // SPI SCLK: 20 MHz -> 50 ns period.
  // This deliberately stays below the MiniSoC requirement of SCLK <= 25 MHz.
  localparam time SPI_HALF_PERIOD = 25ns;

  // External MEMORY DATA clock: 100 MHz -> 10 ns period.
  localparam time MEM_HALF_PERIOD = 5ns;

  // SPI registers
  localparam logic [5:0] REG_KEY0           = 6'h00;
  localparam logic [5:0] REG_KEY1           = 6'h01;
  localparam logic [5:0] REG_KEY2           = 6'h02;
  localparam logic [5:0] REG_KEY3           = 6'h03;
  localparam logic [5:0] REG_IV0            = 6'h04;
  localparam logic [5:0] REG_IV1            = 6'h05;
  localparam logic [5:0] REG_IV2            = 6'h06;
  localparam logic [5:0] REG_IV3            = 6'h07;
  localparam logic [5:0] REG_COUNTER_HI     = 6'h08;
  localparam logic [5:0] REG_COUNTER_LO     = 6'h09;
  localparam logic [5:0] REG_NUM_BLOCKS     = 6'h0A;
  localparam logic [5:0] REG_AES_CONTROL    = 6'h0B;
  localparam logic [5:0] REG_AES_STATUS     = 6'h0C;
  localparam logic [5:0] REG_VERSION        = 6'h0D;
  localparam logic [5:0] REG_SYSTEM_CONTROL = 6'h0E;
  localparam logic [5:0] REG_SYSTEM_STATUS  = 6'h0F;
  localparam logic [5:0] REG_NOP            = 6'h3F;

  logic clk;
  logic rst_n;

  logic spi_sclk;
  logic spi_cs_n;
  logic spi_mosi;
  logic spi_miso;

  logic        mem_clk;
  logic [31:0] mem_i_data;
  logic        mem_i_wr_en;
  logic [9:0]  mem_i_addr;
  logic [31:0] mem_o_data;

  minisoc_top dut (
    .clk         (clk),
    .rst_n       (rst_n),

    .spi_sclk    (spi_sclk),
    .spi_cs_n    (spi_cs_n),
    .spi_mosi    (spi_mosi),
    .spi_miso    (spi_miso),

    .mem_clk     (mem_clk),
    .mem_i_data  (mem_i_data),
    .mem_i_wr_en (mem_i_wr_en),
    .mem_i_addr  (mem_i_addr),
    .mem_o_data  (mem_o_data)
  );

  always #(REF_HALF_PERIOD) clk = ~clk;
  always #(MEM_HALF_PERIOD) mem_clk = ~mem_clk;

  // --------------------------------------------------------------------------
  // SPI mode-0 transaction.
  // --------------------------------------------------------------------------
  task automatic spi_transfer(
    input  logic [39:0] tx,
    output logic [39:0] rx
  );
    int i;
    begin
      rx       = '0;
      spi_cs_n = 1'b0;
      spi_sclk = 1'b0;

      // Data is valid before the rising edge (CPHA=0).
      for (i = 39; i >= 0; i--) begin
        spi_mosi = tx[i];

        #(SPI_HALF_PERIOD);
        spi_sclk = 1'b1;

        // Sample MISO on rising edge.
        #1ps;
        rx[i] = spi_miso;

        #(SPI_HALF_PERIOD - 1ps);
        spi_sclk = 1'b0;
      end

      spi_cs_n = 1'b1;
      spi_mosi = 1'b0;

      // Large compared with the 2 GHz control clock; gives CDC ample margin.
      #10ns;
    end
  endtask

  task automatic spi_write(
    input logic [5:0] addr,
    input logic [31:0] data
  );
    logic [39:0] rx_unused;
    begin
      spi_transfer({1'b0, addr, 1'b0, data}, rx_unused);
    end
  endtask

  task automatic spi_read(
    input  logic [5:0] addr,
    output logic [31:0] data
  );
    logic [39:0] rx_request;
    logic [39:0] rx_response;
    begin
      // Stage 1: request.
      spi_transfer({1'b1, addr, 1'b0, 32'b0}, rx_request);

      // Stage 2: NOP frame clocks response out.
      spi_transfer({1'b0, REG_NOP, 1'b0, 32'b0}, rx_response);

      data = rx_response[31:0];
    end
  endtask

  // --------------------------------------------------------------------------
  // External MEMORY DATA access.
  // Valid only when SPI SYSTEM_CONTROL.MEM_SEL_AES = 0.
  // --------------------------------------------------------------------------
  task automatic mem_write(
    input logic [9:0] addr,
    input logic [31:0] data
  );
    begin
      @(negedge mem_clk);
      mem_i_addr  = addr;
      mem_i_data  = data;
      mem_i_wr_en = 1'b1;

      @(posedge mem_clk);
      #1ps;

      @(negedge mem_clk);
      mem_i_wr_en = 1'b0;
    end
  endtask

  task automatic mem_read(
    input  logic [9:0] addr,
    output logic [31:0] data
  );
    begin
      @(negedge mem_clk);
      mem_i_addr  = addr;
      mem_i_wr_en = 1'b0;

      @(posedge mem_clk);
      #1ps;
      data = mem_o_data;
    end
  endtask

  task automatic wait_pll_locked;
    logic [31:0] status;
    int tries;
    begin
      status = 32'b0;
      tries  = 0;

      while (!status[0]) begin
        spi_read(REG_SYSTEM_STATUS, status);
        tries++;

        if (tries > 20)
          $fatal(1, "Timeout waiting for PLL lock");
      end

      $display("[%0t] PLL locked after %0d SPI poll(s)", $time, tries);
    end
  endtask

  task automatic wait_aes_done;
    logic [31:0] status;
    int tries;
    begin
      status = 32'b0;
      tries  = 0;

      while (!status[1]) begin
        spi_read(REG_AES_STATUS, status);
        tries++;

        if (status[2])
          $fatal(1, "AES ERROR asserted, status=%08h", status);

        if (tries > 100)
          $fatal(1, "Timeout waiting for AES done");
      end

      if (status[11:3] != 9'd1)
        $fatal(1, "Expected blocks_done=1, status=%08h", status);

      $display("[%0t] AES done, status=%08h", $time, status);
    end
  endtask

  logic [31:0] rd;
  logic [31:0] word0;
  logic [31:0] word1;
  logic [31:0] word2;
  logic [31:0] word3;

  initial begin
    clk         = 1'b0;
    rst_n       = 1'b0;

    spi_sclk    = 1'b0;
    spi_cs_n    = 1'b1;
    spi_mosi    = 1'b0;

    mem_clk     = 1'b0;
    mem_i_data  = 32'b0;
    mem_i_wr_en = 1'b0;
    mem_i_addr  = 10'b0;

    #10ns;
    rst_n = 1'b1;

    // ------------------------------------------------------------------------
    // 1. Confirm SPI is alive while PLL/system clock is still disabled.
    // ------------------------------------------------------------------------
    spi_read(REG_VERSION, rd);
    if (rd !== 32'h0001_0100)
      $fatal(1, "VERSION mismatch. expected=00010100 got=%08h", rd);

    spi_read(REG_SYSTEM_STATUS, rd);
    if (rd[0] !== 1'b0)
      $fatal(1, "PLL must start unlocked");

    // ------------------------------------------------------------------------
    // 2. Preload one 128-bit plaintext block through MEMORY DATA.
    //
    //    plaintext = 00112233445566778899AABBCCDDEEFF
    // ------------------------------------------------------------------------
    mem_write(10'd0, 32'h0011_2233);
    mem_write(10'd1, 32'h4455_6677);
    mem_write(10'd2, 32'h8899_AABB);
    mem_write(10'd3, 32'hCCDD_EEFF);

    // Read it back through the same external interface.
    mem_read(10'd0, rd);
    if (rd !== 32'h0011_2233) $fatal(1, "Memory preload readback failed");

    // ------------------------------------------------------------------------
    // 3. Program AES through SPI.
    //
    //    key = 000102030405060708090A0B0C0D0E0F
    // ------------------------------------------------------------------------
    spi_write(REG_KEY0, 32'h0001_0203);
    spi_write(REG_KEY1, 32'h0405_0607);
    spi_write(REG_KEY2, 32'h0809_0A0B);
    spi_write(REG_KEY3, 32'h0C0D_0E0F);

    spi_write(REG_IV0, 32'h0000_0000);
    spi_write(REG_IV1, 32'h0000_0000);
    spi_write(REG_IV2, 32'h0000_0000);
    spi_write(REG_IV3, 32'h0000_0000);

    spi_write(REG_COUNTER_HI, 32'h0000_0000);
    spi_write(REG_COUNTER_LO, 32'h0000_0000);

    spi_write(REG_NUM_BLOCKS, 32'd1);

    // ECB encrypt, no START yet.
    spi_write(REG_AES_CONTROL, 32'h0000_0000);

    // ------------------------------------------------------------------------
    // 4. Enable PLL at /8 -> 250 MHz. Memory remains owned by USER.
    //
    // SYSTEM_CONTROL:
    //   bit 0    MEM_SEL_AES = 0
    //   bit 1    PLL_ENABLE  = 1
    //   bits 3:2 PLL_DIV_SEL = 11 (/8)
    // ------------------------------------------------------------------------
    spi_write(REG_SYSTEM_CONTROL, 32'h0000_000E);
    wait_pll_locked();

    // The PLL must have released the internal system clock.
    repeat (3) @(posedge dut.sys_clk);

    // ------------------------------------------------------------------------
    // 5. Give memory ownership to AES.
    // ------------------------------------------------------------------------
    spi_write(REG_SYSTEM_CONTROL, 32'h0000_000F);

    spi_read(REG_SYSTEM_CONTROL, rd);
    if (rd[3:0] !== 4'hF)
      $fatal(1, "SYSTEM_CONTROL readback mismatch: %08h", rd);

    // ------------------------------------------------------------------------
    // 6. Start one ECB encryption.
    // ------------------------------------------------------------------------
    spi_write(REG_AES_CONTROL, 32'h0000_0001);

    wait_aes_done();

    // ------------------------------------------------------------------------
    // 7. Return memory ownership to USER while keeping PLL enabled /8.
    // ------------------------------------------------------------------------
    spi_write(REG_SYSTEM_CONTROL, 32'h0000_000E);

    // ------------------------------------------------------------------------
    // 8. Read result through external MEMORY DATA.
    //
    // Expected AES-128 ECB:
    //   69C4E0D86A7B0430D8CDB78070B4C55A
    // ------------------------------------------------------------------------
    mem_read(10'd0, word0);
    mem_read(10'd1, word1);
    mem_read(10'd2, word2);
    mem_read(10'd3, word3);

    $display("Ciphertext = %08h%08h%08h%08h",
             word0, word1, word2, word3);

    if ({word0, word1, word2, word3} !==
        128'h69C4E0D86A7B0430D8CDB78070B4C55A) begin
      $fatal(1,
             "AES ciphertext mismatch expected=69C4E0D86A7B0430D8CDB78070B4C55A got=%08h%08h%08h%08h",
             word0, word1, word2, word3);
    end

    // ------------------------------------------------------------------------
    // 9. Disable PLL at the end. Memory remains USER-owned.
    // ------------------------------------------------------------------------
    spi_write(REG_SYSTEM_CONTROL, 32'h0000_0000);

    spi_read(REG_SYSTEM_STATUS, rd);
    if (rd[0] !== 1'b0)
      $fatal(1, "PLL should be unlocked after disable");

    $display("");
    $display("==============================================");
    $display("[PASS] MiniSoC AES top-level integration test");
    $display("       SPI -> PLL -> AES -> MEMORY");
    $display("       SPI SCLK = 20 MHz (requirement <=25 MHz)");
    $display("==============================================");

    #100ns;
    $finish;
  end

endmodule
