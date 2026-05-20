//Function: The design encodes 4-bit din.
//Design file: encoder4x2.v
//∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗
// Module starts encoding 4-bit din
// This is combinational block which doesn’t require clock and reset. But clock used to
//latch the output.//
//User can refer to any Verilog HDL language book to understand the syntax of
//commands. //
//∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗/
//4:2 encoder
module encoder4x2(
    din,
    clk,
    dout,
    rstn,
    en
);

//------------------------input ports------------
input en;        // active high enable
input clk;       // clock input of the design
input rstn;      // avtive low reset
input [3:0] din; // 4 bit input data

//------------------------output ports------------
output [1:0] dout; //2 bit output data

//------------------------input datatypes------------
wire en;
wire rstn;
wire [3:0] din;

//------------------------output datatypes------------
reg [1:0] dout;

// for every positive edge of the clock below operation has to take place
always @(posedge clk or negedge rstn)
begin
    if (!rstn)
        dout = 2'b00;
    else if (en)
        case (din)
            4'b0001: dout = 2'b00;
            4'b0010: dout = 2'b01;
            4'b0100: dout = 2'b10;
            4'b1000: dout = 2'b11;
            default dout = 2'b00;
        endcase
end

endmodule