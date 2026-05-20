//Inputs: Nil
//Outputs: Nil
//Function: The test bench applies random values to op_a and op_b operands and
//checks the result of addition by generating a signal match to indicate the correct
//behavior. The waveform adder_tb.vcd is written out which can be observed using
//waveform viewer.
//Test Bench File: 32bit_adder_tb.v
module adder_tb;
  //---------------- Inputs--------
  reg clk;
  reg reset_n;
  reg en;
  reg [31:0] A;
  reg [31:0] B;
  //------------------ Outputs-----------
  wire [31:0] sum;
  wire carry_out;
  // clock generation

  always #5 clk = ~clk; // toggle clock for every 5 ticks
  
  initial begin
    clk = 0;
    reset_n = 1;
    en = 0;
    $display("--------- Test Started ---------");
    #10 reset_n = 0;
    #10 reset_n = 1;
    en = 1;

    $display("--------- Sending Data A = 32'hAAAAAAAA and B = 32'hEEEEEEEE ---------");
    A = 32'hAAAAAAAA;
    B = 32'hEEEEEEEE;
    $display("--------- Sending Data A = 32'h7777777 and B = 32'h2456321 ---------");
    #10
    A = 32'h7777777;
    B = 32'h2456321;
    $display("--------- Sending Data A = 32'hCCCCCCCC and B = 32'hBBBBBBB ---------");
    #10
    A = 32'hCCCCCCCC;
    B = 32'hBBBBBBB;
    $display("--------- Sending Data A = 32'h11111111 and B = 32'b11111111 ---------");
    #10
    A = 32'h11111111;
    B = 32'h11111111;
    $display("--------- Test Ended ---------");
  end

  //module instantiation
  adder u_adder(
    .clk(clk),
    .reset_n(reset_n),
    .en(en),
    .op_a(A),
    .op_b(B),
    .adder_out(sum),
    .carry_out(carry_out)
  );

  reg [8*200:1] fsdb_name;

  initial begin
    if (!$value$plusargs("FSDB=%s", fsdb_name))
      fsdb_name = "adder32.fsdb";

    $display("[TB] FSDB file = %0s", fsdb_name);
    $fsdbDumpfile(fsdb_name);
    $fsdbDumpvars();

    #1000 $finish;
  end
endmodule
