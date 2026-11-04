/**
 * MiniSoC AES - Shared Memory
 *
 * 1024 x 32-bit single-port synchronous memory.
 *
 * The memory has two logical masters:
 *   - USER: external memory/data interface
 *   - AES : AES memory engine
 *
 * Only one master owns the physical memory port at a time. The ownership
 * selector is expected to be driven by the SPI configuration register:
 *
 *   i_sel_aes = 1'b0 -> USER owns the memory
 *   i_sel_aes = 1'b1 -> AES owns the memory
 *
 * IMPORTANT:
 * Both logical interfaces are synchronous to the same `clk`.
 * This module intentionally does not mux clocks.
 *
 * There is no reset. Memory contents and read-data registers are undefined
 * after power-up until written/read by the active master.
 */

module minisoc_memory #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 10,
  parameter int DEPTH      = 1024
)(
  input  logic                  clk,

  // Ownership control from SPI
  input  logic                  i_sel_aes,

  // External USER interface
  input  logic [DATA_WIDTH-1:0] i_user_data,
  input  logic                  i_user_wr_en,  // 1 = write, 0 = read
  input  logic [ADDR_WIDTH-1:0] i_user_addr,
  output logic [DATA_WIDTH-1:0] o_user_data,

  // AES interface
  input  logic [DATA_WIDTH-1:0] i_aes_data,
  input  logic                  i_aes_wr_en,   // 1 = write, 0 = read
  input  logic [ADDR_WIDTH-1:0] i_aes_addr,
  output logic [DATA_WIDTH-1:0] o_aes_data
);

  logic [DATA_WIDTH-1:0] memory [0:DEPTH-1];

  logic [DATA_WIDTH-1:0] selected_wdata;
  logic [ADDR_WIDTH-1:0] selected_addr;
  logic                  selected_wr_en;

  // Single physical memory port selected by SPI-controlled ownership.
  always_comb begin
    if (i_sel_aes) begin
      selected_addr  = i_aes_addr;
      selected_wdata = i_aes_data;
      selected_wr_en = i_aes_wr_en;
    end
    else begin
      selected_addr  = i_user_addr;
      selected_wdata = i_user_data;
      selected_wr_en = i_user_wr_en;
    end
  end

  // Synchronous single-port RAM.
  //
  // Write:
  //   memory[address] is updated on the rising edge.
  //
  // Read:
  //   the selected master's output register receives memory[address]
  //   on the rising edge (1-cycle synchronous read behavior).
  //
  // The non-selected master cannot modify or read the physical memory port.
  always_ff @(posedge clk) begin
    if (selected_wr_en) begin
      memory[selected_addr] <= selected_wdata;
    end
    else begin
      if (i_sel_aes)
        o_aes_data  <= memory[selected_addr];
      else
        o_user_data <= memory[selected_addr];
    end
  end

endmodule
