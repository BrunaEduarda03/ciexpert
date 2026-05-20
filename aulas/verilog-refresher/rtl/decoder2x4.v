//Inputs: 2-bit din
//Outputs: 4-bit dout
//Function: The design decodes 2-bit din.
//Design file: decoder2x4.v
//∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗
// Module starts decoding 2-bit din
// This is combinational block which doesn’t require clock and reset, but used //
// to latch the output //
//User can refer to any Verilog HDL language book to understand the syntax of
//commands. //
//∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗/
//u2:4 decoder
module decoder2x4(
    clk,
    rstn,
    en,
    din,
    dout
);

//---------------input ports----------------
input en;      // active high enable
input clk;     // input clock of the design
input rstn;    // active low reset
input [1:0] din; // input data

//---------------output ports----------------
output [3:0] dout; // output data

//---------------input datatypes----------------
wire clk;
wire en;
wire rstn;
wire [1:0] din;

//---------------output datatypes ports----------------
reg [3:0] dout;

// for every positive edge of the clock below operation take place
always @(posedge clk or negedge rstn)
begin
    if (!rstn) // check condition reset=0, reset the dout to 0
        dout = 4'b0000;
    else if (en)
        case (din)
            2'b00: dout = 4'b0001;
            2'b01: dout = 4'b0010;
            2'b10: dout = 4'b0100;
            2'b11: dout = 4'b1000;
            default dout = 4'b0000;
        endcase
end

endmodule