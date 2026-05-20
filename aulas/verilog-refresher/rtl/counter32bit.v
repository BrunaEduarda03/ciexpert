//32 bit counter_overflow
//Inputs: en, load,clock,reset_n
//Outputs: counter_out,counter_overflow
//Function: The design, when enable is high counter starts counting, when load is
//made high, 33’hfffffff8 is loaded to counter_out the result is stored in register
//counter_out {counter_out2, counter_overflow}.
//Design file: counter_overflow.v
//∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗
// Module starts 32-bit counting and when load is made high, 33’hfffffff8 is loaded to
//counter_out.
// This is sequential block which require clock and reset_n
//
//User can refer to any Verilog HDL language book to understand the syntax of
//commands. //
//∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗/

//32-bit counter with overflow design
module counter_overflow(
    //------------------clock_reset-----------------//
    clk,
    reset_n,
    //----------------Input---------------------//
    en,
    load,
    //--------------output-----------------------//
    counter_out,
    counter_overflow
);

input clk,
      reset_n;

//----------------Input---------------------//
input en;
input load;

//--------------output-----------------------//
output [31:0] counter_out;
output counter_overflow;

reg [32:0] counter_reg;
wire load;

assign counter_overflow = counter_reg[32];
assign counter_out = counter_reg[31:0];

always @(posedge clk or negedge reset_n)
begin
    if (!reset_n) begin
        counter_reg <= 33'd0;
    end

    if (load)
        counter_reg <= 33'b111111111111111111111111111111000;

    if (en)
        counter_reg <= counter_reg + 33'd1;
end

endmodule