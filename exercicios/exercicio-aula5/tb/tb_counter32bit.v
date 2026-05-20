//Function: The test bench is the module where the counter_overflow is instantiated
//and test stimulus to be applied to the IO signals of the design are generated. During
//simulation, the stimulus generated are applied and design responses are captured.
//Signals enable and load are set appropriately and 32-bit counting sequence is
//verified. The waveform file counter_overflow_tb.vcd is written out during the simulation
//by the test bench, which can be observed using waveform viewer.
//Test bench file: counter_overflow_tb.v

module counter_overflow_tb;

// Inputs
reg clk;
reg reset_n;
reg en;
reg load;

// Outputs
wire [31:0] counter_out;
wire counter_overflow;

always
    #5 clk = ~clk;

initial
begin
    clk = 0;
    reset_n = 0;
    en = 0;
    load = 0;

    #10 reset_n = 0;
    #10 reset_n = 1;
    #10 en = 1;
    #10 load = 1;
    #80 en = 0;
    #10 en = 1;

    #10000 $finish;
end

counter_overflow uut (
    .clk(clk),
    .reset_n(reset_n),
    .en(en),
    .counter_out(counter_out),
    .counter_overflow(counter_overflow),
    .load(load)
);

initial
begin
    $fsdbDumpvars();
end

endmodule