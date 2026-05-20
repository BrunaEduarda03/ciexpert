//Function: The test bench applies random values to 4-bit din and checks the encoded
//2-bit dout. The waveform encoder4x2_tb.vcd can be observed using waveform
//viewer.
//Test bench file: encoder4x2_tb.v

module encoder4x2_tb;

// Inputs
reg [3:0] din;
reg en;
reg clk;
reg rstn;

// Outputs
wire [1:0] dout;

// clock generation
always #5 clk = ~clk; // toggle clock for every 5 ticks

initial begin
    // Initialize Inputs
    clk = 0;
    rstn = 1;
    en = 0;

    //$display("--------- Test Started ---------");

    #10 rstn = 0;
    #10 rstn = 1;

    en = 1;

    din = 4'b0001;
    #10 din = 4'b0010;
    #10 din = 4'b0100;
    #10 din = 4'b1000;

    #100 $finish;
end

encoder4x2 uut (
    .clk(clk),
    .din(din),
    .dout(dout),
    .rstn(rstn),
    .en(en)
);

initial begin
    $dumpfile("encoder4x2_tb.vcd");
    $dumpvars(0, encoder4x2_tb);
end

endmodule