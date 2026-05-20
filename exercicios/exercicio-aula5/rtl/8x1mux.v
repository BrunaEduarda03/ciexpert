//Inputs: din, sel,clk,rstn,en
//Outputs: dout
//Function: The design works based on the selected lines; appropriate output for
//given input is generated.
//Design file: mux8x1.v
//∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗
// Module works based on the select lines. If select line is 1 1st input is selected and goes
//on..
// mux is a combinational block which doesn’t require clock and reset but the output from
// mux is latched on clokedge as can be seen in the model.
// User can refer to any Verilog HDL language book to understand the syntax of
//commands.
//∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗/
//8:1 multiplexer
module mux8x1(
    clk,// clock input of the design
    rstn,// avtive low reset
    en,// avtive high enable
    din, //data input
    sel,// select lines
    dout// data output
);

//---------------------------input port------------
input clk;
input rstn;
input en;
input [7:0] din;
input [2:0] sel;

//---------------------------output port-------------
output dout;

//-----------------------------input datatype=---------
wire clk;
wire rstn;
wire en;
wire [7:0] din;
wire [2:0] sel;

// -----------------------output datatype---------------
reg dout;

// for every posedge of the clock below operation should take place
always @(posedge clk or negedge rstn)
begin
    if (!rstn)
        dout = 0;
    else if (en)
        case(sel)
            3'b000: dout = din[0];
            3'b001: dout = din[1];
            3'b010: dout = din[2];
            3'b011: dout = din[3];
            3'b100: dout = din[4];
            3'b101: dout = din[5];
            3'b110: dout = din[6];
            3'b111: dout = din[7];
        endcase
end

endmodule