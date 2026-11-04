`timescale 1ns/1ps

module minisoc_memory_tb;

  localparam int DATA_WIDTH = 32;
  localparam int ADDR_WIDTH = 10;

  logic clk;
  logic i_sel_aes;

  logic [31:0] i_user_data;
  logic        i_user_wr_en;
  logic [9:0]  i_user_addr;
  logic [31:0] o_user_data;

  logic [31:0] i_aes_data;
  logic        i_aes_wr_en;
  logic [9:0]  i_aes_addr;
  logic [31:0] o_aes_data;

  minisoc_memory dut (
    .clk          (clk),
    .i_sel_aes    (i_sel_aes),

    .i_user_data  (i_user_data),
    .i_user_wr_en (i_user_wr_en),
    .i_user_addr  (i_user_addr),
    .o_user_data  (o_user_data),

    .i_aes_data   (i_aes_data),
    .i_aes_wr_en  (i_aes_wr_en),
    .i_aes_addr   (i_aes_addr),
    .o_aes_data   (o_aes_data)
  );

  always #5 clk = ~clk;

  task automatic user_write(input logic [9:0] addr, input logic [31:0] data);
    i_sel_aes   = 1'b0;
    i_user_addr = addr;
    i_user_data = data;
    i_user_wr_en = 1'b1;
    @(posedge clk);
    #1;
    i_user_wr_en = 1'b0;
  endtask

  task automatic user_read(
    input logic [9:0] addr,
    input logic [31:0] expected
  );
    i_sel_aes    = 1'b0;
    i_user_addr  = addr;
    i_user_wr_en = 1'b0;
    @(posedge clk);
    #1;
    if (o_user_data !== expected)
      $fatal(1, "USER read mismatch addr=%0d expected=%08h got=%08h",
             addr, expected, o_user_data);
  endtask

  task automatic aes_write(input logic [9:0] addr, input logic [31:0] data);
    i_sel_aes   = 1'b1;
    i_aes_addr  = addr;
    i_aes_data  = data;
    i_aes_wr_en = 1'b1;
    @(posedge clk);
    #1;
    i_aes_wr_en = 1'b0;
  endtask

  task automatic aes_read(
    input logic [9:0] addr,
    input logic [31:0] expected
  );
    i_sel_aes   = 1'b1;
    i_aes_addr  = addr;
    i_aes_wr_en = 1'b0;
    @(posedge clk);
    #1;
    if (o_aes_data !== expected)
      $fatal(1, "AES read mismatch addr=%0d expected=%08h got=%08h",
             addr, expected, o_aes_data);
  endtask

  initial begin
    clk          = 1'b0;
    i_sel_aes    = 1'b0;

    i_user_data  = '0;
    i_user_wr_en = 1'b0;
    i_user_addr  = '0;

    i_aes_data   = '0;
    i_aes_wr_en  = 1'b0;
    i_aes_addr   = '0;

    repeat (2) @(posedge clk);

    // USER owns memory.
    user_write(10'd10, 32'h1122_3344);
    user_read (10'd10, 32'h1122_3344);

    // AES takes ownership and can see the same physical memory.
    aes_read (10'd10, 32'h1122_3344);
    aes_write(10'd10, 32'hA5A5_5A5A);
    aes_read (10'd10, 32'hA5A5_5A5A);

    // Return ownership to USER.
    user_read(10'd10, 32'hA5A5_5A5A);

    // Prove non-owner cannot write:
    // USER attempts to write while AES is selected. Physical write must come
    // from AES interface, not USER interface.
    i_sel_aes    = 1'b1;
    i_user_addr  = 10'd20;
    i_user_data  = 32'hDEAD_BEEF;
    i_user_wr_en = 1'b1;

    i_aes_addr   = 10'd20;
    i_aes_data   = 32'hCAFE_BABE;
    i_aes_wr_en  = 1'b1;

    @(posedge clk);
    #1;

    i_user_wr_en = 1'b0;
    i_aes_wr_en  = 1'b0;

    user_read(10'd20, 32'hCAFE_BABE);

    $display("[PASS] minisoc_memory_tb");
    $finish;
  end

endmodule
