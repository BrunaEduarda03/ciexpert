module adder32_assertion #(
  parameter int NBW = 32
)(
  input logic           clk,
  input logic           reset_n,

  input logic [NBW-1:0] adder_out,
  input logic           carry_out
);

  // During reset, DUT outputs must be zero.
  property p_reset_outputs_zero;
    @(posedge clk)
      (!reset_n) |-> (adder_out == '0 && carry_out == 1'b0);
  endproperty

  a_reset_outputs_zero: assert property (p_reset_outputs_zero)
    else begin
      $error("[ASSERTION] Reset failure: adder_out=%0h carry_out=%0b while reset_n=0",
             adder_out,
             carry_out);
    end

endmodule: adder32_assertion