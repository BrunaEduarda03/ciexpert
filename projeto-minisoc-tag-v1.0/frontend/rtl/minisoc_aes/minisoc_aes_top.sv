/**
 * MiniSoC AES memory engine.
 *
 * Processes 1..256 AES blocks stored in a 1024 x 32-bit synchronous memory.
 * Each 128-bit block occupies four consecutive 32-bit memory words:
 *   block[127:96] = mem[base + 0]
 *   block[ 95:64] = mem[base + 1]
 *   block[ 63:32] = mem[base + 2]
 *   block[ 31: 0] = mem[base + 3]
 *
 * Results are written back in place to the same four memory locations.
 *
 * This module deliberately contains no SPI/AMBA protocol logic. The future SPI
 * register bank only has to drive the cfg_* signals below.
 */
module minisoc_aes_top (
  input  logic         clk,
  input  logic         rst_n,

  // Configuration/status interface. These signals will later be driven by SPI registers.
  input  logic         cfg_start,
  input  logic         cfg_decrypt,
  input  logic [2:0]   cfg_mode,
  input  logic [8:0]   cfg_num_blocks,
  input  logic [127:0] cfg_key,
  input  logic [127:0] cfg_iv,
  input  logic [63:0]  cfg_counter,

  output logic         busy,
  output logic         done,
  output logic         error,
  output logic [8:0]   blocks_done,

  // Single-port synchronous memory master interface.
  output logic         mem_en,
  output logic         mem_wr_en,
  output logic [9:0]   mem_addr,
  output logic [31:0]  mem_wdata,
  input  logic [31:0]  mem_rdata
);

  localparam logic [2:0] AES_MODE_ECB  = 3'b000;
  localparam logic [2:0] AES_MODE_CBC  = 3'b001;
  localparam logic [2:0] AES_MODE_PCBC = 3'b010;
  localparam logic [2:0] AES_MODE_CFB  = 3'b011;
  localparam logic [2:0] AES_MODE_OFB  = 3'b100;
  localparam logic [2:0] AES_MODE_CTR  = 3'b101;

  typedef enum logic [4:0] {
    ST_IDLE,
    ST_RD0_REQ, ST_RD0_CAP,
    ST_RD1_REQ, ST_RD1_CAP,
    ST_RD2_REQ, ST_RD2_CAP,
    ST_RD3_REQ, ST_RD3_CAP,
    ST_AES_PREP,
    ST_AES_WAIT,
    ST_WR0,
    ST_WR1,
    ST_WR2,
    ST_WR3,
    ST_DONE
  } state_e;

  state_e state_q;

  logic cfg_start_d;
  logic start_pulse;

  logic         decrypt_q;
  logic [2:0]   mode_q;
  logic [8:0]   num_blocks_q;
  logic [127:0] key_q;
  logic [127:0] iv_q;
  logic [63:0]  counter_q;
  logic [127:0] chain_q;

  logic [7:0]   block_index_q;
  logic [127:0] block_in_q;
  logic [127:0] block_out_q;
  logic [9:0]   block_base_addr;

  logic         aes_start;
  logic         aes_decrypt;
  logic [127:0] aes_input;
  logic [127:0] aes_output;
  logic         aes_valid;
  logic         aes_expanding;

  assign start_pulse     = cfg_start & ~cfg_start_d;
  assign block_base_addr = {block_index_q, 2'b00};
  assign busy            = (state_q != ST_IDLE) && (state_q != ST_DONE);

  minisoc_aes_dp u_aes_dp (
    .clk       (clk),
    .rst_n     (rst_n),
    .start_AES (aes_start),
    .decrypt   (aes_decrypt),
    .key       (key_q),
    .busB      (aes_input),
    .valid_AES (aes_valid),
    .expanding (aes_expanding),
    .busAES    (aes_output)
  );

  // AES input selection. CFB/OFB/CTR always use the AES encryption primitive.
  always_comb begin
    aes_input   = block_in_q;
    aes_decrypt = decrypt_q;

    unique case (mode_q)
      AES_MODE_ECB: begin
        aes_input   = block_in_q;
        aes_decrypt = decrypt_q;
      end

      AES_MODE_CBC,
      AES_MODE_PCBC: begin
        aes_input   = decrypt_q ? block_in_q : (block_in_q ^ chain_q);
        aes_decrypt = decrypt_q;
      end

      AES_MODE_CFB,
      AES_MODE_OFB: begin
        aes_input   = chain_q;
        aes_decrypt = 1'b0;
      end

      AES_MODE_CTR: begin
        // Preserves the behavior of the original IP: IV XOR zero-extended 64-bit counter.
        aes_input   = iv_q ^ {64'b0, counter_q};
        aes_decrypt = 1'b0;
      end

      default: begin
        aes_input   = block_in_q;
        aes_decrypt = decrypt_q;
      end
    endcase
  end

  // The current AES datapath expects start_AES to remain asserted until valid_AES.
  assign aes_start = (state_q == ST_AES_WAIT);

  // Memory interface. Reads use one request cycle followed by one capture cycle.
  always_comb begin
    mem_en     = 1'b0;
    mem_wr_en  = 1'b0;
    mem_addr   = 10'b0;
    mem_wdata  = 32'b0;

    unique case (state_q)
      ST_RD0_REQ: begin
        mem_en   = 1'b1;
        mem_addr = block_base_addr + 10'd0;
      end
      ST_RD1_REQ: begin
        mem_en   = 1'b1;
        mem_addr = block_base_addr + 10'd1;
      end
      ST_RD2_REQ: begin
        mem_en   = 1'b1;
        mem_addr = block_base_addr + 10'd2;
      end
      ST_RD3_REQ: begin
        mem_en   = 1'b1;
        mem_addr = block_base_addr + 10'd3;
      end

      ST_WR0: begin
        mem_en    = 1'b1;
        mem_wr_en = 1'b1;
        mem_addr  = block_base_addr + 10'd0;
        mem_wdata = block_out_q[127:96];
      end
      ST_WR1: begin
        mem_en    = 1'b1;
        mem_wr_en = 1'b1;
        mem_addr  = block_base_addr + 10'd1;
        mem_wdata = block_out_q[95:64];
      end
      ST_WR2: begin
        mem_en    = 1'b1;
        mem_wr_en = 1'b1;
        mem_addr  = block_base_addr + 10'd2;
        mem_wdata = block_out_q[63:32];
      end
      ST_WR3: begin
        mem_en    = 1'b1;
        mem_wr_en = 1'b1;
        mem_addr  = block_base_addr + 10'd3;
        mem_wdata = block_out_q[31:0];
      end

      default: begin
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state_q       <= ST_IDLE;
      cfg_start_d   <= 1'b0;
      decrypt_q     <= 1'b0;
      mode_q        <= AES_MODE_ECB;
      num_blocks_q  <= 9'd0;
      key_q         <= '0;
      iv_q          <= '0;
      counter_q     <= '0;
      chain_q       <= '0;
      block_index_q <= 8'd0;
      block_in_q    <= '0;
      block_out_q   <= '0;
      blocks_done   <= 9'd0;
      done          <= 1'b0;
      error         <= 1'b0;
    end else begin
      cfg_start_d <= cfg_start;

      unique case (state_q)
        ST_IDLE: begin
          if (start_pulse) begin
            blocks_done <= 9'd0;
            done        <= 1'b0;
            error       <= 1'b0;

            if ((cfg_num_blocks == 9'd0) || (cfg_num_blocks > 9'd256) ||
                (cfg_mode > AES_MODE_CTR)) begin
              error   <= 1'b1;
              state_q <= ST_DONE;
            end else begin
              decrypt_q     <= cfg_decrypt;
              mode_q        <= cfg_mode;
              num_blocks_q  <= cfg_num_blocks;
              key_q         <= cfg_key;
              iv_q          <= cfg_iv;
              counter_q     <= cfg_counter;
              chain_q       <= cfg_iv;
              block_index_q <= 8'd0;
              state_q       <= ST_RD0_REQ;
            end
          end
        end

        ST_RD0_REQ: state_q <= ST_RD0_CAP;
        ST_RD0_CAP: begin
          block_in_q[127:96] <= mem_rdata;
          state_q             <= ST_RD1_REQ;
        end

        ST_RD1_REQ: state_q <= ST_RD1_CAP;
        ST_RD1_CAP: begin
          block_in_q[95:64] <= mem_rdata;
          state_q            <= ST_RD2_REQ;
        end

        ST_RD2_REQ: state_q <= ST_RD2_CAP;
        ST_RD2_CAP: begin
          block_in_q[63:32] <= mem_rdata;
          state_q            <= ST_RD3_REQ;
        end

        ST_RD3_REQ: state_q <= ST_RD3_CAP;
        ST_RD3_CAP: begin
          block_in_q[31:0] <= mem_rdata;
          state_q           <= ST_AES_PREP;
        end

        // One explicit preparation cycle guarantees stable AES inputs before start_AES.
        ST_AES_PREP: state_q <= ST_AES_WAIT;

        ST_AES_WAIT: begin
          if (aes_valid) begin
            unique case (mode_q)
              AES_MODE_ECB: begin
                block_out_q <= aes_output;
              end

              AES_MODE_CBC: begin
                if (decrypt_q) begin
                  block_out_q <= aes_output ^ chain_q;
                  chain_q     <= block_in_q;
                end else begin
                  block_out_q <= aes_output;
                  chain_q     <= aes_output;
                end
              end

              AES_MODE_PCBC: begin
                if (decrypt_q) begin
                  block_out_q <= aes_output ^ chain_q;
                  chain_q     <= block_in_q ^ (aes_output ^ chain_q);
                end else begin
                  block_out_q <= aes_output;
                  chain_q     <= block_in_q ^ aes_output;
                end
              end

              AES_MODE_CFB: begin
                block_out_q <= block_in_q ^ aes_output;
                chain_q     <= decrypt_q ? block_in_q : (block_in_q ^ aes_output);
              end

              AES_MODE_OFB: begin
                block_out_q <= block_in_q ^ aes_output;
                chain_q     <= aes_output;
              end

              AES_MODE_CTR: begin
                block_out_q <= block_in_q ^ aes_output;
                counter_q   <= counter_q + 1'b1;
              end

              default: begin
                block_out_q <= aes_output;
              end
            endcase

            state_q <= ST_WR0;
          end
        end

        ST_WR0: state_q <= ST_WR1;
        ST_WR1: state_q <= ST_WR2;
        ST_WR2: state_q <= ST_WR3;

        ST_WR3: begin
          blocks_done <= blocks_done + 1'b1;

          if (({1'b0, block_index_q} + 9'd1) >= num_blocks_q) begin
            state_q <= ST_DONE;
          end else begin
            block_index_q <= block_index_q + 1'b1;
            state_q       <= ST_RD0_REQ;
          end
        end

        ST_DONE: begin
          // Sticky completion indication. It is cleared by the next accepted start.
          done    <= 1'b1;
          state_q <= ST_IDLE;
        end

        default: state_q <= ST_IDLE;
      endcase
    end
  end

endmodule
