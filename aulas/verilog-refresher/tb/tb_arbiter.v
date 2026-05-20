//==============================================================================
// File: arbiter_tb.v
// Description:
//   Simple testbench for the arbiter.
//   Applies requests from client1 and client2 and observes grants.
//==============================================================================

module arbiter_tb;

  // Inputs
  reg clk;
  reg reset_n;
  reg priority_sel;
  reg client1_req;
  reg client2_req;

  // Outputs
  wire o_grant1;
  wire o_grant2;

  //--------------------------------------------------------------------------
  // Clock generation
  //--------------------------------------------------------------------------
  initial begin
      clk = 1'b0;
      forever #5 clk = ~clk;
  end

  //--------------------------------------------------------------------------
  // DUT instantiation
  //--------------------------------------------------------------------------
  arbiter uu_arbiter (
      .clk         (clk),
      .reset_n     (reset_n),
      .priority_sel(priority_sel),
      .client1_req (client1_req),
      .client2_req (client2_req),
      .o_grant1    (o_grant1),
      .o_grant2    (o_grant2)
  );

  //--------------------------------------------------------------------------
  // Stimulus
  //--------------------------------------------------------------------------
  initial begin
      reset_n      = 1'b0;
      priority_sel = 1'b0;
      client1_req  = 1'b0;
      client2_req  = 1'b0;

      // Reset
      #10 reset_n = 1'b0;
      #10 reset_n = 1'b1;

      // Case 1: client1 has priority
      @(posedge clk);
      #1;
      priority_sel = 1'b1;
      client1_req  = 1'b1;
      client2_req  = 1'b0;

      #10;
      client1_req  = 1'b0;
      client2_req  = 1'b1;

      #10;
      client1_req  = 1'b0;
      client2_req  = 1'b0;

      // Case 2: both request, client2 has priority
      #10;
      priority_sel = 1'b0;
      client1_req  = 1'b1;
      client2_req  = 1'b1;

      // Case 3: both request, client1 has priority
      #10;
      priority_sel = 1'b1;
      client1_req  = 1'b1;
      client2_req  = 1'b1;

      #100 $finish;
  end

  //--------------------------------------------------------------------------
  // Dump
  //--------------------------------------------------------------------------
  initial begin
      $fsdbDumpvars();
  end

endmodule