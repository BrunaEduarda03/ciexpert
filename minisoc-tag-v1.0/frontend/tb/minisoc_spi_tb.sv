`timescale 1ns/1ps

/**
 * Baseline testbench for the MiniSoC AES memory engine.
 */
module minisoc_spi_tb;

  localparam int SPI_TRANSF_SIZE = 40;

  localparam logic [5:0] REG_KEY0       = 6'h00;
  localparam logic [5:0] REG_KEY1       = 6'h01;
  localparam logic [5:0] REG_KEY2       = 6'h02;
  localparam logic [5:0] REG_KEY3       = 6'h03;
  localparam logic [5:0] REG_IV0        = 6'h04;
  localparam logic [5:0] REG_IV1        = 6'h05;
  localparam logic [5:0] REG_IV2        = 6'h06;
  localparam logic [5:0] REG_IV3        = 6'h07;
  localparam logic [5:0] REG_COUNTER_HI = 6'h08;
  localparam logic [5:0] REG_COUNTER_LO = 6'h09;
  localparam logic [5:0] REG_NUM_BLOCKS = 6'h0A;
  localparam logic [5:0] REG_CONTROL    = 6'h0B;
  localparam logic [5:0] REG_STATUS     = 6'h0C;
  localparam logic [5:0] REG_VERSION    = 6'h0D;
  localparam logic [5:0] REG_NOP        = 6'h3F;

  logic sclk;
  logic cs_n;
  logic mosi;
  logic miso;

  logic sys_clk;
  logic rstn;

  logic         cfg_start;
  logic         cfg_decrypt;
  logic [2:0]   cfg_mode;
  logic [8:0]   cfg_num_blocks;
  logic [127:0] cfg_key;
  logic [127:0] cfg_iv;
  logic [63:0]  cfg_counter;

  logic         aes_busy;
  logic         aes_done;
  logic         aes_error;
  logic [8:0]   aes_blocks_done;

  logic [7:0] leds;

  int errors;
  int start_pulse_count;

  minisoc_spi #(
    .SPI_TRANSF_SIZE(SPI_TRANSF_SIZE)
  ) dut (
    .sclk            (sclk),
    .cs_n            (cs_n),
    .mosi            (mosi),
    .miso            (miso),
    .sys_clk         (sys_clk),
    .rstn            (rstn),
    .cfg_start       (cfg_start),
    .cfg_decrypt     (cfg_decrypt),
    .cfg_mode        (cfg_mode),
    .cfg_num_blocks  (cfg_num_blocks),
    .cfg_key         (cfg_key),
    .cfg_iv          (cfg_iv),
    .cfg_counter     (cfg_counter),
    .aes_busy        (aes_busy),
    .aes_done        (aes_done),
    .aes_error       (aes_error),
    .aes_blocks_done (aes_blocks_done),
    .leds            (leds)
  );

  always #5 sys_clk = ~sys_clk; // 100 MHz

  // Count generated START pulses.
  always @(posedge sys_clk) begin
    if (!rstn)
      start_pulse_count <= 0;
    else if (cfg_start)
      start_pulse_count <= start_pulse_count + 1;
  end

  function automatic logic [SPI_TRANSF_SIZE-1:0] make_frame(
    input logic        rwb,
    input logic [5:0]  addr,
    input logic [31:0] data
  );
    make_frame = {rwb, addr, 1'b0, data};
  endfunction

  // SPI mode 0 transaction. Both directions are MSB-first.
  task automatic spi_transfer(
    input  logic [SPI_TRANSF_SIZE-1:0] tx_frame,
    output logic [SPI_TRANSF_SIZE-1:0] rx_frame
  );
    begin
      rx_frame = '0;
      sclk     = 1'b0;
      cs_n     = 1'b0;
      #20;

      for (int i = SPI_TRANSF_SIZE-1; i >= 0; i--) begin
        // Present MOSI while SCLK is low.
        mosi = tx_frame[i];
        #20;

        // Rising edge: DUT samples MOSI; master samples MISO.
        sclk = 1'b1;
        #1;
        rx_frame[i] = miso;
        #19;

        // Falling edge: DUT advances MISO to the next bit.
        sclk = 1'b0;
        #20;
      end

      cs_n = 1'b1;
      mosi = 1'b0;
      #80; // allow the asynchronous frame event to cross into SYS_CLK
    end
  endtask

  task automatic spi_write(
    input logic [5:0]  addr,
    input logic [31:0] data
  );
    logic [SPI_TRANSF_SIZE-1:0] dummy_rx;
    begin
      spi_transfer(make_frame(1'b0, addr, data), dummy_rx);
    end
  endtask

  task automatic spi_read(
    input  logic [5:0]  addr,
    output logic [31:0] data
  );
    logic [SPI_TRANSF_SIZE-1:0] first_rx;
    logic [SPI_TRANSF_SIZE-1:0] second_rx;
    begin
      // Stage 1: request the register.
      spi_transfer(make_frame(1'b1, addr, 32'b0), first_rx);

      // Stage 2: shift out the previously selected register. Use NOP as the
      // command carried on MOSI so no useful register is modified.
      spi_transfer(make_frame(1'b0, REG_NOP, 32'b0), second_rx);
      data = second_rx[31:0];
    end
  endtask

  task automatic check32(
    input string       name,
    input logic [31:0] observed,
    input logic [31:0] expected
  );
    begin
      if (observed !== expected) begin
        $error("%s mismatch: expected=0x%08h observed=0x%08h",
               name, expected, observed);
        errors++;
      end else begin
        $display("[PASS] %-24s = 0x%08h", name, observed);
      end
    end
  endtask

  task automatic check128(
    input string        name,
    input logic [127:0] observed,
    input logic [127:0] expected
  );
    begin
      if (observed !== expected) begin
        $error("%s mismatch: expected=%032h observed=%032h",
               name, expected, observed);
        errors++;
      end else begin
        $display("[PASS] %-24s = %032h", name, observed);
      end
    end
  endtask

  initial begin
    logic [31:0] rd;

    sys_clk         = 1'b0;
    sclk            = 1'b0;
    cs_n            = 1'b1;
    mosi            = 1'b0;
    rstn            = 1'b0;

    aes_busy        = 1'b0;
    aes_done        = 1'b0;
    aes_error       = 1'b0;
    aes_blocks_done = 9'd0;

    errors          = 0;
    start_pulse_count = 0;

    repeat (5) @(posedge sys_clk);
    rstn = 1'b1;
    repeat (5) @(posedge sys_clk);

    // ----------------------------------------------------------------------
    // TEST 1: reset values and version register.
    // ----------------------------------------------------------------------
    $display("\nTEST 1 - Reset values / version");
    check128("cfg_key reset", cfg_key, 128'b0);
    check128("cfg_iv reset", cfg_iv, 128'b0);
    check32("cfg_counter reset", cfg_counter[31:0], 32'b0);
    check32("cfg_num_blocks reset", {23'b0, cfg_num_blocks}, 32'd1);

    spi_read(REG_VERSION, rd);
    check32("VERSION", rd, 32'h0001_0000);

    // ----------------------------------------------------------------------
    // TEST 2: program AES key.
    // ----------------------------------------------------------------------
    $display("\nTEST 2 - Program KEY");
    spi_write(REG_KEY0, 32'h00010203);
    spi_write(REG_KEY1, 32'h04050607);
    spi_write(REG_KEY2, 32'h08090A0B);
    spi_write(REG_KEY3, 32'h0C0D0E0F);

    check128("cfg_key",
             cfg_key,
             128'h000102030405060708090A0B0C0D0E0F);

    spi_read(REG_KEY2, rd);
    check32("KEY2 readback", rd, 32'h08090A0B);

    // ----------------------------------------------------------------------
    // TEST 3: program IV, counter and number of blocks.
    // ----------------------------------------------------------------------
    $display("\nTEST 3 - Program IV/counter/num_blocks");
    spi_write(REG_IV0, 32'hCCCCCCCC);
    spi_write(REG_IV1, 32'hAAAAAAAA);
    spi_write(REG_IV2, 32'hFFFFFFFF);
    spi_write(REG_IV3, 32'hEEEEEEEE);

    spi_write(REG_COUNTER_HI, 32'h11223344);
    spi_write(REG_COUNTER_LO, 32'h55667788);
    spi_write(REG_NUM_BLOCKS, 32'd256);

    check128("cfg_iv",
             cfg_iv,
             128'hCCCCCCCCAAAAAAAAFFFFFFFFEEEEEEEE);
    check32("counter high", cfg_counter[63:32], 32'h11223344);
    check32("counter low",  cfg_counter[31:0],  32'h55667788);
    check32("num blocks", {23'b0, cfg_num_blocks}, 32'd256);

    // ----------------------------------------------------------------------
    // TEST 4: CONTROL register and one-cycle START pulse.
    // mode=001(CBC), decrypt=1, start=1 -> data = 0b0_001_1_1 = 0x07
    // ----------------------------------------------------------------------
    $display("\nTEST 4 - CONTROL / START pulse");
    spi_write(REG_CONTROL, 32'h0000_0007);
    repeat (4) @(posedge sys_clk);

    check32("mode/decrypt",
            {28'b0, cfg_mode, cfg_decrypt},
            {28'b0, 3'b001, 1'b1});

    if (start_pulse_count != 1) begin
      $error("START pulse count mismatch: expected=1 observed=%0d",
             start_pulse_count);
      errors++;
    end else begin
      $display("[PASS] START pulse count        = %0d", start_pulse_count);
    end

    if (cfg_start !== 1'b0) begin
      $error("cfg_start must return low after one SYS_CLK cycle");
      errors++;
    end else begin
      $display("[PASS] cfg_start returned low");
    end

    spi_read(REG_CONTROL, rd);
    check32("CONTROL readback", rd, 32'h0000_0006); // START reads as zero

    // ----------------------------------------------------------------------
    // TEST 5: STATUS monitor readback.
    // ----------------------------------------------------------------------
    $display("\nTEST 5 - STATUS readback");
    aes_busy        = 1'b1;
    aes_done        = 1'b0;
    aes_error       = 1'b1;
    aes_blocks_done = 9'd37;
    repeat (2) @(posedge sys_clk);

    spi_read(REG_STATUS, rd);
    check32("STATUS busy/error",
            rd,
            {20'b0, 9'd37, 1'b1, 1'b0, 1'b1});

    aes_busy        = 1'b0;
    aes_done        = 1'b1;
    aes_error       = 1'b0;
    aes_blocks_done = 9'd256;
    repeat (2) @(posedge sys_clk);

    spi_read(REG_STATUS, rd);
    check32("STATUS done",
            rd,
            {20'b0, 9'd256, 1'b0, 1'b1, 1'b0});

    // ----------------------------------------------------------------------
    // TEST 6: configuration writes are ignored while AES is busy.
    // ----------------------------------------------------------------------
    $display("\nTEST 6 - Write protection while busy");
    aes_busy = 1'b1;
    repeat (2) @(posedge sys_clk);

    spi_write(REG_KEY0, 32'hDEADBEEF);
    spi_write(REG_NUM_BLOCKS, 32'd12);
    spi_write(REG_CONTROL, 32'h0000_0001); // attempt another START
    repeat (4) @(posedge sys_clk);

    check32("KEY0 protected", cfg_key[127:96], 32'h00010203);
    check32("NUM_BLOCKS protected", {23'b0, cfg_num_blocks}, 32'd256);

    if (start_pulse_count != 1) begin
      $error("START must be ignored while busy: pulse count=%0d", start_pulse_count);
      errors++;
    end else begin
      $display("[PASS] START ignored while busy");
    end

    aes_busy = 1'b0;

    // ----------------------------------------------------------------------
    // TEST 7: LED status mapping.
    // ----------------------------------------------------------------------
    $display("\nTEST 7 - LED status mapping");
    aes_busy        = 1'b1;
    aes_done        = 1'b1;
    aes_error       = 1'b1;
    aes_blocks_done = 9'd21; // low 5 bits = 10101
    #1;

    if (leds !== {5'b10101, 1'b1, 1'b1, 1'b1}) begin
      $error("LED mapping mismatch: observed=%08b", leds);
      errors++;
    end else begin
      $display("[PASS] LEDs                     = %08b", leds);
    end

    // ----------------------------------------------------------------------
    // Final result.
    // ----------------------------------------------------------------------
    if (errors == 0) begin
      $display("\n========================================");
      $display(" ALL MINISOC SPI TESTS PASSED");
      $display("========================================\n");
    end else begin
      $display("\n========================================");
      $display(" MINISOC SPI TESTS FAILED: %0d error(s)", errors);
      $display("========================================\n");
      $fatal(1);
    end

    $finish;
  end

endmodule
