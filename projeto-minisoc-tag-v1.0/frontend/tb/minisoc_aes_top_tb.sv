`timescale 1ns/1ps

/**
 * Baseline testbench for the MiniSoC AES memory engine.
 */
module minisoc_aes_top_tb;

  localparam logic [2:0] AES_MODE_ECB = 3'b000;
  localparam logic [2:0] AES_MODE_CBC = 3'b001;

  logic clk;
  logic rst_n;

  logic         cfg_start;
  logic         cfg_decrypt;
  logic [2:0]   cfg_mode;
  logic [8:0]   cfg_num_blocks;
  logic [127:0] cfg_key;
  logic [127:0] cfg_iv;
  logic [63:0]  cfg_counter;

  logic         busy;
  logic         done;
  logic         error;
  logic [8:0]   blocks_done;

  logic         mem_en;
  logic         mem_wr_en;
  logic [9:0]   mem_addr;
  logic [31:0]  mem_wdata;
  logic [31:0]  mem_rdata;

  // 1024 x 32-bit RAM model. Read latency = 1 clock cycle.
  logic [31:0] memory [0:1023];

  int errors;

  minisoc_aes_top dut (
    .clk            (clk),
    .rst_n          (rst_n),
    .cfg_start      (cfg_start),
    .cfg_decrypt    (cfg_decrypt),
    .cfg_mode       (cfg_mode),
    .cfg_num_blocks (cfg_num_blocks),
    .cfg_key        (cfg_key),
    .cfg_iv         (cfg_iv),
    .cfg_counter    (cfg_counter),
    .busy           (busy),
    .done           (done),
    .error          (error),
    .blocks_done    (blocks_done),
    .mem_en         (mem_en),
    .mem_wr_en      (mem_wr_en),
    .mem_addr       (mem_addr),
    .mem_wdata      (mem_wdata),
    .mem_rdata      (mem_rdata)
  );

  always #5 clk = ~clk;

  // Testbench RAM model.
  // Do not use always_ff here because the testbench also preloads/clears
  // the memory array procedurally through helper tasks. always_ff requires
  // every LHS variable to have a single procedural writer.
  always @(posedge clk) begin
    if (!rst_n) begin
      mem_rdata <= 32'b0;
    end else if (mem_en) begin
      if (mem_wr_en) begin
        memory[mem_addr] <= mem_wdata;
      end else begin
        mem_rdata <= memory[mem_addr];
      end
    end
  end

  task automatic clear_memory;
    for (int i = 0; i < 1024; i++) begin
      memory[i] = 32'b0;
    end
  endtask

  task automatic write_block(input int block_index, input logic [127:0] value);
    int base;
    begin
      base = block_index * 4;
      memory[base + 0] = value[127:96];
      memory[base + 1] = value[95:64];
      memory[base + 2] = value[63:32];
      memory[base + 3] = value[31:0];
    end
  endtask

  function automatic logic [127:0] read_block(input int block_index);
    int base;
    begin
      base = block_index * 4;
      read_block = {
        memory[base + 0],
        memory[base + 1],
        memory[base + 2],
        memory[base + 3]
      };
    end
  endfunction

  task automatic pulse_start;
    begin
      @(negedge clk);
      cfg_start = 1'b1;
      @(negedge clk);
      cfg_start = 1'b0;
    end
  endtask

  task automatic wait_for_done;
    int timeout;
    begin
      timeout = 0;
      while (!done && timeout < 5000) begin
        @(posedge clk);
        timeout++;
      end

      if (!done) begin
        $error("Timeout waiting for done");
        errors++;
      end

      @(posedge clk);
    end
  endtask

  task automatic check_block(
    input string test_name,
    input int block_index,
    input logic [127:0] expected
  );
    logic [127:0] observed;
    begin
      observed = read_block(block_index);
      if (observed !== expected) begin
        $error("%s block %0d mismatch. expected=%032h observed=%032h",
               test_name, block_index, expected, observed);
        errors++;
      end else begin
        $display("[PASS] %s block %0d = %032h", test_name, block_index, observed);
      end
    end
  endtask

  initial begin
    clk            = 1'b0;
    rst_n          = 1'b0;
    cfg_start      = 1'b0;
    cfg_decrypt    = 1'b0;
    cfg_mode       = AES_MODE_ECB;
    cfg_num_blocks = 9'd1;
    cfg_key        = 128'b0;
    cfg_iv         = 128'b0;
    cfg_counter    = 64'b0;
    errors         = 0;

    clear_memory();

    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    // ----------------------------------------------------------------------
    // Test 1: AES-128 ECB encryption, FIPS-197 known-answer vector.
    // ----------------------------------------------------------------------
    $display("\nTEST 1 - ECB encrypt, one block");
    clear_memory();
    cfg_key        = 128'h000102030405060708090A0B0C0D0E0F;
    cfg_iv         = 128'b0;
    cfg_counter    = 64'b0;
    cfg_mode       = AES_MODE_ECB;
    cfg_decrypt    = 1'b0;
    cfg_num_blocks = 9'd1;
    write_block(0, 128'h00112233445566778899AABBCCDDEEFF);
    pulse_start();
    wait_for_done();
    check_block("ECB encrypt", 0, 128'h69C4E0D86A7B0430D8CDB78070B4C55A);

    // ----------------------------------------------------------------------
    // Test 2: AES-128 ECB decryption of the same vector.
    // ----------------------------------------------------------------------
    $display("\nTEST 2 - ECB decrypt, one block");
    clear_memory();
    cfg_mode       = AES_MODE_ECB;
    cfg_decrypt    = 1'b1;
    cfg_num_blocks = 9'd1;
    write_block(0, 128'h69C4E0D86A7B0430D8CDB78070B4C55A);
    pulse_start();
    wait_for_done();
    check_block("ECB decrypt", 0, 128'h00112233445566778899AABBCCDDEEFF);

    // ----------------------------------------------------------------------
    // Test 3: CBC encryption, two blocks, vector from the original AES IP doc.
    // This test validates both multi-block memory traversal and chaining.
    // ----------------------------------------------------------------------
    $display("\nTEST 3 - CBC encrypt, two blocks");
    clear_memory();
    cfg_key        = 128'h000102030405060708090A0B0C0D0E0F;
    cfg_iv         = 128'hCCCCCCCCAAAAAAAAFFFFFFFFEEEEEEEE;
    cfg_mode       = AES_MODE_CBC;
    cfg_decrypt    = 1'b0;
    cfg_num_blocks = 9'd2;
    write_block(0, 128'h00112233445566778899AABBCCDDEEFF);
    write_block(1, 128'hFFEEDDCCBBAA99887766554433221100);
    pulse_start();
    wait_for_done();
    check_block("CBC encrypt", 0, 128'hF6217F61B2D50A6AE6791F8C384B1E07);
    check_block("CBC encrypt", 1, 128'h00E6F7C3F089B33AF8D701BEB170AF82);

    // ----------------------------------------------------------------------
    // Test 4: CBC decryption of the same two blocks.
    // ----------------------------------------------------------------------
    $display("\nTEST 4 - CBC decrypt, two blocks");
    clear_memory();
    cfg_mode       = AES_MODE_CBC;
    cfg_decrypt    = 1'b1;
    cfg_num_blocks = 9'd2;
    write_block(0, 128'hF6217F61B2D50A6AE6791F8C384B1E07);
    write_block(1, 128'h00E6F7C3F089B33AF8D701BEB170AF82);
    pulse_start();
    wait_for_done();
    check_block("CBC decrypt", 0, 128'h00112233445566778899AABBCCDDEEFF);
    check_block("CBC decrypt", 1, 128'hFFEEDDCCBBAA99887766554433221100);

    if (error) begin
      $error("DUT error flag asserted unexpectedly");
      errors++;
    end

    if (errors == 0) begin
      $display("\n========================================");
      $display("ALL MINISOC AES BASELINE TESTS PASSED");
      $display("========================================");
    end else begin
      $fatal(1, "MiniSoC AES baseline failed with %0d error(s)", errors);
    end

    $finish;
  end

endmodule
