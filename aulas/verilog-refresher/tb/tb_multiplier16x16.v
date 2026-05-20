//Inputs: Nil
//Outputs: Nil
//Function: The test bench applies random values of op_a and op_b, and result is
//stored in 32-bit register. The waveform multiplier_tb.vcd can be observed using
//waveform viewer.
//∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗/
//Test bench file: multiplier_tb.v

module multiplier_tb;

reg clk;
reg reset_n;
reg en;
reg [15:0] op_a;
reg [15:0] op_b;
wire [31:0] multi_out;

multiplier u1 (clk, reset_n, en, op_a, op_b, multi_out);

always #5 clk = ~clk;

initial
begin
    clk = 0;
    reset_n = 0;
    en = 0;
    op_a = 0;
    op_b = 0;

    #10 reset_n = 0;
    #10 reset_n = 1;

    en = 1;
    op_a = 16'hAAAA;
    op_b = 16'hBBBB;

    #10 op_a = 16'h4444;
    op_b = 16'h1111;

    #100 $finish;
end

initial
begin
    $fsdbDumpvars();
end

endmodule