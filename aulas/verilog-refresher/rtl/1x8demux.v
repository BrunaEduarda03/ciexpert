//Function: The design works based on the selected lines; appropriate output for
//given input is generated.
//Design file: demux3x8.v
//∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗
// Module works based on the select lines. If select lines is 2, the 2nd bit in output will be
//high //
// and rest will be zeros.
// This is combinational block which doesn’t require clock and reset but the //
// output is latched using clock. //
// User can refer to any Verilog HDL language book to understand the syntax of
//commands. //
//∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗/
//1:8 demultiplxer with 3 selectlines
module demux1x8(
    clk,
    rstn,
    en,
    sel,
    din,
    dout
);

//--------------input ports-----------
input clk; // input clock of the design
input rstn;// active low reset
input en;// active high enable
input [2:0] sel;// select lines
input din;// datain

//--------------output ports-----------
output [7:0] dout;// output data

//--------------input datatypes-----------
wire clk;
wire rstn;
wire en;
wire din;
wire [2:0] sel;

//--------------output datatypes-----------
reg [7:0] dout;

// for every postitive edge of clock perform below operation
always @(posedge clk or negedge rstn)
begin
    if (!rstn) // check condition reset=0,reset dout to 0
        dout = 0;
    else if (en)
        case(sel)
            3'b000: begin
                dout[0] = din;
                dout[7:1] = 7'b0;
            end
            3'b001: begin
                dout[1] = din;
                dout[0] = 1'b0;
                dout[7:2] = 6'b0;
            end
            3'b010: begin
                dout[2] = din;
                dout[1:0] = 2'b0;
                dout[7:3] = 5'b0;
            end
            3'b011: begin
                dout[3] = din;
                dout[2:0] = 3'b0;
                dout[7:4] = 4'b0;
            end
            3'b100: begin
                dout[4] = din;
                dout[3:0] = 4'b0;
                dout[7:5] = 3'b0;
            end
            3'b101: begin
                dout[5] = din;
                dout[4:0] = 5'b0;
                dout[7:6] = 2'b0;
            end
            3'b110: begin
                dout[6] = din;
                dout[5:0] = 6'b0;
                dout[7] = 1'b0;
            end
            3'b111: begin
                dout[7] = din;
                dout[6:0] = 7'b0;
            end
        endcase
end

endmodule