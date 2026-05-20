//16 × 16 multiplier
//Inputs: two 16-bit operands in op_a, op_b
//Outputs: 32-bit multi_out
//Function: The design performs multiplication of two operands of 16 bit binary numbers
//stored in op_a, op_b both 16-bit registers representing the operands. The
//result is stored in 32-bit register multi_out
//Design file: multiplier.v
//∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗
// Module works for 16x16 multiplier of A and B.
// This is combinational block which doesn’t require clock and reset
//
//User can refer to any Verilog HDL language book to understand the syntax of
//commands. //
//∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗/
//16∗16 bit multiplier
module multiplier (
    //------------------clock_reset-----------------//
    clk,
    reset_n,
    //----------------Input---------------------//
    en,
    op_a,
    op_b,
    //--------------output-----------------------//
    multi_out
);

//------------------clock_reset-------------//
input clk,
      reset_n;

//----------------Input---------------------//
input en;
input [15:0] op_a, op_b;

//--------------output-----------------------//
output [31:0] multi_out;

reg [31:0] multi_out_reg;
wire [31:0] multi_out;

assign multi_out = multi_out_reg;

always @(posedge clk or negedge reset_n)
begin
    if (!reset_n)
        multi_out_reg <= 32'd0;
    else if (en)
        multi_out_reg <= (op_a * op_b);
end

endmodule