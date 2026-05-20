//4-Bit Up/Down Counter
//Inputs: en
//Outputs:up_counter, down_counter
//Function: When enable signal is set high, in the design updowncounter, the up_
//counter starts counting from 0000 to 1111. The down counter starts counting
//from 1111 to 0000.
//Design file: updowncounter.v
//∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗
// Module starts 4-bit up counting and 4-bit down counting
// This is sequential block which require clock and reset //
//User can refer to any Verilog HDL language book to understand the syntax of
//commands. //
//∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗/
//4-bit counter design
module updowncounter(
    clk,
    resetn,
    en,
    up_counter,
    down_counter
);

//-----------------input ports------------
input clk;     //input clock of the design
input resetn;  // avtive low reset
input en;      // active high enable

//-----------------output ports------------
output [3:0] up_counter;
output [3:0] down_counter;

//-----------------input datatype------------
wire clk;
wire resetn;
wire en;

//-----------------output datatype------------
reg [3:0] up_counter;
reg [3:0] down_counter;

// for every posedge of the clock below function has to happen
always @(posedge clk or posedge resetn)
begin
    if (!resetn) //if reset is zero, reset upcounter to 0000 downcounter to 1111
    begin
        up_counter <= 4'b0000;
        down_counter <= 4'b1111;
    end
    else if (en)
    begin
        up_counter <= up_counter + 4'b0001; // incrementing the count value
        down_counter <= down_counter - 4'b0001; // decrementing the count value
    end
end

endmodule