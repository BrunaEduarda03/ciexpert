//2 × 2 matrix multiplication
//Inputs: two 32-bit operands in A, B,clk,rstn,en
//Outputs: 32-bit Res
//Function: The design performs matrix multiplication of two operands of 32-bit
//binary numbers stored in A and B both 32-bit registers representing the operands.
//The result is stored in 32-bit Res register.
//Design file: matrix2x2_mult.v
//∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗
// Module works for 2x2 matrix multiplication. Both the inputs are converted to 1D to 3D
//
// array and becomes and each rows and columns will have 8 bit. //
// This is combinational block which doesn’t require clock and reset //
//User can refer to any Verilog HDL language book to understand the syntax of
//commands. //
//∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗/
//2x2 matrix multiplication
module matrix2x2_mult(A, B, Res, clk, rstn, en);

//-------------input port--------------------
input clk, rstn, en;
input [31:0] A;
input [31:0] B;

// ------------------------output port-----------
output [31:0] Res;

//------------------input datatype------------
wire clk, rstn, en;

//------------------output datatype------------
reg [31:0] Res;
reg [7:0] A1 [0:1][0:1];
reg [7:0] B1 [0:1][0:1];
reg [7:0] Res1 [0:1][0:1];

//for ever A and B value below format should be adopted
always @ (A or B)
begin
    {A1[0][0], A1[0][1], A1[1][0], A1[1][1]} = A;
    {B1[0][0], B1[0][1], B1[1][0], B1[1][1]} = B;
end

//for every posedge of clock below operation should take place
always @ (posedge clk or negedge rstn)
begin
    if (!rstn) begin
        {Res1[0][0], Res1[0][1], Res1[1][0], Res1[1][1]} = 32'd0;
    end
    else if (en) begin
        Res1[0][0] = (A1[0][0] * B1[0][0]) + (A1[0][1] * B1[1][0]);
        Res1[0][1] = (A1[0][0] * B1[0][1]) + (A1[0][1] * B1[1][1]);
        Res1[1][0] = (A1[1][0] * B1[0][0]) + (A1[1][1] * B1[1][0]);
        Res1[1][1] = (A1[1][0] * B1[0][1]) + (A1[1][1] * B1[1][1]);
        Res = {Res1[0][0], Res1[0][1], Res1[1][0], Res1[1][1]};
    end
end

endmodule