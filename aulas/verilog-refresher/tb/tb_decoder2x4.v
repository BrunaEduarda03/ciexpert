//Function: The test bench applies random values to 2-bit din and checks the decoded
//4-bit dout. The waveform decoder2x4_tb.vcd can be observed using waveform
//viewer.
//est bench file: decoder2x4_tb.v

module decoder2x4_tb;

// Inputs
reg clk;
reg rstn;
reg en;
reg [1:0] din;

// Outputs
wire [3:0] dout;

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

    din = 2'b00;
    #10 din = 2'b01;
    #10 din = 2'b10;
    #10 din = 2'b11;

    #100 $finish;
end

decoder2x4 uut (
    .clk(clk),
    .rstn(rstn),
    .en(en),
    .din(din),
    .dout(dout)
);

initial begin
    $dumpfile("decoder2x4_tb.vcd");
    $dumpvars(0, decoder2x4_tb);
end

endmodule