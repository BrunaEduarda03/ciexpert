//Inputs: Nil
//Outputs: Nil
//Function: The test bench applies random values and checks the result of counting.
//The waveform updown_counter_tb.vcd can be observed using waveform viewer.
//Test bench file: updown_counter_tb.v

module updown_counter_tb;

// Inputs
reg clk;
reg resetn;
reg en;

// Outputs
wire [3:0] up_counter;
wire [3:0] down_counter;

// clock generation
always #5 clk = ~clk; // toggle clock for every 5 ticks

initial begin
    // Initialize Inputs
    clk = 0;
    resetn = 1;
    en = 0;

    //$display("--------- Test Started ---------");

    #10 resetn = 0;
    #10 resetn = 1;

    en = 1;

    #500 $finish;
end

updowncounter uut (
    .clk(clk),
    .resetn(resetn),
    .en(en),
    .up_counter(up_counter),
    .down_counter(down_counter)
);

initial begin
    $fsdbDumpvars(0, updown_counter_tb);
end

endmodule