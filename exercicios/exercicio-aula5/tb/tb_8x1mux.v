//Function: The test bench applies random values to 3-bit select lines and checks the
//dout. The waveform mux8x1_tb.vcd can be observed using waveform viewer.
//Test bench file: mux8x1_tb.v

module mux8x1_tb;

// Inputs
reg clk;
reg rstn;
reg en;
reg [7:0] din;
reg [2:0] sel;

// Outputs
wire dout;

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

    sel = 3'b000; din = 8'b00000001;
    #10 sel = 3'b001; din = 8'b00000010;
    #10 sel = 3'b010; din = 8'b00000100;
    #10 sel = 3'b011; din = 8'b00001000;
    #10 sel = 3'b100; din = 8'b00010000;
    #10 sel = 3'b101; din = 8'b00100000;
    #10 sel = 3'b110; din = 8'b01000000;
    #10 sel = 3'b111; din = 8'b10000000;
    #10 sel = 3'b111; din = 8'b00000000;
    #10 sel = 3'b110; din = 8'b10000000;
    #10 sel = 3'b100; din = 8'b00010000;

    #100 $finish;
end

mux8x1 uut (
    .clk(clk),
    .rstn(rstn),
    .en(en),
    .din(din),
    .sel(sel),
    .dout(dout)
);

initial begin
    $dumpfile("mux8x1_tb.vcd");
    $dumpvars(0, mux8x1_tb);
end

endmodule