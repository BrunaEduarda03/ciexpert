//Function: The test bench applies random values of A and B, and result is stored in
//32-bit Res. The waveform matrix2x2_mult_tb.vcd can be observed using waveform
//viewer.
//Test bench file: matrix2x2_mult_tb.v

module matrix2x2_mult_tb();

reg [31:0] A;
reg [31:0] B;
reg clk;
reg rstn;
reg en;

// Outputs
wire [31:0] Res;

always #5 clk = ~clk;

initial begin
    clk = 0;
    rstn = 0;
    en = 0;
    A = 0;
    B = 0;

    #10 rstn = 0;
    #10 rstn = 1;
    #10 en = 1;

    A = 32'b00000001000000010000000100000001;
    #10 B = 32'b00000001000000010000000100000001;
    #10 A = 32'b00000010000000100000001000000010;
    #10 B = 32'b00000010000000100000001000000010;

    #100 $finish;
end

matrix2x2_mult uut (
    .A(A),
    .B(B),
    .Res(Res),
    .clk(clk),
    .rstn(rstn),
    .en(en)
);

initial begin
    $dumpfile("matrix2x2_mult_tb.vcd");
    $dumpvars(0, matrix2x2_mult_tb);
end

endmodule